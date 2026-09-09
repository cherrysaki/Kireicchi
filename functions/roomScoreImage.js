const { getStorage } = require("firebase-admin/storage");
const { logger } = require("firebase-functions");

// 署名付きURLの有効期限（日数）。仮の初期値で、ここを変更するだけで調整できる。
const SIGNED_URL_EXPIRY_DAYS = 7;

/**
 * roomScoresドキュメントに保存された imagePath から、Admin SDKで期限付き
 * 署名付きURL(v4)を生成する。恒久的な公開URLにはしない。
 *
 * imagePathが無い、Storage上にファイルが存在しない、署名付きURLの生成自体が
 * 失敗した、のいずれの場合も例外を投げず null を返す。呼び出し側（dailyDigest.js）は
 * これをテキストのみ配信へのフォールバックのトリガーとして使う（配信全体は落とさない）。
 *
 * @param {string|undefined} imagePath
 * @returns {Promise<string|null>}
 */
async function getSignedRoomScoreImageUrl(imagePath) {
  if (!imagePath) {
    return null;
  }

  try {
    const file = getStorage().bucket().file(imagePath);
    const [exists] = await file.exists();
    if (!exists) {
      logger.warn("[roomScoreImage] image not found in Storage, fallback to text-only", { imagePath });
      return null;
    }

    const [url] = await file.getSignedUrl({
      version: "v4",
      action: "read",
      expires: Date.now() + SIGNED_URL_EXPIRY_DAYS * 24 * 60 * 60 * 1000,
    });
    return url;
  } catch (error) {
    logger.warn("[roomScoreImage] failed to generate signed URL, fallback to text-only", {
      imagePath,
      error: String(error),
    });
    return null;
  }
}

module.exports = { SIGNED_URL_EXPIRY_DAYS, getSignedRoomScoreImageUrl };
