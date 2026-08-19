/**
 * Bootstrap de super_admin.
 *
 * Concede a custom claim `super_admin` a um UID recebido por ARGUMENTO ou
 * variável de ambiente. Nenhum UID ou e-mail fica fixo no código.
 *
 * Uso (emulador):
 *   node bootstrap_super_admin.js --uid <UID>
 *   node bootstrap_super_admin.js --email pessoa@exemplo.com
 *   SUPER_ADMIN_UID=<UID> node bootstrap_super_admin.js
 *
 * Para PRODUÇÃO, este script exige confirmação dupla e credencial explícita:
 *   PERMITIR_PRODUCAO=1 GOOGLE_APPLICATION_CREDENTIALS=<chave.json> \
 *   GCLOUD_PROJECT=<projeto-real> node bootstrap_super_admin.js --uid <UID>
 *
 * Por padrão, roda apenas contra o emulador.
 */
const admin = require("firebase-admin");

function argumento(nome) {
  const indice = process.argv.indexOf(`--${nome}`);
  return indice >= 0 ? process.argv[indice + 1] : undefined;
}

const uidAlvo = argumento("uid") || process.env.SUPER_ADMIN_UID;
const emailAlvo = argumento("email") || process.env.SUPER_ADMIN_EMAIL;
const remover = process.argv.includes("--remover");

if (!uidAlvo && !emailAlvo) {
  console.error(
    "Informe o alvo:\n" +
      "  node bootstrap_super_admin.js --uid <UID>\n" +
      "  node bootstrap_super_admin.js --email <EMAIL>\n"
  );
  process.exit(1);
}

const permitirProducao = process.env.PERMITIR_PRODUCAO === "1";
const projeto = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT_ID;
const noEmulador = Boolean(process.env.FIREBASE_AUTH_EMULATOR_HOST);

if (!noEmulador && !permitirProducao) {
  console.error(
    "\n[ABORTADO] FIREBASE_AUTH_EMULATOR_HOST nao definida.\n" +
      "Este script roda contra o emulador por padrao.\n" +
      "Para um projeto real, defina explicitamente PERMITIR_PRODUCAO=1 e\n" +
      "GOOGLE_APPLICATION_CREDENTIALS, ciente de que concede acesso total a rede.\n"
  );
  process.exit(1);
}

if (!noEmulador && permitirProducao) {
  console.warn(
    `\n⚠️  ATENCAO: concedendo super_admin em PROJETO REAL (${projeto}).\n` +
      "    super_admin le e administra TODAS as unidades da rede.\n"
  );
}

admin.initializeApp({ projectId: projeto || "demo-nova-alianca" });

(async () => {
  const auth = admin.auth();

  const usuario = uidAlvo
    ? await auth.getUser(uidAlvo)
    : await auth.getUserByEmail(emailAlvo);

  const claimsAtuais = usuario.customClaims || {};
  const novasClaims = { ...claimsAtuais };

  if (remover) {
    delete novasClaims.super_admin;
  } else {
    novasClaims.super_admin = true;
  }

  await auth.setCustomUserClaims(usuario.uid, novasClaims);

  console.log(
    `\n${remover ? "Removido" : "Concedido"} super_admin:\n` +
      `  uid:   ${usuario.uid}\n` +
      `  email: ${usuario.email ?? "(sem e-mail)"}\n` +
      `  projeto: ${projeto}\n`
  );
  console.log(
    "A claim so entra em vigor no proximo token do usuario " +
      "(fazer logout/login ou aguardar a renovacao).\n"
  );
  process.exit(0);
})().catch((erro) => {
  console.error("\n[ERRO]", erro.message || erro);
  process.exit(1);
});
