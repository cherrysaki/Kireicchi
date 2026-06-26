import SwiftUI
import AVFoundation
import UserNotifications

struct TutorialView: View {
    @AppStorage("hasShownTutorial") private var hasShownTutorial: Bool = false
    @State private var currentPage: Int = 0

    private let totalContentPages = 5

    var body: some View {
        ZStack {
            Color(hex: "FFF8E1").ignoresSafeArea()

            Group {
                switch currentPage {
                case 0: welcomePage
                case 1: cameraPage
                case 2: scorePage
                case 3: healthPage
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
    }

    private var showsSkipButton: Bool {
        currentPage <= 3
    }

    private var showsPageIndicator: Bool {
        true
    }

    private var pageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<totalContentPages, id: \.self) { i in
                Circle()
                    .fill(i == currentPage ? DesignSystem.Color.primary : DesignSystem.Color.textPrimary.opacity(0.2))
                    .frame(width: 10, height: 10)
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

    // MARK: - Page 0: Welcome
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
                    .frame(maxWidth: 180)
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
                    .clipShape(PixelCornerRectangle(cornerRadius: 16))
            ),
            buttonTitle: "次へ",
            action: goNext
        )
    }

    // MARK: - Page 4: Health
    private var healthPage: some View {
        contentPage(
            title: "きれいっちを元気にしよう！",
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
            title: "さあ始めよう！",
            subtitle: "毎日撮影して\nきれいっちを元気にしてあげてね！",
            media: AnyView(
                CharacterView(characterType: .character01, characterState: .happy)
                    .frame(width: 280, height: 280)
            ),
            buttonTitle: "始める",
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
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text(title)
                    .font(DesignSystem.Font.title)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 24)
                    .frame(height: 60, alignment: .center)

                media
                    .frame(height: 260)

                Text(subtitle)
                    .font(DesignSystem.Font.body)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .frame(height: 80, alignment: .top)
            }

            Spacer()

            Button(action: action) {
                Text(buttonTitle)
                    .font(DesignSystem.Font.pixelMedium)
                    .foregroundColor(DesignSystem.Color.textOnPrimary)
                    .frame(width: 240)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Color.primary)
                    .clipShape(PixelCornerRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 64)
        }
    }
}

#Preview {
    TutorialView()
}
