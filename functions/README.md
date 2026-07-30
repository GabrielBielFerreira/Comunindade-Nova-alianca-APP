# Cloud Functions — Pagamentos (Mercado Pago)

Backend seguro para contribuições. **Nenhum segredo fica no app Flutter.**

> ⚠️ **Requer o plano Blaze** do Firebase (Cloud Functions v2). No plano Spark
> (gratuito) não é possível fazer deploy destas functions.

## Endpoints
- `criarContribuicaoPix` (callable) — cria pagamento PIX, retorna QR Code e
  copia-e-cola; registra `transacoes/{id}` como **pendente**.
- `criarContribuicaoCheckout` (callable) — cria preferência para **cartão/boleto**
  (Checkout Pro), retorna `initPoint` (URL externa para WebView/navegador).
- `mercadoPagoWebhook` (HTTP) — recebe notificações do MP e atualiza o status
  (`aprovado`/`recusado`/`cancelado`/`pendente`) de forma **idempotente**.

## Princípios de segurança
- Access token via **secret** (nunca no código/app).
- Valores **validados no servidor** (`VALOR_MIN`/`VALOR_MAX`).
- Confirmação sempre pelo **webhook** (server-side), nunca pelo cliente.
- **Idempotência** na criação (`X-Idempotency-Key`) e na atualização (transação).

## Configuração e deploy
```bash
cd functions
npm install

# Segredos (não versionados):
firebase functions:secrets:set MP_ACCESS_TOKEN
firebase functions:secrets:set MP_WEBHOOK_SECRET   # opcional (validar assinatura)

firebase deploy --only functions
```
Depois, no painel do Mercado Pago, configure a **URL de notificação (webhook)**
apontando para a função `mercadoPagoWebhook`.

## Integração no app (cliente)
O app já tem a dependência `cloud_functions`. Para usar (após o deploy):
```dart
final fn = FirebaseFunctions.instanceFor(region: 'southamerica-east1')
    .httpsCallable('criarContribuicaoPix');
final res = await fn.call({'tipo': 'dizimo', 'valor': 50.0, 'igrejaId': 'principal'});
// res.data['copiaECola'], res.data['qrCodeBase64'], res.data['transacaoId']
```
Enquanto as functions não estiverem publicadas, o fluxo de contribuição
permanece **honesto** no app (PIX manual identificado, cartão/boleto indisponíveis).

## Pendências externas
- Plano **Blaze** habilitado.
- Credenciais **Mercado Pago** (access token de produção/sandbox).
- URL de webhook configurada no painel do Mercado Pago.
