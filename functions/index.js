const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

const { verifyLineSignature } = require("./lineSignature");
const { dispatchLineEvent } = require("./lineEventHandlers");

admin.initializeApp();

const LINE_CHANNEL_SECRET = defineSecret("LINE_CHANNEL_SECRET");

/**
 * LINE Webhook 受信エンドポイント。
 * 署名検証(Channel SecretはSecret Manager経由)を行った上で events を処理する。
 */
exports.lineWebhook = onRequest(
  { secrets: [LINE_CHANNEL_SECRET], region: "asia-northeast1" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const signature = req.get("x-line-signature");
    const channelSecret = LINE_CHANNEL_SECRET.value();

    if (!verifyLineSignature(req.rawBody, signature, channelSecret)) {
      logger.warn("[lineWebhook] signature verification failed");
      res.status(401).send("Invalid signature");
      return;
    }

    const events = req.body?.events ?? [];
    await Promise.all(events.map((event) => dispatchLineEvent(event)));

    // LINEプラットフォームへは常に200を返す(仕様上、非200はリトライの対象になる)
    res.status(200).send("OK");
  }
);
