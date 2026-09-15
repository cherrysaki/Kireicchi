/**
 * 危機レベル（functions/crisisLevel.js）に応じた通知文面のテンプレート。
 * 文面は仮の案のため、調整しやすいようテンプレート化してある。
 */

const DIGEST_MESSAGE_TEMPLATES = {
  lightNoCapture: (name) => `${name}のお部屋、今日は撮影がなかったようです💦`,
  warningNoCapture: (name) =>
    `${name}のお部屋、しばらく片づけの記録がないようです💦\n最近どうしてるか、少し聞いてみませんか？`,
  warningLowScore: (name) =>
    `${name}のお部屋、最近スコアが低めな日が続いています💦\n一緒にお片づけをしてみるといいかもしれません✨`,
  runaway: (name) =>
    `${name}のお部屋、7日以上記録がありません💦\nよろしければ様子を見てあげてください✨`,
};

// 80点／60点は仮の初期値。ここを変更するだけでスコア帯の区切りを調整できる。
const SCORE_BAND_THRESHOLDS = {
  HIGH_MIN: 80, // これ以上で high
  MID_MIN: 60, // これ以上 HIGH_MIN未満で mid、それ未満は low
};

// 2日／7日は仮の初期値。ここを変更するだけで連続日数帯の区切りを調整できる。
const STREAK_BAND_THRESHOLDS = {
  SHORT_MIN: 2, // これ以上 LONG_MIN未満で short（1日は first）
  LONG_MIN: 7, // これ以上で long
};

/**
 * 「通常」かつ当日撮影ありの日に送る一言（AI生成ではない固定文言）。
 * スコア帯(high/mid/low) × 連続撮影日数帯(first/short/long) の9パターン。
 */
const NORMAL_DAY_ONE_LINERS = {
  high: {
    first: "今日はしっかり片づいた状態で記録できています。ひとこと伝えてみてください。",
    short: "きれいな状態が続いています。自分のペースがつかめてきているようです。",
    long: "1週間以上、きれいな状態を保てています。かなり習慣になってきました。",
  },
  mid: {
    first: "今日の記録が入りました。少しずつ整いはじめています。",
    short: "記録が続いています。少しずつ整ってきました。",
    long: "記録が長く続いています。無理のないペースが定着してきたようです。",
  },
  low: {
    first: "今日は記録を残すことができました。続けること自体が一歩です。",
    short: "点数に波はありますが、記録は続いています。",
    long: "点数はまちまちですが、続けることが習慣になっています。",
  },
};

function resolveDisplayName(username) {
  return username ? `${username}さん` : "お子さん";
}

function resolveScoreBand(score) {
  if (score >= SCORE_BAND_THRESHOLDS.HIGH_MIN) return "high";
  if (score >= SCORE_BAND_THRESHOLDS.MID_MIN) return "mid";
  return "low";
}

function resolveStreakBand(consecutiveCaptureDays) {
  if (consecutiveCaptureDays >= STREAK_BAND_THRESHOLDS.LONG_MIN) return "long";
  if (consecutiveCaptureDays >= STREAK_BAND_THRESHOLDS.SHORT_MIN) return "short";
  return "first";
}

/**
 * 「通常」かつ当日撮影ありの日の本文を組み立てる。
 *
 * この関数は daysSinceLastCapture === 0 の場合にのみ呼ばれる想定であり、
 * その前提のもとでは consecutiveCaptureDays は必ず1以上になる
 * （当日の撮影が無ければ computeConsecutiveCaptureDays は0を返す仕様のため）。
 * この前提が崩れる呼び出し方をすると streakBand が意図せず "first" 扱いになるので注意。
 *
 * @param {string} name resolveDisplayName適用済みの呼称
 * @param {number} score 当日のスコア
 * @param {number} consecutiveCaptureDays 連続撮影日数（1以上を想定）
 */
function buildNormalDayMessage(name, score, consecutiveCaptureDays) {
  const lines = [`${name}のお部屋、今日は${score}点でした✨`];
  if (consecutiveCaptureDays >= 2) {
    lines.push(`${consecutiveCaptureDays}日連続で記録がついています。`);
  }
  lines.push("");
  lines.push(NORMAL_DAY_ONE_LINERS[resolveScoreBand(score)][resolveStreakBand(consecutiveCaptureDays)]);
  return lines.join("\n");
}

/**
 * 「注意」状態で未撮影・低スコア継続の両条件が同時に成立する場合、
 * 未撮影理由の文面を優先する（reasons配列の並び順には依存せず、
 * "noCapture" が含まれているかどうかで明示的に分岐する）。
 *
 * 「通常」状態でも、daysSinceLastCaptureが1〜2日（＝まだ「注意」には至らないが
 * 当日の撮影も無い）の場合は、スコア文面ではなく軽い呼びかけの文面を返す。
 *
 * @param {"normal"|"warning"|"runaway"} level
 * @param {("noCapture"|"lowScore")[]} reasons
 * @param {number|undefined} score 「通常」かつ当日撮影ありの場合のみ使用
 * @param {string|undefined} username
 * @param {number|null|undefined} daysSinceLastCapture
 * @param {number|undefined} consecutiveCaptureDays 「通常」かつ当日撮影ありの場合のみ使用
 */
function buildDigestMessage(level, reasons, score, username, daysSinceLastCapture, consecutiveCaptureDays) {
  const name = resolveDisplayName(username);

  if (level === "runaway") {
    return DIGEST_MESSAGE_TEMPLATES.runaway(name);
  }

  if (level === "warning") {
    if (reasons.includes("noCapture")) {
      return DIGEST_MESSAGE_TEMPLATES.warningNoCapture(name);
    }
    return DIGEST_MESSAGE_TEMPLATES.warningLowScore(name);
  }

  if (daysSinceLastCapture === 1 || daysSinceLastCapture === 2) {
    return DIGEST_MESSAGE_TEMPLATES.lightNoCapture(name);
  }

  return buildNormalDayMessage(name, score, consecutiveCaptureDays);
}

module.exports = {
  DIGEST_MESSAGE_TEMPLATES,
  SCORE_BAND_THRESHOLDS,
  STREAK_BAND_THRESHOLDS,
  NORMAL_DAY_ONE_LINERS,
  resolveDisplayName,
  resolveScoreBand,
  resolveStreakBand,
  buildNormalDayMessage,
  buildDigestMessage,
};
