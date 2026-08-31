/**
 * アプリ内お知らせ（AppNotification .lowScoreWarning）用の文面テンプレート。
 *
 * LINEダイジェスト（digestMessages.js）は保護者向け・第三者視点の文面だが、
 * こちらは受け手（子ども本人）も文体（きれいっち＝キャラクターからの一人称の
 * 呼びかけ）も異なるため、テンプレートを共有せず別々に管理する。
 * 文面は仮の案（実装しやすい形でテンプレート化してある）。
 */

const APP_NOTIFICATION_TEMPLATES = {
  warningNoCapture: {
    title: "きれいっちが寂しがってるよ",
    body: "しばらく会えてないね…お部屋の様子、見せてくれる？",
  },
  warningLowScore: {
    title: "きれいっちが弱ってるよ！",
    body: "このままだときれいっちが家出しちゃう！少しだけでもお片付けしよう",
  },
  runaway: {
    title: "きれいっちが家出しちゃったかも",
    body: "もう7日も会えてないよ…お部屋、大丈夫？迎えに来てくれる？",
  },
};

/**
 * 「注意」で未撮影・低スコア継続の両条件が同時に成立する場合、未撮影理由を
 * 優先する（digestMessages.buildDigestMessage と同じ考え方。reasons配列の
 * 並び順には依存せず、"noCapture" が含まれているかどうかで明示的に分岐する）。
 *
 * @param {"warning"|"runaway"} level 呼び出し元で "normal" を除外している前提
 * @param {("noCapture"|"lowScore")[]} reasons
 * @returns {{title: string, body: string}}
 */
function buildAppNotificationContent(level, reasons) {
  if (level === "runaway") {
    return APP_NOTIFICATION_TEMPLATES.runaway;
  }
  if (reasons.includes("noCapture")) {
    return APP_NOTIFICATION_TEMPLATES.warningNoCapture;
  }
  return APP_NOTIFICATION_TEMPLATES.warningLowScore;
}

module.exports = { APP_NOTIFICATION_TEMPLATES, buildAppNotificationContent };
