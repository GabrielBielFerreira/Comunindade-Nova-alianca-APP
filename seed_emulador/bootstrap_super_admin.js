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
 * Para PRODUÇÃO, este script exige confirmação, projectId exato e ADC válida:
 *   gcloud auth application-default login
 *   PERMITIR_PRODUCAO=1 GCLOUD_PROJECT=nova-alianca-app \
 *   node bootstrap_super_admin.js --uid <UID>
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
const PROJETO_PRODUCAO = "nova-alianca-app";
const variaveisProjeto = [
  "GCLOUD_PROJECT",
  "GOOGLE_CLOUD_PROJECT",
  "FIREBASE_PROJECT_ID",
];
const projetosInformados = variaveisProjeto
  .map((nome) => ({ nome, valor: process.env[nome] }))
  .filter(({ valor }) => Boolean(valor));
const projeto =
  process.env.GCLOUD_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  process.env.FIREBASE_PROJECT_ID;
const noEmulador = Boolean(process.env.FIREBASE_AUTH_EMULATOR_HOST);

if (!noEmulador && !permitirProducao) {
  console.error(
    "\n[ABORTADO] FIREBASE_AUTH_EMULATOR_HOST nao definida.\n" +
      "Este script roda contra o emulador por padrao.\n" +
      "Para um projeto real, defina explicitamente PERMITIR_PRODUCAO=1 e\n" +
      "GCLOUD_PROJECT=nova-alianca-app, com ADC valida, ciente de que concede\n" +
      "acesso total a rede.\n"
  );
  process.exit(1);
}

if (!noEmulador && permitirProducao) {
  const divergentes = projetosInformados.filter(
    ({ valor }) => valor !== PROJETO_PRODUCAO
  );
  if (projeto !== PROJETO_PRODUCAO || divergentes.length > 0) {
    console.error(
      `\n[ABORTADO] O projectId de producao deve ser exatamente ` +
        `"${PROJETO_PRODUCAO}".\n` +
        `Recebido: ${projeto || "(ausente)"}.` +
        (divergentes.length
          ? ` Variaveis divergentes: ${divergentes
              .map(({ nome, valor }) => `${nome}=${valor}`)
              .join(", ")}.`
          : "") +
        "\n"
    );
    process.exit(1);
  }
}

(async () => {
  let opcoesInicializacao;

  if (noEmulador) {
    opcoesInicializacao = { projectId: projeto || "demo-nova-alianca" };
  } else {
    let credencial;
    try {
      credencial = admin.credential.applicationDefault();
      const token = await credencial.getAccessToken();
      if (!token || !token.access_token) {
        throw new Error("ADC nao retornou um access token");
      }
    } catch (erro) {
      console.error(
        "\n[ABORTADO] Application Default Credentials (ADC) ausente ou " +
          "invalida.\nExecute `gcloud auth application-default login` (ou " +
          "configure GOOGLE_APPLICATION_CREDENTIALS com uma credencial " +
          `valida) e tente novamente.\nDetalhe: ${erro.message || erro}\n`
      );
      process.exit(1);
    }

    opcoesInicializacao = {
      projectId: PROJETO_PRODUCAO,
      credential: credencial,
    };
  }

  admin.initializeApp(opcoesInicializacao);

  if (!noEmulador) {
    console.warn(
      `\n⚠️  ATENCAO: concedendo super_admin em PROJETO REAL ` +
        `(${PROJETO_PRODUCAO}).\n` +
        "    super_admin le e administra TODAS as unidades da rede.\n"
    );
  }

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
      `  projeto: ${noEmulador ? projeto || "demo-nova-alianca" : PROJETO_PRODUCAO}\n`
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
