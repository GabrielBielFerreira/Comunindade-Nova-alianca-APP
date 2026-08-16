/**
 * Seed de demonstração — EXCLUSIVO do Firebase Emulator Suite.
 *
 * Cria Olinda e Petrolina, o elenco de teste com todos os papéis e algumas
 * transações CLARAMENTE MARCADAS COMO TESTE.
 *
 * Idempotente: pode rodar quantas vezes quiser.
 *
 * ⚠️ As contas @teste.local e a senha abaixo existem só no emulador. A trava
 * em guarda.js impede execução fora dele.
 */
const admin = require("firebase-admin");
const { exigirEmulador, PROJECT_ID } = require("./guarda");

exigirEmulador();

admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();
const auth = admin.auth();

const SENHA = "Teste123!";

/** Elenco: cobre toda a matriz de permissões. */
const PESSOAS = [
  {
    email: "superadmin@teste.local",
    nome: "Super Admin (teste)",
    superAdmin: true,
    vinculos: [],
  },
  {
    email: "pastor.olinda@teste.local",
    nome: "Pastor Olinda (teste)",
    vinculos: [{ igreja: "olinda", perfil: "pastor", funcoes: ["pastor"] }],
  },
  {
    email: "diacono.olinda@teste.local",
    nome: "Diácono Olinda (teste)",
    vinculos: [{ igreja: "olinda", perfil: "diacono" }],
  },
  {
    email: "evangelista.olinda@teste.local",
    nome: "Evangelista Olinda (teste)",
    vinculos: [{ igreja: "olinda", perfil: "evangelista" }],
  },
  {
    email: "lider.olinda@teste.local",
    nome: "Líder Olinda (teste)",
    vinculos: [{ igreja: "olinda", perfil: "lider" }],
  },
  {
    email: "lider2.olinda@teste.local",
    nome: "Líder Dois Olinda (teste)",
    vinculos: [{ igreja: "olinda", perfil: "lider" }],
  },
  {
    // Perfil comunitário membro + função tesoureiro: acesso financeiro sem
    // ser liderança ministerial.
    email: "tesoureiro.olinda@teste.local",
    nome: "Tesoureiro Olinda (teste)",
    vinculos: [{ igreja: "olinda", perfil: "membro", funcoes: ["tesoureiro"] }],
  },
  {
    email: "editor.olinda@teste.local",
    nome: "Editor Olinda (teste)",
    vinculos: [{ igreja: "olinda", perfil: "membro", funcoes: ["editor"] }],
  },
  {
    email: "moderador.olinda@teste.local",
    nome: "Moderador Olinda (teste)",
    vinculos: [
      { igreja: "olinda", perfil: "membro", funcoes: ["moderador_oracao"] },
    ],
  },
  {
    email: "pastor.petrolina@teste.local",
    nome: "Pastor Petrolina (teste)",
    vinculos: [{ igreja: "petrolina", perfil: "pastor", funcoes: ["pastor"] }],
  },
  {
    email: "membro@teste.local",
    nome: "Membro Pendente (teste)",
    vinculos: [{ igreja: "olinda", perfil: "membro", status: "pendente" }],
  },
];

const IGREJAS = [
  {
    id: "olinda",
    nome: "Nova Aliança Olinda",
    ativa: true,
    // Sede: dados institucionais já conhecidos do código atual.
    configurada: true,
    dados_institucionais: {
      pastor_responsavel: "José Victor Carvalho P. Santos",
      endereco: "Av. Leopoldino Canuto de Melo, 846, Caixa D'Água",
      cidade_estado: "Olinda — PE",
      cep: "53210-250",
      instagram: "@novaaliancaolinda",
      pix_chave: null,
      pix_tipo: null,
      telefone: null,
    },
  },
  {
    id: "petrolina",
    nome: "Nova Aliança Petrolina",
    // Entra INATIVA e NÃO CONFIGURADA: os dados oficiais ainda não foram
    // confirmados pelo responsável e não serão inventados aqui.
    ativa: false,
    configurada: false,
    dados_institucionais: {
      pastor_responsavel: null,
      endereco: null,
      cidade_estado: null,
      cep: null,
      instagram: null,
      pix_chave: null,
      pix_tipo: null,
      telefone: null,
    },
  },
];

async function garantirUsuario(pessoa) {
  let user;
  try {
    user = await auth.getUserByEmail(pessoa.email);
  } catch {
    user = await auth.createUser({
      email: pessoa.email,
      password: SENHA,
      displayName: pessoa.nome,
      emailVerified: true,
    });
  }

  // Custom claim de super_admin — a única permissão global do sistema.
  const claims = pessoa.superAdmin ? { super_admin: true } : {};
  await auth.setCustomUserClaims(user.uid, claims);

  await db.doc(`usuarios/${user.uid}`).set(
    {
      nome: pessoa.nome,
      email: pessoa.email,
      telefone: "",
      igreja_principal_id: pessoa.vinculos[0]?.igreja ?? null,
      criado_em: admin.firestore.FieldValue.serverTimestamp(),
      origem: "seed_emulador",
    },
    { merge: true }
  );

  return user.uid;
}

async function criarVinculo(uid, vinculo) {
  await db.doc(`igrejas/${vinculo.igreja}/membros/${uid}`).set(
    {
      perfil: vinculo.perfil,
      status: vinculo.status ?? "aprovado",
      funcoes_admin: vinculo.funcoes ?? [],
      ministerio_ids: [],
      aprovado_por: "seed_emulador",
      aprovado_em: admin.firestore.FieldValue.serverTimestamp(),
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

/** Transações de demonstração, marcadas como teste. */
async function criarTransacoes(igrejaId, usuarioId, quantia) {
  const amostras = [
    { tipo: "dizimo", metodo: "pix", status: "aprovado", valor_centavos: 15000 },
    { tipo: "oferta", metodo: "pix", status: "aprovado", valor_centavos: 5050 },
    { tipo: "oferta", metodo: "checkout_pro", status: "pendente", valor_centavos: 2500 },
    { tipo: "campanha", metodo: "pix", status: "rejeitado", valor_centavos: 8000 },
    { tipo: "dizimo", metodo: "pix", status: "aprovado", valor_centavos: quantia },
  ];

  for (let i = 0; i < amostras.length; i++) {
    const a = amostras[i];
    const criadoEm = new Date(Date.now() - i * 86400000);
    await db.doc(`igrejas/${igrejaId}/transacoes/seed_${igrejaId}_${i}`).set({
      usuario_id: usuarioId,
      igreja_id: igrejaId,
      valor_centavos: a.valor_centavos,
      tipo: a.tipo,
      metodo: a.metodo,
      status: a.status,
      campanha_id: a.tipo === "campanha" ? "campanha_teste" : null,
      mp_payment_id: null,
      mp_status_detail: "seed_emulador",
      // Marcação explícita: nada aqui representa dinheiro real.
      origem: "seed_emulador",
      demonstracao: true,
      criado_em: admin.firestore.Timestamp.fromDate(criadoEm),
      atualizado_em: admin.firestore.Timestamp.fromDate(criadoEm),
      aprovado_em:
        a.status === "aprovado"
          ? admin.firestore.Timestamp.fromDate(criadoEm)
          : null,
    });
  }
}

/**
 * Conteúdo de demonstração da unidade.
 *
 * O rótulo `[{IGREJA}]` no título é proposital: se o painel misturasse
 * unidades, apareceria conteúdo de Petrolina dentro de Olinda e o erro seria
 * visível na hora.
 */
async function criarConteudo(igrejaId) {
  const marca = igrejaId.toUpperCase();
  const agora = admin.firestore.FieldValue.serverTimestamp();
  const base = { origem: "seed_emulador", demonstracao: true };

  // ── Avisos ────────────────────────────────────────────────────────
  // `conteudo` é o campo canônico (o legado `corpo` só é lido, nunca gravado).
  await db.doc(`igrejas/${igrejaId}/avisos/seed_publico`).set({
    ...base,
    titulo: `[${marca}] Aviso público de demonstração`,
    conteudo: "Conteúdo de teste do emulador, visível também a visitantes.",
    prioridade: "normal",
    publico: true,
    ativo: true,
    publicado_em: agora,
  });
  await db.doc(`igrejas/${igrejaId}/avisos/seed_interno`).set({
    ...base,
    titulo: `[${marca}] Aviso interno de demonstração`,
    conteudo: "Visível apenas para membros aprovados desta unidade.",
    prioridade: "urgente",
    publico: false,
    ativo: true,
    publicado_em: agora,
  });

  // ── Eventos ───────────────────────────────────────────────────────
  const emDias = (d) =>
    admin.firestore.Timestamp.fromDate(new Date(Date.now() + d * 86400000));

  await db.doc(`igrejas/${igrejaId}/eventos/seed_culto`).set({
    ...base,
    titulo: `[${marca}] Culto de demonstração`,
    descricao: "Evento de teste criado pelo seed do emulador.",
    data: emDias(3),
    local: "Templo",
    tipo: "culto",
    publico: true,
    cancelado: false,
  });
  await db.doc(`igrejas/${igrejaId}/eventos/seed_reuniao`).set({
    ...base,
    titulo: `[${marca}] Reunião de liderança (interna)`,
    descricao: "Somente membros aprovados desta unidade.",
    data: emDias(7),
    local: "Sala 2",
    tipo: "reuniao",
    publico: false,
    cancelado: false,
  });

  // ── Campanhas ─────────────────────────────────────────────────────
  await db.doc(`igrejas/${igrejaId}/campanhas/seed_campanha`).set({
    ...base,
    titulo: `[${marca}] Campanha de demonstração`,
    descricao: "Campanha de teste do emulador.",
    data_inicio: emDias(-10),
    data_fim: null,
    meta_centavos: 500000, // R$ 5.000,00
    status: "ativa",
    publico: true,
  });

  // ── Ministérios ───────────────────────────────────────────────────
  await db.doc(`igrejas/${igrejaId}/ministerios/seed_louvor`).set({
    ...base,
    nome: `[${marca}] Ministério de Louvor`,
    descricao: "Ministério de teste do emulador.",
    ativo: true,
    publico: true,
    lider_id: null,
    lider_nome: null,
  });
  await db.doc(`igrejas/${igrejaId}/ministerios/seed_infantil`).set({
    ...base,
    nome: `[${marca}] Ministério Infantil`,
    descricao: "Ministério inativo, para testar o filtro.",
    ativo: false,
    publico: true,
    lider_id: null,
    lider_nome: null,
  });

  // ── Devocionais ───────────────────────────────────────────────────
  await db.doc(`igrejas/${igrejaId}/devocionais/seed_devocional`).set({
    ...base,
    titulo: `[${marca}] Devocional de demonstração`,
    corpo: "Texto devocional de teste do emulador.",
    autor: "Equipe de comunicação",
    data: emDias(-1),
    referencia: "Salmos 23",
    destaque: true,
    ativo: true,
  });

  // ── Pedidos de oração ─────────────────────────────────────────────
  await db.doc(`igrejas/${igrejaId}/pedidos_oracao/seed_aprovado`).set({
    ...base,
    autor_id: "seed",
    autor_nome: "Membro de teste",
    texto: `[${marca}] Pedido já aprovado, visível no mural.`,
    privado: false,
    anonimo: false,
    urgente: false,
    aprovado: true,
    recusado: false,
    oram_count: 0,
    oram_por: [],
    criado_em: emDias(-2),
  });
  await db.doc(`igrejas/${igrejaId}/pedidos_oracao/seed_moderacao`).set({
    ...base,
    autor_id: "seed",
    autor_nome: "Visitante de teste",
    texto: `[${marca}] Pedido comum aguardando moderação.`,
    privado: false,
    anonimo: false,
    urgente: false,
    aprovado: false,
    recusado: false,
    oram_count: 0,
    oram_por: [],
    criado_em: emDias(-1),
  });
  await db.doc(`igrejas/${igrejaId}/pedidos_oracao/seed_urgente`).set({
    ...base,
    autor_id: "seed",
    autor_nome: "Anônimo",
    texto: `[${marca}] Pedido URGENTE e anônimo aguardando moderação.`,
    privado: false,
    anonimo: true,
    urgente: true,
    aprovado: false,
    recusado: false,
    oram_count: 0,
    oram_por: [],
    criado_em: agora,
  });
}

(async () => {
  console.log("\n=== SEED DO EMULADOR — Nova Aliança ===\n");

  for (const igreja of IGREJAS) {
    const { id, ...dados } = igreja;
    await db.doc(`igrejas/${id}`).set(
      {
        ...dados,
        slug: id,
        mercado_pago_status: "nao_configurado",
        criado_em: admin.firestore.FieldValue.serverTimestamp(),
        atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    console.log(
      `igreja  ${id.padEnd(12)} ativa=${dados.ativa} configurada=${dados.configurada}`
    );
  }

  const criados = [];
  for (const pessoa of PESSOAS) {
    const uid = await garantirUsuario(pessoa);
    for (const vinculo of pessoa.vinculos) {
      await criarVinculo(uid, vinculo);
    }
    criados.push({ email: pessoa.email, uid, superAdmin: !!pessoa.superAdmin });
    const resumo = pessoa.superAdmin
      ? "super_admin (claim)"
      : pessoa.vinculos
          .map(
            (v) =>
              `${v.igreja}:${v.perfil}${
                v.funcoes?.length ? `+${v.funcoes.join("+")}` : ""
              }${v.status ? `(${v.status})` : ""}`
          )
          .join(", ");
    console.log(`usuario ${pessoa.email.padEnd(34)} ${resumo}`);
  }

  const membroUid = criados.find((c) => c.email === "membro@teste.local").uid;
  await criarTransacoes("olinda", membroUid, 30000);
  // Petrolina recebe valores DIFERENTES: se o painel misturar unidades, o
  // total muda e o teste de isolamento falha de forma visível.
  await criarTransacoes("petrolina", membroUid, 99900);
  console.log("\ntransacoes de teste criadas em olinda e petrolina");

  await criarConteudo("olinda");
  await criarConteudo("petrolina");
  console.log("conteudo de demonstracao criado");

  console.log(`\nSenha de todas as contas de teste: ${SENHA}`);
  console.log("Todas as contas usam @teste.local e existem SO no emulador.\n");
  process.exit(0);
})().catch((erro) => {
  console.error("\n[ERRO] seed falhou:", erro);
  process.exit(1);
});
