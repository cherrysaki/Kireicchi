import Foundation
import UIKit

struct PixelArtRequest {
    let imageData: Data
    let prompt: String
    let model: String
    let size: String
    let quality: String
    let count: Int

    init(imageData: Data) {
        self.imageData = UIImage(data: imageData)?.pngData() ?? imageData
        self.model = "gpt-image-1"
        self.size = "1024x1024"
        self.quality = "medium"
        self.count = 1
        self.prompt = """
        Convert this room photograph into pixel art at approximately 512x512 pixel resolution, \
        8-bit retro game aesthetic. Preserve the overall scene composition and visible objects. \
        Use flat colors, clearly visible pixel grid, no gradients or anti-aliasing.
        """
    }

    func multipartBody(boundary: String) -> Data {
        var body = Data()

        body.appendField(name: "model", value: model, boundary: boundary)
        body.appendField(name: "prompt", value: prompt, boundary: boundary)
        body.appendField(name: "size", value: size, boundary: boundary)
        body.appendField(name: "quality", value: quality, boundary: boundary)
        body.appendField(name: "n", value: String(count), boundary: boundary)
        body.appendFile(
            name: "image",
            filename: "room.png",
            contentType: "image/png",
            data: imageData,
            boundary: boundary
        )

        body.appendString("--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }

    mutating func appendField(name: String, value: String, boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        appendString("\(value)\r\n")
    }

    mutating func appendFile(name: String, filename: String, contentType: String, data: Data, boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        appendString("Content-Type: \(contentType)\r\n\r\n")
        append(data)
        appendString("\r\n")
    }
}
