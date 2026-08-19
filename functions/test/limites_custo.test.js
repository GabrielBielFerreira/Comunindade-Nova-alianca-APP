/**
 * Limites de custo de TODAS as Functions publicadas.
 *
 * O plano Blaze não tem teto automático de gastos, e um orçamento do Cloud
 * Billing apenas avisa. O que realmente limita o estrago é o teto de
 * instâncias — e ele só vale se estiver em TODA função que vai ao ar. Este
 * teste lê o endpoint que o deploy publicaria, para que uma função nova sem
 * limite reprove antes de chegar em produção.
 *
 * Não precisa de emulador: só carrega o bundle compilado.
 */
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-nova-alianca";

const assert = require("node:assert/strict");
const { describe, it } = require("node:test");

const funcoes = require("../lib/index.js");

const ESPERADO = {
  regiao: "southamerica-east1",
  minInstances: 0,
  maxInstances: 1,
  memoriaMb: 256,
  concurrency: 1,
  cpu: "gcf_gen1",
  timeoutSeconds: 30,
};

/** Nomes que NUNCA podem ser publicados nesta fase. */
const PROIBIDAS = [
  "criarPagamentoPix",
  "criarPreferenciaCheckout",
  "webhookMercadoPago",
  "mercadoPagoWebhook",
];

describe("limites de custo das Cloud Functions", () => {
  const nomes = Object.keys(funcoes);

  it("exporta pelo menos uma função", () => {
    assert.ok(nomes.length > 0, "nenhuma função exportada");
  });

  it("não exporta nenhuma função de pagamento legada", () => {
    for (const proibida of PROIBIDAS) {
      assert.equal(
        nomes.includes(proibida),
        false,
        `${proibida} não pode ser publicada: o webhook legado não valida assinatura`
      );
    }
  });

  for (const nome of nomes) {
    describe(nome, () => {
      const endpoint = funcoes[nome].__endpoint;

      it("tem endpoint de deploy", () => {
        assert.ok(endpoint, "função sem __endpoint — não seria publicada");
      });

      it("roda na região da rede", () => {
        assert.deepEqual(endpoint.region, [ESPERADO.regiao]);
      });

      it("não mantém instância aquecida (cobrada mesmo parada)", () => {
        assert.equal(endpoint.minInstances, ESPERADO.minInstances);
      });

      it("tem teto de instâncias", () => {
        assert.equal(endpoint.maxInstances, ESPERADO.maxInstances);
        assert.ok(
          endpoint.maxInstances >= 1,
          "maxInstances precisa existir e ser finito"
        );
      });

      it("usa o menor porte de memória e CPU", () => {
        assert.equal(endpoint.availableMemoryMb, ESPERADO.memoriaMb);
        assert.equal(endpoint.cpu, ESPERADO.cpu);
      });

      it("usa concorrência 1, coerente com CPU fracionária", () => {
        assert.equal(endpoint.concurrency, ESPERADO.concurrency);
      });

      it("tem timeout curto", () => {
        assert.equal(endpoint.timeoutSeconds, ESPERADO.timeoutSeconds);
        assert.ok(endpoint.timeoutSeconds <= 60, "timeout longo custa caro");
      });
    });
  }
});
