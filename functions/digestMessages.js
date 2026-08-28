/**
 * 危機レベル（functions/crisisLevel.js）に応じた通知文面のテンプレート。
 * 文面は仮の案のため、調整しやすいようテンプレート化してある。
 */

const DIGEST_MESSAGE_TEMPLATES = {
  normal: (name, score) => `${name}のお部屋、今日のスコアは${score}点でした`,
  warningNoCapture: (name) =>
    `${name}のお部屋、しばらく片づけの記録がないようです。声をかけてあげてください`,
  warningLowScore: (name) =>
    `${name}のお部屋、最近スコアが低めな日が続いています。一緒に片づけてみてはいかがでしょうか`,
  runaway: (name) =>
    `${name}のお部屋、7日以上記録がありません。よろしければ様子を見てあげてください`,
};

function resolveDisplayName(username) {
  return username ? `${username}ちゃん` : "お子さん";
}

/**
 * 「注意」状態で未撮影・低スコア継続の両条件が同時に成立する場合、
 * 未撮影理由の文面を優先する（reasons配列の並び順には依存せず、
 * "noCapture" が含まれているかどうかで明示的に分岐する）。
 *
 * @param {"normal"|"warning"|"runaway"} level
 * @param {("noCapture"|"lowScore")[]} reasons
 * @param {number|undefined} score 「通常」の場合のみ使用
 * @param {string|undefined} username
 */
function buildDigestMessage(level, reasons, score, username) {
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

  return DIGEST_MESSAGE_TEMPLATES.normal(name, score);
}

module.exports = { DIGEST_MESSAGE_TEMPLATES, resolveDisplayName, buildDigestMessage };
