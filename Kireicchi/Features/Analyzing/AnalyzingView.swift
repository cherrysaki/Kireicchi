import SwiftUI
import SwiftData

struct AnalyzingView: View {
    let imageData: Data
    @EnvironmentObject var navigationRouter: NavigationRouter
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: AnalyzingViewModel

    init(imageData: Data,
         viewModel: AnalyzingViewModel? = nil) {
        self.imageData = imageData
        
        if let viewModel = viewModel {
            self._viewModel = StateObject(wrappedValue: viewModel)
        } else {
            // デフォルトの依存性を設定（AppDependenciesのフラグに基づく）
            let openAIClient = AppDependencies.shared.currentOpenAIClient()
            let analyzeRoomUseCase = AnalyzeRoomUseCase(openAIClient: openAIClient)
            let generatePixelArtUseCase = GeneratePixelArtUseCase(openAIClient: openAIClient)
            
            self._viewModel = StateObject(wrappedValue: AnalyzingViewModel(
                analyzeRoomUseCase: analyzeRoomUseCase,
                generatePixelArtUseCase: generatePixelArtUseCase
            ))
        }
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if viewModel.errorMessage == nil {
                    Text("かいせきちゅう...")
                        .font(DesignSystem.Font.largeTitle)
                        .foregroundColor(DesignSystem.Color.primaryDark)
                        .scaleEffect(viewModel.isAnalyzing ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.isAnalyzing)
                } else {
                    Text("エラーが おきました")
                        .font(DesignSystem.Font.title2)
                        .foregroundColor(DesignSystem.Color.accentWarm)
                }

                Spacer().frame(height: 40)

                Text("🐱")
                    .font(DesignSystem.Font.custom(size: 120))
                    .scaleEffect(viewModel.isAnalyzing ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: viewModel.isAnalyzing)

                Spacer()

                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage)
                            .font(DesignSystem.Font.footnote)
                            .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        HStack(spacing: 12) {
                            Button(action: {
                                navigationRouter.navigateBack()
                            }) {
                                Text("もどる")
                                    .font(DesignSystem.Font.subheadline)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(PixelButtonStyle(
                                fill: DesignSystem.Color.surface,
                                foreground: DesignSystem.Color.primaryDark,
                                border: DesignSystem.Color.primaryDark
                            ))

                            Button(action: {
                                Task {
                                    await viewModel.retry(imageData: imageData)
                                }
                            }) {
                                Text("もういちど")
                                    .font(DesignSystem.Font.subheadline)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(PixelButtonStyle())
                        }
                    }
                    .padding(.bottom, 60)
                } else {
                    stepList
                    Spacer().frame(height: 60)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 実際のNavigationRouterとModelContextを設定
            let roomRecordStore = LatestRoomRecordStore(context: modelContext)
            viewModel.setup(roomRecordStore: roomRecordStore, navigationRouter: navigationRouter)
            
            Task {
                await viewModel.startAnalysis(imageData: imageData)
            }
        }
    }

    private var stepList: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 12) {
                    Image(systemName: index <= viewModel.currentStep ? "checkmark.square.fill" : "square")
                        .foregroundColor(index <= viewModel.currentStep ? DesignSystem.Color.primary : DesignSystem.Color.textPrimary.opacity(0.3))
                        .font(DesignSystem.Font.title3)

                    Text(step)
                        .font(DesignSystem.Font.subheadline)
                        .foregroundColor(index <= viewModel.currentStep ? DesignSystem.Color.textPrimary : DesignSystem.Color.textPrimary.opacity(0.5))

                    Spacer()

                    if index == viewModel.currentStep && viewModel.isAnalyzing {
                        ProgressView()
                            .tint(DesignSystem.Color.primary)
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 18)
        .pixelSquareCard(
            fill: DesignSystem.Color.surface,
            border: DesignSystem.Color.primary,
            borderWidth: 2,
            shadowOffset: 3
        )
        .padding(.horizontal)
        .padding(.trailing, 3)
    }
    
    private func setupViewModel() {
        // ViewModelに実際の依存性を注入
        // 注意: これは理想的な実装ではありませんが、既存のArchitectureに合わせています
    }
}

#Preview {
    let dummyImageData = (UIImage(systemName: "photo") ?? UIImage()).pngData() ?? Data()
    let mockViewModel = MockAnalyzingViewModel(shouldSucceed: true, delay: 0.5)
    
    NavigationStack {
        AnalyzingView(imageData: dummyImageData)
            .environmentObject(NavigationRouter())
            .modelContainer(for: LatestRoomRecord.self, inMemory: true)
    }
}
