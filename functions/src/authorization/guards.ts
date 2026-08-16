/**
 * Helpers de autorização server-side.
 *
 * O Admin SDK IGNORA as Firestore Rules. Toda Function precisa repetir a
 * autorização aqui antes de ler ou alterar qualquer coisa.
 */
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { db } from "../firebase";
import {
  canApproveMember,
  canManageLeadership,
  canReadFinance,
  isPastor,
  lerFuncoes,
  lerPerfil,
  lerStatus,
  podeAcessarPainel,
  validarIgrejaId,
  type FuncaoAdmin,
  type VinculoIgreja,
} from "../dominio/tipos";

export interface Chamador {
  uid: string;
  isSuperAdmin: boolean;
}

/** Exige sessão autenticada. */
export function requireSignedIn(request: CallableRequest): Chamador {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Faça login para continuar.");
  }
  // Custom claim — nunca lida de documento gravável pelo cliente.
  const isSuperAdmin = request.auth?.token?.super_admin === true;
  return { uid, isSuperAdmin };
}

export function requireSuperAdmin(request: CallableRequest): Chamador {
  const chamador = requireSignedIn(request);
  if (!chamador.isSuperAdmin) {
    throw new HttpsError("permission-denied", "Operação restrita ao superadministrador.");
  }
  return chamador;
}

/** Lê o vínculo de um uid numa unidade. `null` quando não existe. */
export async function lerVinculo(
  igrejaId: string,
  uid: string
): Promise<VinculoIgreja | null> {
  const snap = await db.doc(`igrejas/${igrejaId}/membros/${uid}`).get();
  if (!snap.exists) return null;
  const dados = snap.data() ?? {};
  return {
    uid,
    igrejaId,
    status: lerStatus(dados.status),
    perfil: lerPerfil(dados.perfil),
    funcoesAdmin: lerFuncoes(dados.funcoes_admin),
  };
}

/** Garante que a unidade existe; devolve o id validado. */
export async function requireIgrejaExistente(bruto: unknown): Promise<string> {
  let igrejaId: string;
  try {
    igrejaId = validarIgrejaId(bruto);
  } catch {
    throw new HttpsError("invalid-argument", "Unidade inválida.");
  }
  const snap = await db.doc(`igrejas/${igrejaId}`).get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Unidade não encontrada.");
  }
  return igrejaId;
}

export interface ContextoIgreja extends Chamador {
  igrejaId: string;
  vinculo: VinculoIgreja | null;
}

async function contexto(
  request: CallableRequest,
  igrejaIdBruto: unknown
): Promise<ContextoIgreja> {
  const chamador = requireSignedIn(request);
  const igrejaId = await requireIgrejaExistente(igrejaIdBruto);
  const vinculo = await lerVinculo(igrejaId, chamador.uid);
  return { ...chamador, igrejaId, vinculo };
}

/** Acesso ao painel da unidade (qualquer função administrativa). */
export async function requireChurchAccess(
  request: CallableRequest,
  igrejaIdBruto: unknown
): Promise<ContextoIgreja> {
  const ctx = await contexto(request, igrejaIdBruto);
  if (!podeAcessarPainel(ctx.vinculo, ctx.isSuperAdmin)) {
    throw new HttpsError("permission-denied", "Sem acesso administrativo a esta unidade.");
  }
  return ctx;
}

/** Aprovar/recusar membros comuns. */
export async function requireChurchMemberApprover(
  request: CallableRequest,
  igrejaIdBruto: unknown
): Promise<ContextoIgreja> {
  const ctx = await contexto(request, igrejaIdBruto);
  if (!canApproveMember(ctx.vinculo, ctx.isSuperAdmin)) {
    throw new HttpsError("permission-denied", "Somente a liderança aprova cadastros.");
  }
  return ctx;
}

/** Gestão do ciclo de vida da liderança: pastor da unidade ou super_admin. */
export async function requireChurchPastor(
  request: CallableRequest,
  igrejaIdBruto: unknown
): Promise<ContextoIgreja> {
  const ctx = await contexto(request, igrejaIdBruto);
  if (!canManageLeadership(ctx.vinculo, ctx.isSuperAdmin)) {
    throw new HttpsError(
      "permission-denied",
      "Somente o pastor da unidade ou o superadministrador pode gerir a liderança."
    );
  }
  return ctx;
}

export async function requireChurchFinance(
  request: CallableRequest,
  igrejaIdBruto: unknown
): Promise<ContextoIgreja> {
  const ctx = await contexto(request, igrejaIdBruto);
  if (!canReadFinance(ctx.vinculo, ctx.isSuperAdmin)) {
    throw new HttpsError("permission-denied", "Sem acesso financeiro nesta unidade.");
  }
  return ctx;
}

export async function requireChurchCapability(
  request: CallableRequest,
  igrejaIdBruto: unknown,
  funcao: FuncaoAdmin
): Promise<ContextoIgreja> {
  const ctx = await contexto(request, igrejaIdBruto);
  const permitido =
    ctx.isSuperAdmin ||
    (ctx.vinculo?.status === "aprovado" && ctx.vinculo.funcoesAdmin.includes(funcao));
  if (!permitido) {
    throw new HttpsError("permission-denied", `Requer a função ${funcao} nesta unidade.`);
  }
  return ctx;
}

/**
 * Regras do ciclo de vida da liderança, além de exigir pastor/super_admin:
 * - pastor não age sobre si mesmo;
 * - pastor não age sobre outro pastor (troca de pastor exige super_admin).
 */
export function assertPodeAlterarVinculo(
  ctx: ContextoIgreja,
  alvo: VinculoIgreja
): void {
  if (ctx.isSuperAdmin) return;

  if (!isPastor(ctx.vinculo)) {
    throw new HttpsError(
      "permission-denied",
      "Somente o pastor da unidade ou o superadministrador pode alterar a liderança."
    );
  }
  if (alvo.uid === ctx.uid) {
    throw new HttpsError(
      "permission-denied",
      "Um pastor não pode alterar o próprio vínculo. Solicite ao superadministrador."
    );
  }
  if (alvo.perfil === "pastor") {
    throw new HttpsError(
      "permission-denied",
      "Alterar o vínculo de um pastor exige o superadministrador."
    );
  }
}

/** Motivo obrigatório para rebaixamento/inativação. */
export function requireMotivo(bruto: unknown): string {
  const motivo = String(bruto ?? "").trim();
  if (motivo.length < 5) {
    throw new HttpsError(
      "invalid-argument",
      "Informe o motivo da alteração (mínimo de 5 caracteres)."
    );
  }
  if (motivo.length > 500) {
    throw new HttpsError("invalid-argument", "Motivo muito longo (máximo de 500 caracteres).");
  }
  return motivo;
}

export function requireUidAlvo(bruto: unknown): string {
  const uid = String(bruto ?? "").trim();
  if (!uid || uid.length > 128) {
    throw new HttpsError("invalid-argument", "Usuário alvo inválido.");
  }
  return uid;
}
