const { getFirestore, FieldValue } = require("firebase-admin/firestore");

/**
 * inviteCodes/{code} を引き換えて parentLinks を作成する。
 * 存在しない・使用済み・期限切れのいずれかであれば null を返し、何もしない。
 * トランザクションで inviteCodes.used=true への更新と parentLinks 作成を原子的に行う
 * (同じコードが同時に複数回引き換えられるのを防ぐ)。
 */
async function tryRedeemInviteCode(code, lineUserId) {
  const db = getFirestore();
  const inviteRef = db.collection("inviteCodes").doc(code);
  const parentLinkRef = db.collection("parentLinks").doc();

  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(inviteRef);
    if (!snapshot.exists) return null;

    const data = snapshot.data();
    if (data.used === true) return null;

    const expiresAt = data.expiresAt;
    if (!expiresAt || expiresAt.toMillis() <= Date.now()) return null;

    transaction.update(inviteRef, { used: true });
    transaction.create(parentLinkRef, {
      childId: data.childId,
      lineUserId,
      status: "active",
      linkedAt: FieldValue.serverTimestamp(),
    });

    return { childId: data.childId };
  });
}

module.exports = { tryRedeemInviteCode };
