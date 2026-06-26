import SwiftUI
import UIKit

struct WorldviewOnboardingView: View {
    @AppStorage("hasShownWorldviewOnboarding") private var hasShownWorldviewOnboarding: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image("onboarding_morning_room")
                    .resizable()
                    .scaledToFit()

                Text("ある朝、\nふしぎな出来事が\nありました。")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                    .padding(.horizontal, 32)

                decoratorSeparator
                    .padding(.horizontal, 32)

                Image("onboarding_egg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80)
                    .padding(.bottom, 24)

                Text("目を覚ますと、\n窓辺に見慣れない卵が\n置かれていました。")
                    .font(.system(size: 13))
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Image("onboarding_kireicchi")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                Text("その卵の中には、\nきれいっちという\n小さな妖精が\n眠っています。")
                    .font(.system(size: 13))
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                HStack(spacing: 32) {
                    StaticGIFView(gifName: "character01_happy")
                        .frame(width: 100, height: 100)
                    StaticGIFView(gifName: "character01_sad")
                        .frame(width: 100, height: 100)
                }
                .padding(.top, 32)

                VStack(spacing: 12) {
                    Text("きれいっちは、\nお部屋を見守る妖精です。")
                    Text("お部屋が片付くと元気に。")
                    Text("散らかるとしょんぼり。")
                    Text("そして、さみしい日が続くと、\n旅に出てしまうことも。")
                }
                .font(.system(size: 13))
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 32)
                .padding(.horizontal, 32)

                decoratorSeparator
                    .padding(.horizontal, 32)

                Text("きれいっちと一緒に、\n\n心地よいお部屋を\nつくりませんか？")
                    .font(.system(size: 13))
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    hasShownWorldviewOnboarding = true
                } label: {
                    Text("きれいっちをお迎えする")
                        .font(DesignSystem.Font.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
                .buttonStyle(PixelButtonStyle())
                .padding(.horizontal, 40)
                .padding(.top, 24)
                .padding(.bottom, 50)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(DesignSystem.Color.background.ignoresSafeArea())
    }

    private var decoratorSeparator: some View {
        HStack(spacing: 8) {
            dashedLine
            Text("✦")
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.Color.primary.opacity(0.6))
            dashedLine
        }
        .padding(.vertical, 40)
    }

    private var dashedLine: some View {
        DashedLine()
            .stroke(DesignSystem.Color.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .frame(width: 80, height: 1)
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

private struct StaticGIFView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIImageView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        guard let gifData = NSDataAsset(name: gifName)?.data,
              let source = CGImageSourceCreateWithData(gifData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return
        }
        uiView.image = UIImage(cgImage: cgImage)
    }
}

#Preview {
    WorldviewOnboardingView()
}
