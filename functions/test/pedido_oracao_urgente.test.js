/** Testes da trigger de oração urgente sem chamar o FCM real. */
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-nova-alianca";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const assert = require("node:assert/strict");
const { after, before, beforeEach, describe, it } = require("node:test");

const { db } = require("../lib/firebase");
const {
  dividirEmLotes,
  processarPedidoOracaoUrgente,
} = require("../lib/notifications/pedidoOracaoUrgente");

const IGREJA = "olinda";

async function limparTudo() {
  await db.recursiveDelete(db.collection("igrejas"));
  await db.recursiveDelete(db.collection("usuarios"));
}

async function membro(igrejaId, uid, perfil, status = "aprovado") {
  await db.doc(`igrejas/${igrejaId}/membros/${uid}`).set({ perfil, status });
}

async function token(uid, valor, ativo = true) {
  await db.doc(`usuarios/${uid}/tokens_dispositivo/${valor}`).set({
    token: valor,
    ativo,
  });
}

function evento(extra = {}) {
  return {
    igrejaId: IGREJA,
    pedidoId: "pedido-secreto",
    eventId: "evento-unico-1",
    dados: {
      urgente: true,
      autor_id: "autor-cadastrado",
      descricao: "texto pastoral que nao pode vazar",
      autor_nome: "Nome Confidencial",
      categoria: "saude",
      privado: true,
    },
    ...extra,
  };
}

function remetenteFake(respostas) {
  const chamadas = [];
  return {
    chamadas,
    dependencias: {
      firestore: db,
      async buscarAutor() {
        return {
          disabled: false,
          providerData: [{ providerId: "password" }],
        };
      },
      async enviarMulticast(mensagem) {
        chamadas.push(mensagem);
        return {
          responses:
            typeof respostas === "function"
              ? respostas(mensagem)
              : mensagem.tokens.map(() => ({ success: true })),
        };
      },
    },
  };
}

describe("notificacao de pedido de oracao urgente", () => {
  before(async () => {
    await db.doc("_ping/_ping").set({ em: Date.now() });
    await db.doc("_ping/_ping").delete();
  });

  beforeEach(limparTudo);
  after(limparTudo);

  it("ignora pedido comum sem consultar destinatarios nem enviar", async () => {
    const fake = remetenteFake();
    const resultado = await processarPedidoOracaoUrgente(
      evento({ dados: { urgente: false } }),
      fake.dependencias
    );

    assert.equal(resultado.estado, "nao_urgente");
    assert.equal(fake.chamadas.length, 0);
  });

  it("nao envia para autor anonimo mesmo com campo anonimo forjado como false", async () => {
    await membro(IGREJA, "pastor", "pastor");
    await token("pastor", "token-pastor");
    const fake = remetenteFake();
    fake.dependencias.buscarAutor = async () => ({
      disabled: false,
      providerData: [],
    });

    const resultado = await processarPedidoOracaoUrgente(
      evento({
        dados: {
          urgente: true,
          autor_id: "visitante-anonimo",
          anonimo: false,
          descricao: "urgencia privada",
        },
      }),
      fake.dependencias
    );

    assert.equal(resultado.estado, "autor_nao_elegivel");
    assert.equal(fake.chamadas.length, 0);
  });

  it("envia mensagem generica so a liderancas aprovadas da mesma igreja", async () => {
    await membro(IGREJA, "pastor", "pastor");
    await membro(IGREJA, "diacono", "diacono");
    await membro(IGREJA, "lider_inativo", "lider", "inativo");
    await membro(IGREJA, "membro", "membro");
    await membro("petrolina", "lider_outra", "lider");

    await token("pastor", "token-compartilhado");
    await token("diacono", "token-compartilhado");
    await token("diacono", "token-diacono");
    await token("lider_inativo", "token-inativo");
    await token("membro", "token-membro");
    await token("lider_outra", "token-outra-igreja");

    const fake = remetenteFake();
    const resultado = await processarPedidoOracaoUrgente(
      evento(),
      fake.dependencias
    );

    assert.equal(resultado.estado, "enviado");
    assert.equal(resultado.tokensEncontrados, 2);
    assert.equal(fake.chamadas.length, 1);
    assert.deepEqual(fake.chamadas[0].tokens, [
      "token-compartilhado",
      "token-diacono",
    ]);
    assert.deepEqual(fake.chamadas[0].notification, {
      title: "Pedido de oração urgente",
      body: "Uma pessoa solicitou apoio espiritual urgente na sua igreja.",
    });
    assert.deepEqual(fake.chamadas[0].data, {
      tipo: "pedido_oracao_urgente",
      rota: "/moderacao-oracao",
    });

    const serializado = JSON.stringify(fake.chamadas[0]);
    for (const segredo of [
      "texto pastoral",
      "Nome Confidencial",
      "saude",
      "privado",
      "pedido-secreto",
    ]) {
      assert.equal(serializado.includes(segredo), false, `push vazou: ${segredo}`);
    }
  });

  it("remove somente tokens definitivamente invalidos", async () => {
    await membro(IGREJA, "lider", "lider");
    await token("lider", "token-invalido");
    await token("lider", "token-transitorio");
    await token("lider", "token-valido");

    const fake = remetenteFake((mensagem) =>
      mensagem.tokens.map((valor) => {
        if (valor === "token-invalido") {
          return {
            success: false,
            error: { code: "messaging/registration-token-not-registered" },
          };
        }
        if (valor === "token-transitorio") {
          return {
            success: false,
            error: { code: "messaging/internal-error" },
          };
        }
        return { success: true };
      })
    );

    const resultado = await processarPedidoOracaoUrgente(
      evento({ eventId: "evento-token-invalido" }),
      fake.dependencias
    );

    assert.equal(resultado.tokensRemovidos, 1);
    assert.equal(
      (await db.doc("usuarios/lider/tokens_dispositivo/token-invalido").get()).exists,
      false
    );
    assert.equal(
      (await db.doc("usuarios/lider/tokens_dispositivo/token-transitorio").get()).exists,
      true
    );
    assert.equal(
      (await db.doc("usuarios/lider/tokens_dispositivo/token-valido").get()).exists,
      true
    );
  });

  it("deduplica a entrega repetida do mesmo CloudEvent", async () => {
    await membro(IGREJA, "pastor", "pastor");
    await token("pastor", "token-pastor");
    const fake = remetenteFake();

    const primeira = await processarPedidoOracaoUrgente(evento(), fake.dependencias);
    const segunda = await processarPedidoOracaoUrgente(evento(), fake.dependencias);

    assert.equal(primeira.estado, "enviado");
    assert.equal(segunda.estado, "duplicado");
    assert.equal(fake.chamadas.length, 1);
  });

  it("limita por autor e igreja por dez minutos sem confundir CloudEvents", async () => {
    await membro(IGREJA, "pastor", "pastor");
    await token("pastor", "token-pastor");
    let agoraEmMs = Date.UTC(2026, 7, 19, 12, 0, 0);
    const fake = remetenteFake();
    fake.dependencias.agoraEmMs = () => agoraEmMs;

    const primeiro = await processarPedidoOracaoUrgente(
      evento({ eventId: "evento-rate-1", pedidoId: "pedido-rate-1" }),
      fake.dependencias
    );
    const limitado = await processarPedidoOracaoUrgente(
      evento({ eventId: "evento-rate-2", pedidoId: "pedido-rate-2" }),
      fake.dependencias
    );

    assert.equal(primeiro.estado, "enviado");
    assert.equal(limitado.estado, "limitado");
    assert.equal(limitado.tokensEncontrados, 1);
    assert.equal(fake.chamadas.length, 1);

    agoraEmMs += 10 * 60 * 1000;
    const depoisDaJanela = await processarPedidoOracaoUrgente(
      evento({ eventId: "evento-rate-3", pedidoId: "pedido-rate-3" }),
      fake.dependencias
    );

    assert.equal(depoisDaJanela.estado, "enviado");
    assert.equal(fake.chamadas.length, 2);
  });

  it("divide mais de 500 tokens em lotes aceitos pelo FCM", () => {
    const lotes = dividirEmLotes(Array.from({ length: 1001 }, (_, i) => i));
    assert.deepEqual(lotes.map((lote) => lote.length), [500, 500, 1]);
  });
});
