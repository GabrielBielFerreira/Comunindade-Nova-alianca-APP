/**
 * Cadastro e configuração de unidades.
 *
 * `criarIgreja` é exclusiva do super_admin. `atualizarIgreja` aceita o pastor
 * da própria unidade. Unidade nova nasce INATIVA e NÃO CONFIGURADA — nada é
 * inventado para preencher a demonstração.
 */
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { FieldValue, REGIAO, db } from "../firebase";
import { writeAuditLog } from "../audit/audit";
import { requireChurchPastor, requireSuperAdmin } from "../authorization/guards";
import { validarIgrejaId } from "../dominio/tipos";

const opcoes = { region: REGIAO } as const;

/** Campos institucionais editáveis. Ausência = "não configurado". */
const CAMPOS_INSTITUCIONAIS = [
  "pastor_responsavel",
  "endereco",
  "cidade_estado",
  "cep",
  "telefone",
  "instagram",
  "pix_chave",
  "pix_tipo",
] as const;

function extrairInstitucionais(bruto: unknown): Record<string, string | null> {
  const entrada = (bruto ?? {}) as Record<string, unknown>;
  const saida: Record<string, string | null> = {};
  for (const campo of CAMPOS_INSTITUCIONAIS) {
    const valor = entrada[campo];
    if (valor === undefined) continue;
    const texto = String(valor ?? "").trim();
    saida[campo] = texto.length > 0 ? texto : null;
  }
  return saida;
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

  const criada = await db.runTransaction(async (tx) => {
    const existente = await tx.get(ref);
    if (existente.exists) {
      throw new HttpsError("already-exists", "Já existe uma unidade com este identificador.");
    }

    const institucionais = extrairInstitucionais(request.data?.dados_institucionais);
    const temAlgumDado = Object.values(institucionais).some((v) => v !== null);

    tx.set(ref, {
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
    });

    return { igrejaId, nome };
  });

  await writeAuditLog({
    igrejaId,
    acao: "criar_igreja",
    autorUid: chamador.uid,
    autorSuperAdmin: true,
    depois: { nome, ativa: false, configurada: false },
  });

  return { ok: true, ...criada };
});

export const atualizarIgreja = onCall(opcoes, async (request) => {
  const ctx = await requireChurchPastor(request, request.data?.igrejaId);
  const ref = db.doc(`igrejas/${ctx.igrejaId}`);

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
    const mesclados = {
      ...((antes.dados_institucionais as Record<string, unknown>) ?? {}),
      ...institucionais,
    };
    const temAlgumDado = Object.values(mesclados).some(
      (v) => v !== null && v !== undefined && String(v).trim() !== ""
    );

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

    tx.update(ref, alteracoes);
  });

  await writeAuditLog({
    igrejaId: ctx.igrejaId,
    acao: "atualizar_igreja",
    autorUid: ctx.uid,
    autorSuperAdmin: ctx.isSuperAdmin,
    detalhes: { campos: Object.keys(extrairInstitucionais(request.data?.dados_institucionais)) },
  });

  return { ok: true, igrejaId: ctx.igrejaId };
});
