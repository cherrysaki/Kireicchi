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

            VStack(spacing: viewModel.isRunning ? 40 : 24) {
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
                            .font(DesignSystem.Font.pixelLarge)
                            .foregroundColor(DesignSystem.Color.primary)

                        timerDisplaySection
                    }
                } else {
                    timerDisplaySection
                }
                
                Spacer().frame(height: 16)
                
                timerControlSection

                Spacer()

                bottomButtonSection
            }
            .padding(16)
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

    private var timerDisplaySection: some View {
        VStack(spacing: 12) {
            let circleSize: CGFloat = viewModel.isRunning ? 330 : 220
            let lineWidth: CGFloat = viewModel.isRunning ? 20 : 15
            let fontSize: CGFloat = viewModel.isRunning ? 52 : 39

            if viewModel.isRunning {
                Text(timeString(from: viewModel.remainingSeconds))
                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                    .foregroundColor(DesignSystem.Color.textPrimary)
            }

            ZStack {
                Circle()
                    .stroke(DesignSystem.Color.secondary.opacity(0.3), lineWidth: lineWidth)
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(
                        DesignSystem.Color.primary,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: viewModel.progress)

                if viewModel.isRunning {
                    CharacterView(
                        characterType: .character01,
                        characterState: nil,
                        forceGif: .cheer
                    )
                    .frame(width: circleSize * 0.85, height: circleSize * 0.85)
                    .transition(.opacity)
                } else {
                    VStack {
                        Text(timeString(from: viewModel.remainingSeconds))
                            .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                            .foregroundColor(DesignSystem.Color.textPrimary)
                        Text("MM:SS")
                            .font(DesignSystem.Font.pixelSmall)
                            .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                    }
                    .transition(.opacity)
                }
            }
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
            .padding(.bottom, 40)
        }
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    NavigationStack {
        CleanupTimerView()
            .environmentObject(NavigationRouter())
    }
}
