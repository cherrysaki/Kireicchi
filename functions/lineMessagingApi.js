const { logger } = require("firebase-functions");

const LINE_REPLY_ENDPOINT = "https://api.line.me/v2/bot/message/reply";
const LINE_PUSH_ENDPOINT = "https://api.line.me/v2/bot/message/push";

/**
 * LINE Messaging APIのReply APIでテキストメッセージを送る。
 * 失敗しても例外を投げず、警告ログのみ出す(Webhook自体の200応答はブロックしない)。
 */
async function replyText(replyToken, text, channelAccessToken) {
  try {
    const res = await fetch(LINE_REPLY_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${channelAccessToken}`,
      },
      body: JSON.stringify({
        replyToken,
        messages: [{ type: "text", text }],
      }),
    });

    if (!res.ok) {
      const body = await res.text();
      logger.warn("[lineMessagingApi] reply API failed", {
        status: res.status,
        body,
      });
    }
  } catch (error) {
    logger.warn("[lineMessagingApi] reply API request threw", {
      error: String(error),
    });
  }
}

/**
 * LINE Messaging APIのPush APIでメッセージオブジェクト配列を送る（最大5個、公式仕様）。
 * 1リクエストにまとめて送っても無料枠・従量課金のカウントは変わらない
 * （「送信リクエストの数×送信対象の人数」でカウントされるため、吹き出し数は影響しない。
 * 出典: https://developers.line.biz/ja/tips/2026/05/28/how-to-count-messages/）。
 * 失敗時は例外を投げる(呼び出し側で誰宛のpushが失敗したかをログに残せるようにするため)。
 */
async function pushMessages(to, messages, channelAccessToken) {
  const res = await fetch(LINE_PUSH_ENDPOINT, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${channelAccessToken}`,
    },
    body: JSON.stringify({ to, messages }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`LINE push API failed: ${res.status} ${body}`);
  }
}

/**
 * LINE Messaging APIのPush APIでテキストメッセージを1件送る。
 */
async function pushText(to, text, channelAccessToken) {
  await pushMessages(to, [{ type: "text", text }], channelAccessToken);
}

/**
 * originalContentUrl / previewImageUrl に同じURLを使う画像メッセージを組み立てる。
 * きれいっちのドット絵は128x128pxの減色PNGで数十KB程度に収まり、LINEの制限
 * （original 10MB / preview 1MB、HTTPS必須、JPEG/PNG）を十分に満たすため、
 * プレビュー用に別途縮小画像を用意せず同一URLを使う。
 */
function buildImageMessage(url) {
  return { type: "image", originalContentUrl: url, previewImageUrl: url };
}

module.exports = { replyText, pushText, pushMessages, buildImageMessage };
