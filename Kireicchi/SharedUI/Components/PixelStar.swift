import SwiftUI

struct PixelStar: View {
    var size: CGFloat = 20
    var color: SwiftUI.Color = DesignSystem.Color.starYellow

    var body: some View {
        Image(systemName: "star.fill")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundColor(color)
    }
}

#Preview {
    VStack(spacing: 16) {
        PixelStar()
        PixelStar(size: 32)
        PixelStar(size: 48)
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { _ in
                PixelStar(size: 14)
            }
        }
    }
    .padding()
    .background(DesignSystem.Color.background)
}
