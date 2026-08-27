const { getFirestore } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { pushText } = require("./lineMessagingApi");

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
 * 1人の保護者(parentLinks 1件)に対して、対象の子の直近スコアが「今日」であれば
 * LINE Pushでダイジェストメッセージを送る。今日の更新が無ければ何もしない。
 */
async function digestForLink(db, link, channelAccessToken) {
  const { childId, lineUserId } = link;
  if (!childId || !lineUserId) {
    logger.warn("[dailyDigest] parentLink missing childId/lineUserId, skip", { link });
    return;
  }

  const scoreSnap = await db
    .collection("users")
    .doc(childId)
    .collection("roomScores")
    .orderBy("createdAt", "desc")
    .limit(1)
    .get();

  if (scoreSnap.empty) {
    logger.info("[dailyDigest] no roomScores yet, skip", { childId });
    return;
  }

  const scoreDoc = scoreSnap.docs[0].data();
  const createdAt = scoreDoc.createdAt;
  if (!createdAt || !isTodayInJst(createdAt.toDate())) {
    logger.info("[dailyDigest] latest score is not from today(JST), skip", { childId });
    return;
  }

  const userSnap = await db.collection("users").doc(childId).get();
  const username = userSnap.exists ? userSnap.data().username : undefined;
  const text = username
    ? `${username}ちゃんのお部屋、今日のスコアは${scoreDoc.score}点でした`
    : `お子さんのお部屋、今日のスコアは${scoreDoc.score}点でした`;

  try {
    await pushText(lineUserId, text, channelAccessToken);
    logger.info("[dailyDigest] pushed", { childId, lineUserId, score: scoreDoc.score });
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
