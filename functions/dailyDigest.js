const { getFirestore } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { pushMessages, buildImageMessage } = require("./lineMessagingApi");
const { fetchCrisisLevel } = require("./crisisLevel");
const { buildDigestMessage } = require("./digestMessages");
const { computeConsecutiveCaptureDays } = require("./consecutiveCaptureDays");
const { getSignedRoomScoreImageUrl } = require("./roomScoreImage");

/**
 * 1人の保護者(parentLinks 1件)に対して、対象の子の危機レベル(crisisLevel.js)に
 * 応じたLINE Pushダイジェストメッセージを送る。
 *
 * 「通常」の場合、daysSinceLastCaptureに応じて文面を分ける（buildDigestMessage側で
 * 判定）: 当日撮影あり(0)はスコア文面＋一言＋ドット絵画像、1〜2日は軽い呼びかけ文面
 * のみ（一言・画像は付けない）。一度も撮影記録が無い(null)場合のみ送信自体をスキップ
 * する。「注意」「家出」の場合は、撮影の有無に関わらず従来通りのメッセージのみ送る
 * （一言・画像は付けない。この挙動は変更しないこと）。
 */

/**
 * LINE pushの messages 配列を組み立てる。画像（あれば）を1つ目、テキストを2つ目にする
 * （トーク画面での見え方を優先し、写真の下に説明が続く順序にしている）。画像が無い
 * 日はテキストのみになる。Firestore/Storageに依存しない純粋関数にして単体で
 * 検証しやすくしている。
 *
 * @param {string} text
 * @param {string|null} imageUrl 署名付きURL、または画像を添付しない場合は null
 */
function assembleDigestMessages(text, imageUrl) {
  const messages = [];
  if (imageUrl) {
    messages.push(buildImageMessage(imageUrl));
  }
  messages.push({ type: "text", text });
  return messages;
}

async function digestForLink(db, link, channelAccessToken) {
  const { childId, lineUserId } = link;
  if (!childId || !lineUserId) {
    logger.warn("[dailyDigest] parentLink missing childId/lineUserId, skip", { link });
    return;
  }

  const now = new Date();
  const crisis = await fetchCrisisLevel(db, childId, now);

  if (crisis.level === "normal" && crisis.daysSinceLastCapture == null) {
    logger.info("[dailyDigest] no roomScores yet, skip", { childId });
    return;
  }

  // crisisLevel.js が取得済みの roomScores（crisis.scores）を使い回し、
  // 連続撮影日数のためだけに Firestore を再度読みには行かない。
  const consecutiveCaptureDays = computeConsecutiveCaptureDays(crisis.scores, now);

  const userSnap = await db.collection("users").doc(childId).get();
  const username = userSnap.exists ? userSnap.data().username : undefined;
  const text = buildDigestMessage(
    crisis.level,
    crisis.reasons,
    crisis.latestScore?.score,
    username,
    crisis.daysSinceLastCapture,
    consecutiveCaptureDays
  );

  // 「通常」かつ当日撮影ありの日に限り、その日撮影した部屋のドット絵画像を添付する。
  // 「注意」「家出」、および「通常」だが当日未撮影の日（1〜2日）は対象外
  // （既存の危機メッセージ／軽い呼びかけ文面のみの挙動を変えない）。
  const isNormalWithCaptureToday = crisis.level === "normal" && crisis.daysSinceLastCapture === 0;
  const imageUrl = isNormalWithCaptureToday
    ? await getSignedRoomScoreImageUrl(crisis.latestScore?.imagePath)
    : null;
  const messages = assembleDigestMessages(text, imageUrl);

  try {
    await pushMessages(lineUserId, messages, channelAccessToken);
    logger.info("[dailyDigest] pushed", {
      childId,
      lineUserId,
      level: crisis.level,
      reasons: crisis.reasons,
      daysSinceLastCapture: crisis.daysSinceLastCapture,
      consecutiveCaptureDays,
      messageCount: messages.length,
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

module.exports = { runDailyDigest, digestForLink, assembleDigestMessages };
