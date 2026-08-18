/**
 * Transferência OFICIAL de vínculo entre unidades da rede.
 *
 * Não confundir com a troca de igreja VISUALIZADA no aplicativo: aquela é
 * preferência local de leitura e não altera nada no servidor. Esta operação
 * move onde a pessoa é MEMBRO — `usuarios/{uid}.igreja_principal_id` e o
 * vínculo `/igrejas/{id}/membros/{uid}` das duas unidades.
 *
 * Regras que a operação garante:
 * - exclusiva do `super_admin` (custom claim), nunca do pastor da unidade;
 * - atômica: as duas igrejas e o perfil global mudam na mesma transação;
 * - preserva o documento e o histórico da origem — nada é apagado;
 * - NÃO transporta perfil ministerial nem função administrativa;
 * - idempotente: repetir a chamada não gera segundo efeito nem segunda
 *   auditoria;
 * - auditada nas DUAS unidades, com autor, motivo e estado antes/depois.
 */
import { HttpsError, onCall, type CallableRequest } from "firebase-functions/v2/https";
import { FieldValue, REGIAO, db, type Transaction } from "../firebase";
import { writeAuditLogTx } from "../audit/audit";
import {
  requireIgrejaExistente,
  requireMotivo,
  requireSuperAdmin,
  requireUidAlvo,
} from "../authorization/guards";
import {
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

function refUsuario(uid: string) {
  return db.doc(`usuarios/${uid}`);
}

/** Converte o documento cru num vínculo; `null` quando não existe. */
function paraVinculo(
  igrejaId: string,
  uid: string,
  dados: Record<string, unknown> | undefined
): VinculoIgreja | null {
  if (!dados) return null;
  return {
    uid,
    igrejaId,
    status: lerStatus(dados.status),
    perfil: lerPerfil(dados.perfil),
    funcoesAdmin: lerFuncoes(dados.funcoes_admin),
  };
}

function instantanea(v: VinculoIgreja | null): Record<string, unknown> {
  if (v === null) return { status: "sem_vinculo" };
  return { perfil: v.perfil, status: v.status, funcoes_admin: v.funcoesAdmin };
}

export interface ResultadoTransferencia {
  ok: true;
  uid: string;
  origem: string;
  destino: string;
  /** `true` quando o estado final já estava aplicado e nada foi reescrito. */
  jaAplicada: boolean;
  /** Perfil com que a pessoa passa a existir no destino. */
  perfilDestino: PerfilComunitario;
}

/**
 * Handler exportado separadamente do `onCall` para que os testes possam
 * exercitá-lo com um `CallableRequest` montado à mão — inclusive os casos de
 * chamador sem `super_admin`, que precisam passar pelo guard real.
 */
export async function transferirVinculoIgrejaHandler(
  request: CallableRequest
): Promise<ResultadoTransferencia> {
  const chamador = requireSuperAdmin(request);
  const alvoUid = requireUidAlvo(request.data?.uid);
  const motivo = requireMotivo(request.data?.motivo);

  const origemId = await requireIgrejaExistente(request.data?.igrejaOrigemId);
  const destinoId = await requireIgrejaExistente(request.data?.igrejaDestinoId);

  if (origemId === destinoId) {
    throw new HttpsError(
      "invalid-argument",
      "A unidade de origem e a de destino precisam ser diferentes."
    );
  }

  // A saída de um pastor esvazia a liderança da unidade. Não é proibida, mas
  // exige confirmação explícita de quem chama — nunca acontece por descuido.
  const confirmarSaidaDePastor = request.data?.confirmarSaidaDePastor === true;

  return db.runTransaction(async (tx: Transaction) => {
    // ── Leituras (todas antes de qualquer escrita) ────────────────────
    const [origemSnap, destinoSnap, usuarioSnap] = await Promise.all([
      tx.get(refVinculo(origemId, alvoUid)),
      tx.get(refVinculo(destinoId, alvoUid)),
      tx.get(refUsuario(alvoUid)),
    ]);

    const origem = paraVinculo(origemId, alvoUid, origemSnap.data());
    const destino = paraVinculo(destinoId, alvoUid, destinoSnap.data());
    const usuario = usuarioSnap.data() ?? {};
    const principalAtual = (usuario.igreja_principal_id as string | null) ?? null;

    // ── Idempotência ──────────────────────────────────────────────────
    // Estado final já aplicado: devolve sucesso sem reescrever nem duplicar
    // auditoria. Uma chamada repetida (duplo clique, retry de rede) é inócua.
    const jaAplicada =
      origem !== null &&
      origem.status === "inativo" &&
      destino !== null &&
      destino.status === "aprovado" &&
      principalAtual === destinoId;

    if (jaAplicada) {
      return {
        ok: true as const,
        uid: alvoUid,
        origem: origemId,
        destino: destinoId,
        jaAplicada: true,
        perfilDestino: destino.perfil,
      };
    }

    // ── Validações do estado de origem ────────────────────────────────
    if (origem === null) {
      throw new HttpsError(
        "not-found",
        "Esta pessoa não possui vínculo com a unidade de origem."
      );
    }
    if (origem.status === "inativo") {
      throw new HttpsError(
        "failed-precondition",
        "O vínculo de origem já está inativo. Reative-o antes de transferir."
      );
    }
    if (origem.status !== "aprovado") {
      throw new HttpsError(
        "failed-precondition",
        "Só é possível transferir um vínculo aprovado. Aprove ou recuse o cadastro primeiro."
      );
    }

    if (origem.perfil === "pastor" && !confirmarSaidaDePastor) {
      // Leitura extra ainda dentro da fase de leitura da transação.
      const pastores = await tx.get(
        db
          .collection(`igrejas/${origemId}/membros`)
          .where("status", "==", "aprovado")
          .where("perfil", "==", "pastor")
      );
      const ultimo = pastores.size <= 1;
      throw new HttpsError(
        "failed-precondition",
        ultimo
          ? "Esta pessoa é o único pastor aprovado da unidade de origem. Confirme " +
              "explicitamente a transferência (confirmarSaidaDePastor), ciente de que " +
              "a unidade ficará sem pastor."
          : "Transferir um pastor exige confirmação explícita (confirmarSaidaDePastor)."
      );
    }

    // ── Destino ───────────────────────────────────────────────────────
    // Um vínculo de destino JÁ APROVADO mantém o perfil e as funções que ele
    // próprio já tinha naquela unidade — rebaixá-lo seria destruir uma
    // permissão legítima que nada tem a ver com a origem. Vínculo novo,
    // pendente ou inativo entra (ou volta) como membro comum e sem função:
    // é assim que nenhum cargo atravessa a fronteira entre as igrejas.
    const destinoJaAprovado = destino !== null && destino.status === "aprovado";
    const perfilDestino: PerfilComunitario = destinoJaAprovado ? destino.perfil : "membro";
    const funcoesDestino: FuncaoAdmin[] = destinoJaAprovado ? destino.funcoesAdmin : [];

    const dadosOrigem = origemSnap.data() ?? {};
    const dadosDestino = destinoSnap.data() ?? {};

    // Identificação segue a pessoa para que a lista do painel de destino não
    // mostre um uid cru. Não sobrescreve o que o destino já tiver.
    const identificacao: Record<string, unknown> = {};
    for (const campo of ["nome", "email"] as const) {
      const jaTem = dadosDestino[campo];
      const veioDaOrigem = dadosOrigem[campo];
      if (
        (jaTem === undefined || jaTem === null || jaTem === "") &&
        typeof veioDaOrigem === "string" &&
        veioDaOrigem.trim() !== ""
      ) {
        identificacao[campo] = veioDaOrigem;
      }
    }

    // ── Escritas ──────────────────────────────────────────────────────
    tx.set(
      refVinculo(destinoId, alvoUid),
      {
        ...identificacao,
        status: "aprovado",
        perfil: perfilDestino,
        funcoes_admin: funcoesDestino,
        // Ministérios são da unidade de origem e não acompanham a pessoa.
        ministerio_ids: destinoSnap.exists ? (dadosDestino.ministerio_ids ?? []) : [],
        transferido_de: origemId,
        transferido_em: FieldValue.serverTimestamp(),
        motivo_status: motivo,
        aprovado_por: chamador.uid,
        aprovado_em: FieldValue.serverTimestamp(),
        atualizado_por: chamador.uid,
        atualizado_em: FieldValue.serverTimestamp(),
        ...(destinoSnap.exists ? {} : { criado_em: FieldValue.serverTimestamp() }),
      },
      { merge: true }
    );

    // Origem: documento PRESERVADO. O perfil histórico continua registrado —
    // ele não concede nada com o status inativo — e as funções
    // administrativas são revogadas.
    tx.update(refVinculo(origemId, alvoUid), {
      status: "inativo",
      funcoes_admin: [],
      motivo_status: motivo,
      transferido_para: destinoId,
      transferido_em: FieldValue.serverTimestamp(),
      atualizado_por: chamador.uid,
      atualizado_em: FieldValue.serverTimestamp(),
    });

    // Perfil global: é isto que define onde a pessoa é membro.
    tx.set(
      refUsuario(alvoUid),
      {
        igreja_principal_id: destinoId,
        atualizado_em: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // ── Auditoria nas DUAS unidades ───────────────────────────────────
    const detalhes = {
      origem: origemId,
      destino: destinoId,
      igreja_principal_anterior: principalAtual,
      igreja_principal_nova: destinoId,
      funcoes_revogadas_na_origem: origem.funcoesAdmin,
      perfil_historico_na_origem: origem.perfil,
    };

    writeAuditLogTx(tx, {
      igrejaId: origemId,
      acao: "transferir_vinculo_igreja",
      autorUid: chamador.uid,
      autorSuperAdmin: true,
      alvoUid,
      motivo,
      antes: instantanea(origem),
      depois: { perfil: origem.perfil, status: "inativo", funcoes_admin: [] },
      detalhes,
    });

    writeAuditLogTx(tx, {
      igrejaId: destinoId,
      acao: "transferir_vinculo_igreja",
      autorUid: chamador.uid,
      autorSuperAdmin: true,
      alvoUid,
      motivo,
      antes: instantanea(destino),
      depois: {
        perfil: perfilDestino,
        status: "aprovado",
        funcoes_admin: funcoesDestino,
      },
      detalhes,
    });

    return {
      ok: true as const,
      uid: alvoUid,
      origem: origemId,
      destino: destinoId,
      jaAplicada: false,
      perfilDestino,
    };
  });
}

export const transferirVinculoIgreja = onCall(opcoes, transferirVinculoIgrejaHandler);
