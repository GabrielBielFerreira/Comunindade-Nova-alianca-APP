/**
 * Limites de custo de TODAS as Functions v2 — fonte única da verdade.
 *
 * Este módulo é importado primeiro por `index.ts`: `setGlobalOptions` precisa
 * rodar ANTES de qualquer `onCall`/`onRequest` ser construído, porque as
 * opções são capturadas no momento em que a função é definida.
 *
 * ## Por que estes valores
 *
 * O projeto está no plano Blaze, onde não existe teto automático de gastos.
 * Um orçamento do Cloud Billing apenas AVISA — ele não interrompe a cobrança.
 * O controle que realmente limita o estrago de um abuso ou de um laço de
 * repetição malfeito é o teto de instâncias, e ele mora aqui, no código, que
 * é o que o deploy aplica.
 *
 * - `minInstances: 0` — instância aquecida é cobrada mesmo parada. Uma igreja
 *   em piloto não justifica pagar por espera; alguns segundos de cold start
 *   são aceitáveis numa operação administrativa.
 * - `maxInstances: 1` — teto duro. Com uma unidade piloto o volume é de
 *   dezenas de chamadas por dia; um pico só pode significar erro ou abuso, e
 *   nesse caso a fila é preferível à conta.
 * - `memory: "256MiB"` e `cpu: "gcf_gen1"` — o menor porte disponível. Estas
 *   Functions leem alguns documentos e escrevem uma transação.
 * - `concurrency: 1` — obrigatório com CPU fracionária (gcf_gen1 a 256 MiB dá
 *   menos de 1 vCPU) e coerente com operações transacionais.
 * - `timeoutSeconds: 30` — uma transação do Firestore que passe disso está
 *   travada, não lenta.
 *
 * `enforceAppCheck` NÃO é ligado aqui de propósito: App Check entra primeiro
 * em modo de monitoramento e só depois em enforcement, para não derrubar o
 * aplicativo e o painel reais antes de validá-los.
 *
 * Ao mudar qualquer valor daqui, atualize `CONTROLE_CUSTOS_FIREBASE.md` e
 * `scripts/verificar_producao.js`, que reprova o deploy se estes limites
 * sumirem.
 */
import { setGlobalOptions } from "firebase-functions/v2";
import { REGIAO } from "./firebase";

setGlobalOptions({
  region: REGIAO,
  minInstances: 0,
  maxInstances: 1,
  memory: "256MiB",
  cpu: "gcf_gen1",
  concurrency: 1,
  timeoutSeconds: 30,
  // O deploy é a fonte da verdade: alteração feita à mão no Console é
  // sobrescrita, em vez de ficar divergindo em silêncio do repositório.
  preserveExternalChanges: false,
});
