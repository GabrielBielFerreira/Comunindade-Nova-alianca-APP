const fs = require("fs");
const path = require("path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT_ID = "demo-nova-alianca";

// Host/porta do emulador do Firestore (mesma porta do firebase.json).
// `firebase emulators:exec` também define FIRESTORE_EMULATOR_HOST.
const [host, portStr] = (process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080").split(":");

async function makeTestEnv() {
  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, "..", "firestore.rules"), "utf8"),
      host,
      port: Number(portStr),
    },
  });
}

/**
 * Semeia documentos com privilégios de administrador (ignora as Rules),
 * usado para montar o estado inicial dos testes.
 */
async function seed(testEnv, fn) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

module.exports = { makeTestEnv, seed, assertFails, assertSucceeds, PROJECT_ID };
