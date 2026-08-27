const { getFirestore, FieldValue } = require("firebase-admin/firestore");

/**
 * inviteCodes/{code} を引き換えて parentLinks を作成する。
 * 成功時は { ok: true, childId }、失敗時は { ok: false, reason } を返す
 * (reason: "not_found" | "already_used" | "expired")。
 * トランザクションで inviteCodes.used=true への更新と parentLinks 作成を原子的に行う
 * (同じコードが同時に複数回引き換えられるのを防ぐ)。
 */
async function tryRedeemInviteCode(code, lineUserId) {
  const db = getFirestore();
  const inviteRef = db.collection("inviteCodes").doc(code);
  const parentLinkRef = db.collection("parentLinks").doc();

  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(inviteRef);
    if (!snapshot.exists) return { ok: false, reason: "not_found" };

    const data = snapshot.data();
    if (data.used === true) return { ok: false, reason: "already_used" };

    const expiresAt = data.expiresAt;
    if (!expiresAt || expiresAt.toMillis() <= Date.now()) {
      return { ok: false, reason: "expired" };
    }

    transaction.update(inviteRef, { used: true });
    transaction.create(parentLinkRef, {
      childId: data.childId,
      lineUserId,
      status: "active",
      linkedAt: FieldValue.serverTimestamp(),
    });

    return { ok: true, childId: data.childId };
  });
}

/**
 * 呼び出し元(context.auth.uid)がchildIdである全ての有効な(status=="active")
 * parentLinksを連携解除する。クライアントはparentLinksを読めない(ルールでdeny-all)ため、
 * linkIdではなくchildId(=requesterUid)で対象を検索する。
 * dailyDigestはstatus=="active"のみを対象にするため、statusを"unlinked"に
 * 更新するだけで送信対象から漏れなく除外できる(ハード削除は不要)。
 */
async function unlinkParentLinks(requesterUid) {
  const db = getFirestore();
  const linksSnap = await db
    .collection("parentLinks")
    .where("childId", "==", requesterUid)
    .where("status", "==", "active")
    .get();

  if (linksSnap.empty) {
    return { ok: false, reason: "not_found" };
  }

  const batch = db.batch();
  linksSnap.docs.forEach((doc) => {
    batch.update(doc.ref, {
      status: "unlinked",
      unlinkedAt: FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();

  return { ok: true, unlinkedCount: linksSnap.size };
}

module.exports = { tryRedeemInviteCode, unlinkParentLinks };
