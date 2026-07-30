/**
 * Promove os administradores para LÍDER + APROVADO no Firestore.
 *
 * PRÉ-REQUISITOS:
 *  1. Cada e-mail abaixo já deve ter se CADASTRADO no app (cria o registro).
 *  2. Chave de service account em seed/serviceAccountKey.json
 *     (Firebase Console > Configurações > Contas de serviço > Gerar nova chave).
 *
 * COMO RODAR:
 *   cd seed && npm install && node promover_lideres.js
 *
 * Reexecutar é seguro (idempotente). Para rebaixar alguém, edite no Console.
 */
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const auth = admin.auth();

// Administradores da Comunidade Nova Aliança.
const EMAILS = [
  "jailtonmjc@gmail.com",
  "gabrielbiel.ferreira0411@gmail.com",
];

// Perfil de liderança: 'lider' | 'pastor' | 'diacono'
const PERFIL = "lider";

(async () => {
  for (const email of EMAILS) {
    try {
      const user = await auth.getUserByEmail(email);
      await db.collection("usuarios").doc(user.uid).set(
        {
          email: email,
          perfil: PERFIL,
          status: "aprovado",
          aprovado_em: admin.firestore.FieldValue.serverTimestamp(),
          aprovado_por: "admin-script",
        },
        { merge: true }
      );
      console.log(`OK  ${email} -> ${PERFIL} / aprovado (uid ${user.uid})`);
    } catch (e) {
      if (e.code === "auth/user-not-found") {
        console.log(`FALTA  ${email} ainda não se cadastrou no app.`);
      } else {
        console.log(`ERRO  ${email}: ${e.message}`);
      }
    }
  }
  process.exit(0);
})();
