import SwiftUI
import AVFoundation
import UserNotifications

struct TutorialView: View {
    @AppStorage("hasShownTutorial") private var hasShownTutorial: Bool = false
    @State private var currentPage: Int = 0

    private let totalContentPages = 5

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            Group {
                switch currentPage {
                case 0: logoPage
                case 1: welcomePage
                case 2: cameraPage
                case 3: scorePage
                case 4: healthPage
                default: startPage
                }
            }
            .id(currentPage)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))

            if showsSkipButton {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: complete) {
                            Text("スキップ")
                                .font(DesignSystem.Font.footnote)
                                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }
                    }
                    Spacer()
                }
            }

            if showsPageIndicator {
                VStack {
                    Spacer()
                    pageIndicator
                        .padding(.bottom, 28)
                }
            }
        }
        .onAppear(perform: scheduleLogoTransition)
    }

    private var showsSkipButton: Bool {
        currentPage >= 1 && currentPage <= 4
    }

    private var showsPageIndicator: Bool {
        currentPage >= 1
    }

    private var pageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(1...totalContentPages, id: \.self) { i in
                Circle()
                    .fill(i == currentPage ? DesignSystem.Color.primary : DesignSystem.Color.textPrimary.opacity(0.2))
                    .frame(width: 10, height: 10)
            }
        }
    }

    private func scheduleLogoTransition() {
        guard currentPage == 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                if currentPage == 0 {
                    currentPage = 1
                }
            }
        }
    }

    private func goNext() {
        withAnimation(.easeInOut(duration: 0.35)) {
            currentPage += 1
        }
    }

    private func complete() {
        hasShownTutorial = true
    }

    // MARK: - Page 0: Logo
    private var logoPage: some View {
        Image("logo_Kireicchi")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 320)
            .transition(.opacity)
    }

    // MARK: - Page 1: Welcome
    private var welcomePage: some View {
        contentPage(
            title: "きれいっちへようこそ！",
            subtitle: "激落くんの妖精\nきれいっちと一緒に\nお部屋をきれいにしよう！",
            media: AnyView(
                CharacterView(characterType: .character01, characterState: .happy)
                    .frame(width: 280, height: 280)
            ),
            buttonTitle: "次へ",
            action: goNext
        )
    }

    // MARK: - Page 2: Camera
    private var cameraPage: some View {
        contentPage(
            title: "お部屋を撮影しよう",
            subtitle: "カメラボタンを押して\nお部屋の写真を撮るだけ！\nAIがお部屋の状態を分析するよ",
            media: AnyView(
                Image("tutorial_camera")
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 280)
            ),
            buttonTitle: "次へ",
            action: goNext
        )
    }

    // MARK: - Page 3: Score
    private var scorePage: some View {
        contentPage(
            title: "スコアが出るよ",
            subtitle: "お部屋の散らかり具合を\n100点満点でスコア化！\n片付けるべき場所も教えてくれるよ",
            media: AnyView(
                Image("tutorial_score_preview")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 320)
                    .cornerRadius(16)
            ),
            buttonTitle: "次へ",
            action: goNext
        )
    }

    // MARK: - Page 4: Health
    private var healthPage: some View {
        contentPage(
            title: "きれいっちを元気にしよう",
            subtitle: "部屋がきれいだと\nきれいっちが元気になるよ！\n7日間撮影しないと家出しちゃう…",
            media: AnyView(
                CharacterView(characterType: .character01, characterState: .sad)
                    .frame(width: 280, height: 280)
            ),
            buttonTitle: "次へ",
            action: goNext
        )
    }

    // MARK: - Page 5: Start
    private var startPage: some View {
        contentPage(
            title: "さあはじめよう！",
            subtitle: "毎日撮影して\nきれいっちを元気にしてあげてね！",
            media: AnyView(
                CharacterView(characterType: .character01, characterState: .happy)
                    .frame(width: 280, height: 280)
            ),
            buttonTitle: "はじめる",
            action: {
                Task {
                    await AVCaptureDevice.requestAccess(for: .video)
                    try? await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound, .badge])
                    hasShownTutorial = true
                }
            }
        )
    }

    private func contentPage(
        title: String,
        subtitle: String,
        media: AnyView,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 32)

            Text(title)
                .font(DesignSystem.Font.title)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 24)

            media

            Text(subtitle)
                .font(DesignSystem.Font.body)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button(buttonTitle, action: action)
                .font(DesignSystem.Font.pixelSmall)
                .foregroundColor(DesignSystem.Color.textOnPrimary)
                .padding(.horizontal, 48)
                .padding(.vertical, 14)
                .background(DesignSystem.Color.primary)
                .cornerRadius(8)
                .padding(.bottom, 32)
                .padding(.bottom, 24)
        }
    }
}

#Preview {
    TutorialView()
}
