/**
 * Trava de segurança comum aos scripts de emulador.
 *
 * Recusa executar se as variáveis de emulador não estiverem definidas ou se o
 * projeto não for o de demonstração. Sem isto, um `node seed.js` distraído com
 * credenciais de administrador na máquina escreveria em PRODUÇÃO.
 */
const PROJECT_ID = "demo-nova-alianca";

function exigirEmulador() {
  const erros = [];

  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    erros.push("FIRESTORE_EMULATOR_HOST nao definida");
  }
  if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    erros.push("FIREBASE_AUTH_EMULATOR_HOST nao definida");
  }

  const projeto = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT_ID;
  if (projeto !== PROJECT_ID) {
    erros.push(`projeto '${projeto}' != '${PROJECT_ID}'`);
  }
  if (!String(projeto ?? "").startsWith("demo-")) {
    erros.push("projeto nao comeca com 'demo-'");
  }

  // Credencial real presente é sinal de que o ambiente não é o do emulador.
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    erros.push(
      "GOOGLE_APPLICATION_CREDENTIALS definida (credencial real) — remova antes de rodar"
    );
  }

  if (erros.length > 0) {
    console.error("\n[ABORTADO] Este script so roda contra o Firebase Emulator Suite.\n");
    for (const erro of erros) console.error(`  - ${erro}`);
    console.error(
      "\nUse o script de execucao (scripts/dev.ps1) ou defina:\n" +
        "  $env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'\n" +
        "  $env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'\n" +
        "  $env:GCLOUD_PROJECT='demo-nova-alianca'\n"
    );
    process.exit(1);
  }

  console.log(`[guarda] emulador confirmado (projeto ${PROJECT_ID}).`);
}

module.exports = { exigirEmulador, PROJECT_ID };
