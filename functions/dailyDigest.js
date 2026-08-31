const { getFirestore } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { pushText } = require("./lineMessagingApi");
const { fetchCrisisLevel } = require("./crisisLevel");
const { buildDigestMessage } = require("./digestMessages");

/**
 * dateがJST(Asia/Tokyo)で「今日」かどうかを判定する。
 * サーバーのローカルタイムゾーンに依存しないよう、UTC時刻に+9時間して
 * 日付部分だけを文字列比較する(タイムゾーンライブラリを増やさないための簡易実装)。
 */
function isTodayInJst(date) {
  const JST_OFFSET_MS = 9 * 60 * 60 * 1000;
  const toJstDateString = (d) => new Date(d.getTime() + JST_OFFSET_MS).toISOString().slice(0, 10);
  return toJstDateString(new Date()) === toJstDateString(date);
}

/**
 * 1人の保護者(parentLinks 1件)に対して、対象の子の危機レベル(crisisLevel.js)に
 * 応じたLINE Pushダイジェストメッセージを送る。
 * 「通常」の場合は従来通り、今日の撮影が無ければ何も送らない
 * （即時通知は今回のスコープ外のため、19:00時点で「今日はまだ通常運転」なら静か
 * にしておく）。「注意」「家出」の場合は、今日の撮影の有無に関わらず送る。
 */
async function digestForLink(db, link, channelAccessToken) {
  const { childId, lineUserId } = link;
  if (!childId || !lineUserId) {
    logger.warn("[dailyDigest] parentLink missing childId/lineUserId, skip", { link });
    return;
  }

  const crisis = await fetchCrisisLevel(db, childId);

  if (crisis.level === "normal") {
    const createdAt = crisis.latestScore?.createdAt;
    if (!createdAt || !isTodayInJst(createdAt.toDate())) {
      logger.info("[dailyDigest] normal level and no capture today(JST), skip", { childId });
      return;
    }
  }

  const userSnap = await db.collection("users").doc(childId).get();
  const username = userSnap.exists ? userSnap.data().username : undefined;
  const text = buildDigestMessage(crisis.level, crisis.reasons, crisis.latestScore?.score, username);

  try {
    await pushText(lineUserId, text, channelAccessToken);
    logger.info("[dailyDigest] pushed", {
      childId,
      lineUserId,
      level: crisis.level,
      reasons: crisis.reasons,
    });
  } catch (error) {
    logger.warn("[dailyDigest] push failed", {
      childId,
      lineUserId,
      error: String(error),
    });
  }
}

/**
 * status: "active" な parentLinks 全件について、それぞれ独立にダイジェストを試みる。
 * 1件の失敗が他の送信をブロックしないよう、digestForLink 内で個別にエラーを握りつぶす。
 */
async function runDailyDigest(channelAccessToken) {
  const db = getFirestore();
  const linksSnap = await db.collection("parentLinks").where("status", "==", "active").get();

  logger.info("[dailyDigest] starting", { activeLinkCount: linksSnap.size });

  await Promise.all(
    linksSnap.docs.map((doc) => digestForLink(db, doc.data(), channelAccessToken))
  );

  logger.info("[dailyDigest] finished");
}

module.exports = { runDailyDigest, digestForLink, isTodayInJst };
