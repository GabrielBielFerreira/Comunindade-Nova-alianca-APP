/**
 * Complemento do seed para demonstração:
 *  - vincula os administradores a um ministério (faz o card "Meu Ministério"
 *    da Home aparecer — o card só surge quando existe vínculo REAL);
 *  - cria uma campanha ATIVA com valor arrecadado ZERO (honesto: nenhum
 *    progresso financeiro é inventado — a conciliação é manual/por webhook);
 *  - cria a notificação real de "Cadastro aprovado" para os administradores
 *    (eles acabaram de ser aprovados pelo promover_lideres.js).
 *
 *   cd seed && node seed_extra.js            # aplica
 *   cd seed && node seed_extra.js --limpar   # remove o que este script criou
 */
const admin = require("firebase-admin");
const sa = require("./serviceAccountKey.json");

admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();
const auth = admin.auth();
const Timestamp = admin.firestore.Timestamp;

const TAG = "seed-exemplo"; // mesma marca do seed.js (permite limpeza)
const EMAILS = ["jailtonmjc@gmail.com", "gabrielbiel.ferreira0411@gmail.com"];
const MINISTERIO_ALVO = "Ministério de Louvor";

async function limpar() {
  for (const col of ["campanhas", "notificacoes"]) {
    const snap = await db.collection(col).where("_seed", "==", TAG).get();
    const batch = db.batch();
    snap.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    console.log(`Removidos ${snap.size} de ${col}`);
  }
  // Desfaz o vínculo de ministério.
  for (const email of EMAILS) {
    try {
      const u = await auth.getUserByEmail(email);
      await db.collection("usuarios").doc(u.uid).set(
        { ministerio_id: admin.firestore.FieldValue.delete() },
        { merge: true }
      );
    } catch (_) {}
  }
  console.log("Vínculos de ministério removidos.");
}

(async () => {
  if (process.argv.includes("--limpar")) {
    await limpar();
    process.exit(0);
  }

  // 1) Vincula os admins ao ministério (usa o ID real do documento).
  const minSnap = await db
    .collection("ministerios")
    .where("nome", "==", MINISTERIO_ALVO)
    .limit(1)
    .get();

  if (minSnap.empty) {
    console.log(`AVISO: ministério "${MINISTERIO_ALVO}" não encontrado.`);
  } else {
    const ministerioId = minSnap.docs[0].id;
    for (const email of EMAILS) {
      try {
        const u = await auth.getUserByEmail(email);
        await db
          .collection("usuarios")
          .doc(u.uid)
          .set({ ministerio_id: ministerioId }, { merge: true });
        console.log(`Vinculado ${email} -> ${MINISTERIO_ALVO} (${ministerioId})`);
      } catch (e) {
        console.log(`ERRO vínculo ${email}: ${e.message}`);
      }
    }
  }

  // 2) Campanha ativa — SEM progresso financeiro inventado.
  const jaTem = await db
    .collection("campanhas")
    .where("_seed", "==", TAG)
    .limit(1)
    .get();
  if (jaTem.empty) {
    await db.collection("campanhas").add({
      titulo: "Reforma do Templo",
      descricao:
        "Campanha para a reforma e ampliação do espaço de cultos da Comunidade Nova Aliança.",
      meta_valor: 5000000, // R$ 50.000,00 em centavos
      valor_arrecadado: 0, // honesto: nenhuma contribuição confirmada ainda
      status: "ativa",
      data_inicio: Timestamp.fromDate(new Date()),
      criado_por: "seed",
      _seed: TAG,
    });
    console.log("Campanha criada (arrecadado R$ 0,00 — sem dado falso).");
  } else {
    console.log("Campanha de exemplo já existe.");
  }

  // 3) Notificação real de cadastro aprovado.
  for (const email of EMAILS) {
    try {
      const u = await auth.getUserByEmail(email);
      const existe = await db
        .collection("notificacoes")
        .where("destinatario_id", "==", u.uid)
        .where("_seed", "==", TAG)
        .limit(1)
        .get();
      if (existe.empty) {
        await db.collection("notificacoes").add({
          destinatario_id: u.uid,
          titulo: "Cadastro aprovado",
          corpo:
            "Bem-vindo(a)! Seu acesso à Comunidade Nova Aliança foi liberado.",
          tipo: "sistema",
          lida: false,
          criado_em: Timestamp.fromDate(new Date()),
          _seed: TAG,
        });
        console.log(`Notificação criada para ${email}`);
      }
    } catch (e) {
      console.log(`ERRO notificação ${email}: ${e.message}`);
    }
  }

  process.exit(0);
})();
