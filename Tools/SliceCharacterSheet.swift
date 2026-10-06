import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 4 else {
    fputs("Usage: swift SliceCharacterSheet.swift <sheet.png> <output-directory> <character-id>\n", stderr)
    exit(1)
}

let sheetURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let characterID = CommandLine.arguments[3]
let names = ["normal", "happy", "sad", "sick", "walk", "walk_alt", "cheer", "run"]

guard let source = CGImageSourceCreateWithURL(sheetURL as CFURL, nil),
      let sheet = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fputs("Could not read sprite sheet\n", stderr)
    exit(2)
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for (index, name) in names.enumerated() {
    let column = index % 4
    let row = index / 4
    let left = sheet.width * column / 4
    let top = sheet.height * row / 2
    let right = sheet.width * (column + 1) / 4
    let bottom = sheet.height * (row + 1) / 2
    let cellRect = CGRect(x: left, y: top, width: right - left, height: bottom - top)
    guard let cell = sheet.cropping(to: cellRect),
          let context = CGContext(
            data: nil, width: 512, height: 512, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else { exit(3) }

    let scale = 512 / CGFloat(max(cell.width, cell.height))
    let width = CGFloat(cell.width) * scale
    let height = CGFloat(cell.height) * scale
    context.interpolationQuality = .none
    context.setShouldAntialias(false)
    context.draw(cell, in: CGRect(x: (512 - width) / 2, y: (512 - height) / 2, width: width, height: height))

    let outputURL = outputDirectory.appendingPathComponent("\(characterID)_\(name).png")
    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { exit(4) }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { exit(5) }
    print("Created \(outputURL.path)")
}
