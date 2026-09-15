/**
 * 「連続撮影日数」の算出。
 *
 * users/{uid}/roomScores の createdAt を JST(Asia/Tokyo)の日付単位でユニーク化し、
 * 当日から過去に向かって途切れずに続いている日数を求める。同じ日に複数回撮影が
 * あっても1日と数え、当日の撮影が無ければ 0 を返す。
 *
 * crisisLevel.js の fetchCrisisLevel が同じ roomScores を既に取得しているため、
 * ここでは Firestore を読まない（純粋関数のみを提供する）。呼び出し側は
 * fetchCrisisLevel が返す scores 配列をそのまま computeConsecutiveCaptureDays に渡すこと。
 */

const JST_OFFSET_MS = 9 * 60 * 60 * 1000;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * dateをJST(Asia/Tokyo)の日付文字列(YYYY-MM-DD)に変換する。
 * タイムゾーンライブラリを増やさないための簡易実装（UTC+9して日付部分を切り出す）。
 *
 * @param {Date} date
 * @returns {string}
 */
function toJstDateString(date) {
  return new Date(date.getTime() + JST_OFFSET_MS).toISOString().slice(0, 10);
}

/**
 * @param {{createdAt: {toDate: () => Date}}[]} scores roomScoresドキュメント配列（順不同で可）
 * @param {Date} now 判定基準時刻（テスト時に固定できるよう引数化）
 * @returns {number} 当日から過去に向かって途切れず続いている撮影日数（当日未撮影なら0）
 */
function computeConsecutiveCaptureDays(scores, now = new Date()) {
  if (!scores || scores.length === 0) {
    return 0;
  }

  const capturedJstDates = new Set(scores.map((s) => toJstDateString(s.createdAt.toDate())));
  const todayStr = toJstDateString(now);
  if (!capturedJstDates.has(todayStr)) {
    return 0;
  }

  let streak = 0;
  let cursorMs = now.getTime();
  while (capturedJstDates.has(toJstDateString(new Date(cursorMs)))) {
    streak += 1;
    cursorMs -= MS_PER_DAY;
  }
  return streak;
}

module.exports = { toJstDateString, computeConsecutiveCaptureDays };
