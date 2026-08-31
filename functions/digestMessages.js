/**
 * 危機レベル（functions/crisisLevel.js）に応じた通知文面のテンプレート。
 * 文面は仮の案のため、調整しやすいようテンプレート化してある。
 */

const DIGEST_MESSAGE_TEMPLATES = {
  normal: (name, score) => `${name}のお部屋、今日のスコアは${score}点でした✨`,
  lightNoCapture: (name) => `${name}のお部屋、今日は撮影がなかったようです💦`,
  warningNoCapture: (name) =>
    `${name}のお部屋、しばらく片づけの記録がないようです💦\n最近どうしてるか、少し聞いてみませんか？`,
  warningLowScore: (name) =>
    `${name}のお部屋、最近スコアが低めな日が続いています💦\n一緒にお片づけをしてみるといいかもしれません✨`,
  runaway: (name) =>
    `${name}のお部屋、7日以上記録がありません💦\nよろしければ様子を見てあげてください✨`,
};

function resolveDisplayName(username) {
  return username ? `${username}さん` : "お子さん";
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
 */
function buildDigestMessage(level, reasons, score, username, daysSinceLastCapture) {
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

  return DIGEST_MESSAGE_TEMPLATES.normal(name, score);
}

module.exports = { DIGEST_MESSAGE_TEMPLATES, resolveDisplayName, buildDigestMessage };
