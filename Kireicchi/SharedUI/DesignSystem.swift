import SwiftUI

struct DesignSystem {
    
    // MARK: - Colors
    struct Color {
        static let primary = SwiftUI.Color(hex: "FD98B8")        // ピンク - ボタン・アクセント・スコアバナー枠
        static let secondary = SwiftUI.Color(hex: "92D9FD")      // 水色 - カード背景・ゲージ・ミッションカード枠
        static let background = SwiftUI.Color(hex: "FFF9E6")     // クリーム - 画面背景
        static let surface = SwiftUI.Color(hex: "FFFFFF")        // 白 - カード・シート背景
        static let textPrimary = SwiftUI.Color(hex: "5C3D2E")    // ダークブラウン - 本文
        static let textOnPrimary = SwiftUI.Color(hex: "FFFFFF")  // 白 - primaryボタン上のテキスト
        static let starYellow = SwiftUI.Color(hex: "FFE782")     // イエロー - 星デコレーション
        static let rankText = SwiftUI.Color(hex: "FD98B8")       // ピンク - ランク文字・スコア数字
    }
    
    // MARK: - Fonts
    struct Font {
        static let pixelLarge = SwiftUI.Font.system(size: 48, weight: .bold, design: .rounded)   // スコア数字・ランク文字
        static let pixelMedium = SwiftUI.Font.system(size: 24, weight: .bold, design: .rounded)  // セクションタイトル
        static let pixelSmall = SwiftUI.Font.system(size: 15, weight: .medium, design: .rounded) // 本文・リスト
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