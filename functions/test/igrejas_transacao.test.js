/**
 * Prova de atomicidade da criação de unidade.
 *
 * Executa o handler real contra o Firestore Emulator. O caso de falha usa um
 * documento maior que o limite do Firestore: a rejeição acontece no commit,
 * depois que raiz, catálogo e auditoria já foram enfileirados na transação.
 */
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-nova-alianca";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const assert = require("node:assert/strict");
const { after, before, beforeEach, describe, it } = require("node:test");

const { atualizarIgreja, criarIgreja } = require("../lib/churches/igrejas");
const { db } = require("../lib/firebase");

function requisicao(data, uid = "super_admin_transacao") {
  return {
    auth: {
      uid,
      token: { super_admin: true },
    },
    data,
    rawRequest: {},
  };
}

async function limparTudo() {
  await db.recursiveDelete(db.collection("igrejas"));
  await db.recursiveDelete(db.collection("catalogo_igrejas"));
}

async function auditorias(igrejaId) {
  return db
    .collection(`igrejas/${igrejaId}/auditoria`)
    .where("acao", "==", "criar_igreja")
    .get();
}

describe("criarIgreja: transação raiz + catálogo + auditoria", () => {
  before(async () => {
    await db.doc("_ping/_ping").set({ em: Date.now() });
    await db.doc("_ping/_ping").delete();
  });

  beforeEach(limparTudo);

  after(async () => {
    await limparTudo();
    await db.terminate();
  });

  it("persiste os três efeitos no mesmo sucesso", async () => {
    const igrejaId = "unidade_tx_sucesso";

    const resultado = await criarIgreja.run(
      requisicao({
        igrejaId,
        nome: "Unidade Transacional",
        dados_institucionais: {
          endereco: "Rua do Teste, 10",
          cidade_estado: "Olinda - PE",
          endereco_secundario: "  Próximo à praça  ",
          slogan: "  Família para pertencer  ",
          cultos_recorrentes: ["  Domingo 18h  ", "Domingo 18h"],
          instagram: "  @novaalianca  ",
          youtube_url: "  https://youtube.example/canal  ",
          pastores_publicos: ["  Pastora Ana  "],
          pix_chave: "privado-na-raiz",
        },
      })
    );

    assert.deepEqual(resultado, {
      ok: true,
      igrejaId,
      nome: "Unidade Transacional",
    });

    const [raiz, catalogo, logs] = await Promise.all([
      db.doc(`igrejas/${igrejaId}`).get(),
      db.doc(`catalogo_igrejas/${igrejaId}`).get(),
      auditorias(igrejaId),
    ]);

    assert.equal(raiz.exists, true);
    assert.equal(catalogo.exists, true);
    assert.equal(logs.size, 1);
    assert.equal(logs.docs[0].data().autor_id, "super_admin_transacao");
    assert.deepEqual(catalogo.data(), {
      nome: "Unidade Transacional",
      ativa: false,
      configurada: true,
      endereco: "Rua do Teste, 10",
      cidade_estado: "Olinda - PE",
      endereco_secundario: "Próximo à praça",
      slogan: "Família para pertencer",
      cultos_recorrentes: ["Domingo 18h"],
      instagram: "@novaalianca",
      youtube_url: "https://youtube.example/canal",
      pastores_publicos: ["Pastora Ana"],
    });
    assert.equal(raiz.data().dados_institucionais.pix_chave, "privado-na-raiz");
    assert.equal(JSON.stringify(catalogo.data()).includes("privado-na-raiz"), false);
  });

  it("atualiza campos públicos sanitizados e sobrescreve o catálogo fechado", async () => {
    const igrejaId = "unidade_tx_atualiza";
    await criarIgreja.run(
      requisicao({ igrejaId, nome: "Unidade Atualizável" })
    );

    await atualizarIgreja.run(
      requisicao({
        igrejaId,
        dados_institucionais: {
          slogan: "  Novo slogan  ",
          cultos_recorrentes: ["  Quarta 19h  ", "", "Quarta 19h"],
          pastores_publicos: ["  Pastor Um  ", "Pastora Dois"],
          telefone: "privado-no-catalogo",
        },
      })
    );

    const [raiz, catalogo] = await Promise.all([
      db.doc(`igrejas/${igrejaId}`).get(),
      db.doc(`catalogo_igrejas/${igrejaId}`).get(),
    ]);
    assert.deepEqual(raiz.data().dados_institucionais.cultos_recorrentes, [
      "Quarta 19h",
    ]);
    assert.deepEqual(catalogo.data(), {
      nome: "Unidade Atualizável",
      ativa: false,
      configurada: true,
      endereco: null,
      cidade_estado: null,
      endereco_secundario: null,
      slogan: "Novo slogan",
      cultos_recorrentes: ["Quarta 19h"],
      instagram: null,
      youtube_url: null,
      pastores_publicos: ["Pastor Um", "Pastora Dois"],
    });
    assert.equal(JSON.stringify(catalogo.data()).includes("privado-no-catalogo"), false);
  });

  it("não persiste nenhum efeito quando o commit transacional falha", async () => {
    const igrejaId = "unidade_tx_falha";
    // O UID não passa pela sanitização institucional e é incluído na raiz e
    // na auditoria. O tamanho inválido só é rejeitado no commit, depois que
    // raiz, catálogo e auditoria já foram enfileirados na transação.
    const uidGrandeDemais = "u".repeat(1_100_000);

    await assert.rejects(
      criarIgreja.run(
        requisicao({
          igrejaId,
          nome: "Unidade que Deve Falhar",
          dados_institucionais: { endereco: "Rua válida, 10" },
        }, uidGrandeDemais)
      )
    );

    const [raiz, catalogo, logs] = await Promise.all([
      db.doc(`igrejas/${igrejaId}`).get(),
      db.doc(`catalogo_igrejas/${igrejaId}`).get(),
      auditorias(igrejaId),
    ]);

    assert.equal(raiz.exists, false);
    assert.equal(catalogo.exists, false);
    assert.equal(logs.empty, true);
  });
});
