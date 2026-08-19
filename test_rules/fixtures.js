/**
 * Elenco fixo usado pelas suítes de Rules. UIDs fictícios, apenas emulador.
 */
const OLINDA = "olinda";
const PETROLINA = "petrolina";

const U = {
  superAdmin: "uid_superadmin",
  pastorOlinda: "uid_pastor_olinda",
  diaconoOlinda: "uid_diacono_olinda",
  evangelistaOlinda: "uid_evangelista_olinda",
  liderOlinda: "uid_lider_olinda",
  liderOlinda2: "uid_lider_olinda_2",
  tesoureiroOlinda: "uid_tesoureiro_olinda",
  editorOlinda: "uid_editor_olinda",
  moderadorOlinda: "uid_moderador_olinda",
  membroOlinda: "uid_membro_olinda",
  pendenteOlinda: "uid_pendente_olinda",
  inativoOlinda: "uid_inativo_olinda",
  pastorPetrolina: "uid_pastor_petrolina",
  visitante: "uid_visitante_anonimo",
};

const SEGREDO_CANARIO = "SEGREDO-CANARIO-NAO-PODE-VAZAR";

const CATALOGO_IGREJAS = {
  [OLINDA]: {
    nome: "Nova Aliança Olinda",
    ativa: true,
    configurada: true,
    endereco: "Av. Leopoldino Canuto de Melo, 846, Caixa D'Água",
    cidade_estado: "Olinda — PE",
    endereco_secundario: null,
    slogan: "Uma família para pertencer",
    cultos_recorrentes: ["Domingo às 18h"],
    instagram: "@novaaliancaolinda",
    youtube_url: null,
    pastores_publicos: ["Pastor Público de Teste"],
  },
  [PETROLINA]: {
    nome: "Nova Aliança Petrolina",
    ativa: false,
    configurada: false,
    endereco: "Rua 47, número 180 — São Gonçalo",
    cidade_estado: "Petrolina — PE",
    endereco_secundario: "Rua Tomaz Maia, número 255",
    slogan: "Uma família para pertencer",
    cultos_recorrentes: ["Quinta-feira às 19h30", "Domingo às 18h"],
    instagram: "@cna.petrolina_",
    youtube_url: "https://www.youtube.com/@comunidadenovaalianca547",
    pastores_publicos: [],
  },
};

function institucionaisDoCatalogo(catalogo) {
  const { nome: _nome, ativa: _ativa, configurada: _configurada, ...dados } =
    catalogo;
  return dados;
}

function vinculo(perfil, status = "aprovado", funcoes = []) {
  return {
    perfil,
    status,
    funcoes_admin: funcoes,
    ministerio_ids: [],
    aprovado_por: "seed",
    aprovado_em: new Date(),
  };
}

/**
 * Semeia o catálogo público sanitizado, documentos institucionais privados,
 * vínculos, conteúdo, transações e auditoria nas duas unidades. Executado com
 * as Rules desabilitadas.
 */
async function semearBase(fs) {
  for (const [igrejaId, catalogo] of Object.entries(CATALOGO_IGREJAS)) {
    // `set` sem merge mantém a projeção pública com EXATAMENTE 11 campos.
    await fs.doc(`catalogo_igrejas/${igrejaId}`).set(catalogo);
  }

  await fs.doc(`igrejas/${OLINDA}`).set({
    nome: "Nova Aliança Olinda",
    ativa: true,
    configurada: true,
    criado_por: SEGREDO_CANARIO,
    mercado_pago_status: "configurado",
    dados_institucionais: {
      ...institucionaisDoCatalogo(CATALOGO_IGREJAS[OLINDA]),
      pix_chave: SEGREDO_CANARIO,
      telefone: SEGREDO_CANARIO,
      responsavel_administrativo_uid: U.pastorOlinda,
    },
  });
  await fs.doc(`igrejas/${PETROLINA}`).set({
    nome: "Nova Aliança Petrolina",
    ativa: false,
    configurada: false,
    criado_por: SEGREDO_CANARIO,
    mercado_pago_status: "nao_configurado",
    dados_institucionais: {
      ...institucionaisDoCatalogo(CATALOGO_IGREJAS[PETROLINA]),
      pix_chave: SEGREDO_CANARIO,
      telefone: SEGREDO_CANARIO,
      responsavel_administrativo_uid: U.pastorPetrolina,
    },
  });

  const membrosOlinda = {
    [U.pastorOlinda]: vinculo("pastor", "aprovado", ["pastor"]),
    [U.diaconoOlinda]: vinculo("diacono"),
    [U.evangelistaOlinda]: vinculo("evangelista"),
    [U.liderOlinda]: vinculo("lider"),
    [U.liderOlinda2]: vinculo("lider"),
    [U.tesoureiroOlinda]: vinculo("membro", "aprovado", ["tesoureiro"]),
    [U.editorOlinda]: vinculo("membro", "aprovado", ["editor"]),
    [U.moderadorOlinda]: vinculo("membro", "aprovado", ["moderador_oracao"]),
    [U.membroOlinda]: vinculo("membro"),
    [U.pendenteOlinda]: vinculo("membro", "pendente"),
    // Perfil de liderança porém INATIVO: não pode conceder nada.
    [U.inativoOlinda]: vinculo("lider", "inativo"),
  };

  for (const [uid, dados] of Object.entries(membrosOlinda)) {
    await fs.doc(`igrejas/${OLINDA}/membros/${uid}`).set(dados);
  }

  await fs
    .doc(`igrejas/${PETROLINA}/membros/${U.pastorPetrolina}`)
    .set(vinculo("pastor", "aprovado", ["pastor"]));

  // Conteúdo: um público e um restrito em cada unidade.
  for (const igreja of [OLINDA, PETROLINA]) {
    await fs.doc(`igrejas/${igreja}/avisos/publico`).set({
      titulo: "Aviso público",
      publico: true,
      ativo: true,
    });
    await fs.doc(`igrejas/${igreja}/avisos/restrito`).set({
      titulo: "Aviso interno",
      publico: false,
      ativo: true,
    });
    await fs.doc(`igrejas/${igreja}/eventos/publico`).set({
      titulo: "Culto",
      publico: true,
    });

    await fs.doc(`igrejas/${igreja}/transacoes/tx1`).set({
      usuario_id: U.membroOlinda,
      igreja_id: igreja,
      valor_centavos: 5000,
      tipo: "dizimo",
      metodo: "pix",
      status: "aprovado",
      criado_em: new Date(),
    });

    await fs.doc(`igrejas/${igreja}/auditoria/log1`).set({
      acao: "aprovar_membro",
      autor_id: "seed",
      alvo_id: U.membroOlinda,
      em: new Date(),
    });

    await fs.doc(`igrejas/${igreja}/pedidos_oracao/publico`).set({
      autor_id: U.membroOlinda,
      texto: "Orem por mim",
      privado: false,
      aprovado: true,
      oram_count: 0,
      oram_por: [],
    });
    await fs.doc(`igrejas/${igreja}/pedidos_oracao/moderacao`).set({
      autor_id: U.visitante,
      texto: "Pedido novo",
      privado: false,
      aprovado: false,
      oram_count: 0,
      oram_por: [],
    });
  }

  await fs.doc(`usuarios/${U.membroOlinda}`).set({
    nome: "Membro Teste",
    email: "membro@teste.local",
    igreja_principal_id: OLINDA,
  });
  await fs.doc(`usuarios/${U.liderOlinda}`).set({
    nome: "Lider Teste",
    email: "lider@teste.local",
    igreja_principal_id: OLINDA,
  });
}

module.exports = {
  OLINDA,
  PETROLINA,
  U,
  SEGREDO_CANARIO,
  CATALOGO_IGREJAS,
  vinculo,
  semearBase,
};
