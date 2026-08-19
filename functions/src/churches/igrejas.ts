/**
 * Cadastro e configuração de unidades.
 *
 * `criarIgreja` é exclusiva do super_admin. `atualizarIgreja` aceita o pastor
 * da própria unidade. Unidade nova nasce INATIVA e NÃO CONFIGURADA — nada é
 * inventado para preencher a demonstração.
 */
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { FieldValue, REGIAO, db } from "../firebase";
import { writeAuditLogTx } from "../audit/audit";
import { requireChurchPastor, requireSuperAdmin } from "../authorization/guards";
import { validarIgrejaId } from "../dominio/tipos";
import { projetarCatalogoPublico } from "./catalogoPublico";

const opcoes = { region: REGIAO } as const;

type ValorInstitucional = string | null | string[];
type DadosInstitucionais = Record<string, ValorInstitucional>;

/**
 * Allowlist de edição da raiz privada. Campos financeiros/contato existentes
 * continuam operacionais, mas a projeção pública decide separadamente o que
 * pode sair em `catalogo_igrejas`.
 */
export const LIMITES_CAMPOS_TEXTO = Object.freeze({
  pastor_responsavel: 120,
  endereco: 300,
  cidade_estado: 120,
  endereco_secundario: 300,
  slogan: 240,
  cep: 16,
  telefone: 32,
  instagram: 120,
  youtube_url: 500,
  pix_chave: 180,
  pix_tipo: 32,
});

export const LIMITES_CAMPOS_LISTA = Object.freeze({
  cultos_recorrentes: { itens: 20, caracteresPorItem: 160 },
  pastores_publicos: { itens: 20, caracteresPorItem: 120 },
});

const CAMPOS_INSTITUCIONAIS = new Set([
  ...Object.keys(LIMITES_CAMPOS_TEXTO),
  ...Object.keys(LIMITES_CAMPOS_LISTA),
]);

function erroInstitucional(mensagem: string): never {
  throw new HttpsError("invalid-argument", mensagem);
}

function comoEntradaInstitucional(bruto: unknown): Record<string, unknown> {
  if (bruto === undefined || bruto === null) return {};
  if (typeof bruto !== "object" || Array.isArray(bruto)) {
    return erroInstitucional("Dados institucionais devem ser um objeto.");
  }
  const entrada = bruto as Record<string, unknown>;
  if (Object.keys(entrada).some((campo) => !CAMPOS_INSTITUCIONAIS.has(campo))) {
    return erroInstitucional("Há campos institucionais não permitidos.");
  }
  return entrada;
}

/** Sanitiza estritamente o payload usado tanto em criar quanto em atualizar. */
export function extrairInstitucionais(bruto: unknown): DadosInstitucionais {
  const entrada = comoEntradaInstitucional(bruto);
  const saida: DadosInstitucionais = {};

  for (const [campo, limite] of Object.entries(LIMITES_CAMPOS_TEXTO)) {
    const valor = entrada[campo];
    if (valor === undefined) continue;
    if (valor === null) {
      saida[campo] = null;
      continue;
    }
    if (typeof valor !== "string") {
      erroInstitucional("Campo institucional de texto inválido.");
    }
    const texto = valor.trim();
    if (texto.length > limite) {
      erroInstitucional("Campo institucional excede o limite permitido.");
    }
    saida[campo] = texto.length > 0 ? texto : null;
  }

  for (const [campo, limite] of Object.entries(LIMITES_CAMPOS_LISTA)) {
    const valor = entrada[campo];
    if (valor === undefined) continue;
    if (valor === null) {
      saida[campo] = [];
      continue;
    }
    if (!Array.isArray(valor) || valor.length > limite.itens) {
      erroInstitucional("Lista institucional inválida ou acima do limite.");
    }
    const itens: string[] = [];
    for (const item of valor) {
      if (typeof item !== "string") {
        erroInstitucional("Lista institucional contém item inválido.");
      }
      const texto = item.trim();
      if (texto.length > limite.caracteresPorItem) {
        erroInstitucional("Item institucional excede o limite permitido.");
      }
      if (texto.length > 0 && !itens.includes(texto)) itens.push(texto);
    }
    saida[campo] = itens;
  }

  return saida;
}

export function temDadosInstitucionais(dados: Record<string, unknown>): boolean {
  return Object.entries(dados).some(
    ([campo, valor]) =>
      CAMPOS_INSTITUCIONAIS.has(campo) &&
      (Array.isArray(valor)
        ? valor.length > 0
        : typeof valor === "string" && valor.trim().length > 0)
  );
}

export function mesclarInstitucionais(
  atuais: unknown,
  alteracoes: unknown
): Record<string, unknown> {
  const base =
    typeof atuais === "object" && atuais !== null && !Array.isArray(atuais)
      ? (atuais as Record<string, unknown>)
      : {};
  return { ...base, ...extrairInstitucionais(alteracoes) };
}

function exigirNome(bruto: unknown): string {
  const nome = String(bruto ?? "").trim();
  if (nome.length < 3 || nome.length > 120) {
    throw new HttpsError("invalid-argument", "Informe o nome da unidade (3 a 120 caracteres).");
  }
  return nome;
}

export const criarIgreja = onCall(opcoes, async (request) => {
  const chamador = requireSuperAdmin(request);

  let igrejaId: string;
  try {
    igrejaId = validarIgrejaId(request.data?.igrejaId);
  } catch {
    throw new HttpsError(
      "invalid-argument",
      "Identificador inválido. Use letras, números e _ (2 a 40 caracteres)."
    );
  }

  const nome = exigirNome(request.data?.nome);
  const ref = db.doc(`igrejas/${igrejaId}`);
  const catalogoRef = db.doc(`catalogo_igrejas/${igrejaId}`);

  const criada = await db.runTransaction(async (tx) => {
    const existente = await tx.get(ref);
    const catalogoExistente = await tx.get(catalogoRef);
    if (existente.exists) {
      throw new HttpsError("already-exists", "Já existe uma unidade com este identificador.");
    }
    if (catalogoExistente.exists) {
      throw new HttpsError(
        "already-exists",
        "Já existe uma entrada de catálogo com este identificador. Nenhuma unidade foi criada."
      );
    }

    const institucionais = extrairInstitucionais(request.data?.dados_institucionais);
    const temAlgumDado = temDadosInstitucionais(institucionais);

    const novaIgreja = {
      nome,
      slug: igrejaId,
      // Unidade nova entra desligada e não configurada, de propósito.
      ativa: false,
      configurada: temAlgumDado,
      dados_institucionais: institucionais,
      mercado_pago_status: "nao_configurado",
      criado_em: FieldValue.serverTimestamp(),
      atualizado_em: FieldValue.serverTimestamp(),
      criado_por: chamador.uid,
    };

    tx.set(ref, novaIgreja);
    tx.set(catalogoRef, projetarCatalogoPublico(novaIgreja));
    writeAuditLogTx(tx, {
      igrejaId,
      acao: "criar_igreja",
      autorUid: chamador.uid,
      autorSuperAdmin: true,
      depois: { nome, ativa: false, configurada: temAlgumDado },
    });

    return { igrejaId, nome };
  });

  return { ok: true, ...criada };
});

export const atualizarIgreja = onCall(opcoes, async (request) => {
  const ctx = await requireChurchPastor(request, request.data?.igrejaId);
  const ref = db.doc(`igrejas/${ctx.igrejaId}`);
  const catalogoRef = db.doc(`catalogo_igrejas/${ctx.igrejaId}`);

  // Ativar/desativar uma unidade é decisão de rede, não da própria unidade.
  const querAlterarAtiva = request.data?.ativa !== undefined;
  if (querAlterarAtiva && !ctx.isSuperAdmin) {
    throw new HttpsError(
      "permission-denied",
      "Ativar ou desativar uma unidade exige o superadministrador."
    );
  }

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Unidade não encontrada.");
    }
    const antes = snap.data() ?? {};

    const institucionais = extrairInstitucionais(request.data?.dados_institucionais);
    const mesclados = mesclarInstitucionais(
      antes.dados_institucionais,
      request.data?.dados_institucionais
    );
    const temAlgumDado = temDadosInstitucionais(mesclados);

    const alteracoes: Record<string, unknown> = {
      dados_institucionais: mesclados,
      configurada: temAlgumDado,
      atualizado_em: FieldValue.serverTimestamp(),
      atualizado_por: ctx.uid,
    };
    if (request.data?.nome !== undefined) {
      alteracoes.nome = exigirNome(request.data?.nome);
    }
    if (querAlterarAtiva) {
      alteracoes.ativa = request.data?.ativa === true;
    }

    const depois = {
      ...antes,
      ...alteracoes,
      dados_institucionais: mesclados,
    };

    tx.update(ref, alteracoes);
    // `set` sem merge substitui qualquer documento antigo e mantém somente a
    // projeção pública explicitamente permitida.
    tx.set(catalogoRef, projetarCatalogoPublico(depois));
    writeAuditLogTx(tx, {
      igrejaId: ctx.igrejaId,
      acao: "atualizar_igreja",
      autorUid: ctx.uid,
      autorSuperAdmin: ctx.isSuperAdmin,
      detalhes: { campos: Object.keys(institucionais) },
    });
  });

  return { ok: true, igrejaId: ctx.igrejaId };
});
