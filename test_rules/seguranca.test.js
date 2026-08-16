/**
 * Suíte de segurança das Rules multi-igreja.
 *
 * Inclui os testes de REGRESSÃO das vulnerabilidades da v1.3.0: o que antes
 * era permitido (autopromoção, auditoria forjada, reação manipulável) agora
 * precisa ser NEGADO.
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
});

/** Contexto autenticado comum. */
function db(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

/** Contexto com a custom claim de super_admin. */
function dbSuper(uid = U.superAdmin) {
  return testEnv.authenticatedContext(uid, { super_admin: true }).firestore();
}

function anon() {
  return testEnv.unauthenticatedContext().firestore();
}

// ══════════════════════════════════════════════════════════════════════
describe("REGRESSÃO — vulnerabilidades da v1.3.0 agora são negadas", () => {
  test("D.1 — líder NÃO consegue se autopromover a pastor", async () => {
    await assertFails(
      db(U.liderOlinda)
        .doc(`igrejas/${OLINDA}/membros/${U.liderOlinda}`)
        .update({ perfil: "pastor" })
    );
  });

  test("D.1 — líder NÃO promove outro usuário", async () => {
    await assertFails(
      db(U.liderOlinda)
        .doc(`igrejas/${OLINDA}/membros/${U.membroOlinda}`)
        .update({ perfil: "pastor" })
    );
  });

  test("D.1 — nem o pastor altera perfil pelo cliente (só via Function)", async () => {
    await assertFails(
      db(U.pastorOlinda)
        .doc(`igrejas/${OLINDA}/membros/${U.liderOlinda}`)
        .update({ perfil: "membro" })
    );
  });

  test("D.1 — usuário NÃO se concede funcoes_admin no autocadastro", async () => {
    await assertFails(
      db("uid_novo")
        .doc(`igrejas/${OLINDA}/membros/uid_novo`)
        .set({ perfil: "membro", status: "pendente", funcoes_admin: ["tesoureiro"] })
    );
  });

  test("D.1 — autocadastro NÃO pode nascer aprovado", async () => {
    await assertFails(
      db("uid_novo")
        .doc(`igrejas/${OLINDA}/membros/uid_novo`)
        .set({ perfil: "membro", status: "aprovado", funcoes_admin: [] })
    );
  });

  test("autocadastro válido (pendente/membro/sem funções) é permitido", async () => {
    await assertSucceeds(
      db("uid_novo")
        .doc(`igrejas/${OLINDA}/membros/uid_novo`)
        .set({ perfil: "membro", status: "pendente", funcoes_admin: [] })
    );
  });

  test("D.2 — líder NÃO forja auditoria", async () => {
    await assertFails(
      db(U.liderOlinda).doc(`igrejas/${OLINDA}/auditoria/forjado`).set({
        acao: "qualquer",
        autor_id: "outra_pessoa",
      })
    );
  });

  test("D.2 — nem o pastor cria auditoria pelo cliente", async () => {
    await assertFails(
      db(U.pastorOlinda).doc(`igrejas/${OLINDA}/auditoria/forjado`).set({ acao: "x" })
    );
  });

  test("D.2 — auditoria existente é imutável para o cliente", async () => {
    await assertFails(
      db(U.pastorOlinda).doc(`igrejas/${OLINDA}/auditoria/log1`).update({ acao: "alterado" })
    );
    await assertFails(
      db(U.pastorOlinda).doc(`igrejas/${OLINDA}/auditoria/log1`).delete()
    );
  });

  test("D.6 — reação de oração NÃO aceita valor arbitrário", async () => {
    await assertFails(
      db(U.membroOlinda)
        .doc(`igrejas/${OLINDA}/pedidos_oracao/publico`)
        .update({ oram_count: 999, oram_por: [U.membroOlinda] })
    );
  });

  test("D.6 — reação com incremento de 1 e próprio uid é permitida", async () => {
    await assertSucceeds(
      db(U.membroOlinda)
        .doc(`igrejas/${OLINDA}/pedidos_oracao/publico`)
        .update({ oram_count: 1, oram_por: [U.membroOlinda] })
    );
  });

  test("D.6 — não é possível reagir em nome de outra pessoa", async () => {
    await assertFails(
      db(U.membroOlinda)
        .doc(`igrejas/${OLINDA}/pedidos_oracao/publico`)
        .update({ oram_count: 1, oram_por: [U.liderOlinda] })
    );
  });

  test("D.4 — pedido de oração não pode ser apagado pelo cliente", async () => {
    await assertFails(
      db(U.pastorOlinda).doc(`igrejas/${OLINDA}/pedidos_oracao/publico`).delete()
    );
  });

  test("D.4 — vínculo não pode ser apagado (saída é inativação)", async () => {
    await assertFails(
      db(U.pastorOlinda).doc(`igrejas/${OLINDA}/membros/${U.liderOlinda}`).delete()
    );
  });
});

// ══════════════════════════════════════════════════════════════════════
describe("FINANÇAS — acesso por unidade", () => {
  const permitidos = [
    ["pastor", U.pastorOlinda],
    ["diácono", U.diaconoOlinda],
    ["evangelista", U.evangelistaOlinda],
    ["líder", U.liderOlinda],
    ["tesoureiro", U.tesoureiroOlinda],
  ];

  for (const [rotulo, uid] of permitidos) {
    test(`${rotulo} de Olinda LÊ finanças de Olinda`, async () => {
      await assertSucceeds(db(uid).doc(`igrejas/${OLINDA}/transacoes/tx1`).get());
    });

    test(`${rotulo} de Olinda NÃO lê finanças de Petrolina`, async () => {
      await assertFails(db(uid).doc(`igrejas/${PETROLINA}/transacoes/tx1`).get());
    });
  }

  test("editor NÃO lê finanças", async () => {
    await assertFails(db(U.editorOlinda).doc(`igrejas/${OLINDA}/transacoes/tx1`).get());
  });

  test("moderador de oração NÃO lê finanças", async () => {
    await assertFails(db(U.moderadorOlinda).doc(`igrejas/${OLINDA}/transacoes/tx1`).get());
  });

  test("líder com vínculo INATIVO NÃO lê finanças", async () => {
    await assertFails(db(U.inativoOlinda).doc(`igrejas/${OLINDA}/transacoes/tx1`).get());
  });

  test("membro PENDENTE NÃO lê finanças", async () => {
    await assertFails(db(U.pendenteOlinda).doc(`igrejas/${OLINDA}/transacoes/tx1`).get());
  });

  test("pastor de Petrolina NÃO lê finanças de Olinda", async () => {
    await assertFails(db(U.pastorPetrolina).doc(`igrejas/${OLINDA}/transacoes/tx1`).get());
  });

  test("pastor de Petrolina LÊ finanças de Petrolina", async () => {
    await assertSucceeds(db(U.pastorPetrolina).doc(`igrejas/${PETROLINA}/transacoes/tx1`).get());
  });

  test("super_admin lê finanças das duas unidades", async () => {
    await assertSucceeds(dbSuper().doc(`igrejas/${OLINDA}/transacoes/tx1`).get());
    await assertSucceeds(dbSuper().doc(`igrejas/${PETROLINA}/transacoes/tx1`).get());
  });

  test("dono lê a própria contribuição", async () => {
    await assertSucceeds(db(U.membroOlinda).doc(`igrejas/${OLINDA}/transacoes/tx1`).get());
  });

  test("CLIENTE NUNCA cria transação — nem pendente", async () => {
    await assertFails(
      db(U.membroOlinda).doc(`igrejas/${OLINDA}/transacoes/nova`).set({
        usuario_id: U.membroOlinda,
        igreja_id: OLINDA,
        valor_centavos: 1000,
        status: "pendente",
      })
    );
  });

  test("CLIENTE NUNCA aprova pagamento", async () => {
    await assertFails(
      db(U.pastorOlinda)
        .doc(`igrejas/${OLINDA}/transacoes/tx1`)
        .update({ status: "aprovado" })
    );
    await assertFails(
      dbSuper().doc(`igrejas/${OLINDA}/transacoes/tx1`).update({ status: "aprovado" })
    );
  });
});

// ══════════════════════════════════════════════════════════════════════
describe("ISOLAMENTO entre Olinda e Petrolina", () => {
  test("pastor de Olinda NÃO lê membros de Petrolina", async () => {
    await assertFails(
      db(U.pastorOlinda).doc(`igrejas/${PETROLINA}/membros/${U.pastorPetrolina}`).get()
    );
  });

  test("pastor de Petrolina NÃO lê membros de Olinda", async () => {
    await assertFails(
      db(U.pastorPetrolina).doc(`igrejas/${OLINDA}/membros/${U.liderOlinda}`).get()
    );
  });

  test("pastor de Olinda NÃO escreve conteúdo em Petrolina", async () => {
    await assertFails(
      db(U.pastorOlinda).doc(`igrejas/${PETROLINA}/avisos/novo`).set({ titulo: "invasao" })
    );
  });

  test("pastor de Olinda NÃO lê aviso restrito de Petrolina", async () => {
    await assertFails(db(U.pastorOlinda).doc(`igrejas/${PETROLINA}/avisos/restrito`).get());
  });

  test("pastor de Olinda NÃO lê auditoria de Petrolina", async () => {
    await assertFails(db(U.pastorOlinda).doc(`igrejas/${PETROLINA}/auditoria/log1`).get());
  });

  test("liderança de Olinda escreve conteúdo em Olinda", async () => {
    await assertSucceeds(
      db(U.pastorOlinda).doc(`igrejas/${OLINDA}/avisos/novo`).set({ titulo: "ok", publico: true })
    );
  });
});

// ══════════════════════════════════════════════════════════════════════
describe("CONTEÚDO público e restrito", () => {
  test("visitante autenticado lê conteúdo público", async () => {
    await assertSucceeds(db(U.visitante).doc(`igrejas/${OLINDA}/avisos/publico`).get());
  });

  test("visitante autenticado NÃO lê conteúdo restrito", async () => {
    await assertFails(db(U.visitante).doc(`igrejas/${OLINDA}/avisos/restrito`).get());
  });

  test("membro aprovado lê conteúdo restrito da própria unidade", async () => {
    await assertSucceeds(db(U.membroOlinda).doc(`igrejas/${OLINDA}/avisos/restrito`).get());
  });

  test("consulta filtrando publico==true é aceita para visitante", async () => {
    await assertSucceeds(
      db(U.visitante)
        .collection(`igrejas/${OLINDA}/avisos`)
        .where("publico", "==", true)
        .get()
    );
  });

  test("consulta SEM filtro de publico é negada para visitante", async () => {
    await assertFails(db(U.visitante).collection(`igrejas/${OLINDA}/avisos`).get());
  });

  test("editor gerencia conteúdo; membro comum não", async () => {
    await assertSucceeds(
      db(U.editorOlinda).doc(`igrejas/${OLINDA}/avisos/do_editor`).set({ titulo: "x" })
    );
    await assertFails(
      db(U.membroOlinda).doc(`igrejas/${OLINDA}/avisos/do_membro`).set({ titulo: "x" })
    );
  });

  test("catálogo de igrejas é legível sem login (seleção de unidade)", async () => {
    await assertSucceeds(anon().doc(`igrejas/${OLINDA}`).get());
  });

  test("ninguém altera a configuração da igreja pelo cliente", async () => {
    await assertFails(db(U.pastorOlinda).doc(`igrejas/${OLINDA}`).update({ nome: "outro" }));
    await assertFails(dbSuper().doc(`igrejas/${OLINDA}`).update({ nome: "outro" }));
  });
});

// ══════════════════════════════════════════════════════════════════════
describe("ORAÇÃO — moderação", () => {
  test("visitante anônimo cria pedido não aprovado", async () => {
    await assertSucceeds(
      db(U.visitante).doc(`igrejas/${OLINDA}/pedidos_oracao/novo`).set({
        autor_id: U.visitante,
        texto: "Pedido",
        privado: false,
        aprovado: false,
      })
    );
  });

  test("pedido NÃO pode nascer aprovado", async () => {
    await assertFails(
      db(U.visitante).doc(`igrejas/${OLINDA}/pedidos_oracao/novo`).set({
        autor_id: U.visitante,
        texto: "Pedido",
        privado: false,
        aprovado: true,
      })
    );
  });

  test("moderador aprova pedido da própria unidade", async () => {
    await assertSucceeds(
      db(U.moderadorOlinda)
        .doc(`igrejas/${OLINDA}/pedidos_oracao/moderacao`)
        .update({ aprovado: true })
    );
  });

  test("moderador de Olinda NÃO aprova pedido de Petrolina", async () => {
    await assertFails(
      db(U.moderadorOlinda)
        .doc(`igrejas/${PETROLINA}/pedidos_oracao/moderacao`)
        .update({ aprovado: true })
    );
  });

  test("autor NÃO aprova o próprio pedido", async () => {
    await assertFails(
      db(U.visitante)
        .doc(`igrejas/${OLINDA}/pedidos_oracao/moderacao`)
        .update({ aprovado: true })
    );
  });

  test("membro comum NÃO lê pedido aguardando moderação", async () => {
    await assertFails(
      db(U.membroOlinda).doc(`igrejas/${OLINDA}/pedidos_oracao/moderacao`).get()
    );
  });
});

// ══════════════════════════════════════════════════════════════════════
describe("PERFIL global do usuário", () => {
  test("dono lê e edita o próprio perfil", async () => {
    await assertSucceeds(db(U.membroOlinda).doc(`usuarios/${U.membroOlinda}`).get());
    await assertSucceeds(
      db(U.membroOlinda).doc(`usuarios/${U.membroOlinda}`).update({ nome: "Novo Nome" })
    );
  });

  test("líder NÃO lê o perfil global de outro usuário (vazamento fechado)", async () => {
    await assertFails(db(U.liderOlinda).doc(`usuarios/${U.membroOlinda}`).get());
  });

  test("usuário NÃO altera a própria igreja principal pelo cliente", async () => {
    await assertFails(
      db(U.membroOlinda)
        .doc(`usuarios/${U.membroOlinda}`)
        .update({ igreja_principal_id: PETROLINA })
    );
  });

  test("super_admin lê perfis globais", async () => {
    await assertSucceeds(dbSuper().doc(`usuarios/${U.membroOlinda}`).get());
  });
});

// ══════════════════════════════════════════════════════════════════════
describe("CAMINHOS GLOBAIS ANTIGOS estão negados", () => {
  const caminhos = [
    "avisos/x",
    "eventos/x",
    "campanhas/x",
    "ministerios/x",
    "devocionais/x",
    "pedidos_oracao/x",
    "transacoes/x",
    "auditoria/x",
    "notificacoes/x",
    "tokens_dispositivo/x",
    "interesses_ministerio/x",
    "igreja/principal",
    "configuracoes/app",
  ];

  for (const caminho of caminhos) {
    test(`/${caminho} negado para leitura e escrita`, async () => {
      await assertFails(db(U.pastorOlinda).doc(caminho).get());
      await assertFails(db(U.pastorOlinda).doc(caminho).set({ x: 1 }));
    });
  }
});
