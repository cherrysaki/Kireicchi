const { logger } = require("firebase-functions");
const { tryRedeemInviteCode } = require("./parentLinking");
const { replyText } = require("./lineMessagingApi");

/**
 * LINEの友だち追加(follow)イベントを処理する。
 * フェーズ1時点ではログ出力のみ。parentLinksへの保存はフェーズ2で追加する。
 */
async function handleFollowEvent(event) {
  logger.info("[lineWebhook] follow event received", {
    lineUserId: event.source?.userId,
    timestamp: event.timestamp,
  });
}

/**
 * テキストメッセージ受信時、それが有効な招待コードであれば親子連携(parentLinks)を作成する。
 * 該当しなければ何もしない(返信もしない)。
 */
async function handleMessageEvent(event, deps) {
  const lineUserId = event.source?.userId;
  const text = event.message?.type === "text" ? event.message.text?.trim() : undefined;

  if (!lineUserId || !text) {
    logger.info("[lineWebhook] message event ignored (not a text message)", {
      lineUserId,
    });
    return;
  }

  const result = await tryRedeemInviteCode(text, lineUserId);
  if (!result) {
    logger.info("[lineWebhook] message did not match a valid invite code", {
      lineUserId,
    });
    return;
  }

  logger.info("[lineWebhook] parentLink created", {
    childId: result.childId,
    lineUserId,
  });

  if (event.replyToken) {
    await replyText(event.replyToken, "連携が完了しました", deps.channelAccessToken);
  }
}

/**
 * follow/message以外のイベントは現時点では処理せず、可視化のためログのみ出力する。
 */
async function handleOtherEvent(event) {
  logger.info("[lineWebhook] event received (no-op)", {
    type: event.type,
    lineUserId: event.source?.userId,
  });
}

async function dispatchLineEvent(event, deps) {
  switch (event.type) {
    case "follow":
      return handleFollowEvent(event);
    case "message":
      return handleMessageEvent(event, deps);
    default:
      return handleOtherEvent(event);
  }
}

module.exports = {
  dispatchLineEvent,
  handleFollowEvent,
  handleMessageEvent,
  handleOtherEvent,
};
