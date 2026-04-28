import SwiftUI

struct DesignSystem {
    
    // MARK: - Colors
    struct Color {
        static let primary = SwiftUI.Color(hex: "4DA8FF")        // ビビッドな空色 - ボタン・主要アクセント
        static let primaryDark = SwiftUI.Color(hex: "2D6BC4")    // 深い青 - shadow / 強調
        static let secondary = SwiftUI.Color(hex: "92D9FD")      // ライトブルー - カード背景・ゲージ
        static let accent = SwiftUI.Color(hex: "FFE782")         // イエロー - ハイライト・コイン的アクセント
        static let accentWarm = SwiftUI.Color(hex: "FF9F5E")     // オレンジ - スコア悪化警告
        static let background = SwiftUI.Color(hex: "FFF9E6")     // クリーム - 画面背景
        static let surface = SwiftUI.Color(hex: "FFFFFF")        // 白 - カード・シート背景
        static let textPrimary = SwiftUI.Color(hex: "2C3E50")    // ダークネイビー - 本文
        static let textOnPrimary = SwiftUI.Color(hex: "FFFFFF")  // 白 - primaryボタン上のテキスト
        static let starYellow = SwiftUI.Color(hex: "FFE782")     // イエロー - 星デコレーション(=accentエイリアス)
        static let rankText = SwiftUI.Color(hex: "2D6BC4")       // 深い青 - ランク文字・スコア数字
    }
    
    // MARK: - Fonts
    struct Font {
        private static let name = "CP-period"

        static let pixelLarge = SwiftUI.Font.custom(name, size: 52)
        static let pixelMedium = SwiftUI.Font.custom(name, size: 28)
        static let pixelSmall = SwiftUI.Font.custom(name, size: 17)

        static let largeTitle = SwiftUI.Font.custom(name, size: 38)
        static let title = SwiftUI.Font.custom(name, size: 32)
        static let title2 = SwiftUI.Font.custom(name, size: 26)
        static let title3 = SwiftUI.Font.custom(name, size: 24)
        static let headline = SwiftUI.Font.custom(name, size: 19)
        static let body = SwiftUI.Font.custom(name, size: 19)
        static let subheadline = SwiftUI.Font.custom(name, size: 17)
        static let footnote = SwiftUI.Font.custom(name, size: 15)
        static let caption = SwiftUI.Font.custom(name, size: 14)

        static func custom(size: CGFloat) -> SwiftUI.Font {
            SwiftUI.Font.custom(name, size: size)
        }
    }
    
    // MARK: - Layout
    struct Layout {
        static let cardCornerRadius: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 999  // pill型
        static let cardBorderWidth: CGFloat = 2.0
        static let shadowRadius: CGFloat = 8
        static let shadowOffset: CGFloat = 4
    }
}

// MARK: - Color Extension for Hex
extension SwiftUI.Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ViewModifiers
struct PixelCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius)
                    .stroke(DesignSystem.Color.primary, lineWidth: DesignSystem.Layout.cardBorderWidth)
            )
            .cornerRadius(DesignSystem.Layout.cardCornerRadius)
            .shadow(
                color: DesignSystem.Color.primary.opacity(0.15),
                radius: DesignSystem.Layout.shadowRadius,
                y: DesignSystem.Layout.shadowOffset
            )
    }
}

struct BluePixelCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.Color.secondary.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius)
                    .stroke(DesignSystem.Color.secondary, lineWidth: DesignSystem.Layout.cardBorderWidth)
            )
            .cornerRadius(DesignSystem.Layout.cardCornerRadius)
            .shadow(
                color: DesignSystem.Color.secondary.opacity(0.15),
                radius: DesignSystem.Layout.shadowRadius,
                y: DesignSystem.Layout.shadowOffset
            )
    }
}

// MARK: - Pixel Border Shape
struct PixelBorderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let dashLength: CGFloat = 4
        let gapLength: CGFloat = 2
        
        // Top edge
        var currentX: CGFloat = 0
        while currentX < rect.width {
            path.move(to: CGPoint(x: currentX, y: 0))
            path.addLine(to: CGPoint(x: min(currentX + dashLength, rect.width), y: 0))
            currentX += dashLength + gapLength
        }
        
        // Right edge
        var currentY: CGFloat = 0
        while currentY < rect.height {
            path.move(to: CGPoint(x: rect.width, y: currentY))
            path.addLine(to: CGPoint(x: rect.width, y: min(currentY + dashLength, rect.height)))
            currentY += dashLength + gapLength
        }
        
        // Bottom edge
        currentX = rect.width
        while currentX > 0 {
            path.move(to: CGPoint(x: currentX, y: rect.height))
            path.addLine(to: CGPoint(x: max(currentX - dashLength, 0), y: rect.height))
            currentX -= dashLength + gapLength
        }
        
        // Left edge
        currentY = rect.height
        while currentY > 0 {
            path.move(to: CGPoint(x: 0, y: currentY))
            path.addLine(to: CGPoint(x: 0, y: max(currentY - dashLength, 0)))
            currentY -= dashLength + gapLength
        }
        
        return path
    }
}

// MARK: - Pixel Square Card (sharp corners, chunky border, blocky shadow)
struct PixelSquareCardModifier: ViewModifier {
    var fill: SwiftUI.Color = DesignSystem.Color.surface
    var border: SwiftUI.Color = DesignSystem.Color.primary
    var borderWidth: CGFloat = 3
    var shadowOffset: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .background(fill)
            .overlay(
                Rectangle()
                    .stroke(border, lineWidth: borderWidth)
            )
            .background(
                Rectangle()
                    .fill(border.opacity(0.35))
                    .offset(x: shadowOffset, y: shadowOffset)
            )
    }
}

extension View {
    func pixelSquareCard(
        fill: SwiftUI.Color = DesignSystem.Color.surface,
        border: SwiftUI.Color = DesignSystem.Color.primary,
        borderWidth: CGFloat = 3,
        shadowOffset: CGFloat = 4
    ) -> some View {
        modifier(PixelSquareCardModifier(fill: fill, border: border, borderWidth: borderWidth, shadowOffset: shadowOffset))
    }
}

// MARK: - Pixel Button Style (square, chunky border, press-down shadow)
struct PixelButtonStyle: ButtonStyle {
    var fill: SwiftUI.Color = DesignSystem.Color.primary
    var foreground: SwiftUI.Color = DesignSystem.Color.textOnPrimary
    var border: SwiftUI.Color = DesignSystem.Color.primaryDark
    var borderWidth: CGFloat = 3
    var shadowOffset: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Rectangle()
                .fill(border)
                .offset(x: configuration.isPressed ? 0 : shadowOffset,
                        y: configuration.isPressed ? 0 : shadowOffset)

            Rectangle()
                .fill(fill)
                .overlay(Rectangle().stroke(border, lineWidth: borderWidth))
                .overlay(configuration.label.foregroundColor(foreground))
                .offset(x: configuration.isPressed ? shadowOffset : 0,
                        y: configuration.isPressed ? shadowOffset : 0)
        }
        .animation(.linear(duration: 0.05), value: configuration.isPressed)
    }
}

// MARK: - Pixel Circle Shape (stair-step)
struct PixelCircle: Shape {
    var pixelSize: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2
        let cx = rect.midX
        let cy = rect.midY
        let cols = Int(rect.width / pixelSize)
        let rows = Int(rect.height / pixelSize)
        for row in 0..<rows {
            for col in 0..<cols {
                let x = rect.minX + CGFloat(col) * pixelSize
                let y = rect.minY + CGFloat(row) * pixelSize
                let dx = x + pixelSize / 2 - cx
                let dy = y + pixelSize / 2 - cy
                if dx * dx + dy * dy <= radius * radius {
                    path.addRect(CGRect(x: x, y: y, width: pixelSize, height: pixelSize))
                }
            }
        }
        return path
    }
}

struct PixelCircleStroke: Shape {
    var pixelSize: CGFloat = 4
    var lineWidth: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        let outer = PixelCircle(pixelSize: pixelSize).path(in: rect)
        let innerRect = rect.insetBy(dx: lineWidth, dy: lineWidth)
        let inner = PixelCircle(pixelSize: pixelSize).path(in: innerRect)
        return outer.subtracting(inner)
    }
}

// MARK: - Pixel Frame Modifier (stair-step square)
struct PixelFrameModifier: ViewModifier {
    var pixelSize: CGFloat = 4
    var background: SwiftUI.Color = SwiftUI.Color.black.opacity(0.5)
    var borderColor: SwiftUI.Color = SwiftUI.Color.white

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(background)
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: pixelSize)
            )
    }
}

extension View {
    func pixelFrame(
        pixelSize: CGFloat = 4,
        background: SwiftUI.Color = SwiftUI.Color.black.opacity(0.5),
        borderColor: SwiftUI.Color = SwiftUI.Color.white
    ) -> some View {
        modifier(PixelFrameModifier(pixelSize: pixelSize, background: background, borderColor: borderColor))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Text("68")
            .font(DesignSystem.Font.pixelLarge)
            .foregroundColor(DesignSystem.Color.rankText)
        
        Text("セクションタイトル")
            .font(DesignSystem.Font.pixelMedium)
            .foregroundColor(DesignSystem.Color.textPrimary)
        
        Text("本文テキストのサンプル")
            .font(DesignSystem.Font.pixelSmall)
            .foregroundColor(DesignSystem.Color.textPrimary)
        
        Text("ピクセルカード")
            .padding()
            .modifier(PixelCardModifier())
        
        Text("ブルーピクセルカード")
            .padding()
            .modifier(BluePixelCardModifier())
        
        Rectangle()
            .fill(DesignSystem.Color.surface)
            .frame(width: 100, height: 60)
            .overlay(
                PixelBorderShape()
                    .stroke(DesignSystem.Color.primary, lineWidth: 2)
            )
    }
    .padding()
    .background(DesignSystem.Color.background)
}