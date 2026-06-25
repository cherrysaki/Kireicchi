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
            let generatePixelArtUseCase = GeneratePixelArtUseCase()
            
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
                ZStack {
                    if viewModel.errorMessage == nil {
                        Text("解析中...")
                            .font(DesignSystem.Font.title2)
                            .foregroundColor(DesignSystem.Color.primaryDark)
                            .scaleEffect(viewModel.isAnalyzing ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.isAnalyzing)
                    } else {
                        Text("エラーが発生しました")
                            .font(DesignSystem.Font.title2)
                            .foregroundColor(DesignSystem.Color.accentWarm)
                    }
                }
                .frame(height: 200)

                Spacer()

                CharacterView(
                    characterType: .character01,
                    characterState: nil,
                    forceGif: .run
                )
                .frame(width: 360, height: 360)
                .scaleEffect(viewModel.isAnalyzing ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: viewModel.isAnalyzing)

                Spacer()

                if let errorMessage = viewModel.errorMessage {
                    ErrorDetailView(
                        errorMessage: errorMessage,
                        rawResponse: viewModel.errorDetails?.rawResponse,
                        apiKeyPrefix: viewModel.errorDetails?.apiKeyPrefix,
                        onCopy: {
                            if let rawResponse = viewModel.errorDetails?.rawResponse {
                                UIPasteboard.general.string = rawResponse
                            }
                        },
                        onBack: {
                            navigationRouter.navigateBack()
                        },
                        onRetry: {
                            Task {
                                await viewModel.retry(imageData: imageData)
                            }
                        }
                    )
                    .padding(.bottom, 60)
                } else {
                    stepProgress
                    Spacer().frame(height: 60)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 実際のNavigationRouterとModelContextを設定
            let roomRecordStore = LatestRoomRecordStore(context: modelContext)
            let historyStore = RoomHistoryStore(context: modelContext)
            viewModel.setup(
                roomRecordStore: roomRecordStore,
                historyStore: historyStore,
                navigationRouter: navigationRouter
            )
            Task {
                await viewModel.startAnalysis(imageData: imageData)
            }
        }
    }

    private var stepProgress: some View {
        HorizontalStepProgressView(
            steps: viewModel.steps,
            currentStep: viewModel.currentStep,
            progress: viewModel.progress,
            isAnimating: viewModel.isAnalyzing
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .pixelSquareCard(
            fill: DesignSystem.Color.surface,
            border: DesignSystem.Color.primary,
            borderWidth: 2,
            shadowOffset: 3
        )
        .padding(.horizontal)
        .padding(.trailing, 3)
        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
    }
    
    private func setupViewModel() {
        // ViewModelに実際の依存性を注入
        // 注意: これは理想的な実装ではありませんが、既存のArchitectureに合わせています
    }
}

#Preview {
    let dummyImageData = (UIImage(systemName: "photo") ?? UIImage()).pngData() ?? Data()

    NavigationStack {
        AnalyzingView(imageData: dummyImageData)
            .environmentObject(NavigationRouter())
            .modelContainer(for: LatestRoomRecord.self, inMemory: true)
    }
}
