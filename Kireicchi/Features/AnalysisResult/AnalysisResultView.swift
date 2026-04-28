import SwiftUI

struct AnalysisResultView: View {
    let imageData: Data
    let pixelArtData: Data
    let analysis: RoomAnalysis
    @EnvironmentObject var navigationRouter: NavigationRouter

    private var pixelArtImage: UIImage {
        UIImage(data: pixelArtData) ?? UIImage(systemName: "photo")!
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 上部: ランク文字（大）＋ スコア（xx/100）＋ひとことコメント（横並び）
                HStack(spacing: 16) {
                    VStack {
                        Text("ランク")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(analysis.rank.rawValue)
                            .font(.system(size: 64, weight: .heavy))
                            .foregroundColor(colorForScore(analysis.score))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("スコア")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(analysis.score)/100")
                            .font(.title)
                            .bold()
                        Text("ひとことコメント")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        Text(analysis.characterComment)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)
                
                // キャラクター＋吹き出しコメント（横並び）
                HStack(spacing: 12) {
                    CharacterView(
                        characterType: .character01,
                        characterState: nil,
                        forceGif: .cheer
                    )
                    .frame(width: 80, height: 80)
                    
                    VStack(alignment: .leading) {
                        Text(analysis.characterComment)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // 中央: ドット絵画像（正方形）
                VStack(alignment: .leading, spacing: 8) {
                    Text("ドット絵化された部屋")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(uiImage: pixelArtImage)
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                        )
                        .padding(.horizontal)
                }
                
                // 下部: 片付け優先箇所リスト（番号＋場所名＋★評価）
                VStack(alignment: .leading, spacing: 12) {
                    Text("片付け優先箇所")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(analysis.messyPoints.prefix(3).enumerated()), id: \.offset) { index, point in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(priorityColor(for: index))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .bold()
                                            .foregroundColor(.white)
                                    )
                                
                                Text(point.label)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text(starRating(for: point.priority))
                                    .font(.caption)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.03))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // お片付けタイマーボタン
                Button(action: {
                    navigationRouter.navigate(to: .cleanupTimer)
                }) {
                    HStack {
                        Image(systemName: "timer")
                        Text("お片付けタイマーを始める")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // 最下部: 「ホーム画面に戻る」ボタン
                Button(action: {
                    navigationRouter.popToRoot()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("ホーム画面に戻る")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top)
        }
        .navigationBarHidden(true)
    }
    
    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 85...100: return .green
        case 70...84: return .blue
        case 50...69: return .orange
        case 30...49: return .red
        default: return .purple
        }
    }
    
    private func priorityColor(for index: Int) -> Color {
        switch index {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .blue
        case 4: return .purple
        default: return .gray
        }
    }
    
    private func starRating(for priority: Int) -> String {
        switch priority {
        case 5: return "⭐⭐⭐⭐⭐"
        case 4: return "⭐⭐⭐⭐"
        case 3: return "⭐⭐⭐"
        case 2: return "⭐⭐"
        default: return "⭐"
        }
    }
}

#Preview {
    let mockAnalysis = RoomAnalysis(
        score: 75,
        rank: .b,
        messyPoints: [
            MessyPoint(label: "床の服", priority: 3),
            MessyPoint(label: "机の上の紙", priority: 2),
            MessyPoint(label: "本棚の整理", priority: 1)
        ],
        characterComment: "もう少し片付けると良いかも！"
    )
    let dummyImageData = (UIImage(systemName: "photo") ?? UIImage()).pngData() ?? Data()
    
    NavigationStack {
        AnalysisResultView(
            imageData: dummyImageData,
            pixelArtData: dummyImageData,
            analysis: mockAnalysis
        )
        .environmentObject(NavigationRouter())
    }
}