const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { fetchCrisisLevel } = require("./crisisLevel");
const { buildAppNotificationContent } = require("./appNotificationMessages");

/**
 * 1人のユーザーについて危機レベルを判定し、「注意」または「家出」であれば
 * users/{uid}/appNotifications に AppNotification(.lowScoreWarning) を1件書き込む。
 *
 * 状態が変化した時だけでなく、注意/家出が続く間は毎日1件ずつ生成する方式
 * （通知一覧が埋まる可能性はあるが、まずはこの方式で運用し、必要なら後で
 * 間引きを検討する）。dailyDigest（LINE）とは異なり parentLinks の有無に
 * 依らず、全ユーザーが対象。
 */
async function writeCrisisNotificationForUser(db, uid) {
  const crisis = await fetchCrisisLevel(db, uid);
  if (crisis.level !== "warning" && crisis.level !== "runaway") {
    return;
  }

  const content = buildAppNotificationContent(crisis.level, crisis.reasons);

  await db
    .collection("users")
    .doc(uid)
    .collection("appNotifications")
    .add({
      kind: "lowScoreWarning",
      title: content.title,
      body: content.body,
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });

  logger.info("[dailyCrisisNotifications] created lowScoreWarning notification", {
    uid,
    level: crisis.level,
    reasons: crisis.reasons,
  });
}

/**
 * 全ユーザーについて、それぞれ独立に危機通知の生成を試みる。
 * 1件の失敗が他のユーザーへの処理をブロックしないよう、個別にエラーを握りつぶす。
 */
async function runDailyCrisisNotifications() {
  const db = getFirestore();
  const usersSnap = await db.collection("users").get();

  logger.info("[dailyCrisisNotifications] starting", { userCount: usersSnap.size });

  await Promise.all(
    usersSnap.docs.map(async (doc) => {
      try {
        await writeCrisisNotificationForUser(db, doc.id);
      } catch (error) {
        logger.warn("[dailyCrisisNotifications] failed for user", {
          uid: doc.id,
          error: String(error),
        });
      }
    })
  );

  logger.info("[dailyCrisisNotifications] finished");
}

module.exports = { runDailyCrisisNotifications, writeCrisisNotificationForUser };
