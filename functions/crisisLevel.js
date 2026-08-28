/**
 * お部屋の「危機レベル」判定。
 *
 * users/{uid}/roomScores（撮影のたびに score・createdAt を追記するコレクション）
 * だけを情報源として、通常/注意/家出の3段階を判定する。dailyDigest（LINE）と
 * アプリ内お知らせ（lowScoreWarning）の両方がこのモジュールを共有し、
 * 二重実装によるロジックのズレを防ぐ。
 *
 * 注意: クライアント側の既存「7日未撮影→家出」判定（ローカルSwiftDataの
 * capturedAt基準、置き手紙演出のトリガー）とは別物。データソースが異なる
 * （こちらはFirestore roomScores基準）ため、独立した判定として扱う。
 */

// 3日／7日／3回／40点は仮の初期値。ここを変更するだけで全体の閾値を調整できる。
const CRISIS_THRESHOLDS = {
  RUNAWAY_DAYS: 7, // 未撮影日数がこれ以上で「家出」
  WARNING_DAYS: 3, // 未撮影日数がこれ以上で「注意」（家出未満の場合）
  WARNING_SCORE_STREAK: 3, // 「注意」判定に使う直近スコアの件数
  WARNING_SCORE_THRESHOLD: 40, // 直近スコアが全てこの点未満で「注意」
};

/**
 * 与えられた直近スコア群（createdAt降順、最大 WARNING_SCORE_STREAK 件）から
 * 危機レベルを判定する。Firestoreに依存しない純粋関数にして単体で検証しやすくしている。
 *
 * @param {{score: number, createdAt: {toDate: () => Date}}[]} scores createdAt降順のroomScoresドキュメント配列
 * @param {Date} now 判定基準時刻（テスト時に固定できるよう引数化）
 * @returns {{level: "normal"|"warning"|"runaway", reasons: ("noCapture"|"lowScore")[], daysSinceLastCapture: number|null, latestScore: {score: number, createdAt: {toDate: () => Date}}|null}}
 */
function computeCrisisLevel(scores, now = new Date()) {
  if (!scores || scores.length === 0) {
    // 撮影記録が一度も無い場合は判定材料が無いため「通常」として扱う（既存のdailyDigestが
    // 何も送らずスキップしていた挙動と同様、危機通知も送らない）。
    return { level: "normal", reasons: [], daysSinceLastCapture: null, latestScore: null };
  }

  const latest = scores[0];
  const daysSinceLastCapture = Math.floor(
    (now.getTime() - latest.createdAt.toDate().getTime()) / (24 * 60 * 60 * 1000)
  );

  if (daysSinceLastCapture >= CRISIS_THRESHOLDS.RUNAWAY_DAYS) {
    return { level: "runaway", reasons: ["noCapture"], daysSinceLastCapture, latestScore: latest };
  }

  const reasons = [];
  if (daysSinceLastCapture >= CRISIS_THRESHOLDS.WARNING_DAYS) {
    reasons.push("noCapture");
  }

  const recentScores = scores.slice(0, CRISIS_THRESHOLDS.WARNING_SCORE_STREAK);
  if (
    recentScores.length >= CRISIS_THRESHOLDS.WARNING_SCORE_STREAK &&
    recentScores.every((s) => s.score < CRISIS_THRESHOLDS.WARNING_SCORE_THRESHOLD)
  ) {
    reasons.push("lowScore");
  }

  if (reasons.length > 0) {
    return { level: "warning", reasons, daysSinceLastCapture, latestScore: latest };
  }

  return { level: "normal", reasons: [], daysSinceLastCapture, latestScore: latest };
}

/**
 * Firestoreから直近の roomScores を取得し、危機レベルを判定する。
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} childId
 * @param {Date} now
 */
async function fetchCrisisLevel(db, childId, now = new Date()) {
  const snap = await db
    .collection("users")
    .doc(childId)
    .collection("roomScores")
    .orderBy("createdAt", "desc")
    .limit(CRISIS_THRESHOLDS.WARNING_SCORE_STREAK)
    .get();

  const scores = snap.docs.map((doc) => doc.data());
  return computeCrisisLevel(scores, now);
}

module.exports = { CRISIS_THRESHOLDS, computeCrisisLevel, fetchCrisisLevel };
