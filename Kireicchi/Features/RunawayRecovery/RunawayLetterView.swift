import SwiftUI

/// 家出復帰フロー: 手紙画面
/// tegami画像を表示し、3秒後に「もう一度きれいっちを迎える」ボタンを表示する
struct RunawayLetterView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter

    @State private var showButton = false

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image("tegami")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 40)

                Spacer()

                if showButton {
                    Button {
                        navigationRouter.navigate(to: .runawayRecovery(.egg))
                    } label: {
                        Text("もう一度きれいっちを迎える")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DesignSystem.Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(DesignSystem.Color.secondary.opacity(0.8))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DesignSystem.Color.textPrimary, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer().frame(height: 60)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    navigationRouter.navigateBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(DesignSystem.Color.textPrimary)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showButton = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RunawayLetterView()
            .environmentObject(NavigationRouter())
    }
}
