/**
 * Isolamento e permissões do CRUD de conteúdo do painel.
 *
 * Cobre exatamente o que o painel faz: editor gerencia conteúdo mas não vê
 * finanças; moderador modera oração mas não gerencia conteúdo; tesoureiro vê
 * finanças mas não publica; nada é apagado fisicamente.
 */
const { makeTestEnv, seed, assertFails, assertSucceeds } = require("./helpers");
const { OLINDA, PETROLINA, U, semearBase } = require("./fixtures");

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
  // Conteúdo em cada unidade, para os testes de isolamento.
  await seed(testEnv, async (fs) => {
    for (const igreja of [OLINDA, PETROLINA]) {
      for (const col of ["eventos", "campanhas", "ministerios", "devocionais"]) {
        await fs.doc(`igrejas/${igreja}/${col}/seed`).set({
          titulo: `${col} de ${igreja}`,
          nome: `${col} de ${igreja}`,
          publico: true,
          ativo: true,
        });
      }
    }
  });
});

function db(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

const COLECOES = ["avisos", "eventos", "campanhas", "ministerios", "devocionais"];

describe("CONTEÚDO — quem pode gerenciar", () => {
  for (const col of COLECOES) {
    test(`editor cria em ${col} da propria unidade`, async () => {
      await assertSucceeds(
        db(U.editorOlinda)
          .doc(`igrejas/${OLINDA}/${col}/novo`)
          .set({ titulo: 'x', nome: 'x', publico: true, ativo: true })
      );
    });

    test(`editor de Olinda NAO cria em ${col} de Petrolina`, async () => {
      await assertFails(
        db(U.editorOlinda)
          .doc(`igrejas/${PETROLINA}/${col}/invasao`)
          .set({ titulo: 'x', nome: 'x' })
      );
    });

    test(`membro comum NAO cria em ${col}`, async () => {
      await assertFails(
        db(U.membroOlinda)
          .doc(`igrejas/${OLINDA}/${col}/novo`)
          .set({ titulo: 'x', nome: 'x' })
      );
    });

    test(`tesoureiro NAO gerencia ${col}`, async () => {
      await assertFails(
        db(U.tesoureiroOlinda)
          .doc(`igrejas/${OLINDA}/${col}/novo`)
          .set({ titulo: 'x', nome: 'x' })
      );
    });

    test(`moderador de oracao NAO gerencia ${col}`, async () => {
      await assertFails(
        db(U.moderadorOlinda)
          .doc(`igrejas/${OLINDA}/${col}/novo`)
          .set({ titulo: 'x', nome: 'x' })
      );
    });

    test(`lideranca ministerial gerencia ${col}`, async () => {
      await assertSucceeds(
        db(U.liderOlinda)
          .doc(`igrejas/${OLINDA}/${col}/novo`)
          .set({ titulo: 'x', nome: 'x', publico: true, ativo: true })
      );
    });
  }
});

describe("CONTEÚDO — consultas públicas exigem filtro", () => {
  for (const col of COLECOES) {
    test(`visitante consulta ${col} com publico == true`, async () => {
      await assertSucceeds(
        db(U.visitante)
          .collection(`igrejas/${OLINDA}/${col}`)
          .where("publico", "==", true)
          .get()
      );
    });

    test(`visitante NAO consulta ${col} sem filtro publico`, async () => {
      await assertFails(
        db(U.visitante).collection(`igrejas/${OLINDA}/${col}`).get()
      );
    });
  }
});

describe("CONTEÚDO — inativar em vez de apagar", () => {
  test("editor inativa aviso (update), sem apagar", async () => {
    await assertSucceeds(
      db(U.editorOlinda)
        .doc(`igrejas/${OLINDA}/avisos/restrito`)
        .update({ ativo: false })
    );
    // O documento continua existindo.
    await assertSucceeds(
      db(U.editorOlinda).doc(`igrejas/${OLINDA}/avisos/restrito`).get()
    );
  });

  test("editor cancela evento (update), sem apagar", async () => {
    await assertSucceeds(
      db(U.editorOlinda)
        .doc(`igrejas/${OLINDA}/eventos/seed`)
        .update({ cancelado: true })
    );
  });

  test("editor inativa ministerio, sem apagar", async () => {
    await assertSucceeds(
      db(U.editorOlinda)
        .doc(`igrejas/${OLINDA}/ministerios/seed`)
        .update({ ativo: false })
    );
  });
});

describe("ORAÇÃO — moderação por unidade", () => {
  test("fila inclui pedido privado somente para moderador da unidade", async () => {
    await seed(testEnv, (fs) =>
      fs.doc(`igrejas/${OLINDA}/pedidos_oracao/privado`).set({
        autor_id: U.visitante,
        texto: "Pedido pastoral reservado",
        privado: true,
        aprovado: false,
        recusado: false,
      })
    );

    const consultaOlinda = db(U.moderadorOlinda)
      .collection(`igrejas/${OLINDA}/pedidos_oracao`)
      .where("aprovado", "==", false);
    const resultado = await assertSucceeds(consultaOlinda.get());
    expect(resultado.docs.map((doc) => doc.id)).toContain("privado");

    await assertFails(
      db(U.membroOlinda)
        .collection(`igrejas/${OLINDA}/pedidos_oracao`)
        .where("aprovado", "==", false)
        .get()
    );
    await assertFails(
      db(U.moderadorOlinda)
        .collection(`igrejas/${PETROLINA}/pedidos_oracao`)
        .where("aprovado", "==", false)
        .get()
    );
  });

  test("moderador aprova pedido da propria unidade", async () => {
    await assertSucceeds(
      db(U.moderadorOlinda)
        .doc(`igrejas/${OLINDA}/pedidos_oracao/moderacao`)
        .update({ aprovado: true })
    );
  });

  test("moderador RECUSA marcando status, sem apagar", async () => {
    await assertSucceeds(
      db(U.moderadorOlinda)
        .doc(`igrejas/${OLINDA}/pedidos_oracao/moderacao`)
        .update({ recusado: true, motivo_recusa: "fora de escopo" })
    );
    // Continua existindo: histórico preservado.
    await assertSucceeds(
      db(U.moderadorOlinda)
        .doc(`igrejas/${OLINDA}/pedidos_oracao/moderacao`)
        .get()
    );
  });

  test("moderador NAO apaga pedido", async () => {
    await assertFails(
      db(U.moderadorOlinda)
        .doc(`igrejas/${OLINDA}/pedidos_oracao/moderacao`)
        .delete()
    );
  });

  test("editor NAO modera oracao", async () => {
    await assertFails(
      db(U.editorOlinda)
        .doc(`igrejas/${OLINDA}/pedidos_oracao/moderacao`)
        .update({ aprovado: true })
    );
  });

  test("moderador de Olinda NAO le fila de Petrolina", async () => {
    await assertFails(
      db(U.moderadorOlinda)
        .doc(`igrejas/${PETROLINA}/pedidos_oracao/moderacao`)
        .get()
    );
  });
});

describe("MATRIZ cruzada — conteúdo x finanças", () => {
  test("editor gerencia conteudo, mas NAO le financas", async () => {
    await assertSucceeds(
      db(U.editorOlinda)
        .doc(`igrejas/${OLINDA}/avisos/do_editor`)
        .set({ titulo: 'x', publico: true, ativo: true })
    );
    await assertFails(
      db(U.editorOlinda).doc(`igrejas/${OLINDA}/transacoes/tx1`).get()
    );
  });

  test("tesoureiro le financas, mas NAO gerencia conteudo", async () => {
    await assertSucceeds(
      db(U.tesoureiroOlinda).doc(`igrejas/${OLINDA}/transacoes/tx1`).get()
    );
    await assertFails(
      db(U.tesoureiroOlinda)
        .doc(`igrejas/${OLINDA}/avisos/do_tesoureiro`)
        .set({ titulo: 'x' })
    );
  });

  test("moderador modera oracao, mas NAO le financas", async () => {
    await assertSucceeds(
      db(U.moderadorOlinda)
        .doc(`igrejas/${OLINDA}/pedidos_oracao/moderacao`)
        .update({ aprovado: true })
    );
    await assertFails(
      db(U.moderadorOlinda).doc(`igrejas/${OLINDA}/transacoes/tx1`).get()
    );
  });
});
