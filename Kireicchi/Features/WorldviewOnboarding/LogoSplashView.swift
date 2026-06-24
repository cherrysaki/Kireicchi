import SwiftUI

struct LogoSplashView: View {
    @AppStorage("hasShownLogoSplash") private var hasShownLogoSplash: Bool = false
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            Image("logo_Kireicchi")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .opacity(opacity)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.8)) {
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    hasShownLogoSplash = true
                }
            }
        }
    }
}

#Preview {
    LogoSplashView()
}
