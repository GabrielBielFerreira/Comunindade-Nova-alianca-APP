"use strict";

/**
 * Contrato público mínimo usado antes do login.
 *
 * Este mapa é construído do zero de propósito. O documento operacional em
 * `/igrejas/{id}` pode conter UIDs, autoria, integrações e outros metadados
 * que nunca devem atravessar para o catálogo público.
 */
const CAMPOS_CATALOGO_PUBLICO = Object.freeze([
  "nome",
  "ativa",
  "configurada",
  "endereco",
  "cidade_estado",
  "endereco_secundario",
  "slogan",
  "cultos_recorrentes",
  "instagram",
  "youtube_url",
  "pastores_publicos",
]);

const CAMPOS_UNIDADE_GERENCIADOS = Object.freeze([
  "nome",
  "slug",
  "ativa",
  "configurada",
  "mercado_pago_status",
  "migrado_de",
]);

function objetoSimples(valor) {
  return valor !== null && typeof valor === "object" && !Array.isArray(valor);
}

function textoOpcional(valor) {
  if (valor === null || valor === undefined) return null;
  if (typeof valor !== "string") return null;
  const texto = valor.trim();
  return texto.length > 0 ? texto : null;
}

function listaPublica(valor) {
  if (!Array.isArray(valor)) return [];
  return [
    ...new Set(
      valor
        .filter((item) => typeof item === "string")
        .map((item) => item.trim())
        .filter((item) => item.length > 0)
    ),
  ];
}

function campoInstitucional(dados, campo) {
  const institucionais = objetoSimples(dados.dados_institucionais)
    ? dados.dados_institucionais
    : {};
  return Object.prototype.hasOwnProperty.call(institucionais, campo)
    ? institucionais[campo]
    : dados[campo];
}

function projetarCatalogoPublico(dados) {
  if (!objetoSimples(dados)) {
    throw new Error("catalogo_invalido:documento");
  }

  const nome = textoOpcional(dados.nome);
  if (!nome) throw new Error("catalogo_invalido:nome");
  if (typeof dados.ativa !== "boolean") {
    throw new Error("catalogo_invalido:ativa");
  }
  if (typeof dados.configurada !== "boolean") {
    throw new Error("catalogo_invalido:configurada");
  }
  const pastoresPublicos = listaPublica(
    campoInstitucional(dados, "pastores_publicos")
  );
  if (pastoresPublicos.length === 0) {
    const pastorLegado = textoOpcional(
      campoInstitucional(dados, "pastor_responsavel")
    );
    if (pastorLegado) pastoresPublicos.push(pastorLegado);
  }

  return {
    nome,
    ativa: dados.ativa,
    configurada: dados.configurada,
    endereco: textoOpcional(campoInstitucional(dados, "endereco")),
    cidade_estado: textoOpcional(campoInstitucional(dados, "cidade_estado")),
    endereco_secundario: textoOpcional(
      campoInstitucional(dados, "endereco_secundario")
    ),
    slogan: textoOpcional(campoInstitucional(dados, "slogan")),
    cultos_recorrentes: listaPublica(
      campoInstitucional(dados, "cultos_recorrentes")
    ),
    instagram: textoOpcional(campoInstitucional(dados, "instagram")),
    youtube_url: textoOpcional(campoInstitucional(dados, "youtube_url")),
    pastores_publicos: pastoresPublicos,
  };
}

function valoresPublicosIguais(atual, esperado) {
  if (Object.is(atual, esperado)) return true;
  return (
    Array.isArray(atual) &&
    Array.isArray(esperado) &&
    atual.length === esperado.length &&
    atual.every((item, indice) => Object.is(item, esperado[indice]))
  );
}

function compararCatalogo(atual, esperado) {
  if (!objetoSimples(atual)) {
    return { compativel: false, camposDivergentes: ["documento"] };
  }

  const chavesAtuais = Object.keys(atual).sort();
  const chavesEsperadas = [...CAMPOS_CATALOGO_PUBLICO].sort();
  const divergentes = new Set();

  for (const chave of chavesAtuais) {
    if (!chavesEsperadas.includes(chave)) {
      // Campos fora do contrato podem ter nomes derivados de identificadores.
      // O relatório só precisa indicar que há extras, nunca reproduzi-los.
      divergentes.add("campos_extras");
    }
  }
  for (const chave of chavesEsperadas) {
    if (!Object.prototype.hasOwnProperty.call(atual, chave)) {
      divergentes.add(chave);
      continue;
    }
    if (!valoresPublicosIguais(atual[chave], esperado[chave])) {
      divergentes.add(chave);
    }
  }

  return {
    compativel: divergentes.size === 0,
    camposDivergentes: [...divergentes].sort(),
  };
}

function validarUnidadeConhecida(atual, esperado) {
  if (atual === null || atual === undefined) {
    return { estado: "ausente", camposDivergentes: [] };
  }
  if (!objetoSimples(atual)) {
    return { estado: "invalida", camposDivergentes: ["documento"] };
  }

  const divergentes = CAMPOS_UNIDADE_GERENCIADOS.filter(
    (campo) => !Object.is(atual[campo], esperado[campo])
  );

  return {
    estado: divergentes.length === 0 ? "compativel" : "divergente",
    camposDivergentes: divergentes,
  };
}

function listarCaminhosDeCampos(valor, prefixo = "") {
  if (!objetoSimples(valor)) return [];
  const caminhos = [];
  for (const chave of Object.keys(valor).sort()) {
    const caminho = prefixo ? `${prefixo}.${chave}` : chave;
    caminhos.push(caminho);
    caminhos.push(...listarCaminhosDeCampos(valor[chave], caminho));
  }
  return caminhos;
}

function inventariarCampos(documentos) {
  const campos = new Set();
  for (const documento of documentos) {
    for (const caminho of listarCaminhosDeCampos(documento)) {
      campos.add(caminho);
    }
  }
  return [...campos].sort();
}

module.exports = {
  CAMPOS_CATALOGO_PUBLICO,
  compararCatalogo,
  inventariarCampos,
  listarCaminhosDeCampos,
  projetarCatalogoPublico,
  validarUnidadeConhecida,
};
