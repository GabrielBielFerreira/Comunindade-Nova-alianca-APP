"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  CAMPOS_CATALOGO_PUBLICO,
  compararCatalogo,
  inventariarCampos,
  projetarCatalogoPublico,
  validarUnidadeConhecida,
} = require("../catalogo_igrejas");
const {
  LIMITE_OPERACOES_BATCH,
  analisarArgumentos,
  aplicarPlanoAtomico,
  criarContexto,
  criarPlanoAtomico,
  executarMigracao,
  extrairDadosInstitucionaisLegados,
  mensagemErroSegura,
  planejarCriacaoDocumento,
  planejarIgrejaPrincipal,
  planejarUnidades,
  prepararPlanoCompleto,
  validarLeiturasInalteradas,
  validarProjetoRuntime,
  validarPlanoAtomico,
} = require("../migrar_producao");
const {
  documentosDaResposta,
  exigirNegado,
  validarDocumentoRest,
} = require("../verificar_catalogo_publico");

function clonar(valor) {
  if (valor === null || typeof valor !== "object") return valor;
  if (valor instanceof Date) return new Date(valor.getTime());
  if (Array.isArray(valor)) return valor.map(clonar);
  return Object.fromEntries(
    Object.entries(valor).map(([chave, item]) => [chave, clonar(item)])
  );
}

function criarFirestoreTransacionalFake(
  documentosIniciais = {},
  { aposCommit = null } = {}
) {
  const documentos = new Map(
    Object.entries(documentosIniciais).map(([caminho, dados]) => [
      caminho,
      clonar(dados),
    ])
  );
  const versoes = new Map();
  let proximaVersao = 1;
  for (const caminho of documentos.keys()) {
    versoes.set(caminho, new Date(proximaVersao++ * 1000));
  }

  const metricas = {
    transacoesEscrita: 0,
    transacoesLeitura: 0,
    escritasEnfileiradas: 0,
    commitsEscrita: 0,
  };

  const materializar = (valor) => {
    if (valor === null || typeof valor !== "object") return valor;
    if (valor instanceof Date) return new Date(valor.getTime());
    if (valor.sentinel === "serverTimestamp") {
      return new Date(proximaVersao++ * 1000);
    }
    if (Array.isArray(valor)) return valor.map(materializar);
    return Object.fromEntries(
      Object.entries(valor).map(([chave, item]) => [
        chave,
        materializar(item),
      ])
    );
  };

  const snapshotDocumento = (caminho, fonte, versoesFonte) => {
    const existe = fonte.has(caminho);
    return {
      id: caminho.split("/").at(-1),
      exists: existe,
      data: () => (existe ? clonar(fonte.get(caminho)) : undefined),
      updateTime: existe ? clonar(versoesFonte.get(caminho)) : undefined,
    };
  };

  const snapshotColecao = (nome, fonte, versoesFonte) => {
    const prefixo = `${nome}/`;
    const docs = [...fonte.keys()]
      .filter(
        (caminho) =>
          caminho.startsWith(prefixo) && caminho.split("/").length === 2
      )
      .sort()
      .map((caminho) =>
        snapshotDocumento(caminho, fonte, versoesFonte)
      );
    return { docs, size: docs.length };
  };

  const db = {
    projectId: "nova-alianca-app",
    collection(nome) {
      return {
        tipo: "consulta",
        nome,
        get: async () => snapshotColecao(nome, documentos, versoes),
      };
    },
    doc(caminho) {
      return {
        tipo: "documento",
        path: caminho,
        get: async () => snapshotDocumento(caminho, documentos, versoes),
      };
    },
    async runTransaction(callback, opcoes = {}) {
      const somenteLeitura = opcoes.readOnly === true;
      if (somenteLeitura) metricas.transacoesLeitura++;
      else metricas.transacoesEscrita++;

      const fonte = new Map(
        [...documentos.entries()].map(([caminho, dados]) => [
          caminho,
          clonar(dados),
        ])
      );
      const versoesFonte = new Map(
        [...versoes.entries()].map(([caminho, versao]) => [
          caminho,
          clonar(versao),
        ])
      );
      const operacoes = [];
      const transacao = {
        async get(referencia) {
          return referencia.tipo === "consulta"
            ? snapshotColecao(referencia.nome, fonte, versoesFonte)
            : snapshotDocumento(referencia.path, fonte, versoesFonte);
        },
        create(referencia, dados) {
          metricas.escritasEnfileiradas++;
          operacoes.push({ tipo: "create", caminho: referencia.path, dados });
          return this;
        },
        update(referencia, dados, precondicao) {
          metricas.escritasEnfileiradas++;
          operacoes.push({
            tipo: "update",
            caminho: referencia.path,
            dados,
            precondicao,
          });
          return this;
        },
      };

      const resultado = await callback(transacao);
      if (!somenteLeitura) {
        for (const operacao of operacoes) {
          if (operacao.tipo === "create" && documentos.has(operacao.caminho)) {
            throw new Error("ALREADY_EXISTS");
          }
          if (operacao.tipo === "update" && !documentos.has(operacao.caminho)) {
            throw new Error("NOT_FOUND");
          }
        }
        for (const operacao of operacoes) {
          const atuais = documentos.get(operacao.caminho) ?? {};
          documentos.set(
            operacao.caminho,
            operacao.tipo === "update"
              ? { ...atuais, ...materializar(operacao.dados) }
              : materializar(operacao.dados)
          );
          versoes.set(
            operacao.caminho,
            new Date(proximaVersao++ * 1000)
          );
        }
        if (operacoes.length > 0) {
          metricas.commitsEscrita++;
          if (aposCommit) aposCommit(api);
        }
      }
      return resultado;
    },
  };

  const admin = {
    firestore: {
      FieldValue: {
        serverTimestamp: () => ({ sentinel: "serverTimestamp" }),
      },
    },
  };

  const api = {
    admin,
    db,
    metricas,
    obter(caminho) {
      return documentos.has(caminho) ? clonar(documentos.get(caminho)) : undefined;
    },
    gravar(caminho, dados) {
      documentos.set(caminho, clonar(dados));
      versoes.set(caminho, new Date(proximaVersao++ * 1000));
    },
  };
  return api;
}

test("projeção pública contém somente os onze campos permitidos", () => {
  const segredo = "VALOR-CANARIO-NAO-PODE-VAZAR";
  const catalogo = projetarCatalogoPublico({
    nome: "  Nova Aliança Olinda  ",
    slug: "olinda",
    ativa: true,
    configurada: true,
    criado_por: segredo,
    atualizado_por: segredo,
    criado_em: segredo,
    migrado_de: segredo,
    mercado_pago_status: segredo,
    dados_institucionais: {
      endereco: "  Avenida Teste, 10  ",
      cidade_estado: "  Olinda — PE  ",
      endereco_secundario: "  Ao lado da praça  ",
      slogan: "  Família para pertencer  ",
      cultos_recorrentes: ["  Domingo 18h  ", "", 42, "Domingo 18h"],
      instagram: "  @novaalianca  ",
      youtube_url: "  https://youtube.example/canal  ",
      pastores_publicos: ["  Pastora Ana  ", {}, "Pastora Ana"],
      pastor_responsavel: "Não substituir lista preenchida",
      responsavel_administrativo_uid: segredo,
      telefone: segredo,
      pix_chave: segredo,
      pix_tipo: segredo,
      cep: segredo,
    },
  });

  assert.deepEqual(Object.keys(catalogo), CAMPOS_CATALOGO_PUBLICO);
  assert.deepEqual(catalogo, {
    nome: "Nova Aliança Olinda",
    ativa: true,
    configurada: true,
    endereco: "Avenida Teste, 10",
    cidade_estado: "Olinda — PE",
    endereco_secundario: "Ao lado da praça",
    slogan: "Família para pertencer",
    cultos_recorrentes: ["Domingo 18h"],
    instagram: "@novaalianca",
    youtube_url: "https://youtube.example/canal",
    pastores_publicos: ["Pastora Ana"],
  });
  assert.equal(JSON.stringify(catalogo).includes(segredo), false);
});

test("campos públicos opcionais ausentes permanecem nulos", () => {
  assert.deepEqual(
    projetarCatalogoPublico({
      nome: "Nova Aliança Petrolina",
      ativa: false,
      configurada: false,
    }),
    {
      nome: "Nova Aliança Petrolina",
      ativa: false,
      configurada: false,
      endereco: null,
      cidade_estado: null,
      endereco_secundario: null,
      slogan: null,
      cultos_recorrentes: [],
      instagram: null,
      youtube_url: null,
      pastores_publicos: [],
    }
  );
});

test("pastor responsável legado só preenche lista pública vazia", () => {
  const base = {
    nome: "Olinda",
    ativa: true,
    configurada: true,
    dados_institucionais: {
      pastores_publicos: ["", false],
      pastor_responsavel: "  Pastor Legado  ",
    },
  };
  assert.deepEqual(projetarCatalogoPublico(base).pastores_publicos, [
    "Pastor Legado",
  ]);
  assert.deepEqual(
    projetarCatalogoPublico({
      ...base,
      dados_institucionais: {
        ...base.dados_institucionais,
        pastores_publicos: [" Pastora Pública "],
      },
    }).pastores_publicos,
    ["Pastora Pública"]
  );
});

test("projeção reprova tipos obrigatórios inválidos", () => {
  assert.throws(
    () => projetarCatalogoPublico({ nome: "Olinda", ativa: "sim", configurada: true }),
    /catalogo_invalido:ativa/
  );
  assert.throws(
    () => projetarCatalogoPublico({ nome: "Olinda", ativa: true }),
    /catalogo_invalido:configurada/
  );
});

test("unidade existente divergente é bloqueada apenas pelos nomes dos campos", () => {
  const esperado = {
    nome: "Nova Aliança Olinda",
    slug: "olinda",
    ativa: true,
    configurada: true,
    mercado_pago_status: "nao_configurado",
  };
  const resultado = validarUnidadeConhecida(
    { ...esperado, nome: "outro", ativa: false },
    esperado
  );

  assert.equal(resultado.estado, "divergente");
  assert.deepEqual(resultado.camposDivergentes, ["nome", "ativa"]);
});

test("raiz existente sem campo operacional obrigatório é parcial", () => {
  const esperado = {
    nome: "Nova Aliança Olinda",
    slug: "olinda",
    ativa: true,
    configurada: false,
    mercado_pago_status: "nao_configurado",
  };
  const atual = { ...esperado };
  delete atual.mercado_pago_status;

  assert.deepEqual(validarUnidadeConhecida(atual, esperado), {
    estado: "divergente",
    camposDivergentes: ["mercado_pago_status"],
  });
});

test("catálogo existente com campo extra nunca é aceito como idempotente", () => {
  const esperado = projetarCatalogoPublico({
    nome: "Nova Aliança Olinda",
    ativa: true,
    configurada: true,
  });
  const resultado = compararCatalogo(
    { ...esperado, responsavel_administrativo_uid: "segredo" },
    esperado
  );

  assert.equal(resultado.compativel, false);
  assert.deepEqual(resultado.camposDivergentes, ["campos_extras"]);
});

test("inventário inclui somente caminhos de campos, nunca valores", () => {
  const segredo = "VALOR-CANARIO-NAO-PODE-VAZAR";
  const inventario = inventariarCampos([
    { nome: segredo, dados: { criado_por: segredo } },
  ]);

  assert.deepEqual(inventario, ["dados", "dados.criado_por", "nome"]);
  assert.equal(JSON.stringify(inventario).includes(segredo), false);
});

test("CLI rejeita projeto errado e modos contraditórios", () => {
  assert.throws(
    () => analisarArgumentos(["--project=outro", "--dry-run"]),
    /Projeto recusado/
  );
  assert.throws(
    () =>
      analisarArgumentos([
        "--project=nova-alianca-app",
        "--dry-run",
        "--apply",
      ]),
    /somente um modo/
  );
  assert.deepEqual(analisarArgumentos(["--project=nova-alianca-app"]), {
    projeto: "nova-alianca-app",
    aplicar: false,
    dryRun: true,
  });
});

test("API da migração exige projeto oficial e dryRun boolean explícito", async () => {
  await assert.rejects(
    executarMigracao({ projeto: "outro", dryRun: true }),
    /Projeto recusado/
  );
  await assert.rejects(
    executarMigracao({ projeto: "nova-alianca-app" }),
    /dryRun deve ser informado explicitamente como boolean/
  );
  await assert.rejects(
    executarMigracao({ projeto: "nova-alianca-app", dryRun: "true" }),
    /dryRun deve ser informado explicitamente como boolean/
  );
});

test("dry-run completo planeja todas as etapas sem abrir transação ou batch", async () => {
  let batchesCriados = 0;
  let transacoesCriadas = 0;
  const snapshotVazio = { docs: [], size: 0 };
  const db = {
    projectId: "nova-alianca-app",
    collection() {
      return { get: async () => snapshotVazio };
    },
    doc() {
      return {
        get: async () => ({ exists: false, data: () => undefined }),
      };
    },
    batch() {
      batchesCriados++;
      throw new Error("dry-run não pode criar batch");
    },
    runTransaction() {
      transacoesCriadas++;
      throw new Error("dry-run não pode abrir transação");
    },
  };
  const admin = {
    firestore: {
      FieldValue: {
        serverTimestamp: () => ({ sentinel: "serverTimestamp" }),
      },
    },
  };

  await executarMigracao({
    admin,
    db,
    projeto: "nova-alianca-app",
    dryRun: true,
  });
  assert.equal(batchesCriados, 0);
  assert.equal(transacoesCriadas, 0);
});

test("dados institucionais legados também passam por allowlist", () => {
  const segredo = "VALOR-CANARIO-NAO-PODE-VAZAR";
  const dados = extrairDadosInstitucionaisLegados({
    endereco: " Rua Oficial ",
    pastores_publicos: [" Pastora Um ", ""],
    campo_desconhecido: segredo,
    token: segredo,
  });

  assert.deepEqual(dados, {
    pastores_publicos: ["Pastora Um"],
    endereco: "Rua Oficial",
  });
  assert.equal(JSON.stringify(dados).includes(segredo), false);
});

test("allowlist institucional ignora objetos, booleanos e números", () => {
  assert.deepEqual(
    extrairDadosInstitucionaisLegados({
      endereco: { texto: "não aceitar" },
      cidade_estado: 123,
      pix_chave: false,
      pastores_publicos: ["", { nome: "não aceitar" }, true, 42],
    }),
    { pastores_publicos: [] }
  );
});

test("validador do canário REST exige campos exatos e ativa true", () => {
  const documento = {
    fields: {
      nome: { stringValue: "Nova Aliança Olinda" },
      ativa: { booleanValue: true },
      configurada: { booleanValue: true },
      endereco: { nullValue: null },
      cidade_estado: { stringValue: "Olinda — PE" },
      endereco_secundario: { nullValue: null },
      slogan: { stringValue: "Família para pertencer" },
      cultos_recorrentes: {
        arrayValue: { values: [{ stringValue: "Domingo 18h" }] },
      },
      instagram: { stringValue: "@novaalianca" },
      youtube_url: { nullValue: null },
      pastores_publicos: { arrayValue: {} },
    },
  };

  assert.equal(validarDocumentoRest(documento).valido, true);
  assert.equal(
    validarDocumentoRest({
      fields: { ...documento.fields, criado_por: { stringValue: "segredo" } },
    }).valido,
    false
  );
  assert.deepEqual(
    documentosDaResposta([{ document: documento }, { readTime: "agora" }]),
    [documento]
  );
});

test("canário negativo aceita somente HTTP 403", async () => {
  await exigirNegado("recurso privado", Promise.resolve({ status: 403 }));
  await assert.rejects(
    exigirNegado("recurso privado", Promise.resolve({ status: 404 })),
    /deveria ser negado.*HTTP 403.*HTTP 404/
  );
  await assert.rejects(
    exigirNegado("recurso privado", Promise.resolve({ status: 200 })),
    /deveria ser negado.*HTTP 403.*HTTP 200/
  );
});

test("planejamento vazio cria duas raízes e dois catálogos sem conflito", () => {
  const plano = planejarUnidades({
    raizesAtuais: new Map(),
    catalogosAtuais: new Map(),
  });

  assert.equal(plano.conflitos.length, 0);
  assert.equal(plano.criarRaizes.length, 2);
  assert.equal(plano.criarCatalogos.length, 2);
  assert.deepEqual(
    plano.criarCatalogos.find((item) => item.id === "olinda").dados,
    {
      nome: "Nova Aliança Olinda",
      ativa: true,
      configurada: false,
      endereco: null,
      cidade_estado: null,
      endereco_secundario: null,
      slogan: null,
      cultos_recorrentes: [],
      instagram: null,
      youtube_url: null,
      pastores_publicos: [],
    }
  );
});

test("Olinda só fica configurada quando há dado institucional allowlisted real", () => {
  const semDados = planejarUnidades({
    raizesAtuais: new Map(),
    catalogosAtuais: new Map(),
    legadoDados: {
      endereco: "   ",
      pix_chave: null,
      cidade_estado: 123,
      telefone: false,
      instagram: { valor: "não conta" },
      pastores_publicos: [{ nome: "não conta" }],
      token_privado: "não conta",
    },
  });
  assert.equal(
    semDados.criarRaizes.find((item) => item.id === "olinda").dados.configurada,
    false
  );

  const comDados = planejarUnidades({
    raizesAtuais: new Map(),
    catalogosAtuais: new Map(),
    legadoDados: {
      endereco: " Rua Oficial ",
      token_privado: "não pode vazar",
    },
  });
  const raiz = comDados.criarRaizes.find((item) => item.id === "olinda").dados;
  const catalogo = comDados.criarCatalogos.find((item) => item.id === "olinda").dados;
  assert.equal(raiz.configurada, true);
  assert.deepEqual(raiz.dados_institucionais, { endereco: "Rua Oficial" });
  assert.deepEqual(catalogo, {
    nome: "Nova Aliança Olinda",
    ativa: true,
    configurada: true,
    endereco: "Rua Oficial",
    cidade_estado: null,
    endereco_secundario: null,
    slogan: null,
    cultos_recorrentes: [],
    instagram: null,
    youtube_url: null,
    pastores_publicos: [],
  });
});

test("legado institucional nunca é ocultado por uma raiz Olinda já existente", () => {
  const base = planejarUnidades({
    raizesAtuais: new Map(),
    catalogosAtuais: new Map(),
  });
  const olindaVazia = base.criarRaizes.find((item) => item.id === "olinda");

  const plano = planejarUnidades({
    raizesAtuais: new Map([["olinda", olindaVazia.dados]]),
    catalogosAtuais: new Map(),
    legadoDados: { endereco: "Rua Oficial" },
  });

  assert.equal(
    plano.conflitos.some(
      (item) =>
        item === "igrejas/olinda[configurada,migrado_de]" ||
        item === "igrejas/olinda[configurada]"
    ),
    true
  );
  assert.equal(plano.criarCatalogos.some((item) => item.id === "olinda"), false);
});

test("segunda execução com dados compatíveis planeja zero escritas", () => {
  const inicial = planejarUnidades({
    raizesAtuais: new Map(),
    catalogosAtuais: new Map(),
  });
  const raizes = new Map(
    inicial.criarRaizes.map((item) => [item.id, item.dados])
  );
  const catalogos = new Map(
    inicial.criarCatalogos.map((item) => [item.id, item.dados])
  );
  const segunda = planejarUnidades({
    raizesAtuais: raizes,
    catalogosAtuais: catalogos,
  });

  assert.deepEqual(segunda, {
    criarRaizes: [],
    criarCatalogos: [],
    conflitos: [],
  });
});

test("Olinda divergente bloqueia antes de qualquer plano de escrita", () => {
  const planoBase = planejarUnidades({
    raizesAtuais: new Map(),
    catalogosAtuais: new Map(),
  });
  const olinda = planoBase.criarRaizes.find((item) => item.id === "olinda");
  const plano = planejarUnidades({
    raizesAtuais: new Map([["olinda", { ...olinda.dados, ativa: false }]]),
    catalogosAtuais: new Map(),
  });

  assert.equal(plano.conflitos.some((item) => item.includes("[ativa]")), true);
});

test("destino parcial ou estrangeiro vira conflito sem revelar valores nem UID", () => {
  const plano = criarPlanoAtomico();
  const uidCanario = "uid-secreto-nao-imprimir";
  const resultado = planejarCriacaoDocumento(plano, {
    caminho: `igrejas/olinda/avisos/${uidCanario}`,
    caminhoSeguro: "igrejas/olinda/avisos/{id}",
    dados: {
      titulo: "Oficial",
      migrado_de: "avisos/origem-oficial",
      migrado_em: { sentinel: true },
    },
    atual: {
      titulo: "Outro",
      migrado_de: `avisos/${uidCanario}`,
      campo_extra: uidCanario,
    },
  });

  assert.equal(resultado, "conflito");
  assert.equal(plano.operacoes.length, 0);
  assert.deepEqual(plano.conflitos, [
    "igrejas/olinda/avisos/{id}[campos_extras,migrado_de,migrado_em,titulo]",
  ]);
  assert.throws(
    () => validarPlanoAtomico(plano),
    (erro) => {
      assert.equal(erro.message.includes(uidCanario), false);
      return true;
    }
  );
});

test("destino só é idempotente com proveniência e contrato compatíveis", () => {
  const plano = criarPlanoAtomico();
  const resultado = planejarCriacaoDocumento(plano, {
    caminho: "igrejas/olinda/avisos/aviso-1",
    caminhoSeguro: "igrejas/olinda/avisos/{id}",
    dados: {
      titulo: "Aviso oficial",
      publico: false,
      migrado_de: "avisos/aviso-1",
      migrado_em: { sentinel: true },
    },
    atual: {
      titulo: "Aviso oficial",
      publico: false,
      migrado_de: "avisos/aviso-1",
      migrado_em: {
        toDate: () => new Date("2026-08-19T00:00:00.000Z"),
      },
    },
  });

  assert.equal(resultado, "inalterado");
  assert.deepEqual(plano, { operacoes: [], conflitos: [] });
});

test("proveniência temporal falsa nunca é aceita como idempotente", () => {
  const plano = criarPlanoAtomico();
  assert.equal(
    planejarCriacaoDocumento(plano, {
      caminho: "igrejas/olinda/avisos/aviso-1",
      caminhoSeguro: "igrejas/olinda/avisos/{id}",
      dados: {
        titulo: "Aviso oficial",
        migrado_de: "avisos/aviso-1",
        migrado_em: { sentinel: true },
      },
      atual: {
        titulo: "Aviso oficial",
        migrado_de: "avisos/aviso-1",
        migrado_em: false,
      },
    }),
    "conflito"
  );
  assert.deepEqual(plano.conflitos, [
    "igrejas/olinda/avisos/{id}[migrado_em]",
  ]);
});

test("unidades desconhecidas geram conflito sanitizado e nunca viram catálogo", () => {
  const idSecreto = "uid-secreto-nao-imprimir";
  const plano = planejarUnidades({
    raizesAtuais: new Map([
      [
        idSecreto,
        {
          nome: "Estrangeira",
          slug: "estrangeira",
          ativa: true,
          configurada: true,
          mercado_pago_status: "configurado",
        },
      ],
    ]),
    catalogosAtuais: new Map([
      [
        idSecreto,
        {
          nome: "Estrangeira",
          ativa: true,
          configurada: true,
          endereco: null,
          cidade_estado: null,
        },
      ],
    ]),
  });

  assert.equal(JSON.stringify(plano).includes(idSecreto), false);
  assert.equal(
    plano.conflitos.includes("igrejas/{igrejaId}[unidade_desconhecida]"),
    true
  );
  assert.equal(
    plano.conflitos.includes(
      "catalogo_igrejas/{igrejaId}[sem_raiz_operacional]"
    ),
    true
  );
  assert.equal(plano.criarCatalogos.some((item) => item.id === idSecreto), false);
});

test("igreja principal ausente vira Olinda; outro ID gera conflito", () => {
  const plano = criarPlanoAtomico();
  assert.equal(
    planejarIgrejaPrincipal(plano, {
      caminho: "usuarios/uid-1",
      caminhoSeguro: "usuarios/{uid}",
      dadosAtuais: {},
      precondicao: { lastUpdateTime: "versao-1" },
    }),
    "atualizar"
  );
  assert.equal(
    planejarIgrejaPrincipal(plano, {
      caminho: "usuarios/uid-2",
      caminhoSeguro: "usuarios/{uid}",
      dadosAtuais: { igreja_principal_id: "olinda" },
    }),
    "inalterado"
  );
  assert.equal(plano.operacoes.length, 1);
  assert.deepEqual(plano.operacoes[0].dados, {
    igreja_principal_id: "olinda",
  });
  assert.deepEqual(plano.conflitos, []);

  for (const outroId of ["petrolina", "unidade_desconhecida", "ID inválido"]) {
    const planoInconsistente = criarPlanoAtomico();
    assert.equal(
      planejarIgrejaPrincipal(planoInconsistente, {
        caminho: "usuarios/uid-nao-exposto",
        caminhoSeguro: "usuarios/{uid}",
        dadosAtuais: { igreja_principal_id: outroId },
      }),
      "conflito"
    );
    assert.deepEqual(planoInconsistente.conflitos, [
      "usuarios/{uid}[igreja_principal_id]",
    ]);
    assert.equal(JSON.stringify(planoInconsistente).includes(outroId), false);
  }
});

test("tokens globais são planejados no usuário com proveniência preservada", async () => {
  const tokenSecreto = "TOKEN-CANARIO-NAO-IMPRIMIR";
  const fake = criarFirestoreTransacionalFake({
    "tokens_dispositivo/token-doc": {
      perfil_id: "uid-1",
      token: tokenSecreto,
      plataforma: "android",
    },
  });
  const ctx = criarContexto({
    admin: fake.admin,
    db: fake.db,
    dryRun: false,
    silencioso: true,
  });
  const plano = await prepararPlanoCompleto(ctx);
  const operacao = plano.operacoes.find(
    (item) => item.caminho === "usuarios/uid-1/tokens_dispositivo/token-doc"
  );

  assert.equal(Boolean(operacao), true);
  assert.equal(operacao.caminhoSeguro, "usuarios/{uid}/tokens_dispositivo/{id}");
  assert.equal(operacao.dados.token, tokenSecreto);
  assert.equal(operacao.dados.migrado_de, "tokens_dispositivo/token-doc");

  const resultado = await aplicarPlanoAtomico({
    admin: fake.admin,
    db: fake.db,
    plano,
    leituras: ctx.leituras,
    projeto: "nova-alianca-app",
    dryRun: false,
  });
  assert.equal(resultado.posVerificacao, true);
  assert.equal(
    fake.obter("usuarios/uid-1/tokens_dispositivo/token-doc").token,
    tokenSecreto
  );
});

test("onze tokens globais acrescentam exatamente onze operações privadas", async () => {
  const documentos = Object.fromEntries(
    Array.from({ length: 11 }, (_, indice) => [
      `tokens_dispositivo/token-${indice}`,
      {
        perfil_id: `uid-${indice}`,
        token: `token-privado-${indice}`,
        plataforma: "android",
      },
    ])
  );
  const fake = criarFirestoreTransacionalFake(documentos);
  const ctx = criarContexto({
    admin: fake.admin,
    db: fake.db,
    dryRun: true,
    silencioso: true,
  });
  const plano = await prepararPlanoCompleto(ctx);

  assert.equal(
    plano.operacoes.filter((item) =>
      item.caminhoSeguro?.includes("tokens_dispositivo")
    ).length,
    11
  );
});

test("UID inválido e colisão de token geram conflitos sem expor UID ou token", async () => {
  const casos = [
    {
      uid: "uid/secreto",
      documentos: {
        "tokens_dispositivo/doc-secreto": {
          perfil_id: "uid/secreto",
          token: "TOKEN-SECRETO",
        },
      },
    },
    {
      uid: "uid-secreto",
      documentos: {
        "tokens_dispositivo/doc-secreto": {
          perfil_id: "uid-secreto",
          token: "TOKEN-SECRETO",
        },
        "usuarios/uid-secreto/tokens_dispositivo/doc-secreto": {
          perfil_id: "uid-secreto",
          token: "OUTRO-TOKEN",
        },
      },
    },
  ];

  for (const caso of casos) {
    const fake = criarFirestoreTransacionalFake(caso.documentos);
    const ctx = criarContexto({
      admin: fake.admin,
      db: fake.db,
      dryRun: true,
      silencioso: true,
    });
    await assert.rejects(prepararPlanoCompleto(ctx), (erro) => {
      assert.equal(erro.message.includes(caso.uid), false);
      assert.equal(erro.message.includes("TOKEN-SECRETO"), false);
      assert.match(erro.message, /tokens_dispositivo/);
      return true;
    });
  }
});

test("configurações globais exigem coleção vazia sem expor documento", async () => {
  const idSecreto = "config-id-secreto";
  const valorSecreto = "CONFIG-VALOR-SECRETO";
  const fake = criarFirestoreTransacionalFake({
    [`configuracoes/${idSecreto}`]: { segredo: valorSecreto },
  });
  const ctx = criarContexto({
    admin: fake.admin,
    db: fake.db,
    dryRun: true,
    silencioso: true,
  });

  await assert.rejects(prepararPlanoCompleto(ctx), (erro) => {
    assert.match(erro.message, /configuracoes\/\{id\}\[contrato_indefinido\]/);
    assert.equal(erro.message.includes(idSecreto), false);
    assert.equal(erro.message.includes(valorSecreto), false);
    return true;
  });
});

test("plano relê, aplica create/update em uma transação e pós-verifica zero", async () => {
  const fake = criarFirestoreTransacionalFake({
    "usuarios/uid-1": {
      nome: "Membro",
      email: "membro@example.test",
      perfil: "membro",
      status: "aprovado",
    },
  });
  const ctx = criarContexto({
    admin: fake.admin,
    db: fake.db,
    dryRun: false,
    silencioso: true,
  });
  const plano = await prepararPlanoCompleto(ctx);

  const resultado = await aplicarPlanoAtomico({
    admin: fake.admin,
    db: fake.db,
    plano,
    leituras: ctx.leituras,
    projeto: "nova-alianca-app",
    dryRun: false,
  });

  assert.equal(resultado.operacoesAplicadas, 6);
  assert.equal(resultado.posVerificacao, true);
  assert.equal(resultado.operacoesPendentes, 0);
  assert.equal(resultado.leiturasValidadas > 0, true);
  assert.deepEqual(fake.metricas, {
    transacoesEscrita: 2,
    transacoesLeitura: 0,
    escritasEnfileiradas: 6,
    commitsEscrita: 1,
  });
  assert.equal(fake.obter("usuarios/uid-1").igreja_principal_id, "olinda");
  assert.equal(fake.obter("igrejas/olinda/membros/uid-1").status, "aprovado");
  assert.equal(fake.obter("catalogo_igrejas/olinda").ativa, true);
});

test("phantom ou destino concorrente aborta antes de enfileirar qualquer escrita", async () => {
  const cenarios = [
    {
      iniciais: {},
      drift: (fake) => fake.gravar("avisos/novo", { titulo: "Concorrente" }),
    },
    {
      iniciais: {},
      drift: (fake) =>
        fake.gravar("tokens_dispositivo/novo", {
          perfil_id: "uid-1",
          token: "TOKEN-CONCORRENTE",
        }),
    },
    {
      iniciais: {},
      drift: (fake) =>
        fake.gravar("configuracoes/nova", { contrato: "desconhecido" }),
    },
    {
      iniciais: { "avisos/existente": { titulo: "Antes" } },
      drift: (fake) => fake.gravar("avisos/existente", { titulo: "Depois" }),
    },
    {
      iniciais: { "avisos/existente": { titulo: "Mesmo conteúdo" } },
      // Mesmo conteúdo, mas updateTime novo: também deve abortar.
      drift: (fake) =>
        fake.gravar("avisos/existente", { titulo: "Mesmo conteúdo" }),
    },
    {
      iniciais: {},
      drift: (fake) =>
        fake.gravar("catalogo_igrejas/olinda", {
          nome: "Destino concorrente",
          ativa: true,
          configurada: false,
          endereco: null,
          cidade_estado: null,
        }),
    },
  ];

  for (const cenario of cenarios) {
    const fake = criarFirestoreTransacionalFake(cenario.iniciais);
    const ctx = criarContexto({
      admin: fake.admin,
      db: fake.db,
      dryRun: false,
      silencioso: true,
    });
    const plano = await prepararPlanoCompleto(ctx);
    cenario.drift(fake);

    await assert.rejects(
      aplicarPlanoAtomico({
        admin: fake.admin,
        db: fake.db,
        plano,
        leituras: ctx.leituras,
        projeto: "nova-alianca-app",
        dryRun: false,
      }),
      /Drift concorrente detectado/
    );
    assert.equal(fake.metricas.escritasEnfileiradas, 0);
    assert.equal(fake.metricas.commitsEscrita, 0);
    assert.equal(fake.metricas.transacoesLeitura, 0);
    assert.equal(fake.obter("igrejas/olinda"), undefined);
  }
});

test("pós-verificação obrigatória detecta origem criada depois do commit", async () => {
  const fake = criarFirestoreTransacionalFake({}, {
    aposCommit: (estado) =>
      estado.gravar("avisos/depois-do-commit", { titulo: "Novo" }),
  });
  const ctx = criarContexto({
    admin: fake.admin,
    db: fake.db,
    dryRun: false,
    silencioso: true,
  });
  const plano = await prepararPlanoCompleto(ctx);

  await assert.rejects(
    aplicarPlanoAtomico({
      admin: fake.admin,
      db: fake.db,
      plano,
      leituras: ctx.leituras,
      projeto: "nova-alianca-app",
      dryRun: false,
    }),
    /Pós-verificação falhou/
  );
  assert.equal(fake.metricas.commitsEscrita, 1);
  assert.equal(fake.metricas.transacoesEscrita, 2);
});

test("guardas detectam mudança de membership da coleção", () => {
  const iniciais = new Map([["colecao:avisos", "[]"]]);
  const atuais = new Map([["colecao:avisos", "[novo]"]]);
  assert.throws(
    () => validarLeiturasInalteradas(iniciais, atuais),
    /Drift concorrente detectado/
  );
});

test("runtime de outro projeto é recusado antes de qualquer acesso", async () => {
  let acessos = 0;
  await assert.rejects(
    executarMigracao({
      admin: {},
      db: {
        projectId: "projeto-errado",
        collection() {
          acessos++;
          throw new Error("não deveria ler");
        },
      },
      projeto: "nova-alianca-app",
      dryRun: true,
    }),
    /Firestore ligado a outro projeto/
  );
  assert.equal(acessos, 0);
  assert.throws(
    () =>
      validarProjetoRuntime({
        db: {},
        projeto: "nova-alianca-app",
      }),
    /projeto do Firestore não verificável/
  );
});

test("erro externo da transação não imprime caminho nem UID", () => {
  const uid = "uid-secreto-nao-imprimir";
  const segura = mensagemErroSegura(
    new Error(`ALREADY_EXISTS: igrejas/olinda/avisos/${uid}`)
  );

  assert.equal(segura.includes(uid), false);
  assert.equal(segura.includes("igrejas/olinda/avisos"), false);
});

test("plano acima de 450 operações ou com delete é recusado antes da transação", () => {
  const excessivo = {
    conflitos: [],
    operacoes: Array.from(
      { length: LIMITE_OPERACOES_BATCH + 1 },
      (_, indice) => ({
        tipo: "create",
        caminho: `destinos/${indice}`,
        caminhoSeguro: "destinos/{id}",
        dados: {},
      })
    ),
  };
  assert.throws(
    () => validarPlanoAtomico(excessivo),
    /451 operações excedem o limite seguro de 450/
  );
  assert.throws(
    () =>
      validarPlanoAtomico({
        conflitos: [],
        operacoes: [
          {
            tipo: "delete",
            caminho: "destinos/1",
            caminhoSeguro: "destinos/{id}",
          },
        ],
      }),
    /somente create e update/
  );
});
