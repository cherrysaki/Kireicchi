import SwiftUI

struct CleanupTimerView: View {
    @StateObject private var viewModel: CleanupTimerViewModel
    @EnvironmentObject var navigationRouter: NavigationRouter

    init(viewModel: CleanupTimerViewModel? = nil) {
        if let viewModel = viewModel {
            self._viewModel = StateObject(wrappedValue: viewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: CleanupTimerViewModel())
        }
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea(.all)

            GeometryReader { geo in
                let metrics = TimerMetrics(size: geo.size, isRunning: viewModel.isRunning)

                VStack(spacing: viewModel.isRunning ? 16 : 24) {
                    // 戻るボタン（画面上部）
                    HStack {
                        Button(action: {
                            navigationRouter.navigateBack()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(DesignSystem.Font.title3)
                                Text("戻る")
                                    .font(DesignSystem.Font.subheadline)
                            }
                            .foregroundColor(DesignSystem.Color.textPrimary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if !viewModel.isRunning {
                        Text("お片付けタイマー")
                            .font(DesignSystem.Font.pixelMedium)
                            .foregroundColor(DesignSystem.Color.textPrimary)
                    }

                    Spacer()

                    if !viewModel.isRunning {
                        timePickerSection
                    }

                    if viewModel.isRunning {
                        VStack(spacing: 16) {
                            Text("お片付け中...")
                                .font(DesignSystem.Font.pixelMedium)
                                .foregroundColor(DesignSystem.Color.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            timerDisplaySection(metrics)
                        }
                    } else {
                        timerDisplaySection(metrics)
                    }

                    Spacer().frame(height: viewModel.isRunning ? 8 : 16)

                    timerControlSection

                    Spacer()

                    bottomButtonSection
                }
                .padding(16)
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .navigationBarHidden(true)
        .alert("お片付け完了！", isPresented: $viewModel.isFinished) {
            Button("もう一度撮影") {
                viewModel.isFinished = false
                navigationRouter.popToRoot()
                navigationRouter.navigate(to: .capture)
            }

            Button("ホームに戻る") {
                viewModel.isFinished = false
                navigationRouter.popToRoot()
            }

            Button("もう一度タイマー") {
                viewModel.reset()
            }
        } message: {
            Text("よく頑張りました！")
        }
    }

    /// 画面サイズから実行中の円・文字サイズを決める。開始前は従来の固定値。
    private struct TimerMetrics {
        let circleSize: CGFloat
        let lineWidth: CGFloat
        let fontSize: CGFloat

        init(size: CGSize, isRunning: Bool) {
            if isRunning {
                circleSize = min(size.width - 48, size.height * 0.40, 300)
                lineWidth = 16
                fontSize = 44
            } else {
                circleSize = 220
                lineWidth = 15
                fontSize = 39
            }
        }
    }

    private var timePickerSection: some View {
        VStack(spacing: 12) {
            Text("タイマー時間")
                .font(DesignSystem.Font.pixelSmall)
                .foregroundColor(DesignSystem.Color.textPrimary)

            Picker("分", selection: $viewModel.selectedMinutes) {
                ForEach(1...30, id: \.self) { minute in
                    Text("\(minute) 分")
                        .tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(height:  150)
            .modifier(PixelCardModifier())
        }
    }

    private func timerDisplaySection(_ metrics: TimerMetrics) -> some View {
        VStack(spacing: 12) {
            if viewModel.isRunning {
                Text(timeString(from: viewModel.remainingSeconds))
                    .font(.system(size: metrics.fontSize, weight: .bold, design: .monospaced))
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            ZStack {
                Circle()
                    .stroke(DesignSystem.Color.secondary.opacity(0.3), lineWidth: metrics.lineWidth)
                    .frame(width: metrics.circleSize, height: metrics.circleSize)

                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(
                        DesignSystem.Color.primary,
                        style: StrokeStyle(lineWidth: metrics.lineWidth, lineCap: .round)
                    )
                    .frame(width: metrics.circleSize, height: metrics.circleSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: viewModel.progress)

                if viewModel.isRunning {
                    CharacterView(
                        characterType: .character01,
                        characterState: nil,
                        forceGif: .cheer
                    )
                    .frame(width: metrics.circleSize * 0.85, height: metrics.circleSize * 0.85)
                    .transition(.opacity)
                } else {
                    VStack {
                        Text(timeString(from: viewModel.remainingSeconds))
                            .font(.system(size: metrics.fontSize, weight: .bold, design: .monospaced))
                            .foregroundColor(DesignSystem.Color.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("MM:SS")
                            .font(DesignSystem.Font.pixelSmall)
                            .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                    }
                    .transition(.opacity)
                }
            }
            .frame(width: metrics.circleSize + metrics.lineWidth, height: metrics.circleSize + metrics.lineWidth)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isRunning)
        }
    }

    private var timerControlSection: some View {
        Button(action: {
            if viewModel.isRunning {
                viewModel.pause()
            } else {
                viewModel.start()
            }
        }) {
            Text(viewModel.isRunning ? "一時停止" : "始める")
                .font(DesignSystem.Font.pixelMedium)
                .foregroundColor(DesignSystem.Color.textOnPrimary)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(DesignSystem.Color.primary)
                .clipShape(PixelCornerRectangle(cornerRadius: 18))
        }
    }

    private var bottomButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                navigationRouter.popToRoot()
                navigationRouter.navigate(to: .capture)
            }) {
                Text("もう一度撮影")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
            }
            .padding(.bottom, 16)
        }
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

#Preview("開始前") {
    NavigationStack {
        CleanupTimerView()
            .environmentObject(NavigationRouter())
    }
}

#Preview("実行中") {
    let viewModel = CleanupTimerViewModel()
    viewModel.isRunning = true
    viewModel.remainingSeconds = 4 * 60 + 12
    return NavigationStack {
        CleanupTimerView(viewModel: viewModel)
            .environmentObject(NavigationRouter())
    }
}
