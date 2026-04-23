import SwiftUI

struct AnalyzingView: View {
    let imageData: Data
    @EnvironmentObject var navigationRouter: NavigationRouter

    @State private var currentStep = 0
    @State private var isAnalyzing = true
    @State private var errorMessage: String?

    private let steps = ["準備中", "アップロード中", "AI変換中", "完了"]

    private let useCase: GeneratePixelArtUseCaseProtocol

    init(imageData: Data,
         useCase: GeneratePixelArtUseCaseProtocol = GeneratePixelArtUseCase(openAIClient: OpenAIClient())) {
        self.imageData = imageData
        self.useCase = useCase
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if errorMessage == nil {
                Text("解析中...")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                    .scaleEffect(isAnalyzing ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnalyzing)
            } else {
                Text("エラーが発生しました")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.red)
            }

            Spacer().frame(height: 40)

            Text("🐱")
                .font(.system(size: 120))
                .scaleEffect(isAnalyzing ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnalyzing)

            Spacer()

            if let errorMessage {
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
                            retry()
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
        .task(id: runID) {
            await runAnalysis()
        }
    }

    @State private var runID = UUID()

    private var stepList: some View {
        VStack(spacing: 16) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 12) {
                    Image(systemName: index <= currentStep ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(index <= currentStep ? .green : .gray.opacity(0.5))
                        .font(.title3)

                    Text(step)
                        .font(.subheadline)
                        .foregroundColor(index <= currentStep ? .primary : .secondary)

                    Spacer()

                    if index == currentStep && isAnalyzing {
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

    private func retry() {
        errorMessage = nil
        currentStep = 0
        isAnalyzing = true
        runID = UUID()
    }

    private func runAnalysis() async {
        currentStep = 0
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled else { return }

        currentStep = 1

        do {
            let pixelArtData = try await useCase.execute(imageData: imageData)

            guard !Task.isCancelled else { return }
            currentStep = 2
            try? await Task.sleep(nanoseconds: 200_000_000)
            currentStep = 3
            isAnalyzing = false

            try? await Task.sleep(nanoseconds: 400_000_000)

            let analysis = RoomAnalysis(
                score: 75,
                rank: .b,
                messyPoints: ["床の服", "机の上の紙"],
                characterComment: "もう少し片付けると良いかも！"
            )
            navigationRouter.navigate(to: .analysisResult(
                imageData: imageData,
                pixelArtData: pixelArtData,
                analysis: analysis
            ))
        } catch {
            isAnalyzing = false
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private final class PreviewMockGeneratePixelArtUseCase: GeneratePixelArtUseCaseProtocol {
    func execute(imageData: Data) async throws -> Data {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return imageData
    }
}

#Preview {
    let dummyImageData = (UIImage(systemName: "photo") ?? UIImage()).pngData() ?? Data()
    NavigationStack {
        AnalyzingView(imageData: dummyImageData,
                      useCase: PreviewMockGeneratePixelArtUseCase())
            .environmentObject(NavigationRouter())
    }
}
