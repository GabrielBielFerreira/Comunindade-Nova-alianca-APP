"use strict";

/**
 * Auditoria remota somente leitura de Rules e App Check.
 *
 * A credencial ADC nunca é impressa. O relatório contém apenas identificadores
 * de versão, hash da fonte e modos de enforcement — nunca o conteúdo das Rules.
 */
const crypto = require("node:crypto");
const admin = require("firebase-admin");

const PROJETO_ESPERADO = "nova-alianca-app";

async function obterJson(url, token, rotulo) {
  const resposta = await fetch(url, {
    headers: { authorization: `Bearer ${token}` },
  });
  if (!resposta.ok) {
    let motivo = "";
    try {
      const corpo = await resposta.json();
      motivo =
        corpo?.error?.details?.find((item) => typeof item?.reason === "string")
          ?.reason ?? corpo?.error?.status ?? "";
    } catch {
      // O status HTTP basta; nunca ecoamos o corpo remoto.
    }
    const seguro = String(motivo).replace(/[^A-Z0-9_-]/gi, "");
    throw new Error(
      `${rotulo}: HTTP ${resposta.status}${seguro ? ` (${seguro})` : ""}`
    );
  }
  return resposta.json();
}

function idFinal(nome) {
  return typeof nome === "string" ? nome.split("/").at(-1) : null;
}

function modoServico(servicos, id) {
  const item = servicos.find((servico) => servico.name?.endsWith(`/services/${id}`));
  return item?.enforcementMode ?? "OFF_PADRAO_NAO_CONFIGURADO";
}

async function executar() {
  const projeto = process.argv
    .slice(2)
    .find((item) => item.startsWith("--project="))
    ?.slice("--project=".length);
  if (projeto !== PROJETO_ESPERADO) {
    throw new Error(`Informe --project=${PROJETO_ESPERADO}.`);
  }

  const credencial = admin.credential.applicationDefault();
  const acesso = await credencial.getAccessToken();
  const token = acesso?.access_token;
  if (!token) throw new Error("ADC não forneceu token de acesso.");

  const projetoCloud = await obterJson(
    `https://cloudresourcemanager.googleapis.com/v1/projects/${projeto}`,
    token,
    "Cloud Resource Manager"
  );
  const numeroProjeto = projetoCloud.projectNumber;
  if (!numeroProjeto) throw new Error("Número do projeto não encontrado.");

  const release = await obterJson(
    `https://firebaserules.googleapis.com/v1/projects/${projeto}` +
      "/releases/cloud.firestore",
    token,
    "release de Rules"
  );
  const arquivos = await obterJson(
    `https://firebaserules.googleapis.com/v1/${release.rulesetName}`,
    token,
    "ruleset vigente"
  );
  const fontes = Array.isArray(arquivos?.source?.files)
    ? arquivos.source.files
    : [];
  const fonteCombinada = fontes
    .map((arquivo) => `${arquivo.name ?? ""}\n${arquivo.content ?? ""}`)
    .sort()
    .join("\n");
  const hashRules = crypto
    .createHash("sha256")
    .update(fonteCombinada)
    .digest("hex");

  let appCheck;
  try {
    const resposta = await obterJson(
      `https://firebaseappcheck.googleapis.com/v1/projects/${numeroProjeto}` +
        "/services?pageSize=100",
      token,
      "App Check"
    );
    const servicos = Array.isArray(resposta.services) ? resposta.services : [];
    appCheck = {
      consulta: "OK",
      firestore: modoServico(servicos, "firestore.googleapis.com"),
      storage: modoServico(servicos, "firebasestorage.googleapis.com"),
      autenticacao: modoServico(servicos, "identitytoolkit.googleapis.com"),
      servicosExplicitamenteConfigurados: servicos.length,
    };
  } catch (erro) {
    appCheck = {
      consulta: "INDISPONIVEL",
      erro: String(erro?.message ?? erro).replace(/[^A-Za-z0-9 :_-]/g, ""),
    };
  }

  console.log(
    JSON.stringify(
      {
        projeto,
        rules: {
          release: idFinal(release.name),
          ruleset: idFinal(release.rulesetName),
          arquivos: fontes.length,
          sha256: hashRules,
          declaraCatalogoPublico: fonteCombinada.includes(
            "match /catalogo_igrejas/"
          ),
          declaraRaizIgrejas: fonteCombinada.includes("match /igrejas/"),
        },
        appCheck,
        somenteLeitura: true,
      },
      null,
      2
    )
  );
}

if (require.main === module) {
  executar().catch((erro) => {
    console.error(`[ERRO] Auditoria remota falhou: ${erro.message}`);
    process.exitCode = 1;
  });
}

module.exports = { idFinal, modoServico };
