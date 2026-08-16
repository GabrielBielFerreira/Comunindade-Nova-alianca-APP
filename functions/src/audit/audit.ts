/**
 * Auditoria — gravada EXCLUSIVAMENTE pelo Admin SDK.
 *
 * As Rules negam create/update/delete de auditoria a qualquer cliente, então
 * este é o único caminho por onde um registro entra. Auditoria nunca é
 * apagada nem editada.
 */
import { FieldValue, db, type Transaction } from "../firebase";

export type AcaoAuditavel =
  | "aprovar_membro"
  | "recusar_membro"
  | "promover_para_lideranca"
  | "remover_da_lideranca"
  | "desvincular_da_igreja"
  | "atribuir_funcao_admin"
  | "remover_funcao_admin"
  | "criar_igreja"
  | "atualizar_igreja";

export interface RegistroAuditoria {
  igrejaId: string;
  acao: AcaoAuditavel;
  autorUid: string;
  autorSuperAdmin: boolean;
  alvoUid?: string;
  motivo?: string;
  /** Estado anterior relevante (perfil, status, funções). */
  antes?: Record<string, unknown>;
  /** Estado posterior relevante. */
  depois?: Record<string, unknown>;
  detalhes?: Record<string, unknown>;
}

function montar(registro: RegistroAuditoria) {
  return {
    acao: registro.acao,
    autor_id: registro.autorUid,
    autor_super_admin: registro.autorSuperAdmin,
    alvo_id: registro.alvoUid ?? null,
    motivo: registro.motivo ?? null,
    antes: registro.antes ?? null,
    depois: registro.depois ?? null,
    detalhes: registro.detalhes ?? null,
    em: FieldValue.serverTimestamp(),
  };
}

/** Grava auditoria dentro de uma transação já aberta. */
export function writeAuditLogTx(tx: Transaction, registro: RegistroAuditoria): void {
  const ref = db.collection(`igrejas/${registro.igrejaId}/auditoria`).doc();
  tx.set(ref, montar(registro));
}

/** Grava auditoria fora de transação. */
export async function writeAuditLog(registro: RegistroAuditoria): Promise<void> {
  const ref = db.collection(`igrejas/${registro.igrejaId}/auditoria`).doc();
  await ref.set(montar(registro));
}
