/**
 * Testes da transferência oficial de vínculo entre unidades.
 *
 * Rodam contra o Firestore Emulator (projeto lógico `demo-nova-alianca`) e
 * exercitam o HANDLER real, com o guard de autorização incluído — um teste que
 * chamasse só a lógica interna não provaria que líder e pastor são barrados.
 *
 * Executar: `npm test` dentro de `functions/`.
 */
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-nova-alianca";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const assert = require("node:assert/strict");
const { after, before, beforeEach, describe, it } = require("node:test");

const { db } = require("../lib/firebase");
const {
  transferirVinculoIgrejaHandler,
} = require("../lib/members/transferencia");

const OLINDA = "olinda";
const PETROLINA = "petrolina";
const MOTIVO = "Mudanca de cidade confirmada pela familia.";

/** `CallableRequest` mínimo — o handler só usa `auth` e `data`. */
function requisicao(uid, { superAdmin = false } = {}, data = {}) {
  return {
    auth: { uid, token: { super_admin: superAdmin } },
    data,
    rawRequest: {},
  };
}

function pedidoTransferencia(extra = {}) {
  return {
    uid: "membro_ana",
    igrejaOrigemId: OLINDA,
    igrejaDestinoId: PETROLINA,
    motivo: MOTIVO,
    ...extra,
  };
}

async function vinculo(igrejaId, uid) {
  const snap = await db.doc(`igrejas/${igrejaId}/membros/${uid}`).get();
  return snap.exists ? snap.data() : null;
}

async function auditoria(igrejaId) {
  const snap = await db
    .collection(`igrejas/${igrejaId}/auditoria`)
    .where("acao", "==", "transferir_vinculo_igreja")
    .get();
  return snap.docs.map((d) => d.data());
}

async function limparTudo() {
  await db.recursiveDelete(db.collection("igrejas"));
  await db.recursiveDelete(db.collection("usuarios"));
}

/**
 * Estado inicial: duas unidades ativas, uma pessoa com vínculo aprovado em
 * Olinda e um chamador de cada papel que precisamos testar.
 */
async function semear({ perfilAna = "lider", funcoesAna = ["tesoureiro"] } = {}) {
  await limparTudo();

  await db.doc(`igrejas/${OLINDA}`).set({ nome: "Nova Alianca Olinda", ativa: true });
  await db.doc(`igrejas/${PETROLINA}`).set({ nome: "Nova Alianca Petrolina", ativa: true });

  await db.doc(`igrejas/${OLINDA}/membros/membro_ana`).set({
    nome: "Ana",
    email: "ana@exemplo.test",
    status: "aprovado",
    perfil: perfilAna,
    funcoes_admin: funcoesAna,
    ministerio_ids: ["louvor"],
  });
  await db.doc("usuarios/membro_ana").set({
    nome: "Ana",
    igreja_principal_id: OLINDA,
  });

  // Pastor e líder de Olinda: são eles que NÃO podem transferir.
  await db.doc(`igrejas/${OLINDA}/membros/pastor_olinda`).set({
    status: "aprovado",
    perfil: "pastor",
    funcoes_admin: ["pastor"],
  });
  await db.doc(`igrejas/${OLINDA}/membros/lider_olinda`).set({
    status: "aprovado",
    perfil: "lider",
    funcoes_admin: [],
  });
}

/** Executa e devolve o erro lançado, falhando se não houver erro. */
async function capturarErro(promessa) {
  try {
    await promessa;
  } catch (erro) {
    return erro;
  }
  assert.fail("esperava um erro, mas a operacao foi concluida");
}

describe("transferirVinculoIgreja", () => {
  before(async () => {
    // Falha cedo e com mensagem clara quando o emulador não está de pé.
    await db.doc("_ping/_ping").set({ em: Date.now() });
    await db.doc("_ping/_ping").delete();
  });

  beforeEach(async () => {
    await semear();
  });

  after(async () => {
    await limparTudo();
    await db.terminate();
  });

  // ── Autorização ────────────────────────────────────────────────────

  it("nega para usuario sem sessao", async () => {
    const erro = await capturarErro(
      transferirVinculoIgrejaHandler({ data: pedidoTransferencia() })
    );
    assert.equal(erro.code, "unauthenticated");
  });

  it("nega para lider comum da unidade de origem", async () => {
    const erro = await capturarErro(
      transferirVinculoIgrejaHandler(
        requisicao("lider_olinda", { superAdmin: false }, pedidoTransferencia())
      )
    );
    assert.equal(erro.code, "permission-denied");
    // Nada mudou.
    assert.equal((await vinculo(OLINDA, "membro_ana")).status, "aprovado");
    assert.equal(await vinculo(PETROLINA, "membro_ana"), null);
  });

  it("nega para pastor da unidade de origem", async () => {
    const erro = await capturarErro(
      transferirVinculoIgrejaHandler(
        requisicao("pastor_olinda", { superAdmin: false }, pedidoTransferencia())
      )
    );
    assert.equal(erro.code, "permission-denied");
    assert.equal((await vinculo(OLINDA, "membro_ana")).status, "aprovado");
  });

  // ── Validação de entrada ───────────────────────────────────────────

  it("exige motivo", async () => {
    const erro = await capturarErro(
      transferirVinculoIgrejaHandler(
        requisicao(
          "super",
          { superAdmin: true },
          pedidoTransferencia({ motivo: "oi" })
        )
      )
    );
    assert.equal(erro.code, "invalid-argument");
  });

  it("recusa origem igual ao destino", async () => {
    const erro = await capturarErro(
      transferirVinculoIgrejaHandler(
        requisicao(
          "super",
          { superAdmin: true },
          pedidoTransferencia({ igrejaDestinoId: OLINDA })
        )
      )
    );
    assert.equal(erro.code, "invalid-argument");
  });

  it("recusa unidade de destino inexistente", async () => {
    const erro = await capturarErro(
      transferirVinculoIgrejaHandler(
        requisicao(
          "super",
          { superAdmin: true },
          pedidoTransferencia({ igrejaDestinoId: "recife" })
        )
      )
    );
    assert.equal(erro.code, "not-found");
  });

  it("recusa quem nao tem vinculo na origem", async () => {
    const erro = await capturarErro(
      transferirVinculoIgrejaHandler(
        requisicao(
          "super",
          { superAdmin: true },
          pedidoTransferencia({ uid: "ninguem" })
        )
      )
    );
    assert.equal(erro.code, "not-found");
  });

  it("recusa vinculo pendente", async () => {
    await db
      .doc(`igrejas/${OLINDA}/membros/membro_ana`)
      .update({ status: "pendente" });

    const erro = await capturarErro(
      transferirVinculoIgrejaHandler(
        requisicao("super", { superAdmin: true }, pedidoTransferencia())
      )
    );
    assert.equal(erro.code, "failed-precondition");
    assert.equal(await vinculo(PETROLINA, "membro_ana"), null);
  });

  // ── Caminho feliz ──────────────────────────────────────────────────

  it("super_admin transfere: origem inativa, destino aprovado, cargos nao migram", async () => {
    const resultado = await transferirVinculoIgrejaHandler(
      requisicao("super", { superAdmin: true }, pedidoTransferencia())
    );

    assert.equal(resultado.ok, true);
    assert.equal(resultado.jaAplicada, false);
    assert.equal(resultado.perfilDestino, "membro");

    const origem = await vinculo(OLINDA, "membro_ana");
    assert.equal(origem.status, "inativo");
    assert.deepEqual(origem.funcoes_admin, []);
    // Documento e historico preservados.
    assert.equal(origem.perfil, "lider", "perfil historico permanece registrado");
    assert.equal(origem.nome, "Ana");
    assert.equal(origem.transferido_para, PETROLINA);
    assert.equal(origem.motivo_status, MOTIVO);

    const destino = await vinculo(PETROLINA, "membro_ana");
    assert.equal(destino.status, "aprovado");
    assert.equal(destino.perfil, "membro", "nenhum cargo atravessa a fronteira");
    assert.deepEqual(destino.funcoes_admin, []);
    assert.deepEqual(destino.ministerio_ids, [], "ministerios nao acompanham");
    assert.equal(destino.transferido_de, OLINDA);
    assert.equal(destino.nome, "Ana", "identificacao acompanha a pessoa");
  });

  it("atualiza igreja_principal_id do perfil global", async () => {
    await transferirVinculoIgrejaHandler(
      requisicao("super", { superAdmin: true }, pedidoTransferencia())
    );

    const usuario = (await db.doc("usuarios/membro_ana").get()).data();
    assert.equal(usuario.igreja_principal_id, PETROLINA);
    assert.equal(usuario.nome, "Ana", "dados pessoais preservados");
  });

  it("registra auditoria nas duas unidades", async () => {
    await transferirVinculoIgrejaHandler(
      requisicao("super", { superAdmin: true }, pedidoTransferencia())
    );

    const naOrigem = await auditoria(OLINDA);
    const noDestino = await auditoria(PETROLINA);

    assert.equal(naOrigem.length, 1);
    assert.equal(noDestino.length, 1);

    for (const registro of [naOrigem[0], noDestino[0]]) {
      assert.equal(registro.autor_id, "super");
      assert.equal(registro.autor_super_admin, true);
      assert.equal(registro.alvo_id, "membro_ana");
      assert.equal(registro.motivo, MOTIVO);
      assert.equal(registro.detalhes.origem, OLINDA);
      assert.equal(registro.detalhes.destino, PETROLINA);
      assert.equal(registro.detalhes.igreja_principal_anterior, OLINDA);
    }

    assert.deepEqual(
      naOrigem[0].detalhes.funcoes_revogadas_na_origem,
      ["tesoureiro"],
      "a auditoria registra qual funcao foi revogada"
    );
  });

  // ── Idempotência ───────────────────────────────────────────────────

  it("chamada repetida nao duplica efeito nem auditoria", async () => {
    const pedido = pedidoTransferencia();
    await transferirVinculoIgrejaHandler(
      requisicao("super", { superAdmin: true }, pedido)
    );
    const segunda = await transferirVinculoIgrejaHandler(
      requisicao("super", { superAdmin: true }, pedido)
    );

    assert.equal(segunda.jaAplicada, true);
    assert.equal((await auditoria(OLINDA)).length, 1);
    assert.equal((await auditoria(PETROLINA)).length, 1);
    assert.equal((await vinculo(OLINDA, "membro_ana")).status, "inativo");
    assert.equal((await vinculo(PETROLINA, "membro_ana")).status, "aprovado");
  });

  it("chamadas simultaneas nao deixam estado parcial", async () => {
    const pedido = pedidoTransferencia();
    const resultados = await Promise.allSettled([
      transferirVinculoIgrejaHandler(requisicao("super", { superAdmin: true }, pedido)),
      transferirVinculoIgrejaHandler(requisicao("super", { superAdmin: true }, pedido)),
    ]);

    const aplicadas = resultados.filter(
      (r) => r.status === "fulfilled" && r.value.jaAplicada === false
    );
    assert.equal(aplicadas.length, 1, "apenas uma execucao aplica a mudanca");

    assert.equal((await auditoria(OLINDA)).length, 1);
    assert.equal((await vinculo(OLINDA, "membro_ana")).status, "inativo");
    assert.equal((await vinculo(PETROLINA, "membro_ana")).status, "aprovado");
    assert.equal(
      (await db.doc("usuarios/membro_ana").get()).data().igreja_principal_id,
      PETROLINA
    );
  });

  // ── Pastor da unidade ──────────────────────────────────────────────

  it("transferir pastor exige confirmacao explicita", async () => {
    await semear({ perfilAna: "pastor", funcoesAna: ["pastor"] });

    const erro = await capturarErro(
      transferirVinculoIgrejaHandler(
        requisicao("super", { superAdmin: true }, pedidoTransferencia())
      )
    );
    assert.equal(erro.code, "failed-precondition");
    assert.match(erro.message, /confirmarSaidaDePastor/);
    assert.equal((await vinculo(OLINDA, "membro_ana")).status, "aprovado");
  });

  it("pastor e transferido com confirmacao e chega como membro comum", async () => {
    await semear({ perfilAna: "pastor", funcoesAna: ["pastor"] });

    const resultado = await transferirVinculoIgrejaHandler(
      requisicao(
        "super",
        { superAdmin: true },
        pedidoTransferencia({ confirmarSaidaDePastor: true })
      )
    );

    assert.equal(resultado.perfilDestino, "membro");
    assert.deepEqual((await vinculo(OLINDA, "membro_ana")).funcoes_admin, []);
    assert.equal((await vinculo(PETROLINA, "membro_ana")).perfil, "membro");
  });

  // ── Destino com vínculo preexistente ───────────────────────────────

  it("nao rebaixa quem ja tinha cargo proprio no destino", async () => {
    await db.doc(`igrejas/${PETROLINA}/membros/membro_ana`).set({
      status: "aprovado",
      perfil: "diacono",
      funcoes_admin: ["editor"],
    });

    const resultado = await transferirVinculoIgrejaHandler(
      requisicao("super", { superAdmin: true }, pedidoTransferencia())
    );

    assert.equal(resultado.perfilDestino, "diacono");
    const destino = await vinculo(PETROLINA, "membro_ana");
    assert.equal(destino.perfil, "diacono");
    assert.deepEqual(destino.funcoes_admin, ["editor"]);
  });

  it("vinculo inativo no destino volta como membro comum, sem cargo antigo", async () => {
    await db.doc(`igrejas/${PETROLINA}/membros/membro_ana`).set({
      status: "inativo",
      perfil: "pastor",
      funcoes_admin: ["pastor", "tesoureiro"],
    });

    const resultado = await transferirVinculoIgrejaHandler(
      requisicao("super", { superAdmin: true }, pedidoTransferencia())
    );

    assert.equal(resultado.perfilDestino, "membro");
    const destino = await vinculo(PETROLINA, "membro_ana");
    assert.equal(destino.perfil, "membro");
    assert.deepEqual(destino.funcoes_admin, []);
  });

  // ── Isolamento entre unidades ──────────────────────────────────────

  it("nao toca em vinculos de terceiros nem nas outras unidades", async () => {
    await transferirVinculoIgrejaHandler(
      requisicao("super", { superAdmin: true }, pedidoTransferencia())
    );

    const pastor = await vinculo(OLINDA, "pastor_olinda");
    assert.equal(pastor.status, "aprovado");
    assert.equal(pastor.perfil, "pastor");
    assert.deepEqual(pastor.funcoes_admin, ["pastor"]);

    // Petrolina recebeu exatamente um vinculo: o transferido.
    const membrosPetrolina = await db
      .collection(`igrejas/${PETROLINA}/membros`)
      .get();
    assert.deepEqual(
      membrosPetrolina.docs.map((d) => d.id),
      ["membro_ana"]
    );
  });
});
