/**
 * Cloud Functions da rede Nova Aliança.
 *
 * ESCOPO ATUAL (Fase 1): administração multi-igreja.
 *
 * PAGAMENTOS: o código do Mercado Pago da v1.3.0 está preservado em
 * `src/legacy/mercadoPago.legacy.ts`, DESATIVADO e NÃO EXPORTADO. Ele não
 * valida a assinatura do webhook e usa uma única credencial para toda a rede;
 * publicá-lo como função ativa seria inseguro. Retomada na Fase 5, com OAuth
 * por igreja e validação de x-signature.
 */

// PRIMEIRO import, sempre: `setGlobalOptions` precisa rodar antes de qualquer
// função ser construída, senão os limites de custo não são aplicados a ela.
import "./opcoes";

// Autorização/sessão
export { meusAcessos } from "./auth/meusAcessos";

// Vínculos e ciclo de vida da liderança
export {
  aprovarMembro,
  recusarMembro,
  promoverParaLideranca,
  removerDaLideranca,
  desvincularDaIgreja,
  atribuirFuncaoAdmin,
  removerFuncaoAdmin,
} from "./members/membros";

// Transferência oficial de vínculo entre unidades (exclusiva do super_admin)
export { transferirVinculoIgreja } from "./members/transferencia";

// Unidades
export { criarIgreja, atualizarIgreja } from "./churches/igrejas";

// Oração urgente: push privado e genérico para a liderança aprovada da unidade.
export { notificarPedidoOracaoUrgente } from "./notifications/pedidoOracaoUrgente";
