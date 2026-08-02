/**
 * Verificação de leitura (não escreve nada): confirma o perfil dos
 * administradores e o conteúdo realmente gravado nas coleções.
 *
 *   cd seed && node verificar.js
 */
const admin = require("firebase-admin");
const sa = require("./serviceAccountKey.json");

admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();
const auth = admin.auth();

const EMAILS = ["jailtonmjc@gmail.com", "gabrielbiel.ferreira0411@gmail.com"];

(async () => {
  for (const email of EMAILS) {
    try {
      const user = await auth.getUserByEmail(email);
      const snap = await db.collection("usuarios").doc(user.uid).get();
      const d = snap.data() || {};
      console.log(
        `ADMIN ${email}: perfil="${d.perfil}" status="${d.status}" nome="${
          d.nome || "(sem nome)"
        }"`
      );
    } catch (e) {
      console.log(`ADMIN ${email}: ERRO ${e.message}`);
    }
  }

  const agora = new Date();
  const ev = await db.collection("eventos").orderBy("data").get();
  console.log(`\nEVENTOS: ${ev.size}`);
  ev.forEach((doc) => {
    const e = doc.data();
    const dt = e.data && e.data.toDate ? e.data.toDate() : null;
    const futuro = dt && dt > agora;
    console.log(
      `  - ${e.titulo} | ${
        dt ? dt.toLocaleString("pt-BR") : "SEM DATA"
      } | ${futuro ? "FUTURO (aparece)" : "PASSADO (nao aparece)"}`
    );
  });

  for (const c of [
    "avisos",
    "ministerios",
    "devocionais",
    "campanhas",
    "pedidos_oracao",
    "notificacoes",
  ]) {
    const s = await db.collection(c).get();
    console.log(`${c.toUpperCase()}: ${s.size}`);
  }

  process.exit(0);
})();
