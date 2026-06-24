import SwiftUI

struct HomeTabBar: View {
    let onHome: () -> Void
    let onCapture: () -> Void
    let onFriends: () -> Void
    var canCapture: Bool = true

    var body: some View {
        ZStack {
            Capsule()
                .fill(DesignSystem.Color.primary)
                .overlay(
                    Capsule()
                        .stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
                )
                .frame(height: 60)
                .padding(.horizontal, 32)

            HStack {
                Button(action: onHome) {
                    Image(systemName: "house.fill")
                        .font(DesignSystem.Font.title3)
                        .foregroundColor(DesignSystem.Color.primaryDark)
                        .frame(width: 56, height: 56)
                }

                Spacer()

                Button(action: onFriends) {
                    Image(systemName: "figure.2")
                        .font(DesignSystem.Font.title3)
                        .foregroundColor(DesignSystem.Color.primaryDark)
                        .frame(width: 56, height: 56)
                }
            }
            .padding(.horizontal, 56)

            Button(action: onCapture) {
                ZStack {
                    Circle()
                        .fill(canCapture ? DesignSystem.Color.primary : Color.gray)
                        .overlay(
                            Circle()
                                .stroke(canCapture ? DesignSystem.Color.primaryDark : Color.gray.opacity(0.7), lineWidth: 3)
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: "camera.fill")
                        .font(DesignSystem.Font.title2)
                        .foregroundColor(canCapture ? DesignSystem.Color.primaryDark : Color.white.opacity(0.8))
                }
                .anchorPreference(key: CoachAnchorKey.self, value: .bounds) {
                    CoachAnchors(settings: nil, camera: $0)
                }
            }
            .offset(y: -18)
        }
    }
}

#Preview {
    ZStack {
        DesignSystem.Color.background.ignoresSafeArea()
        VStack {
            Spacer()
            HomeTabBar(onHome: {}, onCapture: {}, onFriends: {})
                .padding(.bottom, 16)
        }
    }
}
