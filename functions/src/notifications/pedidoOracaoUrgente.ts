/**
 * Push privado para pedidos de oração urgentes.
 *
 * A mensagem nunca carrega o conteúdo do pedido: o documento pode conter
 * dados pastorais sensíveis e o texto do push aparece fora do aplicativo.
 * Os destinatários são derivados do vínculo aprovado NA MESMA unidade; não
 * existe inscrição em tópico público nem confiança em campos do usuário.
 */
import { createHash } from "node:crypto";
import type {
  DocumentReference,
  Firestore,
} from "firebase-admin/firestore";
import {
  getMessaging,
  type MulticastMessage,
} from "firebase-admin/messaging";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { auth, db, FieldValue, REGIAO } from "../firebase";
import {
  LIDERANCA_MINISTERIAL,
  lerPerfil,
  lerStatus,
  validarIgrejaId,
} from "../dominio/tipos";

const TAMANHO_MAXIMO_LOTE_FCM = 500;
const JANELA_NOTIFICACAO_URGENTE_MS = 10 * 60 * 1000;
const PERFIS_LIDERANCA = [...LIDERANCA_MINISTERIAL];
const CODIGOS_TOKEN_INVALIDO = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

export interface RespostaToken {
  success: boolean;
  error?: { code?: string };
}

export interface RespostaMulticast {
  responses: RespostaToken[];
}

export interface DependenciasNotificacaoUrgente {
  firestore: Firestore;
  enviarMulticast: (mensagem: MulticastMessage) => Promise<RespostaMulticast>;
  agoraEmMs?: () => number;
  buscarAutor: (uid: string) => Promise<{
    disabled: boolean;
    providerData: readonly unknown[];
  }>;
}

export interface PedidoUrgenteCriado {
  igrejaId: string;
  pedidoId: string;
  eventId: string;
  dados: Record<string, unknown>;
}

export interface ResultadoNotificacaoUrgente {
  estado:
    | "nao_urgente"
    | "autor_nao_elegivel"
    | "duplicado"
    | "limitado"
    | "sem_destinatarios"
    | "enviado";
  tokensEncontrados: number;
  sucessos: number;
  falhas: number;
  tokensRemovidos: number;
}

interface TokenComReferencias {
  token: string;
  referencias: DocumentReference[];
}

const dependenciasReais: DependenciasNotificacaoUrgente = {
  firestore: db,
  enviarMulticast: (mensagem) => getMessaging().sendEachForMulticast(mensagem),
  buscarAutor: (uid) => auth.getUser(uid),
};

/** Divide sem ultrapassar o limite documentado de 500 tokens por multicast. */
export function dividirEmLotes<T>(itens: readonly T[], tamanho = TAMANHO_MAXIMO_LOTE_FCM): T[][] {
  if (!Number.isInteger(tamanho) || tamanho <= 0) {
    throw new Error("tamanho de lote invalido");
  }
  const lotes: T[][] = [];
  for (let inicio = 0; inicio < itens.length; inicio += tamanho) {
    lotes.push(itens.slice(inicio, inicio + tamanho));
  }
  return lotes;
}

function referenciaProcessamento(
  firestore: Firestore,
  igrejaId: string,
  eventId: string
): DocumentReference {
  // O id do CloudEvent não é usado diretamente como document id: o hash
  // também protege contra qualquer barra ou tamanho inesperado.
  const hash = createHash("sha256").update(eventId).digest("hex");
  return firestore.doc(
    `igrejas/${igrejaId}/processamentos_notificacao_urgente/${hash}`
  );
}

function referenciaLimiteAutor(
  firestore: Firestore,
  igrejaId: string,
  autorId: string
): DocumentReference {
  // Não expõe o uid como document id e mantém exatamente um marcador por
  // autor em cada unidade, independentemente do pedido que originou o push.
  const hashAutor = createHash("sha256").update(autorId).digest("hex");
  return firestore.doc(
    `igrejas/${igrejaId}/limites_notificacao_urgente/${hashAutor}`
  );
}

async function adquirirJanelaDeEnvio(
  firestore: Firestore,
  referencia: DocumentReference,
  agoraEmMs: number
): Promise<boolean> {
  let adquirido = false;
  await firestore.runTransaction(async (transacao) => {
    const existente = await transacao.get(referencia);
    const proximoEnvioEmMs = existente.get("proximo_envio_em_ms");
    if (
      typeof proximoEnvioEmMs === "number" &&
      Number.isFinite(proximoEnvioEmMs) &&
      agoraEmMs < proximoEnvioEmMs
    ) {
      return;
    }

    transacao.set(
      referencia,
      {
        ultimo_envio_em_ms: agoraEmMs,
        proximo_envio_em_ms: agoraEmMs + JANELA_NOTIFICACAO_URGENTE_MS,
        atualizado_em: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    adquirido = true;
  });
  return adquirido;
}

async function adquirirEvento(
  firestore: Firestore,
  referencia: DocumentReference,
  eventId: string,
  pedidoId: string
): Promise<boolean> {
  let adquirido = false;
  await firestore.runTransaction(async (transacao) => {
    const existente = await transacao.get(referencia);
    if (existente.exists && existente.get("status") === "concluido") return;
    if (existente.exists && existente.get("status") === "processando") return;

    transacao.set(
      referencia,
      {
        event_id: eventId,
        pedido_id: pedidoId,
        status: "processando",
        tentativas: FieldValue.increment(1),
        iniciado_em: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    adquirido = true;
  });
  return adquirido;
}

async function concluirEvento(
  referencia: DocumentReference,
  resultado: Omit<ResultadoNotificacaoUrgente, "estado">
): Promise<void> {
  await referencia.set(
    {
      status: "concluido",
      concluido_em: FieldValue.serverTimestamp(),
      tokens_encontrados: resultado.tokensEncontrados,
      sucessos: resultado.sucessos,
      falhas: resultado.falhas,
      tokens_removidos: resultado.tokensRemovidos,
    },
    { merge: true }
  );
}

async function registrarFalha(referencia: DocumentReference): Promise<void> {
  // Não persiste mensagem de exceção: respostas de provedores podem conter
  // detalhes operacionais. Uma nova entrega do mesmo evento pode tentar de
  // novo porque o status deixa de ser "processando".
  await referencia.set(
    {
      status: "falhou",
      falhou_em: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

async function buscarUidsLideranca(
  firestore: Firestore,
  igrejaId: string
): Promise<string[]> {
  // Consultas separadas por perfil evitam exigir um índice composto novo no
  // primeiro deploy. O status é confirmado no servidor antes de incluir uid.
  const consultas = await Promise.all(
    PERFIS_LIDERANCA.map((perfil) =>
      firestore
        .collection(`igrejas/${igrejaId}/membros`)
        .where("perfil", "==", perfil)
        .get()
    )
  );

  const uids = new Set<string>();
  for (const consulta of consultas) {
    for (const documento of consulta.docs) {
      const dados = documento.data();
      if (
        lerStatus(dados.status) === "aprovado" &&
        PERFIS_LIDERANCA.includes(lerPerfil(dados.perfil))
      ) {
        uids.add(documento.id);
      }
    }
  }
  return [...uids].sort();
}

async function buscarTokensAtivos(
  firestore: Firestore,
  uids: readonly string[]
): Promise<TokenComReferencias[]> {
  const porToken = new Map<string, DocumentReference[]>();

  // Limita o fan-out de leituras sem serializar centenas de chamadas.
  for (const loteUids of dividirEmLotes(uids, 20)) {
    const consultas = await Promise.all(
      loteUids.map((uid) =>
        firestore
          .collection(`usuarios/${uid}/tokens_dispositivo`)
          .where("ativo", "==", true)
          .get()
      )
    );
    for (const consulta of consultas) {
      for (const documento of consulta.docs) {
        const token = documento.get("token");
        if (typeof token !== "string" || token.trim().length === 0) continue;
        const normalizado = token.trim();
        const referencias = porToken.get(normalizado) ?? [];
        referencias.push(documento.ref);
        porToken.set(normalizado, referencias);
      }
    }
  }

  return [...porToken.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([token, referencias]) => ({ token, referencias }));
}

async function removerTokensInvalidos(
  firestore: Firestore,
  referencias: readonly DocumentReference[]
): Promise<number> {
  const unicas = new Map(referencias.map((referencia) => [referencia.path, referencia]));
  let removidos = 0;
  for (const lote of dividirEmLotes([...unicas.values()], 450)) {
    const batch = firestore.batch();
    for (const referencia of lote) batch.delete(referencia);
    await batch.commit();
    removidos += lote.length;
  }
  return removidos;
}

/**
 * Lógica testável da trigger. Não confia em autor, privacidade ou texto do
 * pedido para decidir destinatários ou montar a mensagem.
 */
export async function processarPedidoOracaoUrgente(
  evento: PedidoUrgenteCriado,
  dependencias: DependenciasNotificacaoUrgente = dependenciasReais
): Promise<ResultadoNotificacaoUrgente> {
  if (evento.dados.urgente !== true) {
    return {
      estado: "nao_urgente",
      tokensEncontrados: 0,
      sucessos: 0,
      falhas: 0,
      tokensRemovidos: 0,
    };
  }

  // Não basta confiar no campo `anonimo` do documento: o cliente poderia
  // forjá-lo. Contas anônimas do Firebase Auth têm providerData vazio. Um
  // pedido desses continua salvo para acolhimento, mas não dispara push.
  const autorId = evento.dados.autor_id;
  if (typeof autorId !== "string" || autorId.trim().length === 0) {
    return {
      estado: "autor_nao_elegivel",
      tokensEncontrados: 0,
      sucessos: 0,
      falhas: 0,
      tokensRemovidos: 0,
    };
  }
  let autor: Awaited<ReturnType<DependenciasNotificacaoUrgente["buscarAutor"]>>;
  try {
    autor = await dependencias.buscarAutor(autorId.trim());
  } catch (erro) {
    const codigo =
      typeof erro === "object" && erro !== null && "code" in erro
        ? String((erro as { code?: unknown }).code ?? "")
        : "";
    if (codigo === "auth/user-not-found") {
      return {
        estado: "autor_nao_elegivel",
        tokensEncontrados: 0,
        sucessos: 0,
        falhas: 0,
        tokensRemovidos: 0,
      };
    }
    throw erro;
  }
  if (autor.disabled || autor.providerData.length === 0) {
    return {
      estado: "autor_nao_elegivel",
      tokensEncontrados: 0,
      sucessos: 0,
      falhas: 0,
      tokensRemovidos: 0,
    };
  }

  const igrejaId = validarIgrejaId(evento.igrejaId);
  const processamento = referenciaProcessamento(
    dependencias.firestore,
    igrejaId,
    evento.eventId
  );
  const adquirido = await adquirirEvento(
    dependencias.firestore,
    processamento,
    evento.eventId,
    evento.pedidoId
  );
  if (!adquirido) {
    return {
      estado: "duplicado",
      tokensEncontrados: 0,
      sucessos: 0,
      falhas: 0,
      tokensRemovidos: 0,
    };
  }

  try {
    const uids = await buscarUidsLideranca(dependencias.firestore, igrejaId);
    const tokens = await buscarTokensAtivos(dependencias.firestore, uids);

    if (tokens.length === 0) {
      const vazio = {
        tokensEncontrados: 0,
        sucessos: 0,
        falhas: 0,
        tokensRemovidos: 0,
      };
      await concluirEvento(processamento, vazio);
      return { estado: "sem_destinatarios", ...vazio };
    }

    const limiteAutor = referenciaLimiteAutor(
      dependencias.firestore,
      igrejaId,
      autorId.trim()
    );
    const janelaAdquirida = await adquirirJanelaDeEnvio(
      dependencias.firestore,
      limiteAutor,
      dependencias.agoraEmMs?.() ?? Date.now()
    );
    if (!janelaAdquirida) {
      const limitado = {
        tokensEncontrados: tokens.length,
        sucessos: 0,
        falhas: 0,
        tokensRemovidos: 0,
      };
      await concluirEvento(processamento, limitado);
      return { estado: "limitado", ...limitado };
    }

    let sucessos = 0;
    let falhas = 0;
    const invalidos: DocumentReference[] = [];

    for (const lote of dividirEmLotes(tokens)) {
      const resposta = await dependencias.enviarMulticast({
        tokens: lote.map((item) => item.token),
        notification: {
          title: "Pedido de oração urgente",
          body: "Uma pessoa solicitou apoio espiritual urgente na sua igreja.",
        },
        data: {
          tipo: "pedido_oracao_urgente",
          rota: "/moderacao-oracao",
        },
        android: { priority: "high" },
      });

      for (let indice = 0; indice < lote.length; indice += 1) {
        const item = lote[indice];
        const resultado = resposta.responses[indice];
        if (resultado?.success === true) {
          sucessos += 1;
          continue;
        }
        falhas += 1;
        const codigo = resultado?.error?.code;
        if (codigo && CODIGOS_TOKEN_INVALIDO.has(codigo)) {
          invalidos.push(...item.referencias);
        }
      }
    }

    const tokensRemovidos = await removerTokensInvalidos(
      dependencias.firestore,
      invalidos
    );
    const resumo = {
      tokensEncontrados: tokens.length,
      sucessos,
      falhas,
      tokensRemovidos,
    };
    await concluirEvento(processamento, resumo);
    return { estado: "enviado", ...resumo };
  } catch (erro) {
    await registrarFalha(processamento);
    throw erro;
  }
}

export const notificarPedidoOracaoUrgente = onDocumentCreated(
  {
    document: "igrejas/{igrejaId}/pedidos_oracao/{pedidoId}",
    region: REGIAO,
    minInstances: 0,
    maxInstances: 1,
    memory: "256MiB",
    cpu: "gcf_gen1",
    concurrency: 1,
    timeoutSeconds: 30,
    retry: false,
  },
  async (evento) => {
    const documento = evento.data;
    if (!documento) return;
    await processarPedidoOracaoUrgente({
      igrejaId: String(evento.params.igrejaId),
      pedidoId: String(evento.params.pedidoId),
      eventId: evento.id,
      dados: documento.data() as Record<string, unknown>,
    });
  }
);
