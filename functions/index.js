const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

const { verifyLineSignature } = require("./lineSignature");
const { dispatchLineEvent } = require("./lineEventHandlers");
const { runDailyDigest } = require("./dailyDigest");
const { unlinkParentLinks } = require("./parentLinking");

admin.initializeApp();

const LINE_CHANNEL_SECRET = defineSecret("LINE_CHANNEL_SECRET");
const LINE_CHANNEL_ACCESS_TOKEN = defineSecret("LINE_CHANNEL_ACCESS_TOKEN");

// 1日1回ダイジェスト通知のスケジュール。変更する場合はここを編集するだけでよい。
const DAILY_DIGEST_SCHEDULE = "0 19 * * *"; // 毎日19:00
const DAILY_DIGEST_TIME_ZONE = "Asia/Tokyo";

/**
 * LINE Webhook 受信エンドポイント。
 * 署名検証(Channel SecretはSecret Manager経由)を行った上で events を処理する。
 */
exports.lineWebhook = onRequest(
  {
    secrets: [LINE_CHANNEL_SECRET, LINE_CHANNEL_ACCESS_TOKEN],
    region: "asia-northeast1",
  },
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

    const deps = { channelAccessToken: LINE_CHANNEL_ACCESS_TOKEN.value() };
    const events = req.body?.events ?? [];
    await Promise.all(events.map((event) => dispatchLineEvent(event, deps)));

    // LINEプラットフォームへは常に200を返す(仕様上、非200はリトライの対象になる)
    res.status(200).send("OK");
  }
);

/**
 * 1日1回、保護者にその日の部屋スコアをLINE Pushで通知するダイジェストバッチ。
 */
exports.dailyScoreDigest = onSchedule(
  {
    schedule: DAILY_DIGEST_SCHEDULE,
    timeZone: DAILY_DIGEST_TIME_ZONE,
    region: "asia-northeast1",
    secrets: [LINE_CHANNEL_ACCESS_TOKEN],
  },
  async () => {
    await runDailyDigest(LINE_CHANNEL_ACCESS_TOKEN.value());
  }
);

/**
 * 子ども側アプリから呼び出す、親子連携の解除。
 * 認証済みユーザー自身(context.auth.uid)がchildIdであるparentLinksのみを対象にする。
 */
exports.unlinkParent = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "サインインが必要です");
    }

    const result = await unlinkParentLinks(uid);
    if (!result.ok) {
      throw new HttpsError("not-found", "有効な連携が見つかりませんでした");
    }

    logger.info("[unlinkParent] parentLinks unlinked", {
      childId: uid,
      unlinkedCount: result.unlinkedCount,
    });

    return { unlinkedCount: result.unlinkedCount };
  }
);
