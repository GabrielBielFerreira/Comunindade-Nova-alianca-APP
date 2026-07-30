/**
 * Cloud Functions — Pagamentos da Comunidade Nova Aliança (Mercado Pago).
 *
 * SEGURANÇA:
 * - O access token do Mercado Pago NUNCA fica no app Flutter nem no código.
 *   É lido de um "secret" do Firebase (defineSecret) — configure com:
 *     firebase functions:secrets:set MP_ACCESS_TOKEN
 * - Os VALORES são validados no servidor.
 * - A confirmação do pagamento vem do WEBHOOK (server-side), nunca do cliente.
 * - Idempotência: X-Idempotency-Key na criação e atualização condicional no webhook.
 *
 * DEPLOY: requer o plano Blaze do Firebase. Ver functions/README.md.
 */
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { MercadoPagoConfig, Payment, Preference } = require("mercadopago");

admin.initializeApp();
const db = admin.firestore();

const MP_ACCESS_TOKEN = defineSecret("MP_ACCESS_TOKEN");
const MP_WEBHOOK_SECRET = defineSecret("MP_WEBHOOK_SECRET");

// Limite de segurança para valores (ajuste conforme a política da igreja).
const VALOR_MIN = 1; // R$ 1,00
const VALOR_MAX = 50000; // R$ 50.000,00

function validarValor(valor) {
  if (typeof valor !== "number" || !isFinite(valor)) {
    throw new HttpsError("invalid-argument", "Valor inválido.");
  }
  if (valor < VALOR_MIN || valor > VALOR_MAX) {
    throw new HttpsError("out-of-range", "Valor fora do limite permitido.");
  }
}

function mpClient() {
  return new MercadoPagoConfig({ accessToken: MP_ACCESS_TOKEN.value() });
}

/**
 * Cria uma contribuição via PIX. Retorna QR Code e copia-e-cola.
 * O status definitivo virá pelo webhook — o cliente deve tratar como PENDENTE.
 */
exports.criarContribuicaoPix = onCall(
  { secrets: [MP_ACCESS_TOKEN], region: "southamerica-east1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Faça login para contribuir.");
    }
    const uid = request.auth.uid;
    const { tipo, valor, igrejaId, email } = request.data || {};
    validarValor(valor);

    // Registro pendente (fonte da verdade do app).
    const ref = db.collection("transacoes").doc();
    await ref.set({
      usuario_id: uid,
      tipo: tipo || "oferta",
      igreja_id: igrejaId || "principal",
      valor,
      metodo: "pix",
      status: "pendente",
      criado_em: admin.firestore.FieldValue.serverTimestamp(),
    });

    const payment = new Payment(mpClient());
    const result = await payment.create({
      body: {
        transaction_amount: valor,
        description: `Contribuição (${tipo || "oferta"})`,
        payment_method_id: "pix",
        external_reference: ref.id,
        payer: { email: email || "sem-email@novaalianca.app" },
      },
      requestOptions: { idempotencyKey: ref.id },
    });

    const tx = result.point_of_interaction?.transaction_data || {};
    await ref.update({ mp_payment_id: String(result.id) });

    return {
      transacaoId: ref.id,
      status: "pendente",
      qrCodeBase64: tx.qr_code_base64 || null,
      copiaECola: tx.qr_code || null,
    };
  }
);

/**
 * Cria uma preferência de checkout (cartão/boleto) e retorna a URL externa
 * (Checkout Pro). O app deve abrir essa URL em WebView segura / navegador.
 */
exports.criarContribuicaoCheckout = onCall(
  { secrets: [MP_ACCESS_TOKEN], region: "southamerica-east1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Faça login para contribuir.");
    }
    const uid = request.auth.uid;
    const { tipo, valor, igrejaId } = request.data || {};
    validarValor(valor);

    const ref = db.collection("transacoes").doc();
    await ref.set({
      usuario_id: uid,
      tipo: tipo || "oferta",
      igreja_id: igrejaId || "principal",
      valor,
      metodo: "checkout",
      status: "pendente",
      criado_em: admin.firestore.FieldValue.serverTimestamp(),
    });

    const preference = new Preference(mpClient());
    const result = await preference.create({
      body: {
        items: [
          {
            title: `Contribuição (${tipo || "oferta"})`,
            quantity: 1,
            unit_price: valor,
            currency_id: "BRL",
          },
        ],
        external_reference: ref.id,
        // TODO: configurar back_urls/notification_url no deploy.
      },
      requestOptions: { idempotencyKey: ref.id },
    });

    await ref.update({ mp_preference_id: String(result.id) });
    return { transacaoId: ref.id, initPoint: result.init_point };
  }
);

/**
 * Webhook do Mercado Pago — confirma/atualiza o status da transação.
 * Idempotente: só grava se o status mudou.
 */
exports.mercadoPagoWebhook = onRequest(
  { secrets: [MP_ACCESS_TOKEN, MP_WEBHOOK_SECRET], region: "southamerica-east1" },
  async (req, res) => {
    try {
      // (Opcional) validar assinatura do webhook com MP_WEBHOOK_SECRET aqui.
      const paymentId = req.body?.data?.id || req.query?.["data.id"];
      if (!paymentId) {
        res.status(400).send("sem id");
        return;
      }

      const payment = new Payment(mpClient());
      const info = await payment.get({ id: paymentId });
      const externalRef = info.external_reference;
      if (!externalRef) {
        res.status(200).send("sem external_reference");
        return;
      }

      // Mapeia status do MP para os status do app.
      const mapa = {
        approved: "aprovado",
        pending: "pendente",
        in_process: "pendente",
        rejected: "recusado",
        cancelled: "cancelado",
        refunded: "cancelado",
      };
      const novoStatus = mapa[info.status] || "pendente";

      const ref = db.collection("transacoes").doc(externalRef);
      await db.runTransaction(async (t) => {
        const snap = await t.get(ref);
        if (!snap.exists) return;
        if (snap.data().status === novoStatus) return; // idempotente
        t.update(ref, {
          status: novoStatus,
          mp_payment_id: String(paymentId),
          atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      res.status(200).send("ok");
    } catch (e) {
      console.error("webhook erro", e);
      res.status(500).send("erro");
    }
  }
);
