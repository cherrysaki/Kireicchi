import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

private struct Frame {
    let sourceName: String?
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat
    let duration: Double
    let flippedHorizontally: Bool

    init(
        sourceName: String? = nil,
        x: CGFloat,
        y: CGFloat,
        scale: CGFloat,
        duration: Double,
        flippedHorizontally: Bool = false
    ) {
        self.sourceName = sourceName
        self.x = x
        self.y = y
        self.scale = scale
        self.duration = duration
        self.flippedHorizontally = flippedHorizontally
    }
}

private struct Animation {
    let name: String
    let frames: [Frame]
}

private func makeWalkFrames() -> [Frame] {
    let stepCount = 16
    let travelDistance: CGFloat = 300
    let startX = -travelDistance / 2
    var frames: [Frame] = []

    for index in 0..<stepCount {
        let progress = CGFloat(index) / CGFloat(stepCount - 1)
        let isAlternateStep = index.isMultiple(of: 2) == false
        frames.append(Frame(
            sourceName: isAlternateStep ? "walk_alt" : "walk",
            x: startX + travelDistance * progress,
            y: isAlternateStep ? 5 : 0,
            scale: 1,
            duration: 0.11
        ))
    }

    for index in 0..<stepCount {
        let progress = CGFloat(index) / CGFloat(stepCount - 1)
        let isAlternateStep = index.isMultiple(of: 2) == false
        frames.append(Frame(
            sourceName: isAlternateStep ? "walk_alt" : "walk",
            x: -startX - travelDistance * progress,
            y: isAlternateStep ? 5 : 0,
            scale: 1,
            duration: 0.11,
            flippedHorizontally: true
        ))
    }

    return frames
}

private let animations = [
    Animation(name: "normal", frames: [
        Frame(x: 0, y: 0, scale: 1, duration: 0.28),
        Frame(x: 0, y: 3, scale: 1, duration: 0.18),
        Frame(x: 0, y: 0, scale: 1, duration: 0.28),
        Frame(x: 0, y: -2, scale: 1, duration: 0.18)
    ]),
    Animation(name: "happy", frames: [
        Frame(x: 0, y: 0, scale: 1, duration: 0.22),
        Frame(x: 0, y: 8, scale: 1.01, duration: 0.16),
        Frame(x: 0, y: 0, scale: 1, duration: 0.22),
        Frame(x: 0, y: 4, scale: 1, duration: 0.16)
    ]),
    Animation(name: "sad", frames: [
        Frame(x: 0, y: 0, scale: 1, duration: 0.42),
        Frame(x: 0, y: -2, scale: 0.995, duration: 0.32)
    ]),
    Animation(name: "sick", frames: [
        Frame(x: -2, y: 0, scale: 1, duration: 0.34),
        Frame(x: 2, y: -2, scale: 0.995, duration: 0.34),
        Frame(x: 0, y: 0, scale: 1, duration: 0.34)
    ]),
    Animation(name: "walk", frames: makeWalkFrames()),
    Animation(name: "cheer", frames: [
        Frame(x: 0, y: 0, scale: 1, duration: 0.18),
        Frame(x: 0, y: 20, scale: 1.01, duration: 0.16),
        Frame(x: 0, y: 34, scale: 1.015, duration: 0.18),
        Frame(x: 0, y: 14, scale: 1.005, duration: 0.16)
    ]),
    Animation(name: "run", frames: [
        Frame(x: -24, y: 0, scale: 1, duration: 0.11),
        Frame(x: -8, y: 10, scale: 1, duration: 0.10),
        Frame(x: 10, y: 2, scale: 1, duration: 0.11),
        Frame(x: 24, y: 8, scale: 1, duration: 0.10)
    ])
]

private let canvasWidth = 800
private let canvasHeight = 450
private let baseSize: CGFloat = 420

guard (3...4).contains(CommandLine.arguments.count) else {
    fputs("Usage: swift MakeCharacterGIFs.swift <source-directory> <asset-directory> [character-id]\n", stderr)
    exit(1)
}

let sourceDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let assetDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let characterID = CommandLine.arguments.count == 4 ? CommandLine.arguments[3] : "character02"

for animation in animations {
    let outputURL = assetDirectory
        .appendingPathComponent("\(characterID)_\(animation.name).dataset", isDirectory: true)
        .appendingPathComponent("\(characterID)_\(animation.name).gif")

    guard let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.gif.identifier as CFString,
        animation.frames.count,
        nil
    ) else {
        fputs("Could not create \(outputURL.path)\n", stderr)
        exit(3)
    }

    CGImageDestinationSetProperties(destination, [
        kCGImagePropertyGIFDictionary: [
            kCGImagePropertyGIFLoopCount: 0
        ]
    ] as CFDictionary)

    for frame in animation.frames {
        let sourceName = frame.sourceName ?? animation.name
        let sourceURL = sourceDirectory.appendingPathComponent("\(characterID)_\(sourceName).png")
        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let sourceImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            fputs("Could not read \(sourceURL.path)\n", stderr)
            exit(2)
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: canvasWidth,
            height: canvasHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            exit(4)
        }

        context.interpolationQuality = .none
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)
        context.clear(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))

        let aspectRatio = CGFloat(sourceImage.width) / CGFloat(sourceImage.height)
        let height = baseSize * frame.scale
        let width = height * aspectRatio
        let rect = CGRect(
            x: (CGFloat(canvasWidth) - width) / 2 + frame.x,
            y: (CGFloat(canvasHeight) - height) / 2 + frame.y,
            width: width,
            height: height
        )
        if frame.flippedHorizontally {
            context.saveGState()
            context.translateBy(x: CGFloat(canvasWidth), y: 0)
            context.scaleBy(x: -1, y: 1)
            let mirroredRect = CGRect(
                x: CGFloat(canvasWidth) - rect.maxX,
                y: rect.minY,
                width: rect.width,
                height: rect.height
            )
            context.draw(sourceImage, in: mirroredRect)
            context.restoreGState()
        } else {
            context.draw(sourceImage, in: rect)
        }

        guard let renderedImage = context.makeImage() else { exit(5) }
        let properties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: frame.duration,
                kCGImagePropertyGIFUnclampedDelayTime: frame.duration
            ]
        ] as CFDictionary
        CGImageDestinationAddImage(destination, renderedImage, properties)
    }

    guard CGImageDestinationFinalize(destination) else {
        fputs("Could not finalize \(outputURL.path)\n", stderr)
        exit(6)
    }

    print("Created \(outputURL.path)")
}
