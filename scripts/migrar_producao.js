/**
 * Migração das coleções globais para a estrutura multi-igreja.
 *
 * Segurança:
 *  - exige o projeto oficial explicitamente;
 *  - `--dry-run` é o padrão e `--apply` é sempre explícito;
 *  - audita contagens e NOMES de campos, nunca valores;
 *  - valida todos os destinos existentes antes de qualquer escrita;
 *  - cria um catálogo público por allowlist, separado dos metadados internos;
 *  - aplica no máximo 450 operações em uma única transação atômica;
 *  - relê e trava origens/destinos na transação antes de qualquer escrita;
 *  - verifica depois do commit que um novo planejamento produz zero operações;
 *  - usa `create()` nos destinos ausentes, sem sobrescrever corridas;
 *  - nunca apaga coleções legadas.
 *
 * Preparação:
 *   npm --prefix scripts ci
 *   gcloud auth application-default login
 *   gcloud config set project nova-alianca-app
 *
 * Uso:
 *   node scripts/migrar_producao.js --project=nova-alianca-app --dry-run
 *   node scripts/migrar_producao.js --project=nova-alianca-app --apply
 */
"use strict";

const {
  compararCatalogo,
  inventariarCampos,
  projetarCatalogoPublico,
  validarUnidadeConhecida,
} = require("./catalogo_igrejas");

const PROJETO_ESPERADO = "nova-alianca-app";
const OLINDA = "olinda";
const PETROLINA = "petrolina";
const LIMITE_OPERACOES_TRANSACAO = 450;
// Alias preservado para consumidores dos helpers puros anteriores.
const LIMITE_OPERACOES_BATCH = LIMITE_OPERACOES_TRANSACAO;

const COLECOES = [
  "avisos",
  "eventos",
  "campanhas",
  "ministerios",
  "devocionais",
  "pedidos_oracao",
  "interesses_ministerio",
  "auditoria",
];

const COLECOES_AUDITADAS = [
  "igrejas",
  "catalogo_igrejas",
  "igreja",
  "usuarios",
  ...COLECOES,
  "transacoes",
  "notificacoes",
  "tokens_dispositivo",
  "configuracoes",
];

const UNIDADES_BASE = [
  {
    id: OLINDA,
    dados: {
      nome: "Nova Aliança Olinda",
      slug: OLINDA,
      ativa: true,
      // Derivado mais adiante somente de dados institucionais allowlisted.
      configurada: false,
      mercado_pago_status: "nao_configurado",
    },
  },
  {
    id: PETROLINA,
    dados: {
      nome: "Nova Aliança Petrolina",
      slug: PETROLINA,
      ativa: false,
      configurada: false,
      dados_institucionais: {},
      mercado_pago_status: "nao_configurado",
    },
  },
];

const CAMPOS_INSTITUCIONAIS_LEGADOS = [
  "pastor_responsavel",
  "pastores_publicos",
  "responsavel_administrativo_uid",
  "slogan",
  "endereco",
  "endereco_secundario",
  "youtube_url",
  "cultos_recorrentes",
  "cidade_estado",
  "cep",
  "telefone",
  "instagram",
  "pix_chave",
  "pix_tipo",
];

const CAMPOS_LISTA = new Set(["pastores_publicos", "cultos_recorrentes"]);

function argumento(nome, argv) {
  const prefixo = `--${nome}=`;
  const item = argv.find((valor) => valor.startsWith(prefixo));
  return item ? item.slice(prefixo.length) : undefined;
}

function analisarArgumentos(argv = process.argv.slice(2)) {
  const projeto = argumento("project", argv);
  const aplicar = argv.includes("--apply");
  const dryRunExplicito = argv.includes("--dry-run");

  if (!projeto) {
    throw new Error(
      `Informe --project=${PROJETO_ESPERADO} explicitamente (o padrão é --dry-run).`
    );
  }
  if (projeto !== PROJETO_ESPERADO) {
    throw new Error(`Projeto recusado; este script só opera em ${PROJETO_ESPERADO}.`);
  }
  if (aplicar && dryRunExplicito) {
    throw new Error("Use somente um modo: --dry-run ou --apply.");
  }

  return { projeto, aplicar, dryRun: !aplicar };
}

function validarOpcoesExecucao({ projeto, dryRun } = {}) {
  if (projeto !== PROJETO_ESPERADO) {
    throw new Error(`Projeto recusado; este script só opera em ${PROJETO_ESPERADO}.`);
  }
  if (typeof dryRun !== "boolean") {
    throw new Error("dryRun deve ser informado explicitamente como boolean.");
  }
  return { projeto, dryRun };
}

function validarProjetoRuntime({ admin, db, projeto }) {
  const projetosDetectados = [];
  const adicionar = (valor) => {
    if (typeof valor === "string" && valor.trim().length > 0) {
      projetosDetectados.push(valor.trim());
    }
  };

  adicionar(db?.projectId);
  try {
    adicionar(admin?.app?.().options?.projectId);
  } catch {
    // Um runtime sem app padrão ainda será recusado abaixo se o Firestore
    // também não expuser de forma verificável o projeto ao qual está ligado.
  }

  if (projetosDetectados.length === 0) {
    throw new Error("Runtime recusado: projeto do Firestore não verificável.");
  }
  if (projetosDetectados.some((item) => item !== projeto)) {
    throw new Error("Runtime recusado: Firestore ligado a outro projeto.");
  }

  return projeto;
}

function objetoSimples(valor) {
  return valor !== null && typeof valor === "object" && !Array.isArray(valor);
}

function extrairDadosInstitucionaisLegados(bruto) {
  if (!objetoSimples(bruto)) return {};
  const saida = {};

  for (const campo of CAMPOS_INSTITUCIONAIS_LEGADOS) {
    if (!Object.prototype.hasOwnProperty.call(bruto, campo)) continue;
    const valor = bruto[campo];

    if (CAMPOS_LISTA.has(campo)) {
      if (!Array.isArray(valor)) continue;
      saida[campo] = valor
        .filter((item) => typeof item === "string")
        .map((item) => item.trim())
        .filter((item) => item.length > 0);
      continue;
    }

    if (valor === null) {
      saida[campo] = null;
      continue;
    }
    if (typeof valor !== "string") continue;
    const texto = valor.trim();
    saida[campo] = texto.length > 0 ? texto : null;
  }

  return saida;
}

function temDadosInstitucionais(institucionais) {
  if (!objetoSimples(institucionais)) return false;
  return Object.values(institucionais).some((valor) => {
    if (Array.isArray(valor)) return valor.length > 0;
    return typeof valor === "string" && valor.trim().length > 0;
  });
}

function normalizarTexto(valor) {
  return String(valor ?? "").toLowerCase().trim();
}

function normalizarSemAcentos(valor) {
  return normalizarTexto(valor).normalize("NFD").replace(/[\u0300-\u036f]/g, "");
}

function normalizarContratoConteudo(nome, dados) {
  const d = { ...dados };

  if (["avisos", "eventos", "campanhas", "ministerios", "devocionais"].includes(nome)) {
    d.publico = d.publico === true;
  }

  if (nome === "campanhas") {
    const meta =
      typeof d.meta_centavos === "number"
        ? d.meta_centavos
        : typeof d.meta_valor === "number"
          ? d.meta_valor
          : 0;
    d.meta_centavos = Math.round(meta);
  }

  if (nome === "eventos") {
    d.cancelado = d.cancelado === true;
    if (typeof d.horario !== "string" || d.horario.trim() === "") {
      const data = d.data?.toDate?.();
      if (data instanceof Date && !Number.isNaN(data.getTime())) {
        d.horario =
          `${String(data.getHours()).padStart(2, "0")}:` +
          String(data.getMinutes()).padStart(2, "0");
      }
    }
  }

  return d;
}

function valoresIguais(atual, esperado) {
  if (Object.is(atual, esperado)) return true;

  if (atual && typeof atual.isEqual === "function") {
    try {
      return atual.isEqual(esperado);
    } catch {
      return false;
    }
  }
  if (esperado && typeof esperado.isEqual === "function") {
    try {
      return esperado.isEqual(atual);
    } catch {
      return false;
    }
  }
  if (atual instanceof Date || esperado instanceof Date) {
    return (
      atual instanceof Date &&
      esperado instanceof Date &&
      atual.getTime() === esperado.getTime()
    );
  }
  if (Buffer.isBuffer(atual) || Buffer.isBuffer(esperado)) {
    return Buffer.isBuffer(atual) && Buffer.isBuffer(esperado) && atual.equals(esperado);
  }
  if (Array.isArray(atual) || Array.isArray(esperado)) {
    return (
      Array.isArray(atual) &&
      Array.isArray(esperado) &&
      atual.length === esperado.length &&
      atual.every((valor, indice) => valoresIguais(valor, esperado[indice]))
    );
  }
  if (objetoSimples(atual) || objetoSimples(esperado)) {
    if (!objetoSimples(atual) || !objetoSimples(esperado)) return false;
    const chavesAtuais = Object.keys(atual).sort();
    const chavesEsperadas = Object.keys(esperado).sort();
    return (
      chavesAtuais.length === chavesEsperadas.length &&
      chavesAtuais.every((chave, indice) => chave === chavesEsperadas[indice]) &&
      chavesAtuais.every((chave) => valoresIguais(atual[chave], esperado[chave]))
    );
  }
  return false;
}

function representarValorParaGuarda(valor, vistos = new WeakSet()) {
  if (valor === null) return ["null"];

  const tipo = typeof valor;
  if (tipo === "undefined") return ["undefined"];
  if (tipo === "string" || tipo === "boolean") return [tipo, valor];
  if (tipo === "number") {
    if (Number.isNaN(valor)) return ["number", "NaN"];
    if (valor === Infinity) return ["number", "Infinity"];
    if (valor === -Infinity) return ["number", "-Infinity"];
    if (Object.is(valor, -0)) return ["number", "-0"];
    return ["number", valor];
  }
  if (tipo === "bigint") return ["bigint", valor.toString()];
  if (tipo !== "object") return [tipo];

  if (valor instanceof Date) return ["date", valor.getTime()];
  if (Buffer.isBuffer(valor)) return ["bytes", valor.toString("base64")];
  if (valor instanceof Uint8Array) {
    return ["bytes", Buffer.from(valor).toString("base64")];
  }
  if (typeof valor.toMillis === "function") {
    try {
      return [
        "timestamp",
        valor.toMillis(),
        typeof valor.nanoseconds === "number" ? valor.nanoseconds : null,
      ];
    } catch {
      // Continua para a representação estrutural abaixo.
    }
  }
  if (
    typeof valor.latitude === "number" &&
    typeof valor.longitude === "number"
  ) {
    return ["geopoint", valor.latitude, valor.longitude];
  }
  if (typeof valor.path === "string" && typeof valor.isEqual === "function") {
    return ["reference", valor.path];
  }

  if (vistos.has(valor)) {
    throw new Error("Plano recusado: leitura contém referência circular.");
  }
  vistos.add(valor);

  let representacao;
  if (Array.isArray(valor)) {
    representacao = [
      "array",
      valor.map((item) => representarValorParaGuarda(item, vistos)),
    ];
  } else {
    representacao = [
      "object",
      Object.keys(valor)
        .sort()
        .map((chave) => [
          chave,
          representarValorParaGuarda(valor[chave], vistos),
        ]),
    ];
  }

  vistos.delete(valor);
  return representacao;
}

function assinaturaValor(valor) {
  return JSON.stringify(representarValorParaGuarda(valor));
}

function assinaturaDocumento(snapshot) {
  return assinaturaValor({
    existe: snapshot?.exists === true,
    dados: snapshot?.exists === true ? snapshot.data?.() ?? {} : null,
    atualizado_em: snapshot?.updateTime ?? null,
  });
}

function assinaturaColecao(snapshot) {
  const documentos = [...(snapshot?.docs ?? [])]
    .map((doc) => ({
      id: doc.id,
      dados: doc.data?.() ?? {},
      atualizado_em: doc.updateTime ?? null,
    }))
    .sort((a, b) => a.id.localeCompare(b.id));
  return assinaturaValor(documentos);
}

function validarLeiturasInalteradas(iniciais, transacionais) {
  if (!(iniciais instanceof Map) || !(transacionais instanceof Map)) {
    throw new Error("Drift concorrente: conjunto de leituras inválido.");
  }

  const chavesIniciais = [...iniciais.keys()].sort();
  const chavesTransacionais = [...transacionais.keys()].sort();
  if (
    chavesIniciais.length !== chavesTransacionais.length ||
    chavesIniciais.some(
      (chave, indice) => chave !== chavesTransacionais[indice]
    ) ||
    chavesIniciais.some(
      (chave) => iniciais.get(chave) !== transacionais.get(chave)
    )
  ) {
    throw new Error(
      "Drift concorrente detectado; nenhuma escrita foi aplicada. Rode o dry-run novamente."
    );
  }

  return { leiturasValidadas: chavesIniciais.length };
}

function validarPlanosEquivalentes(inicial, transacional) {
  const resumir = (plano) =>
    assinaturaValor(
      (plano?.operacoes ?? []).map((operacao) => ({
        tipo: operacao.tipo,
        caminho: operacao.caminho,
        caminhoSeguro: operacao.caminhoSeguro,
        dados: operacao.dados,
        precondicao: operacao.precondicao ?? null,
      }))
    );

  if (resumir(inicial) !== resumir(transacional)) {
    throw new Error(
      "Drift concorrente detectado; o plano transacional divergiu do preflight."
    );
  }
}

function timestampMigracaoValido(valor) {
  if (valor instanceof Date) return !Number.isNaN(valor.getTime());
  if (!valor || typeof valor.toDate !== "function") return false;

  try {
    const data = valor.toDate();
    return data instanceof Date && !Number.isNaN(data.getTime());
  } catch {
    return false;
  }
}

function compararDocumentoPlanejado(
  atual,
  esperado,
  { camposVolateis = ["migrado_em"] } = {}
) {
  if (!objetoSimples(atual) || !objetoSimples(esperado)) {
    return { compativel: false, camposDivergentes: ["documento"] };
  }

  const volateis = new Set(camposVolateis);
  const chavesAtuais = Object.keys(atual);
  const chavesEsperadas = Object.keys(esperado);
  const esperadas = new Set(chavesEsperadas);
  const divergentes = new Set();

  if (chavesAtuais.some((chave) => !esperadas.has(chave))) {
    // Não ecoa o nome de um campo inesperado: ele pode ter sido criado a
    // partir de um identificador ou outro valor sensível.
    divergentes.add("campos_extras");
  }

  for (const chave of chavesEsperadas) {
    if (!Object.prototype.hasOwnProperty.call(atual, chave)) {
      divergentes.add(chave);
      continue;
    }
    if (volateis.has(chave)) {
      if (
        chave === "migrado_em"
          ? !timestampMigracaoValido(atual[chave])
          : atual[chave] === null || atual[chave] === undefined
      ) {
        divergentes.add(chave);
      }
      continue;
    }
    if (!valoresIguais(atual[chave], esperado[chave])) {
      divergentes.add(chave);
    }
  }

  return {
    compativel: divergentes.size === 0,
    camposDivergentes: [...divergentes].sort(),
  };
}

function criarPlanoAtomico() {
  return { operacoes: [], conflitos: [] };
}

function registrarConflito(plano, caminhoSeguro, campos) {
  const nomes = [...new Set(campos.length > 0 ? campos : ["documento"])].sort();
  plano.conflitos.push(`${caminhoSeguro}[${nomes.join(",")}]`);
}

function planejarCriacaoDocumento(
  plano,
  {
    caminho,
    caminhoSeguro,
    dados,
    atual,
    camposVolateis = ["migrado_em"],
  }
) {
  if (atual === undefined) {
    plano.operacoes.push({
      tipo: "create",
      caminho,
      caminhoSeguro,
      dados,
    });
    return "criar";
  }

  const comparacao = compararDocumentoPlanejado(atual, dados, {
    camposVolateis,
  });
  if (!comparacao.compativel) {
    registrarConflito(plano, caminhoSeguro, comparacao.camposDivergentes);
    return "conflito";
  }
  return "inalterado";
}

function uidDestinoValido(valor) {
  return (
    typeof valor === "string" &&
    valor.length >= 1 &&
    valor.length <= 128 &&
    valor === valor.trim() &&
    !valor.includes("/")
  );
}

function tokenDocumentoValido(valor) {
  return (
    typeof valor === "string" &&
    valor.length >= 1 &&
    valor === valor.trim() &&
    !valor.includes("/") &&
    valor !== "." &&
    valor !== ".." &&
    !/^__.*__$/.test(valor) &&
    Buffer.byteLength(valor, "utf8") <= 1500
  );
}

function planejarIgrejaPrincipal(
  plano,
  { caminho, caminhoSeguro, dadosAtuais, precondicao }
) {
  const possuiCampo = Object.prototype.hasOwnProperty.call(
    dadosAtuais,
    "igreja_principal_id"
  );
  const atual = dadosAtuais.igreja_principal_id;

  if (!possuiCampo || atual === null) {
    plano.operacoes.push({
      tipo: "update",
      caminho,
      caminhoSeguro,
      dados: { igreja_principal_id: OLINDA },
      ...(precondicao ? { precondicao } : {}),
    });
    return "atualizar";
  }
  // Todo usuário legado recebe vínculo somente em Olinda. Preservar outro ID
  // deixaria a igreja principal apontando para uma unidade sem vínculo; isso
  // precisa ser resolvido explicitamente antes de qualquer escrita.
  if (atual === OLINDA) return "inalterado";

  registrarConflito(plano, caminhoSeguro, ["igreja_principal_id"]);
  return "conflito";
}

function validarPlanoAtomico(plano, limite = LIMITE_OPERACOES_TRANSACAO) {
  if (!plano || !Array.isArray(plano.operacoes) || !Array.isArray(plano.conflitos)) {
    throw new Error("Plano atômico inválido.");
  }
  if (plano.conflitos.length > 0) {
    throw new Error(
      "Preflight bloqueou a migração. Revise apenas estes caminhos/campos: " +
        [...new Set(plano.conflitos)].sort().join("; ")
    );
  }
  if (plano.operacoes.length > limite) {
    throw new Error(
      `Plano recusado: ${plano.operacoes.length} operações excedem o limite seguro de ${limite}.`
    );
  }

  const caminhos = new Set();
  for (const operacao of plano.operacoes) {
    if (!operacao || !["create", "update"].includes(operacao.tipo)) {
      throw new Error("Plano recusado: somente create e update são permitidos.");
    }
    if (caminhos.has(operacao.caminho)) {
      throw new Error(
        `Plano recusado: destino duplicado em ${operacao.caminhoSeguro ?? "{documento}"}.`
      );
    }
    caminhos.add(operacao.caminho);
  }

  return { totalOperacoes: plano.operacoes.length, limite };
}

async function carregarRuntime(projeto) {
  let admin;
  try {
    // Carregado somente no CLI: importar funções puras não exige Admin SDK.
    admin = require("firebase-admin");
  } catch {
    throw new Error("Dependência ausente. Rode: npm --prefix scripts ci");
  }

  admin.initializeApp({ projectId: projeto });
  return { admin, db: admin.firestore() };
}

function criarContexto({
  admin,
  db,
  dryRun,
  transacao = null,
  silencioso = false,
}) {
  const cacheColecoes = new Map();
  const cacheDocumentos = new Map();
  const leituras = new Map();
  const relatorio = [];

  async function obterColecao(nome) {
    if (!cacheColecoes.has(nome)) {
      const consulta = db.collection(nome);
      cacheColecoes.set(
        nome,
        transacao ? transacao.get(consulta) : consulta.get()
      );
    }
    const snapshot = await cacheColecoes.get(nome);
    leituras.set(`colecao:${nome}`, assinaturaColecao(snapshot));
    return snapshot;
  }

  async function obterDocumento(caminho) {
    if (!cacheDocumentos.has(caminho)) {
      const referencia = db.doc(caminho);
      cacheDocumentos.set(
        caminho,
        transacao ? transacao.get(referencia) : referencia.get()
      );
    }
    const snapshot = await cacheDocumentos.get(caminho);
    leituras.set(`documento:${caminho}`, assinaturaDocumento(snapshot));
    return snapshot;
  }

  function registrar(item, lidos, migrados, ignorados, extra = "") {
    relatorio.push({ item, lidos, migrados, ignorados, extra });
    if (!silencioso) {
      console.log(
        `  ${item.padEnd(24)} lidos=${String(lidos).padStart(5)} ` +
          `migrados=${String(migrados).padStart(5)} ` +
          `inalterados=${String(ignorados).padStart(5)} ${extra}`
      );
    }
  }

  return {
    admin,
    db,
    dryRun,
    leituras,
    obterColecao,
    obterDocumento,
    registrar,
    relatorio,
    silencioso,
    transacao,
  };
}

async function auditarEstrutura(ctx) {
  console.log("=== AUDITORIA SOMENTE DE ESTRUTURA ===");
  for (const nome of COLECOES_AUDITADAS) {
    const snap = await ctx.obterColecao(nome);
    const campos = inventariarCampos(snap.docs.map((doc) => doc.data() ?? {}));
    console.log(
      `  ${nome.padEnd(24)} documentos=${String(snap.size).padStart(5)} ` +
        `campos=${campos.length > 0 ? campos.join(",") : "(nenhum)"}`
    );
  }
  console.log("Nenhum valor, e-mail, token ou UID foi impresso.\n");
}

function erroCampo(erro) {
  const mensagem = String(erro?.message ?? erro);
  const separador = mensagem.lastIndexOf(":");
  return separador >= 0 ? mensagem.slice(separador + 1) : "documento";
}

function construirUnidadesEsperadas(raizesAtuais, legadoDados) {
  const institucionaisOlinda = extrairDadosInstitucionaisLegados(
    legadoDados
  );
  const configuradaOlinda = temDadosInstitucionais(institucionaisOlinda);

  return UNIDADES_BASE.map((unidade) => {
    const dados = {
      ...unidade.dados,
      migrado_de:
        unidade.id === OLINDA && configuradaOlinda
          ? "igreja/principal"
          : "bootstrap_multi_igreja",
    };
    if (unidade.id === OLINDA) {
      dados.configurada = configuradaOlinda;
      if (configuradaOlinda) {
        dados.dados_institucionais = institucionaisOlinda;
      }
    }
    return { id: unidade.id, dados };
  });
}

function caminhoSeguroUnidade(colecao, id) {
  return id === OLINDA || id === PETROLINA
    ? `${colecao}/${id}`
    : `${colecao}/{igrejaId}`;
}

function dadosInstitucionaisDaRaiz(dados) {
  if (!objetoSimples(dados?.dados_institucionais)) return {};
  return extrairDadosInstitucionaisLegados(dados.dados_institucionais);
}

function planejarUnidades({
  raizesAtuais,
  catalogosAtuais,
  legadoDados = null,
}) {
  const unidadesEsperadas = construirUnidadesEsperadas(
    raizesAtuais,
    legadoDados
  );
  const idsEsperados = new Set(unidadesEsperadas.map((unidade) => unidade.id));
  const raizesPlanejadas = new Map();
  const criarRaizes = [];
  const conflitos = [];

  for (const id of raizesAtuais.keys()) {
    if (!idsEsperados.has(id)) {
      conflitos.push(
        `${caminhoSeguroUnidade("igrejas", id)}[unidade_desconhecida]`
      );
    }
  }

  for (const unidade of unidadesEsperadas) {
    const atual = raizesAtuais.get(unidade.id);
    const validacao = validarUnidadeConhecida(atual, unidade.dados);

    if (validacao.estado === "ausente") {
      const dados = { ...unidade.dados };
      criarRaizes.push({ id: unidade.id, dados });
      raizesPlanejadas.set(unidade.id, dados);
      continue;
    }

    if (validacao.estado !== "compativel") {
      conflitos.push(
        `${caminhoSeguroUnidade("igrejas", unidade.id)}[` +
          `${validacao.camposDivergentes.join(",")}]`
      );
      continue;
    }

    if (
      unidade.id === OLINDA &&
      unidade.dados.configurada === true &&
      !valoresIguais(
        dadosInstitucionaisDaRaiz(atual),
        unidade.dados.dados_institucionais
      )
    ) {
      conflitos.push("igrejas/olinda[dados_institucionais]");
      continue;
    }

    raizesPlanejadas.set(unidade.id, atual);
  }

  const catalogosEsperados = new Map();
  for (const [id, dados] of raizesPlanejadas) {
    try {
      catalogosEsperados.set(id, projetarCatalogoPublico(dados));
    } catch (erro) {
      conflitos.push(
        `${caminhoSeguroUnidade("igrejas", id)}[${erroCampo(erro)}]`
      );
    }
  }

  const criarCatalogos = [];
  for (const [id, esperado] of catalogosEsperados) {
    const atual = catalogosAtuais.get(id);
    if (atual === undefined) {
      criarCatalogos.push({ id, dados: esperado });
      continue;
    }
    const comparacao = compararCatalogo(atual, esperado);
    if (!comparacao.compativel) {
      conflitos.push(
        `${caminhoSeguroUnidade("catalogo_igrejas", id)}[` +
          `${comparacao.camposDivergentes.join(",")}]`
      );
    }
  }

  for (const id of catalogosAtuais.keys()) {
    if (!catalogosEsperados.has(id)) {
      conflitos.push(
        `${caminhoSeguroUnidade("catalogo_igrejas", id)}[` +
          "sem_raiz_operacional]"
      );
    }
  }

  return { criarRaizes, criarCatalogos, conflitos };
}

async function prepararPlanoUnidades(ctx, planoAtomico) {
  const [igrejasSnap, catalogoSnap, legadoSnap] = await Promise.all([
    ctx.obterColecao("igrejas"),
    ctx.obterColecao("catalogo_igrejas"),
    ctx.obterDocumento("igreja/principal"),
  ]);

  const raizesAtuais = new Map(
    igrejasSnap.docs.map((doc) => [doc.id, doc.data() ?? {}])
  );
  const catalogosAtuais = new Map(
    catalogoSnap.docs.map((doc) => [doc.id, doc.data() ?? {}])
  );
  const plano = planejarUnidades({
    raizesAtuais,
    catalogosAtuais,
    legadoDados: legadoSnap.exists ? legadoSnap.data() ?? {} : null,
  });

  planoAtomico.conflitos.push(...plano.conflitos);
  for (const unidade of plano.criarRaizes) {
    planoAtomico.operacoes.push({
      tipo: "create",
      caminho: `igrejas/${unidade.id}`,
      caminhoSeguro: `igrejas/${unidade.id}`,
      dados: {
        ...unidade.dados,
        criado_em: ctx.admin.firestore.FieldValue.serverTimestamp(),
      },
    });
  }
  for (const unidade of plano.criarCatalogos) {
    planoAtomico.operacoes.push({
      tipo: "create",
      caminho: `catalogo_igrejas/${unidade.id}`,
      caminhoSeguro: `catalogo_igrejas/${unidade.id}`,
      dados: unidade.dados,
    });
  }

  if (!ctx.silencioso) {
    console.log("=== PREFLIGHT DE UNIDADES ===");
    console.log(
      `  raízes: existentes=${raizesAtuais.size} criar=${plano.criarRaizes.length}`
    );
    console.log(
      `  catálogo: existentes=${catalogosAtuais.size} criar=${plano.criarCatalogos.length}`
    );
    console.log(`  conflitos=${plano.conflitos.length}\n`);
  }

  ctx.registrar(
    "igrejas",
    UNIDADES_BASE.length,
    plano.criarRaizes.length,
    UNIDADES_BASE.length - plano.criarRaizes.length
  );
  ctx.registrar(
    "catalogo_igrejas",
    catalogosAtuais.size + plano.criarCatalogos.length,
    plano.criarCatalogos.length,
    catalogosAtuais.size
  );
}

async function planejarColecao(ctx, plano, nome) {
  const origem = await ctx.obterColecao(nome);
  let criar = 0;
  let inalterados = 0;
  let conflitos = 0;

  for (const doc of origem.docs) {
    const caminho = `igrejas/${OLINDA}/${nome}/${doc.id}`;
    const snap = await ctx.obterDocumento(caminho);
    const resultado = planejarCriacaoDocumento(plano, {
      caminho,
      caminhoSeguro: `igrejas/${OLINDA}/${nome}/{id}`,
      dados: {
        ...normalizarContratoConteudo(nome, doc.data() ?? {}),
        migrado_de: `${nome}/${doc.id}`,
        migrado_em: ctx.admin.firestore.FieldValue.serverTimestamp(),
      },
      atual: snap.exists ? snap.data() ?? {} : undefined,
    });
    if (resultado === "criar") criar++;
    if (resultado === "inalterado") inalterados++;
    if (resultado === "conflito") conflitos++;
  }

  ctx.registrar(
    nome,
    origem.size,
    criar,
    inalterados,
    conflitos > 0 ? `conflitos=${conflitos}` : ""
  );
}

async function planejarVinculos(ctx, plano) {
  const usuarios = await ctx.obterColecao("usuarios");
  let criados = 0;
  let existentes = 0;
  let principalDefinida = 0;
  let principalExistente = 0;
  let conflitos = 0;

  const PERFIS = ["pastor", "diacono", "evangelista", "lider", "membro"];
  const STATUS = ["pendente", "aprovado", "inativo"];

  for (const doc of usuarios.docs) {
    const d = doc.data() ?? {};
    const perfilBruto = normalizarSemAcentos(d.perfil);
    const perfil = PERFIS.includes(perfilBruto) ? perfilBruto : "membro";
    const statusBruto = normalizarSemAcentos(d.status);
    const status = STATUS.includes(statusBruto) ? statusBruto : "pendente";

    const caminhoVinculo = `igrejas/${OLINDA}/membros/${doc.id}`;
    const vinculoSnap = await ctx.obterDocumento(caminhoVinculo);
    const resultadoVinculo = planejarCriacaoDocumento(plano, {
      caminho: caminhoVinculo,
      caminhoSeguro: `igrejas/${OLINDA}/membros/{uid}`,
      dados: {
        perfil,
        status,
        funcoes_admin: perfil === "pastor" ? ["pastor"] : [],
        ministerio_ids: d.ministerio_id ? [d.ministerio_id] : [],
        nome: d.nome ?? null,
        email: d.email ?? null,
        aprovado_por: d.aprovado_por ?? null,
        aprovado_em: d.aprovado_em ?? null,
        migrado_de: `usuarios/${doc.id}`,
        migrado_em: ctx.admin.firestore.FieldValue.serverTimestamp(),
      },
      atual: vinculoSnap.exists ? vinculoSnap.data() ?? {} : undefined,
    });
    if (resultadoVinculo === "criar") criados++;
    if (resultadoVinculo === "inalterado") existentes++;
    if (resultadoVinculo === "conflito") conflitos++;

    const resultadoPrincipal = planejarIgrejaPrincipal(plano, {
      caminho: `usuarios/${doc.id}`,
      caminhoSeguro: "usuarios/{uid}",
      dadosAtuais: d,
      precondicao: doc.updateTime
        ? { lastUpdateTime: doc.updateTime }
        : undefined,
    });
    if (resultadoPrincipal === "atualizar") principalDefinida++;
    if (resultadoPrincipal === "inalterado") principalExistente++;
    if (resultadoPrincipal === "conflito") conflitos++;
  }

  ctx.registrar(
    "membros (vinculos)",
    usuarios.size,
    criados,
    existentes,
    conflitos > 0 ? `conflitos=${conflitos}` : ""
  );
  ctx.registrar(
    "igreja_principal_id",
    usuarios.size,
    principalDefinida,
    principalExistente,
    conflitos > 0 ? `conflitos=${conflitos}` : ""
  );
}

async function planejarTransacoes(ctx, plano) {
  const origem = await ctx.obterColecao("transacoes");
  let criar = 0;
  let existentes = 0;
  let conflitos = 0;
  let suspeitas = 0;

  const mapaStatus = {
    aprovado: "aprovado",
    approved: "aprovado",
    pendente: "pendente",
    pending: "pendente",
    recusado: "rejeitado",
    rejeitado: "rejeitado",
    rejected: "rejeitado",
    cancelado: "cancelado",
    cancelled: "cancelado",
    estornado: "estornado",
    refunded: "estornado",
  };
  const mapaMetodo = {
    pix: "pix",
    checkout: "checkout_pro",
    checkout_pro: "checkout_pro",
  };

  for (const doc of origem.docs) {
    const d = doc.data() ?? {};

    let valorCentavos;
    if (typeof d.valor_centavos === "number") {
      valorCentavos = Math.round(d.valor_centavos);
    } else if (typeof d.valor === "number") {
      valorCentavos = Math.round(d.valor * 100);
    } else {
      valorCentavos = 0;
      suspeitas++;
    }

    const registro = {
      usuario_id: d.usuario_id ?? d.perfil_id ?? null,
      igreja_id: OLINDA,
      valor_centavos: valorCentavos,
      tipo: d.tipo ?? "oferta",
      metodo: mapaMetodo[normalizarTexto(d.metodo ?? d.meio_pagamento)] ?? "pix",
      status: mapaStatus[normalizarTexto(d.status)] ?? "pendente",
      campanha_id: d.campanha_id ?? null,
      mp_payment_id: d.mp_payment_id ?? null,
      mp_status_detail: d.mp_status_detail ?? null,
      criado_em: d.criado_em ?? null,
      atualizado_em: d.atualizado_em ?? null,
      aprovado_em: d.aprovado_em ?? null,
      migrado_de: `transacoes/${doc.id}`,
      migrado_em: ctx.admin.firestore.FieldValue.serverTimestamp(),
      revisar_valor: valorCentavos === 0 ? true : null,
    };

    const caminho = `igrejas/${OLINDA}/transacoes/${doc.id}`;
    const snap = await ctx.obterDocumento(caminho);
    const resultado = planejarCriacaoDocumento(plano, {
      caminho,
      caminhoSeguro: `igrejas/${OLINDA}/transacoes/{id}`,
      dados: registro,
      atual: snap.exists ? snap.data() ?? {} : undefined,
    });
    if (resultado === "criar") criar++;
    if (resultado === "inalterado") existentes++;
    if (resultado === "conflito") conflitos++;
  }

  ctx.registrar(
    "transacoes",
    origem.size,
    criar,
    existentes,
    [
      suspeitas > 0 ? `ATENCAO:${suspeitas}_sem_valor` : "",
      conflitos > 0 ? `conflitos=${conflitos}` : "",
    ]
      .filter(Boolean)
      .join(" ")
  );
}

async function planejarNotificacoes(ctx, plano) {
  const origem = await ctx.obterColecao("notificacoes");
  let criar = 0;
  let inalteradas = 0;
  let conflitos = 0;

  for (const doc of origem.docs) {
    const d = doc.data() ?? {};
    const uid = d.destinatario_id;
    if (!uidDestinoValido(uid)) {
      registrarConflito(plano, "notificacoes/{id}", ["destinatario_id"]);
      conflitos++;
      continue;
    }
    const caminho = `usuarios/${uid}/notificacoes/${doc.id}`;
    const snap = await ctx.obterDocumento(caminho);
    const resultado = planejarCriacaoDocumento(plano, {
      caminho,
      caminhoSeguro: "usuarios/{uid}/notificacoes/{id}",
      dados: {
        ...d,
        migrado_de: `notificacoes/${doc.id}`,
        migrado_em: ctx.admin.firestore.FieldValue.serverTimestamp(),
      },
      atual: snap.exists ? snap.data() ?? {} : undefined,
    });
    if (resultado === "criar") criar++;
    if (resultado === "inalterado") inalteradas++;
    if (resultado === "conflito") conflitos++;
  }

  ctx.registrar(
    "notificacoes",
    origem.size,
    criar,
    inalteradas,
    conflitos > 0 ? `conflitos=${conflitos}` : ""
  );
}

async function planejarTokensDispositivo(ctx, plano) {
  const origem = await ctx.obterColecao("tokens_dispositivo");
  let criar = 0;
  let inalterados = 0;
  let conflitos = 0;
  const grupos = new Map();
  const uidsPorToken = new Map();

  for (const doc of [...origem.docs].sort((a, b) => a.id.localeCompare(b.id))) {
    const d = doc.data() ?? {};
    const uid = d.perfil_id;
    const token = d.token;
    const camposInvalidos = [];
    if (!uidDestinoValido(uid)) camposInvalidos.push("perfil_id");
    if (!tokenDocumentoValido(token)) camposInvalidos.push("token");
    if (typeof d.ativo !== "boolean") camposInvalidos.push("ativo");
    if (typeof d.plataforma !== "string" || d.plataforma.trim() === "") {
      camposInvalidos.push("plataforma");
    }
    if (camposInvalidos.length > 0) {
      registrarConflito(plano, "tokens_dispositivo/{id}", camposInvalidos);
      conflitos++;
      continue;
    }

    const chave = JSON.stringify([uid, token]);
    const grupo = grupos.get(chave) ?? { uid, token, documentos: [] };
    grupo.documentos.push({ id: doc.id, dados: d });
    grupos.set(chave, grupo);

    const uids = uidsPorToken.get(token) ?? new Set();
    uids.add(uid);
    uidsPorToken.set(token, uids);
  }

  // Um token legado associado a mais de um perfil não tem dono confiável.
  // Em vez de escolher um UID ou bloquear toda a migração, preservamos uma
  // cópia canônica privada em cada perfil e colocamos todas em quarentena. Assim
  // nenhuma das associações ambíguas pode receber push até uma nova gravação
  // autenticada pelo app substituir explicitamente esse estado.
  const tokensCompartilhados = new Set(
    [...uidsPorToken.entries()]
      .filter(([, uids]) => uids.size > 1)
      .map(([token]) => token)
  );

  for (const grupo of grupos.values()) {
    const plataformas = new Set(
      grupo.documentos.map((item) => item.dados.plataforma.trim())
    );
    if (plataformas.size !== 1) {
      registrarConflito(plano, "tokens_dispositivo/{id}", ["plataforma"]);
      conflitos++;
      continue;
    }

    const base = grupo.documentos[0];
    const caminho =
      `usuarios/${grupo.uid}/tokens_dispositivo/${grupo.token}`;
    const snap = await ctx.obterDocumento(caminho);
    const resultado = planejarCriacaoDocumento(plano, {
      caminho,
      caminhoSeguro: "usuarios/{uid}/tokens_dispositivo/{id}",
      dados: {
        ...base.dados,
        perfil_id: grupo.uid,
        token: grupo.token,
        plataforma: [...plataformas][0],
        // Token compartilhado entre perfis é sempre inativo em todos os
        // destinos. Para um único perfil, qualquer cópia com logout também
        // impede reativação silenciosa durante a consolidação.
        ativo: tokensCompartilhados.has(grupo.token)
          ? false
          : grupo.documentos.every((item) => item.dados.ativo === true),
        migrado_de: grupo.documentos.map(
          (item) => `tokens_dispositivo/${item.id}`
        ),
        migrado_em: ctx.admin.firestore.FieldValue.serverTimestamp(),
      },
      atual: snap.exists ? snap.data() ?? {} : undefined,
    });
    if (resultado === "criar") criar++;
    if (resultado === "inalterado") inalterados++;
    if (resultado === "conflito") conflitos++;
  }

  ctx.registrar(
    "tokens_dispositivo",
    origem.size,
    criar,
    inalterados,
    conflitos > 0 ? `conflitos=${conflitos}` : ""
  );
}

async function planejarConfiguracoes(ctx, plano) {
  const origem = await ctx.obterColecao("configuracoes");
  if (origem.size > 0) {
    registrarConflito(plano, "configuracoes/{id}", ["contrato_indefinido"]);
  }
  ctx.registrar(
    "configuracoes",
    origem.size,
    0,
    0,
    origem.size > 0 ? "conflitos=1" : ""
  );
}

async function prepararPlanoCompleto(ctx, { validar = true } = {}) {
  const plano = criarPlanoAtomico();

  await prepararPlanoUnidades(ctx, plano);
  await planejarVinculos(ctx, plano);
  for (const nome of COLECOES) {
    await planejarColecao(ctx, plano, nome);
  }
  await planejarTransacoes(ctx, plano);
  await planejarNotificacoes(ctx, plano);
  await planejarTokensDispositivo(ctx, plano);
  await planejarConfiguracoes(ctx, plano);

  if (validar) validarPlanoAtomico(plano);
  return plano;
}

function aplicarOperacoesNaTransacao(transacao, db, plano) {
  for (const operacao of plano.operacoes) {
    const referencia = db.doc(operacao.caminho);
    if (operacao.tipo === "create") {
      transacao.create(referencia, operacao.dados);
    } else if (operacao.precondicao) {
      transacao.update(referencia, operacao.dados, operacao.precondicao);
    } else {
      transacao.update(referencia, operacao.dados);
    }
  }
}

async function verificarPosAplicacao({ admin, db }) {
  // Mantém o modo read-write padrão, embora não enfileire writes: assim as
  // leituras usam locks pessimistas e não podem vir de um snapshot read-only
  // potencialmente defasado.
  return db.runTransaction(async (transacao) => {
    const ctx = criarContexto({
      admin,
      db,
      dryRun: true,
      transacao,
      silencioso: true,
    });
    const plano = await prepararPlanoCompleto(ctx, { validar: false });

    if (plano.conflitos.length > 0 || plano.operacoes.length > 0) {
      throw new Error(
        "Pós-verificação falhou: um novo planejamento não produziu zero operações."
      );
    }
    validarPlanoAtomico(plano);
    return { posVerificacao: true, operacoesPendentes: 0 };
  });
}

async function aplicarPlanoAtomico({
  admin,
  db,
  plano,
  leituras,
  projeto,
  dryRun,
} = {}) {
  validarOpcoesExecucao({ projeto, dryRun });
  if (dryRun !== false) {
    throw new Error("Aplicação recusada: dryRun deve ser false explicitamente.");
  }
  if (!admin || !db) {
    throw new Error("Runtime Admin/Firestore não informado.");
  }
  validarProjetoRuntime({ admin, db, projeto });
  validarPlanoAtomico(plano);
  if (!(leituras instanceof Map)) {
    throw new Error("Aplicação recusada: guardas do preflight não informadas.");
  }

  const resultado = await db.runTransaction(async (transacao) => {
    const ctx = criarContexto({
      admin,
      db,
      dryRun: false,
      transacao,
      silencioso: true,
    });
    const planoTransacional = await prepararPlanoCompleto(ctx, {
      validar: false,
    });

    // A comparação ocorre antes de qualquer chamada create/update. Se uma
    // consulta ganhou/perdeu documentos (phantom) ou qualquer documento lido
    // mudou, a tentativa é abortada sem escritas. Em caso de retry automático,
    // o baseline continua sendo o preflight original e o drift também aborta.
    const guarda = validarLeiturasInalteradas(leituras, ctx.leituras);
    validarPlanoAtomico(planoTransacional);
    validarPlanosEquivalentes(plano, planoTransacional);
    aplicarOperacoesNaTransacao(transacao, db, planoTransacional);

    return {
      operacoesAplicadas: planoTransacional.operacoes.length,
      leiturasValidadas: guarda.leiturasValidadas,
    };
  });

  const pos = await verificarPosAplicacao({ admin, db });
  return { ...resultado, ...pos };
}

async function executarMigracao(opcoes = {}) {
  const { admin, db, dryRun, projeto } = opcoes;
  validarOpcoesExecucao({ projeto, dryRun });
  if (!admin || !db) {
    throw new Error("Runtime Admin/Firestore não informado.");
  }
  validarProjetoRuntime({ admin, db, projeto });
  console.log("\n=== MIGRAÇÃO MULTI-IGREJA ===");
  console.log(`Projeto: ${projeto}`);
  console.log(`Modo:    ${dryRun ? "DRY-RUN (nada será gravado)" : "APLICAR"}`);
  console.log("Nenhuma coleção antiga é apagada.\n");

  const ctxAuditoria = criarContexto({ admin, db, dryRun });
  await auditarEstrutura(ctxAuditoria);

  // O preflight aplicado é capturado separadamente da auditoria para que a
  // transação releia exatamente o mesmo conjunto de origens e destinos.
  const ctx = criarContexto({ admin, db, dryRun });
  const plano = await prepararPlanoCompleto(ctx);

  // O plano completo e o limite são validados antes da transação de escrita.
  if (!dryRun) {
    console.log("ATENÇÃO: gravação real em 5s. Ctrl+C para cancelar.\n");
    await new Promise((resolve) => setTimeout(resolve, 5000));
    await aplicarPlanoAtomico({
      admin,
      db,
      plano,
      leituras: ctx.leituras,
      projeto,
      dryRun,
    });
  }

  const totalMigrado = plano.operacoes.length;
  console.log("\n=== RESUMO ===");
  console.log(
    `Documentos ${dryRun ? "que SERIAM migrados" : "migrados"}: ${totalMigrado}`
  );
  if (dryRun) {
    console.log("Nada foi gravado. --apply continua proibido sem checkpoint explícito.\n");
  } else {
    console.log("Migração concluída; as coleções antigas permanecem intactas.\n");
  }
}

async function main() {
  const opcoes = analisarArgumentos();
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error("FIRESTORE_EMULATOR_HOST está definida; produção recusada.");
  }
  const runtime = await carregarRuntime(opcoes.projeto);
  await executarMigracao({ ...runtime, ...opcoes });
}

function mensagemErroSegura(erro) {
  const mensagem = String(erro?.message ?? erro);
  const prefixosPermitidos = [
    "Informe --project=",
    "Projeto recusado",
    "Use somente um modo",
    "dryRun deve",
    "Runtime recusado",
    "Runtime Admin/Firestore",
    "Runtime Firestore",
    "Aplicação recusada",
    "Drift concorrente",
    "Pós-verificação falhou",
    "Dependência ausente",
    "FIRESTORE_EMULATOR_HOST",
    "Preflight bloqueou",
    "Plano atômico inválido",
    "Plano recusado",
  ];

  return prefixosPermitidos.some((prefixo) => mensagem.startsWith(prefixo))
    ? mensagem
    : "Falha na transação atômica; detalhes de documentos foram ocultados.";
}

if (require.main === module) {
  main().catch((erro) => {
    console.error(`\n[ERRO] Migração interrompida: ${mensagemErroSegura(erro)}`);
    console.error("Nenhuma exclusão é executada por este script.");
    process.exitCode = 1;
  });
}

module.exports = {
  LIMITE_OPERACOES_BATCH,
  LIMITE_OPERACOES_TRANSACAO,
  analisarArgumentos,
  aplicarPlanoAtomico,
  assinaturaColecao,
  assinaturaDocumento,
  assinaturaValor,
  compararDocumentoPlanejado,
  criarContexto,
  criarPlanoAtomico,
  executarMigracao,
  extrairDadosInstitucionaisLegados,
  mensagemErroSegura,
  normalizarContratoConteudo,
  planejarCriacaoDocumento,
  planejarConfiguracoes,
  planejarIgrejaPrincipal,
  planejarTokensDispositivo,
  planejarUnidades,
  prepararPlanoCompleto,
  temDadosInstitucionais,
  validarLeiturasInalteradas,
  validarOpcoesExecucao,
  validarProjetoRuntime,
  validarPlanoAtomico,
};
