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
        VStack(spacing: 0) {
            Spacer()

            if viewModel.errorMessage == nil {
                Text("解析中...")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                    .scaleEffect(viewModel.isAnalyzing ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.isAnalyzing)
            } else {
                Text("エラーが発生しました")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.red)
            }

            Spacer().frame(height: 40)

            Text("🐱")
                .font(.system(size: 120))
                .scaleEffect(viewModel.isAnalyzing ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: viewModel.isAnalyzing)

            Spacer()

            if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 12) {
                        Button("戻る") {
                            navigationRouter.navigateBack()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)

                        Button("再試行") {
                            Task {
                                await viewModel.retry(imageData: imageData)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.bottom, 60)
            } else {
                stepList
                Spacer().frame(height: 60)
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
        VStack(spacing: 16) {
            ForEach(Array(viewModel.steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 12) {
                    Image(systemName: index <= viewModel.currentStep ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(index <= viewModel.currentStep ? .green : .gray.opacity(0.5))
                        .font(.title3)

                    Text(step)
                        .font(.subheadline)
                        .foregroundColor(index <= viewModel.currentStep ? .primary : .secondary)

                    Spacer()

                    if index == viewModel.currentStep && viewModel.isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
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
