/**
 * Script de SEED — popula Avisos e Eventos de exemplo no Firestore, para
 * visualizar as telas com dados reais enquanto o painel de Gestão não existe.
 *
 * Requer uma chave de service account (Admin SDK) — NÃO versionada:
 *   1. Firebase Console > Configurações do projeto > Contas de serviço
 *   2. "Gerar nova chave privada" -> salve como seed/serviceAccountKey.json
 *   3. cd seed && npm install && node seed.js
 *
 * Rode novamente com `node seed.js --limpar` para remover os itens de exemplo.
 */
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;

const TAG = "seed-exemplo"; // marca para permitir limpeza

const avisos = [
  {
    titulo: "Culto de Celebração neste domingo",
    conteudo:
      "Venha participar do nosso culto de celebração às 19h. Traga a família!",
    prioridade: "normal",
    segmento: "todos",
  },
  {
    titulo: "Reunião de líderes",
    conteudo: "Encontro de liderança na quinta-feira, às 20h, na sala 2.",
    prioridade: "normal",
    segmento: "lideres",
  },
];

function daqui(dias, horas) {
  const d = new Date();
  d.setDate(d.getDate() + dias);
  d.setHours(horas, 0, 0, 0);
  return Timestamp.fromDate(d);
}

const eventos = [
  {
    titulo: "Culto de Domingo",
    descricao: "Culto principal da Comunidade Nova Aliança.",
    data: daqui(3, 19),
    horario: "19h",
    local: "Templo Sede",
    tipo: "culto",
    publico: true,
  },
  {
    titulo: "Encontro de Jovens",
    descricao: "Louvor, palavra e comunhão para a juventude.",
    data: daqui(5, 19),
    horario: "19h",
    local: "Salão de Jovens",
    tipo: "ministerio",
    publico: true,
  },
];

async function limpar() {
  for (const col of ["avisos", "eventos"]) {
    const snap = await db.collection(col).where("_seed", "==", TAG).get();
    for (const doc of snap.docs) await doc.reference.delete();
    console.log(`Removidos ${snap.size} de ${col}`);
  }
}

async function popular() {
  const now = Timestamp.now();
  for (const a of avisos) {
    await db.collection("avisos").add({
      ...a,
      autor_id: "seed",
      publicado_em: now,
      ativo: true,
      _seed: TAG,
    });
  }
  for (const e of eventos) {
    await db.collection("eventos").add({
      ...e,
      criado_por: "seed",
      confirmados_count: 0,
      _seed: TAG,
    });
  }
  console.log(`Inseridos ${avisos.length} avisos e ${eventos.length} eventos.`);
}

(async () => {
  if (process.argv.includes("--limpar")) {
    await limpar();
  } else {
    await popular();
  }
  process.exit(0);
})();
