/**
 * Smoke test do harness de Rules (Fase 0).
 *
 * Verifica que o Emulator Suite sobe, que as Rules do repositório são
 * carregadas e que o ambiente de teste encerra limpo. As asserções de
 * segurança propriamente ditas ficam nas suítes da Fase 1
 * (isolamento / lideranca / financas / auditoria / oracao).
 */
const { makeTestEnv, seed, assertFails } = require("./helpers");

let testEnv;

beforeAll(async () => {
  testEnv = await makeTestEnv();
});

afterAll(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe("harness do Emulator Suite", () => {
  test("carrega as Rules do repositório e nega leitura anônima", async () => {
    await seed(testEnv, async (fs) => {
      await fs.collection("igrejas").doc("olinda").set({ nome: "Nova Aliança Olinda" });
    });

    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(anon.collection("igrejas").doc("olinda").get());
  });

  test("withSecurityRulesDisabled consegue semear dados", async () => {
    await seed(testEnv, async (fs) => {
      await fs.collection("igrejas").doc("petrolina").set({ nome: "Nova Aliança Petrolina" });
    });

    let encontrado = false;
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const snap = await ctx.firestore().collection("igrejas").doc("petrolina").get();
      encontrado = snap.exists;
    });
    expect(encontrado).toBe(true);
  });

  test("clearFirestore limpa entre os testes", async () => {
    let vazio = false;
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const snap = await ctx.firestore().collection("igrejas").get();
      vazio = snap.empty;
    });
    expect(vazio).toBe(true);
  });
});
