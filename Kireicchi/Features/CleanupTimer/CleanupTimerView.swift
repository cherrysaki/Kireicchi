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
            // 背景（タイマー実行中は画面全体に広げる）
            if viewModel.isRunning {
                DesignSystem.Color.background
                    .ignoresSafeArea(.all)
            } else {
                DesignSystem.Color.background
            }
            
            VStack(spacing: viewModel.isRunning ? 40 : 24) {
                // タイトル（タイマー実行中は目立たなくする）
                if !viewModel.isRunning {
                    Text("お片付けタイマー")
                        .font(DesignSystem.Font.pixelMedium)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                        .padding(.top, 20)
                }
                
                Spacer()
                
                // 時間設定エリア（タイマー停止中のみ操作可能）
                if !viewModel.isRunning {
                    timePickerSection
                }
                
                // タイマー表示（実行中は大きく表示）
                if viewModel.isRunning {
                    VStack(spacing: 30) {
                        Text("お片付け中...")
                            .font(DesignSystem.Font.pixelLarge)
                            .foregroundColor(DesignSystem.Color.primary)
                        
                        CharacterView(
                            characterType: .character01,
                            characterState: nil,
                            forceGif: .cheer
                        )
                        .frame(width: 100, height: 100)
                        
                        timerDisplaySection
                    }
                } else {
                    timerDisplaySection
                }
                
                // 操作ボタン（停止中のみ表示）
                if !viewModel.isRunning {
                    timerControlSection
                }
                
                Spacer()
                
                // 下部ボタン（実行中は小さく表示）
                if viewModel.isRunning {
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.pause()
                        }) {
                            Text("いちじていし")
                                .font(DesignSystem.Font.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(PixelButtonStyle(
                            fill: DesignSystem.Color.surface,
                            foreground: DesignSystem.Color.primaryDark,
                            border: DesignSystem.Color.primaryDark,
                            borderWidth: 2,
                            shadowOffset: 2
                        ))

                        Button(action: {
                            navigationRouter.navigateBack()
                        }) {
                            Text("もどる")
                                .font(DesignSystem.Font.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(PixelButtonStyle(
                            fill: DesignSystem.Color.surface,
                            foreground: DesignSystem.Color.primaryDark,
                            border: DesignSystem.Color.primaryDark,
                            borderWidth: 2,
                            shadowOffset: 2
                        ))
                    }
                    .padding(.bottom, 40)
                } else {
                    bottomButtonSection
                }
            }
            .padding(viewModel.isRunning ? 20 : 16)
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isRunning)
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
                    Text("\(minute) ふん")
                        .tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .modifier(PixelCardModifier())
        }
    }
    
    private var timerDisplaySection: some View {
        VStack(spacing: 20) {
            // プログレスサークル（実行中は大きく表示）
            let circleSize: CGFloat = viewModel.isRunning ? 280 : 200
            let lineWidth: CGFloat = viewModel.isRunning ? 16 : 12
            let fontSize: CGFloat = viewModel.isRunning ? 48 : 36
            
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
                
                // 残り時間表示
                VStack {
                    Text(timeString(from: viewModel.remainingSeconds))
                        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                        .foregroundColor(DesignSystem.Color.textPrimary)
                    
                    if !viewModel.isRunning {
                        Text("MM:SS")
                            .font(DesignSystem.Font.pixelSmall)
                            .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isRunning)
        }
    }
    
    private var timerControlSection: some View {
        HStack(spacing: 16) {
            Button(action: {
                if viewModel.isRunning {
                    viewModel.pause()
                } else {
                    viewModel.start()
                }
            }) {
                Text(viewModel.isRunning ? "いちじていし" : "はじめる")
                    .font(DesignSystem.Font.pixelSmall)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .buttonStyle(PixelButtonStyle())

            Button(action: {
                viewModel.reset()
            }) {
                Text("リセット")
                    .font(DesignSystem.Font.pixelSmall)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .buttonStyle(PixelButtonStyle(
                fill: DesignSystem.Color.surface,
                foreground: DesignSystem.Color.primaryDark,
                border: DesignSystem.Color.primaryDark
            ))
        }
    }

    private var bottomButtonSection: some View {
        HStack(spacing: 16) {
            Button(action: {
                navigationRouter.navigateBack()
            }) {
                Text("もどる")
                    .font(DesignSystem.Font.pixelSmall)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .buttonStyle(PixelButtonStyle(
                fill: DesignSystem.Color.surface,
                foreground: DesignSystem.Color.primaryDark,
                border: DesignSystem.Color.primaryDark
            ))

            Button(action: {
                navigationRouter.popToRoot()
                navigationRouter.navigate(to: .capture)
            }) {
                Text("もう一度撮影")
                    .font(DesignSystem.Font.pixelSmall)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .buttonStyle(PixelButtonStyle(
                fill: DesignSystem.Color.secondary,
                foreground: DesignSystem.Color.textPrimary,
                border: DesignSystem.Color.primaryDark
            ))
        }
        .padding(.bottom, 20)
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