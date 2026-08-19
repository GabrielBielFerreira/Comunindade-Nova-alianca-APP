/**
 * Storage Rules — foto de perfil.
 *
 * A foto é o ÚNICO caminho gravável do bucket. Estes testes rodam contra o
 * motor de regras real do Storage Emulator, não contra uma releitura do
 * arquivo: é a diferença entre "a regra parece certa" e "a regra recusa".
 */
const fs = require("fs");
const path = require("path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT_ID = "demo-nova-alianca";

const [host, portStr] = (
  process.env.FIREBASE_STORAGE_EMULATOR_HOST || "127.0.0.1:9199"
).split(":");

const ANA = "uid-ana";
const BRUNO = "uid-bruno";

/** Um "arquivo" de imagem do tamanho pedido. */
function imagemDe(bytes) {
  return new Uint8Array(bytes).fill(7);
}

const JPEG = { contentType: "image/jpeg" };

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    storage: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "..", "storage.rules"),
        "utf8"
      ),
      host,
      port: Number(portStr),
    },
  });
});

afterAll(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearStorage();
});

/** Storage autenticado como [uid]. */
function comoUid(uid) {
  return testEnv.authenticatedContext(uid).storage();
}

function comoVisitante() {
  return testEnv.unauthenticatedContext().storage();
}

const avatarDe = (uid) => `perfil/${uid}/avatar`;

describe("foto de perfil", () => {
  test("o dono grava o proprio avatar", async () => {
    await assertSucceeds(
      comoUid(ANA).ref(avatarDe(ANA)).put(imagemDe(1024), JPEG)
    );
  });

  test("outra pessoa NAO grava o avatar alheio", async () => {
    await assertFails(
      comoUid(BRUNO).ref(avatarDe(ANA)).put(imagemDe(1024), JPEG)
    );
  });

  test("visitante nao autenticado nao grava", async () => {
    await assertFails(
      comoVisitante().ref(avatarDe(ANA)).put(imagemDe(1024), JPEG)
    );
  });

  test("recusa arquivo que nao e imagem", async () => {
    await assertFails(
      comoUid(ANA)
        .ref(avatarDe(ANA))
        .put(imagemDe(1024), { contentType: "application/pdf" })
    );
  });

  test("recusa upload sem contentType", async () => {
    // Sem tipo, o Storage assumiria application/octet-stream.
    await assertFails(
      comoUid(ANA)
        .ref(avatarDe(ANA))
        .put(imagemDe(1024), { contentType: "application/octet-stream" })
    );
  });

  test("aceita imagem no limite de 2 MB", async () => {
    await assertSucceeds(
      comoUid(ANA).ref(avatarDe(ANA)).put(imagemDe(2 * 1024 * 1024), JPEG)
    );
  });

  test("recusa imagem acima de 2 MB", async () => {
    await assertFails(
      comoUid(ANA).ref(avatarDe(ANA)).put(imagemDe(2 * 1024 * 1024 + 1), JPEG)
    );
  });

  test("recusa arquivo vazio", async () => {
    await assertFails(
      comoUid(ANA).ref(avatarDe(ANA)).put(imagemDe(0), JPEG)
    );
  });

  test("autenticado le o avatar (aparece em listas da unidade)", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.storage().ref(avatarDe(ANA)).put(imagemDe(512), JPEG);
    });

    await assertSucceeds(comoUid(BRUNO).ref(avatarDe(ANA)).getDownloadURL());
  });

  test("visitante nao autenticado NAO le o avatar", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.storage().ref(avatarDe(ANA)).put(imagemDe(512), JPEG);
    });

    await assertFails(comoVisitante().ref(avatarDe(ANA)).getDownloadURL());
  });

  test("o dono apaga a propria foto", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.storage().ref(avatarDe(ANA)).put(imagemDe(512), JPEG);
    });

    await assertSucceeds(comoUid(ANA).ref(avatarDe(ANA)).delete());
  });

  test("outra pessoa nao apaga a foto alheia", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.storage().ref(avatarDe(ANA)).put(imagemDe(512), JPEG);
    });

    await assertFails(comoUid(BRUNO).ref(avatarDe(ANA)).delete());
  });
});

describe("nada alem do avatar", () => {
  test("o proprio dono nao usa a pasta de perfil como armazenamento livre", async () => {
    // Sem esta trava, `perfil/{uid}/*` viraria espaco gratuito por conta da
    // rede: 2 MB por arquivo, sem limite de quantidade.
    await assertFails(
      comoUid(ANA).ref(`perfil/${ANA}/outra-foto.jpg`).put(imagemDe(512), JPEG)
    );
    await assertFails(
      comoUid(ANA).ref(`perfil/${ANA}/album/1.jpg`).put(imagemDe(512), JPEG)
    );
  });

  test("caminhos fora de perfil sao negados", async () => {
    for (const caminho of [
      "avisos/banner.jpg",
      "igrejas/olinda/logo.png",
      "qualquer/coisa.jpg",
    ]) {
      await assertFails(comoUid(ANA).ref(caminho).put(imagemDe(512), JPEG));
    }
  });

  test("leitura fora de perfil e negada mesmo autenticado", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.storage().ref("avisos/banner.jpg").put(imagemDe(512), JPEG);
    });

    await assertFails(comoUid(ANA).ref("avisos/banner.jpg").getDownloadURL());
  });
});
