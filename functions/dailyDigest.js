const { getFirestore } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { pushText } = require("./lineMessagingApi");
const { fetchCrisisLevel } = require("./crisisLevel");
const { buildDigestMessage } = require("./digestMessages");

/**
 * 1人の保護者(parentLinks 1件)に対して、対象の子の危機レベル(crisisLevel.js)に
 * 応じたLINE Pushダイジェストメッセージを送る。
 *
 * 「通常」の場合、daysSinceLastCaptureに応じて文面を分ける（buildDigestMessage側で
 * 判定）: 当日撮影あり(0)はスコア文面、1〜2日は軽い呼びかけ文面。一度も撮影記録が
 * 無い(null)場合のみ送信自体をスキップする。「注意」「家出」の場合は、撮影の有無に
 * 関わらず送る。
 */
async function digestForLink(db, link, channelAccessToken) {
  const { childId, lineUserId } = link;
  if (!childId || !lineUserId) {
    logger.warn("[dailyDigest] parentLink missing childId/lineUserId, skip", { link });
    return;
  }

  const crisis = await fetchCrisisLevel(db, childId);

  if (crisis.level === "normal" && crisis.daysSinceLastCapture == null) {
    logger.info("[dailyDigest] no roomScores yet, skip", { childId });
    return;
  }

  const userSnap = await db.collection("users").doc(childId).get();
  const username = userSnap.exists ? userSnap.data().username : undefined;
  const text = buildDigestMessage(
    crisis.level,
    crisis.reasons,
    crisis.latestScore?.score,
    username,
    crisis.daysSinceLastCapture
  );

  try {
    await pushText(lineUserId, text, channelAccessToken);
    logger.info("[dailyDigest] pushed", {
      childId,
      lineUserId,
      level: crisis.level,
      reasons: crisis.reasons,
      daysSinceLastCapture: crisis.daysSinceLastCapture,
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

module.exports = { runDailyDigest, digestForLink };
