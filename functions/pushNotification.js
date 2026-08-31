const { getMessaging } = require("firebase-admin/messaging");
const { logger } = require("firebase-functions");

/**
 * 指定したFCMトークンへプッシュ通知を送る。
 * 無効トークン・期限切れトークン等の送信失敗は呼び出し元(ユーザーごとのループ)を
 * ブロックしないよう、例外を投げず false を返す（dailyDigest の pushText 失敗時の
 * 扱いと同じ方針）。
 *
 * @param {string|undefined} fcmToken
 * @param {string} title
 * @param {string} body
 * @returns {Promise<boolean>} 送信できたかどうか
 */
async function sendPushNotification(fcmToken, title, body) {
  if (!fcmToken) return false;

  try {
    await getMessaging().send({
      token: fcmToken,
      notification: { title, body },
      apns: { payload: { aps: { sound: "default" } } },
    });
    return true;
  } catch (error) {
    logger.warn("[pushNotification] send failed", { error: String(error) });
    return false;
  }
}

module.exports = { sendPushNotification };
