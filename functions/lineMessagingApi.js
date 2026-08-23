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
 * LINE Messaging APIのPush APIでテキストメッセージを送る。
 * 失敗時は例外を投げる(呼び出し側で誰宛のpushが失敗したかをログに残せるようにするため)。
 */
async function pushText(to, text, channelAccessToken) {
  const res = await fetch(LINE_PUSH_ENDPOINT, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${channelAccessToken}`,
    },
    body: JSON.stringify({
      to,
      messages: [{ type: "text", text }],
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`LINE push API failed: ${res.status} ${body}`);
  }
}

module.exports = { replyText, pushText };
