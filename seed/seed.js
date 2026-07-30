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

const ministerios = [
  {
    nome: "Ministério de Louvor",
    descricao:
        "Conduz a igreja em adoração nos cultos e eventos. Reúne cantores e instrumentistas.",
  },
  {
    nome: "Ministério Infantil",
    descricao:
        "Cuida do ensino bíblico das crianças com amor, segurança e criatividade.",
  },
  {
    nome: "Mídia da Igreja",
    descricao:
        "Responsável por transmissão, fotografia, redes sociais e projeção nos cultos.",
  },
  {
    nome: "Grupo de Jovens",
    descricao:
        "Espaço de comunhão, discipulado e serviço para a juventude da comunidade.",
  },
];

const devocionais = [
  {
    titulo: "Descanse no Pastor",
    corpo:
        "O Senhor é o teu pastor e nada te faltará. Entregue hoje suas preocupações a Ele e caminhe em paz, confiando no seu cuidado constante.",
    autor: "Pr. José Victor",
    referencia: "Salmos 23:1",
    destaque: true,
  },
  {
    titulo: "A força que vem de Deus",
    corpo:
        "Tudo posso naquele que me fortalece. Nas dificuldades desta semana, lembre-se de que sua força vem do Senhor, não das circunstâncias.",
    autor: "Equipe Pastoral",
    referencia: "Filipenses 4:13",
    destaque: false,
  },
];

async function limpar() {
  for (const col of ["avisos", "eventos", "ministerios", "devocionais"]) {
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
  for (const m of ministerios) {
    await db.collection("ministerios").add({
      ...m,
      lider_id: "seed",
      membros_count: 0,
      ativo: true,
      criado_em: now,
      _seed: TAG,
    });
  }
  for (const d of devocionais) {
    await db.collection("devocionais").add({
      ...d,
      data: now,
      _seed: TAG,
    });
  }
  console.log(
    `Inseridos ${avisos.length} avisos, ${eventos.length} eventos, ` +
      `${ministerios.length} ministérios e ${devocionais.length} devocionais.`
  );
}

(async () => {
  if (process.argv.includes("--limpar")) {
    await limpar();
  } else {
    await popular();
  }
  process.exit(0);
})();
