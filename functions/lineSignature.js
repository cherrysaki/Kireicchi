const crypto = require("crypto");

/**
 * LINE Webhookの署名検証。
 * x-line-signature は「チャネルシークレットをキーとしたリクエストボディのHMAC-SHA256をBase64化した値」。
 * https://developers.line.biz/ja/reference/messaging-api/#signature-validation
 */
function verifyLineSignature(rawBody, signatureHeader, channelSecret) {
  if (!signatureHeader || !rawBody || !channelSecret) return false;

  const expected = crypto
    .createHmac("SHA256", channelSecret)
    .update(rawBody)
    .digest("base64");

  const expectedBuf = Buffer.from(expected);
  const actualBuf = Buffer.from(signatureHeader);
  if (expectedBuf.length !== actualBuf.length) return false;

  return crypto.timingSafeEqual(expectedBuf, actualBuf);
}

module.exports = { verifyLineSignature };
