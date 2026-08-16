/**
 * Operações de vínculo e ciclo de vida da liderança.
 *
 * Todas: autorização server-side, transação, motivo quando aplicável e
 * auditoria. NENHUMA apaga documento — saída é rebaixamento ou inativação,
 * preservando o histórico.
 */
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { FieldValue, REGIAO, db, type Transaction } from "../firebase";
import { writeAuditLogTx } from "../audit/audit";
import {
  assertPodeAlterarVinculo,
  requireChurchMemberApprover,
  requireChurchPastor,
  requireMotivo,
  requireUidAlvo,
  type ContextoIgreja,
} from "../authorization/guards";
import {
  FUNCOES_ADMIN,
  LIDERANCA_MINISTERIAL,
  lerFuncoes,
  lerPerfil,
  lerStatus,
  type FuncaoAdmin,
  type PerfilComunitario,
  type VinculoIgreja,
} from "../dominio/tipos";

const opcoes = { region: REGIAO } as const;

function refVinculo(igrejaId: string, uid: string) {
  return db.doc(`igrejas/${igrejaId}/membros/${uid}`);
}

/** Lê o vínculo do alvo dentro da transação, garantindo que ele existe. */
async function lerAlvoTx(
  tx: Transaction,
  igrejaId: string,
  uid: string
): Promise<VinculoIgreja> {
  const snap = await tx.get(refVinculo(igrejaId, uid));
  if (!snap.exists) {
    throw new HttpsError("not-found", "Esta pessoa não possui vínculo com a unidade.");
  }
  const dados = snap.data() ?? {};
  return {
    uid,
    igrejaId,
    status: lerStatus(dados.status),
    perfil: lerPerfil(dados.perfil),
    funcoesAdmin: lerFuncoes(dados.funcoes_admin),
  };
}

function instantanea(v: VinculoIgreja) {
  return { perfil: v.perfil, status: v.status, funcoes_admin: v.funcoesAdmin };
}

// ══════════════════════════════════════════════════════════════════════
// Aprovação de cadastros
// ══════════════════════════════════════════════════════════════════════

export const aprovarMembro = onCall(opcoes, async (request) => {
  const alvoUid = requireUidAlvo(request.data?.uid);
  const ctx = await requireChurchMemberApprover(request, request.data?.igrejaId);

  await db.runTransaction(async (tx) => {
    const alvo = await lerAlvoTx(tx, ctx.igrejaId, alvoUid);

    if (alvo.status === "aprovado") {
      throw new HttpsError("failed-precondition", "Este vínculo já está aprovado.");
    }
    // Reativar alguém que foi desvinculado é ato de liderança, não de aprovação.
    if (alvo.status === "inativo") {
      assertPodeAlterarVinculo(ctx, alvo);
    }

    tx.update(refVinculo(ctx.igrejaId, alvoUid), {
      status: "aprovado",
      aprovado_por: ctx.uid,
      aprovado_em: FieldValue.serverTimestamp(),
      atualizado_por: ctx.uid,
      atualizado_em: FieldValue.serverTimestamp(),
    });

    writeAuditLogTx(tx, {
      igrejaId: ctx.igrejaId,
      acao: "aprovar_membro",
      autorUid: ctx.uid,
      autorSuperAdmin: ctx.isSuperAdmin,
      alvoUid,
      antes: instantanea(alvo),
      depois: { ...instantanea(alvo), status: "aprovado" },
    });
  });

  return { ok: true, igrejaId: ctx.igrejaId, uid: alvoUid, status: "aprovado" };
});

export const recusarMembro = onCall(opcoes, async (request) => {
  const alvoUid = requireUidAlvo(request.data?.uid);
  const motivo = requireMotivo(request.data?.motivo);
  const ctx = await requireChurchMemberApprover(request, request.data?.igrejaId);

  await db.runTransaction(async (tx) => {
    const alvo = await lerAlvoTx(tx, ctx.igrejaId, alvoUid);

    // Recusar um cadastro pendente é ato de liderança comum. Inativar quem já
    // é liderança aprovada exige pastor/super_admin.
    if (alvo.status === "aprovado" && LIDERANCA_MINISTERIAL.includes(alvo.perfil)) {
      assertPodeAlterarVinculo(ctx, alvo);
    }

    tx.update(refVinculo(ctx.igrejaId, alvoUid), {
      status: "inativo",
      motivo_status: motivo,
      atualizado_por: ctx.uid,
      atualizado_em: FieldValue.serverTimestamp(),
    });

    writeAuditLogTx(tx, {
      igrejaId: ctx.igrejaId,
      acao: "recusar_membro",
      autorUid: ctx.uid,
      autorSuperAdmin: ctx.isSuperAdmin,
      alvoUid,
      motivo,
      antes: instantanea(alvo),
      depois: { ...instantanea(alvo), status: "inativo" },
    });
  });

  return { ok: true, igrejaId: ctx.igrejaId, uid: alvoUid, status: "inativo" };
});

// ══════════════════════════════════════════════════════════════════════
// Ciclo de vida da liderança — pastor da unidade ou super_admin
// ══════════════════════════════════════════════════════════════════════

export const promoverParaLideranca = onCall(opcoes, async (request) => {
  const alvoUid = requireUidAlvo(request.data?.uid);
  const novoPerfil = lerPerfil(request.data?.perfil);

  if (!LIDERANCA_MINISTERIAL.includes(novoPerfil)) {
    throw new HttpsError(
      "invalid-argument",
      "Perfil de liderança inválido. Use pastor, diacono, evangelista ou lider."
    );
  }

  const ctx = await requireChurchPastor(request, request.data?.igrejaId);

  // Promover alguém a PASTOR é troca de pastor: exige super_admin.
  if (novoPerfil === "pastor" && !ctx.isSuperAdmin) {
    throw new HttpsError(
      "permission-denied",
      "Definir um novo pastor exige o superadministrador."
    );
  }

  await db.runTransaction(async (tx) => {
    const alvo = await lerAlvoTx(tx, ctx.igrejaId, alvoUid);
    assertPodeAlterarVinculo(ctx, alvo);

    if (alvo.status !== "aprovado") {
      throw new HttpsError(
        "failed-precondition",
        "Só é possível promover alguém com vínculo aprovado."
      );
    }
    if (alvo.perfil === novoPerfil) {
      throw new HttpsError("failed-precondition", "A pessoa já possui este perfil.");
    }

    const funcoes = new Set<FuncaoAdmin>(alvo.funcoesAdmin);
    if (novoPerfil === "pastor") funcoes.add("pastor");

    tx.update(refVinculo(ctx.igrejaId, alvoUid), {
      perfil: novoPerfil,
      funcoes_admin: [...funcoes].sort(),
      atualizado_por: ctx.uid,
      atualizado_em: FieldValue.serverTimestamp(),
    });

    writeAuditLogTx(tx, {
      igrejaId: ctx.igrejaId,
      acao: "promover_para_lideranca",
      autorUid: ctx.uid,
      autorSuperAdmin: ctx.isSuperAdmin,
      alvoUid,
      antes: instantanea(alvo),
      depois: { perfil: novoPerfil, status: alvo.status, funcoes_admin: [...funcoes].sort() },
    });
  });

  return { ok: true, igrejaId: ctx.igrejaId, uid: alvoUid, perfil: novoPerfil };
});

/**
 * Rebaixa para `membro`, removendo funções administrativas de liderança.
 * O VÍNCULO CONTINUA APROVADO e todo o histórico é preservado.
 */
export const removerDaLideranca = onCall(opcoes, async (request) => {
  const alvoUid = requireUidAlvo(request.data?.uid);
  const motivo = requireMotivo(request.data?.motivo);
  const ctx = await requireChurchPastor(request, request.data?.igrejaId);

  await db.runTransaction(async (tx) => {
    const alvo = await lerAlvoTx(tx, ctx.igrejaId, alvoUid);
    assertPodeAlterarVinculo(ctx, alvo);

    if (!LIDERANCA_MINISTERIAL.includes(alvo.perfil)) {
      throw new HttpsError("failed-precondition", "Esta pessoa não faz parte da liderança.");
    }

    // Mantém funções não-ministeriais (ex.: tesoureiro segue tesoureiro).
    const funcoes = alvo.funcoesAdmin.filter((f) => f !== "pastor");

    tx.update(refVinculo(ctx.igrejaId, alvoUid), {
      perfil: "membro" satisfies PerfilComunitario,
      funcoes_admin: funcoes,
      motivo_status: motivo,
      atualizado_por: ctx.uid,
      atualizado_em: FieldValue.serverTimestamp(),
    });

    writeAuditLogTx(tx, {
      igrejaId: ctx.igrejaId,
      acao: "remover_da_lideranca",
      autorUid: ctx.uid,
      autorSuperAdmin: ctx.isSuperAdmin,
      alvoUid,
      motivo,
      antes: instantanea(alvo),
      depois: { perfil: "membro", status: alvo.status, funcoes_admin: funcoes },
    });
  });

  return { ok: true, igrejaId: ctx.igrejaId, uid: alvoUid, perfil: "membro" };
});

/**
 * Inativa o vínculo e revoga todas as funções administrativas.
 * O documento é PRESERVADO — nada de exclusão física.
 */
export const desvincularDaIgreja = onCall(opcoes, async (request) => {
  const alvoUid = requireUidAlvo(request.data?.uid);
  const motivo = requireMotivo(request.data?.motivo);
  const ctx = await requireChurchPastor(request, request.data?.igrejaId);

  await db.runTransaction(async (tx) => {
    const alvo = await lerAlvoTx(tx, ctx.igrejaId, alvoUid);
    assertPodeAlterarVinculo(ctx, alvo);

    if (alvo.status === "inativo") {
      throw new HttpsError("failed-precondition", "Este vínculo já está inativo.");
    }

    tx.update(refVinculo(ctx.igrejaId, alvoUid), {
      status: "inativo",
      funcoes_admin: [],
      motivo_status: motivo,
      atualizado_por: ctx.uid,
      atualizado_em: FieldValue.serverTimestamp(),
    });

    writeAuditLogTx(tx, {
      igrejaId: ctx.igrejaId,
      acao: "desvincular_da_igreja",
      autorUid: ctx.uid,
      autorSuperAdmin: ctx.isSuperAdmin,
      alvoUid,
      motivo,
      antes: instantanea(alvo),
      depois: { perfil: alvo.perfil, status: "inativo", funcoes_admin: [] },
    });
  });

  return { ok: true, igrejaId: ctx.igrejaId, uid: alvoUid, status: "inativo" };
});

// ══════════════════════════════════════════════════════════════════════
// Funções administrativas
// ══════════════════════════════════════════════════════════════════════

function validarFuncao(bruto: unknown): FuncaoAdmin {
  const [funcao] = lerFuncoes([bruto]);
  if (!funcao) {
    throw new HttpsError(
      "invalid-argument",
      `Função inválida. Use uma de: ${FUNCOES_ADMIN.join(", ")}.`
    );
  }
  return funcao;
}

export const atribuirFuncaoAdmin = onCall(opcoes, async (request) => {
  const alvoUid = requireUidAlvo(request.data?.uid);
  const funcao = validarFuncao(request.data?.funcao);
  const ctx = await requireChurchPastor(request, request.data?.igrejaId);

  // A função `pastor` acompanha o perfil de pastor — não é concedida avulsa.
  if (funcao === "pastor") {
    throw new HttpsError(
      "invalid-argument",
      "A função de pastor é definida pela promoção de perfil, não avulsa."
    );
  }

  await db.runTransaction(async (tx) => {
    const alvo = await lerAlvoTx(tx, ctx.igrejaId, alvoUid);
    assertPodeAlterarVinculo(ctx, alvo);

    if (alvo.status !== "aprovado") {
      throw new HttpsError(
        "failed-precondition",
        "Só é possível atribuir função a quem tem vínculo aprovado."
      );
    }
    if (alvo.funcoesAdmin.includes(funcao)) {
      throw new HttpsError("failed-precondition", "A pessoa já possui esta função.");
    }

    const funcoes = [...alvo.funcoesAdmin, funcao].sort();
    tx.update(refVinculo(ctx.igrejaId, alvoUid), {
      funcoes_admin: funcoes,
      atualizado_por: ctx.uid,
      atualizado_em: FieldValue.serverTimestamp(),
    });

    writeAuditLogTx(tx, {
      igrejaId: ctx.igrejaId,
      acao: "atribuir_funcao_admin",
      autorUid: ctx.uid,
      autorSuperAdmin: ctx.isSuperAdmin,
      alvoUid,
      antes: instantanea(alvo),
      depois: { ...instantanea(alvo), funcoes_admin: funcoes },
      detalhes: { funcao },
    });
  });

  return { ok: true, igrejaId: ctx.igrejaId, uid: alvoUid, funcao };
});

export const removerFuncaoAdmin = onCall(opcoes, async (request) => {
  const alvoUid = requireUidAlvo(request.data?.uid);
  const funcao = validarFuncao(request.data?.funcao);
  const motivo = requireMotivo(request.data?.motivo);
  const ctx = await requireChurchPastor(request, request.data?.igrejaId);

  await db.runTransaction(async (tx) => {
    const alvo = await lerAlvoTx(tx, ctx.igrejaId, alvoUid);
    assertPodeAlterarVinculo(ctx, alvo);

    if (!alvo.funcoesAdmin.includes(funcao)) {
      throw new HttpsError("failed-precondition", "A pessoa não possui esta função.");
    }

    const funcoes = alvo.funcoesAdmin.filter((f) => f !== funcao);
    tx.update(refVinculo(ctx.igrejaId, alvoUid), {
      funcoes_admin: funcoes,
      atualizado_por: ctx.uid,
      atualizado_em: FieldValue.serverTimestamp(),
    });

    writeAuditLogTx(tx, {
      igrejaId: ctx.igrejaId,
      acao: "remover_funcao_admin",
      autorUid: ctx.uid,
      autorSuperAdmin: ctx.isSuperAdmin,
      alvoUid,
      motivo,
      antes: instantanea(alvo),
      depois: { ...instantanea(alvo), funcoes_admin: funcoes },
      detalhes: { funcao },
    });
  });

  return { ok: true, igrejaId: ctx.igrejaId, uid: alvoUid, funcao };
});

/** Reexportado para uso interno/testes. */
export type { ContextoIgreja };
