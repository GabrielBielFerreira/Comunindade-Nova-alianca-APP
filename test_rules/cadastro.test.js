/**
 * Cadastro multi-igreja contra as Rules REAIS.
 *
 * Estes testes existem porque o cadastro do aplicativo estava sendo NEGADO em
 * produção sem que nada no código Dart acusasse: `UsuarioModel.toMap()`
 * escrevia `uid`, `perfil`, `status` e `data_cadastro`, e o `hasOnly` de
 * `match /usuarios/{uid}` recusa qualquer chave fora da lista.
 *
 * Aqui a verificação roda contra o motor de Rules do emulador, então uma
 * divergência entre o mapa gravado pelo app e as Rules reprova o build.
 */
const { makeTestEnv, seed, assertFails, assertSucceeds } = require("./helpers");

const OLINDA = "olinda";
const PETROLINA = "petrolina";
const NOVO = "uid_recem_cadastrado";

let testEnv;

beforeAll(async () => {
  testEnv = await makeTestEnv();
});

afterAll(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seed(testEnv, async (fs) => {
    await fs.collection("igrejas").doc(OLINDA).set({
      nome: "Nova Aliança Olinda",
      ativa: true,
      criado_por: "uid_privado_olinda",
    });
    await fs.collection("igrejas").doc(PETROLINA).set({
      nome: "Comunidade Nova Aliança Petrolina",
      ativa: true,
      criado_por: "uid_privado_petrolina",
    });
    await fs.collection("catalogo_igrejas").doc(OLINDA).set({
      nome: "Nova Aliança Olinda",
      ativa: true,
      configurada: true,
      endereco: "Av. Leopoldino Canuto de Melo, 846, Caixa D'Água",
      cidade_estado: "Olinda — PE",
    });
    await fs.collection("catalogo_igrejas").doc(PETROLINA).set({
      nome: "Comunidade Nova Aliança Petrolina",
      ativa: true,
      configurada: false,
      endereco: "Rua 47, número 180 — São Gonçalo",
      cidade_estado: "Petrolina — PE",
    });
  });
});

/** Espelha `mapaDeCriacaoUsuario` do aplicativo. */
function mapaDeCriacaoUsuario(igrejaId, extras = {}) {
  return {
    nome: "Maria de Teste",
    email: "maria@teste.local",
    telefone: "(81) 99999-0000",
    igreja_principal_id: igrejaId,
    criado_em: new Date(),
    atualizado_em: new Date(),
    ...extras,
  };
}

/** Espelha o vínculo pendente criado pelo aplicativo. */
function vinculoPendente() {
  return {
    perfil: "membro",
    status: "pendente",
    funcoes_admin: [],
    ministerio_ids: [],
    criado_em: new Date(),
  };
}

describe("cadastro do aplicativo", () => {
  test("o mapa de criação atual é ACEITO pelas Rules", async () => {
    const db = testEnv.authenticatedContext(NOVO).firestore();

    await assertSucceeds(
      db.doc(`usuarios/${NOVO}`).set(mapaDeCriacaoUsuario(OLINDA))
    );
    await assertSucceeds(
      db.doc(`igrejas/${OLINDA}/membros/${NOVO}`).set(vinculoPendente())
    );
  });

  test("o mapa ANTIGO (com perfil/status/uid) é NEGADO", async () => {
    const db = testEnv.authenticatedContext(NOVO).firestore();

    // Exatamente o que UsuarioModel.toMap() produzia.
    await assertFails(
      db.doc(`usuarios/${NOVO}`).set({
        uid: NOVO,
        nome: "Maria",
        email: "maria@teste.local",
        telefone: "",
        perfil: "membro",
        status: "pendente",
        data_cadastro: new Date(),
      })
    );
  });

  test("cada campo proibido isoladamente já reprova", async () => {
    const db = testEnv.authenticatedContext(NOVO).firestore();

    for (const proibido of [
      { uid: NOVO },
      { perfil: "membro" },
      { status: "pendente" },
      { data_cadastro: new Date() },
      { funcoes_admin: [] },
    ]) {
      await assertFails(
        db.doc(`usuarios/${NOVO}`).set(mapaDeCriacaoUsuario(OLINDA, proibido))
      );
    }
  });

  test("o cadastro nasce PENDENTE na igreja escolhida", async () => {
    const db = testEnv.authenticatedContext(NOVO).firestore();
    await db.doc(`igrejas/${PETROLINA}/membros/${NOVO}`).set(vinculoPendente());

    // A liderança de Petrolina precisa enxergar o cadastro para aprová-lo.
    await seed(testEnv, async (fs) => {
      await fs.doc(`igrejas/${PETROLINA}/membros/uid_pastor_petrolina`).set({
        perfil: "pastor",
        status: "aprovado",
        funcoes_admin: ["pastor"],
      });
    });

    const pastor = testEnv
      .authenticatedContext("uid_pastor_petrolina")
      .firestore();
    await assertSucceeds(
      pastor.doc(`igrejas/${PETROLINA}/membros/${NOVO}`).get()
    );
  });

  test("ninguém se autocadastra já aprovado nem como pastor", async () => {
    const db = testEnv.authenticatedContext(NOVO).firestore();

    await assertFails(
      db.doc(`igrejas/${OLINDA}/membros/${NOVO}`).set({
        ...vinculoPendente(),
        status: "aprovado",
      })
    );
    await assertFails(
      db.doc(`igrejas/${OLINDA}/membros/${NOVO}`).set({
        ...vinculoPendente(),
        perfil: "pastor",
      })
    );
    await assertFails(
      db.doc(`igrejas/${OLINDA}/membros/${NOVO}`).set({
        ...vinculoPendente(),
        funcoes_admin: ["pastor"],
      })
    );
  });

  test("ninguém cria vínculo no lugar de outra pessoa", async () => {
    const db = testEnv.authenticatedContext(NOVO).firestore();
    await assertFails(
      db.doc(`igrejas/${OLINDA}/membros/uid_de_outra_pessoa`).set(
        vinculoPendente()
      )
    );
  });

  test("o catálogo de igrejas é legível ANTES do login", async () => {
    // A seleção de igreja acontece antes de existir conta; sem esta leitura a
    // primeira tela do onboarding ficaria vazia.
    const anon = testEnv.unauthenticatedContext().firestore();
    const snap = await assertSucceeds(
      anon.collection("catalogo_igrejas").where("ativa", "==", true).get()
    );
    expect(snap.docs.map((doc) => doc.id).sort()).toEqual([OLINDA, PETROLINA]);
  });

  test("o cliente não muda a própria igreja principal depois", async () => {
    const db = testEnv.authenticatedContext(NOVO).firestore();
    await db.doc(`usuarios/${NOVO}`).set(mapaDeCriacaoUsuario(OLINDA));

    // Trocar de unidade é operação auditada de servidor.
    await assertFails(
      db.doc(`usuarios/${NOVO}`).update({ igreja_principal_id: PETROLINA })
    );
  });
});
