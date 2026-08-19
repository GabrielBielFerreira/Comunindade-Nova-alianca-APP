"use strict";

const { CAMPOS_CATALOGO_PUBLICO } = require("./catalogo_igrejas");

const PROJETO_ESPERADO = "nova-alianca-app";
const CAMPOS_TEXTO_OPCIONAL = [
  "endereco",
  "cidade_estado",
  "endereco_secundario",
  "slogan",
  "instagram",
  "youtube_url",
];
const CAMPOS_LISTA_PUBLICA = ["cultos_recorrentes", "pastores_publicos"];

function argumento(nome, argv = process.argv.slice(2)) {
  const prefixo = `--${nome}=`;
  const item = argv.find((valor) => valor.startsWith(prefixo));
  return item ? item.slice(prefixo.length) : undefined;
}

function temFlag(nome, argv = process.argv.slice(2)) {
  return argv.includes(`--${nome}`);
}

function documentosDaResposta(resposta) {
  if (!Array.isArray(resposta)) return [];
  return resposta
    .map((item) => item?.document)
    .filter((documento) => documento && documento.fields);
}

function tipoTextoOuNulo(valor) {
  if (!valor) return false;
  if (Object.prototype.hasOwnProperty.call(valor, "nullValue")) {
    return valor.nullValue === null;
  }
  return (
    typeof valor.stringValue === "string" &&
    valor.stringValue.length > 0 &&
    valor.stringValue === valor.stringValue.trim()
  );
}

function tipoListaDeTextosSanitizados(valor) {
  if (
    !valor ||
    valor.arrayValue === null ||
    typeof valor.arrayValue !== "object"
  ) {
    return false;
  }
  const itens = valor.arrayValue.values;
  if (itens === undefined) return true;
  if (!Array.isArray(itens)) return false;

  const textos = [];
  for (const item of itens) {
    const texto = item?.stringValue;
    if (
      typeof texto !== "string" ||
      texto.length === 0 ||
      texto !== texto.trim()
    ) {
      return false;
    }
    textos.push(texto);
  }
  return new Set(textos).size === textos.length;
}

function validarDocumentoRest(documento) {
  const campos = documento?.fields ?? {};
  const chaves = Object.keys(campos).sort();
  const esperadas = [...CAMPOS_CATALOGO_PUBLICO].sort();
  const chavesCorretas =
    chaves.length === esperadas.length &&
    chaves.every((chave, indice) => chave === esperadas[indice]);

  return {
    valido:
      chavesCorretas &&
      typeof campos.nome?.stringValue === "string" &&
      campos.nome.stringValue.trim().length > 0 &&
      campos.nome.stringValue === campos.nome.stringValue.trim() &&
      campos.ativa?.booleanValue === true &&
      typeof campos.configurada?.booleanValue === "boolean" &&
      CAMPOS_TEXTO_OPCIONAL.every((campo) =>
        tipoTextoOuNulo(campos[campo])
      ) &&
      CAMPOS_LISTA_PUBLICA.every((campo) =>
        tipoListaDeTextosSanitizados(campos[campo])
      ),
    campos: chaves,
  };
}

async function exigirNegado(rotulo, promessaResposta) {
  const resposta = await promessaResposta;
  if (resposta.status !== 403) {
    throw new Error(
      `${rotulo} deveria ser negado anonimamente com HTTP 403; ` +
        `recebeu HTTP ${resposta.status}.`
    );
  }
  console.log(`Privacidade OK: ${rotulo}=HTTP 403`);
}

function endpointDocumentos(projeto, sufixo = "") {
  return (
    `https://firestore.googleapis.com/v1/projects/${projeto}` +
    `/databases/(default)/documents${sufixo}`
  );
}

function executarQuery(projeto, collectionId, where) {
  return fetch(`${endpointDocumentos(projeto)}:runQuery`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId }],
        ...(where ? { where } : {}),
      },
    }),
  });
}

async function verificarPrivacidade(projeto) {
  await exigirNegado(
    "igrejas/olinda",
    fetch(endpointDocumentos(projeto, "/igrejas/olinda"))
  );
  await exigirNegado(
    "query igrejas sem filtro",
    executarQuery(projeto, "igrejas")
  );
}

async function executar() {
  const projeto = argumento("project");
  if (projeto !== PROJETO_ESPERADO) {
    throw new Error(
      `Informe explicitamente --project=${PROJETO_ESPERADO}; nenhum outro projeto é aceito.`
    );
  }

  await verificarPrivacidade(projeto);
  if (temFlag("preflight-privacidade")) {
    console.log("Preflight de privacidade concluído; nenhuma escrita foi feita.");
    return;
  }

  const filtroAtivas = {
    fieldFilter: {
      field: { fieldPath: "ativa" },
      op: "EQUAL",
      value: { booleanValue: true },
    },
  };

  // Sem Authorization de propósito: este é o canário do primeiro acesso.
  const respostaHttp = await executarQuery(
    projeto,
    "catalogo_igrejas",
    filtroAtivas
  );

  if (!respostaHttp.ok) {
    let codigo = "desconhecido";
    try {
      const erro = await respostaHttp.json();
      codigo = erro?.error?.status ?? codigo;
    } catch {
      // O status HTTP ainda é suficiente; não imprimimos o corpo remoto.
    }
    throw new Error(`Canário anônimo falhou: HTTP ${respostaHttp.status} (${codigo}).`);
  }

  const documentos = documentosDaResposta(await respostaHttp.json());
  if (documentos.length < 1) {
    throw new Error("Canário anônimo retornou HTTP 200, mas nenhuma igreja ativa.");
  }

  for (const documento of documentos) {
    const validacao = validarDocumentoRest(documento);
    if (!validacao.valido) {
      throw new Error(
        `Catálogo público fora do contrato. Campos observados: ${validacao.campos.join(",")}`
      );
    }
  }

  await exigirNegado(
    "query catalogo_igrejas sem filtro",
    executarQuery(projeto, "catalogo_igrejas")
  );
  await exigirNegado(
    "catalogo_igrejas/petrolina inativa",
    fetch(endpointDocumentos(projeto, "/catalogo_igrejas/petrolina"))
  );

  console.log(
    `Canário anônimo OK: HTTP 200, ativas=${documentos.length}, ` +
      `campos=${CAMPOS_CATALOGO_PUBLICO.join(",")}`
  );
}

if (require.main === module) {
  executar().catch((erro) => {
    console.error(`[ERRO] ${erro.message}`);
    process.exitCode = 1;
  });
}

module.exports = {
  documentosDaResposta,
  endpointDocumentos,
  executarQuery,
  exigirNegado,
  tipoListaDeTextosSanitizados,
  validarDocumentoRest,
  verificarPrivacidade,
};
