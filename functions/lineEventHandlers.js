const { logger } = require("firebase-functions");
const { tryRedeemInviteCode } = require("./parentLinking");
const { replyText } = require("./lineMessagingApi");

// 招待コードの形式: 紛らわしい文字(0/O, 1/I/L)を除いた英数字6桁
// (CreateInviteCodeUseCase.generateCode と同じアルファベット)。
const INVITE_CODE_PATTERN = /^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}$/;

const REDEEM_FAILURE_MESSAGES = {
  not_found:
    "入力されたコードが見つかりませんでした。お子さまの「きれいっち」アプリの設定画面で発行された6桁のコードをそのまま送信してください。",
  already_used:
    "このコードはすでに使用されています。新しい連携コードをお子さまの端末で発行してもらってください。",
  expired:
    "このコードの有効期限が切れています(発行から10分間有効です)。お子さまの端末で新しいコードを発行してもらい、もう一度お試しください。",
};

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
 * テキストメッセージ受信時、招待コードの形式(英数字6桁)に一致する場合のみ
 * 引き換えを試み、結果に応じて返信する。形式に一致しないメッセージ(雑談等)は
 * 現状通り無反応のままにする(Webhookの「応答メッセージオフ」の意図を壊さないため)。
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

  if (!INVITE_CODE_PATTERN.test(text)) {
    logger.info("[lineWebhook] message did not match invite code format, ignored", {
      lineUserId,
    });
    return;
  }

  const result = await tryRedeemInviteCode(text, lineUserId);

  if (!result.ok) {
    logger.info("[lineWebhook] invite code redemption failed", {
      lineUserId,
      reason: result.reason,
    });
    if (event.replyToken) {
      await replyText(event.replyToken, REDEEM_FAILURE_MESSAGES[result.reason], deps.channelAccessToken);
    }
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
