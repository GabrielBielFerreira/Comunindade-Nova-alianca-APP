/**
 * Contrato de segurança do catálogo público e dos documentos raiz privados.
 *
 * `/catalogo_igrejas` é uma projeção sanitizada para o primeiro acesso.
 * `/igrejas` continua sendo a raiz institucional e de autorização da unidade.
 */
const { makeTestEnv, seed, assertFails, assertSucceeds } = require("./helpers");
const {
  OLINDA,
  PETROLINA,
  U,
  SEGREDO_CANARIO,
  CATALOGO_IGREJAS,
  semearBase,
} = require("./fixtures");

const CAMPOS_PUBLICOS = [
  "nome",
  "ativa",
  "configurada",
  "endereco",
  "cidade_estado",
  "endereco_secundario",
  "slogan",
  "cultos_recorrentes",
  "instagram",
  "youtube_url",
  "pastores_publicos",
].sort();

let testEnv;

beforeAll(async () => {
  testEnv = await makeTestEnv();
});

afterAll(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seed(testEnv, semearBase);
});

function anon() {
  return testEnv.unauthenticatedContext().firestore();
}

function db(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function dbSuper() {
  return testEnv.authenticatedContext(U.superAdmin, { super_admin: true }).firestore();
}

describe("CATÁLOGO público sanitizado", () => {
  test("consulta anônima exata com ativa == true é aceita", async () => {
    const snap = await assertSucceeds(
      anon().collection("catalogo_igrejas").where("ativa", "==", true).get()
    );

    expect(snap.docs.map((doc) => doc.id)).toEqual([OLINDA]);
    expect(snap.docs[0].data()).toEqual(CATALOGO_IGREJAS[OLINDA]);
    expect(Object.keys(snap.docs[0].data()).sort()).toEqual(CAMPOS_PUBLICOS);
  });

  test("consulta anônima sem o filtro ativa == true é negada", async () => {
    await assertFails(anon().collection("catalogo_igrejas").get());
  });

  test("get anônimo da unidade ativa é aceito e da inativa é negado", async () => {
    await assertSucceeds(anon().doc(`catalogo_igrejas/${OLINDA}`).get());
    await assertFails(anon().doc(`catalogo_igrejas/${PETROLINA}`).get());
  });

  test("metadados privados ficam somente no documento raiz", async () => {
    const catalogo = await assertSucceeds(
      anon().doc(`catalogo_igrejas/${OLINDA}`).get()
    );
    const raiz = await assertSucceeds(db(U.membroOlinda).doc(`igrejas/${OLINDA}`).get());

    expect(Object.keys(catalogo.data()).sort()).toEqual(CAMPOS_PUBLICOS);
    expect(catalogo.data()).not.toHaveProperty("criado_por");
    expect(catalogo.data()).not.toHaveProperty("mercado_pago_status");
    expect(catalogo.data()).not.toHaveProperty("dados_institucionais");
    expect(catalogo.data()).not.toHaveProperty("pix_chave");
    expect(catalogo.data()).not.toHaveProperty("pix_tipo");
    expect(catalogo.data()).not.toHaveProperty("telefone");
    expect(catalogo.data()).not.toHaveProperty("pastor_responsavel");
    expect(catalogo.data()).not.toHaveProperty(
      "responsavel_administrativo_uid"
    );
    expect(JSON.stringify(catalogo.data())).not.toContain(SEGREDO_CANARIO);
    expect(raiz.data().criado_por).toBe(SEGREDO_CANARIO);
    expect(raiz.data().dados_institucionais.responsavel_administrativo_uid).toBe(
      U.pastorOlinda
    );
  });

  const clientes = [
    ["anônimo", () => anon()],
    ["membro aprovado", () => db(U.membroOlinda)],
    ["super_admin", () => dbSuper()],
  ];

  for (const [rotulo, firestore] of clientes) {
    test(`${rotulo} não cria, altera nem apaga o catálogo`, async () => {
      const cliente = firestore();
      await assertFails(
        cliente.doc("catalogo_igrejas/nova").set({
          nome: "Nova unidade",
          ativa: true,
          configurada: false,
          endereco: "Endereço de teste",
          cidade_estado: "Cidade — PE",
          endereco_secundario: null,
          slogan: null,
          cultos_recorrentes: [],
          instagram: null,
          youtube_url: null,
          pastores_publicos: [],
        })
      );
      await assertFails(
        cliente.doc(`catalogo_igrejas/${OLINDA}`).update({ nome: "Nome alterado" })
      );
      await assertFails(cliente.doc(`catalogo_igrejas/${OLINDA}`).delete());
    });
  }
});

describe("DOCUMENTO RAIZ privado", () => {
  test("nega get a usuário sem sessão, visitante e membro de outra igreja", async () => {
    await assertFails(anon().doc(`igrejas/${OLINDA}`).get());
    await assertFails(db(U.visitante).doc(`igrejas/${OLINDA}`).get());
    await assertFails(db(U.pastorPetrolina).doc(`igrejas/${OLINDA}`).get());
  });

  test("vínculo pendente ou inativo não concede leitura do documento raiz", async () => {
    await assertFails(db(U.pendenteOlinda).doc(`igrejas/${OLINDA}`).get());
    await assertFails(db(U.inativoOlinda).doc(`igrejas/${OLINDA}`).get());
  });

  test("membro aprovado lê somente o documento raiz da própria igreja", async () => {
    await assertSucceeds(db(U.membroOlinda).doc(`igrejas/${OLINDA}`).get());
    await assertFails(db(U.membroOlinda).doc(`igrejas/${PETROLINA}`).get());
    await assertFails(db(U.membroOlinda).collection("igrejas").get());
  });

  test("super_admin lista os documentos raiz", async () => {
    const snap = await assertSucceeds(dbSuper().collection("igrejas").get());
    expect(snap.docs.map((doc) => doc.id).sort()).toEqual([OLINDA, PETROLINA]);
  });
});
