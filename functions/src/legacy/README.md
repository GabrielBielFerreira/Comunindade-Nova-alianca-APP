# Legado — Mercado Pago (DESATIVADO)

`mercadoPago.legacy.js` é o código de pagamentos da v1.3.0, preservado
integralmente para a **Fase 5**. Ele **não é compilado** (excluído no
`tsconfig.json`) e **não é exportado** por `src/index.ts`, portanto **não é
publicado como função ativa**.

## Por que está desativado

1. **Webhook sem validação de assinatura.** `x-signature` e `x-request-id` não
   são verificados; o comentário no código diz literalmente que a validação é
   "opcional". Qualquer requisição forjada poderia alterar o status de uma
   transação.
2. **Credencial única para toda a rede.** Um só `MP_ACCESS_TOKEN` — Petrolina
   receberia pela conta de Olinda, o que a arquitetura proíbe.
3. **`igrejaId` com valor padrão `principal`.** Grava fora do escopo de igreja.
4. **Contrato financeiro antigo.** Grava `valor` em reais e `usuario_id` em
   coleção global, incompatível com o contrato canônico
   (`valor_centavos`, `/igrejas/{igrejaId}/transacoes`).

## O que a Fase 5 precisa fazer

- Aplicação integradora Nova Aliança + OAuth Authorization Code por unidade.
- `offline_access` e renovação de token; segredos no Google Secret Manager,
  um por igreja — nunca no Firestore nem no repositório.
- Criar o pagamento com a credencial da unidade selecionada.
- Webhook com validação real de `x-signature`/`x-request-id`, consulta do
  pagamento na API e conferência de recebedor, valor, `external_reference` e
  modo de produção.
- Persistir no contrato canônico em `/igrejas/{igrejaId}/transacoes/{id}`.
- Sandbox primeiro; piloto de Olinda com a conta autorizada; Petrolina só
  depois que o responsável local conectar a conta própria.

Não reative este arquivo sem cumprir os itens acima.
