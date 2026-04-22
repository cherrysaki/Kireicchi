import SwiftUI

struct AnalyzingView: View {
    let imageData: Data
    @EnvironmentObject var navigationRouter: NavigationRouter
    
    private var image: UIImage {
        UIImage(data: imageData) ?? UIImage(systemName: "photo")!
    }
    @State private var currentStep = 0
    @State private var isAnalyzing = true
    
    private let steps = ["準備中", "アップロード中", "AI分析中", "完了"]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 中央大テキスト「解析中...」
            Text("解析中...")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.primary)
                .scaleEffect(isAnalyzing ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnalyzing)
            
            Spacer().frame(height: 40)
            
            // その下: キャラクター（待機ポーズ）
            Text("🐱")
                .font(.system(size: 120))
                .scaleEffect(isAnalyzing ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnalyzing)
            
            Spacer()
            
            // 下部: ステップチェックリスト
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
                        
                        if index == currentStep {
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
            
            Spacer().frame(height: 60)
        }
        .navigationBarHidden(true)
        .onAppear {
            startAnalysis()
        }
    }
    
    private func startAnalysis() {
        // ステップアニメーション
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if currentStep < steps.count - 1 {
                currentStep += 1
            } else {
                timer.invalidate()
                isAnalyzing = false
                
                // 分析完了後、結果画面へ遷移（仮データ）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let mockAnalysis = RoomAnalysis(
                        score: 75,
                        rank: .b,
                        messyPoints: ["床の服", "机の上の紙"],
                        characterComment: "もう少し片付けると良いかも！"
                    )
                    navigationRouter.navigate(to: .analysisResult(imageData: imageData, analysis: mockAnalysis))
                }
            }
        }
    }
}

#Preview {
    let dummyImageData = (UIImage(systemName: "photo") ?? UIImage()).pngData() ?? Data()
    NavigationStack {
        AnalyzingView(imageData: dummyImageData)
            .environmentObject(NavigationRouter())
    }
}