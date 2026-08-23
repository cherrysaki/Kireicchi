const { logger } = require("firebase-functions");

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
 * follow以外のイベントは現時点では処理せず、可視化のためログのみ出力する。
 * message イベントの招待コード引き換え処理はフェーズ2で追加する。
 */
async function handleOtherEvent(event) {
  logger.info("[lineWebhook] event received (no-op in phase1)", {
    type: event.type,
    lineUserId: event.source?.userId,
  });
}

async function dispatchLineEvent(event) {
  switch (event.type) {
    case "follow":
      return handleFollowEvent(event);
    default:
      return handleOtherEvent(event);
  }
}

module.exports = { dispatchLineEvent, handleFollowEvent, handleOtherEvent };
