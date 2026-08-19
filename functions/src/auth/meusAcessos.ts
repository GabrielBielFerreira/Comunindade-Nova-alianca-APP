/**
 * `meusAcessos` — base do gate do painel.
 *
 * O painel NUNCA decide sozinho o que o usuário pode ver: pergunta ao
 * servidor quais unidades ele acessa e com quais capacidades. O seletor de
 * igreja só pode alternar entre as unidades desta resposta.
 */
import { onCall } from "firebase-functions/v2/https";
import { REGIAO, db } from "../firebase";
import { requireSignedIn } from "../authorization/guards";
import {
  canApproveMember,
  canManageContent,
  canManageLeadership,
  canModeratePrayer,
  canReadFinance,
  lerFuncoes,
  lerPerfil,
  lerStatus,
  podeAcessarPainel,
  type VinculoIgreja,
} from "../dominio/tipos";

export interface AcessoIgreja {
  igrejaId: string;
  nome: string;
  ativa: boolean;
  perfil: string;
  status: string;
  funcoesAdmin: string[];
  capacidades: {
    acessarPainel: boolean;
    lerFinancas: boolean;
    gerenciarConteudo: boolean;
    moderarOracao: boolean;
    aprovarMembro: boolean;
    gerenciarLideranca: boolean;
  };
}

export const meusAcessos = onCall({ region: REGIAO }, async (request) => {
  const chamador = requireSignedIn(request);

  const igrejasSnap = await db.collection("igrejas").get();
  const acessos: AcessoIgreja[] = [];

  for (const igrejaDoc of igrejasSnap.docs) {
    const igrejaId = igrejaDoc.id;
    const igrejaDados = igrejaDoc.data() ?? {};

    const vinculoSnap = await db.doc(`igrejas/${igrejaId}/membros/${chamador.uid}`).get();

    let vinculo: VinculoIgreja | null = null;
    if (vinculoSnap.exists) {
      const dados = vinculoSnap.data() ?? {};
      vinculo = {
        uid: chamador.uid,
        igrejaId,
        status: lerStatus(dados.status),
        perfil: lerPerfil(dados.perfil),
        funcoesAdmin: lerFuncoes(dados.funcoes_admin),
      };
    }

    const sa = chamador.isSuperAdmin;
    const acessarPainel = podeAcessarPainel(vinculo, sa);

    // Só devolve unidades que o usuário realmente administra. O painel não
    // recebe sequer o nome de uma unidade onde não tem acesso.
    if (!acessarPainel) continue;

    acessos.push({
      igrejaId,
      nome: String(igrejaDados.nome ?? igrejaId),
      ativa: igrejaDados.ativa === true,
      perfil: vinculo?.perfil ?? "membro",
      status: vinculo?.status ?? "sem_vinculo",
      funcoesAdmin: vinculo?.funcoesAdmin ?? [],
      capacidades: {
        acessarPainel,
        lerFinancas: canReadFinance(vinculo, sa),
        gerenciarConteudo: canManageContent(vinculo, sa),
        moderarOracao: canModeratePrayer(vinculo, sa),
        aprovarMembro: canApproveMember(vinculo, sa),
        gerenciarLideranca: canManageLeadership(vinculo, sa),
      },
    });
  }

  acessos.sort((a, b) => a.nome.localeCompare(b.nome, "pt-BR"));

  return {
    uid: chamador.uid,
    isSuperAdmin: chamador.isSuperAdmin,
    acessos,
  };
});
