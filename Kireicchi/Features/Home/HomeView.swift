import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @Query private var records: [LatestRoomRecord]
    @StateObject private var appDependencies = AppDependencies.shared
    
    @AppStorage("selectedCharacterID") private var selectedCharacterTypeRaw: String = CharacterType.character01.rawValue

    private var latestRecord: LatestRoomRecord? { records.first }
    
    private var selectedCharacterType: CharacterType {
        CharacterType(rawValue: selectedCharacterTypeRaw) ?? .character01
    }
    
    private var characterState: CharacterState {
        guard let score = latestRecord?.score else { return .happy }
        return CharacterState.fromScore(score)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 上部バー: 左「設定」ボタン / 中央「次の撮影までの時間」/ 右「コイン表示」
            HStack {
                Button("設定") {
                    navigationRouter.navigate(to: .settings)
                }
                .font(.subheadline)
                
                Spacer()
                
                Text("次の撮影まで: 8時間30分")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("💰")
                    Text("120")
                        .font(.caption)
                        .bold()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // 「お部屋の散らかり指数 68/100」バナー
            HStack {
                Text("お部屋の散らかり指数")
                    .font(.subheadline)
                    .bold()
                Spacer()
                Text(latestRecord.map { "\($0.score)/100" } ?? "--/100")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.orange)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // ハートゲージ（横棒）
            VStack(alignment: .leading, spacing: 4) {
                Text("ハッピー度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red)
                        .frame(width: 120, height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 8)
                }
            }
            .padding()
            
            // ドット絵部屋（正方形）＋キャラクター＋吹き出しコメント
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .aspectRatio(1, contentMode: .fit)

                if let data = latestRecord?.pixelArtImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                }

                VStack {
                    // キャラクター＋吹き出し
                    HStack {
                        Spacer()
                        VStack {
                            Text("もう少し片付けよう！")
                                .font(.caption)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    // 吹き出しの尻尾
                                    Path { path in
                                        path.move(to: CGPoint(x: 20, y: 25))
                                        path.addLine(to: CGPoint(x: 30, y: 35))
                                        path.addLine(to: CGPoint(x: 10, y: 35))
                                    }
                                    .fill(Color.white),
                                    alignment: .bottom
                                )
                            CharacterView(
                                characterType: selectedCharacterType,
                                characterState: characterState
                            )
                            .frame(width: 150, height: 150)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)

                    Spacer()

                    if latestRecord == nil {
                        Text("🏠")
                            .font(.system(size: 60))
                    }

                    Spacer()
                }
            }
            .padding(.horizontal)
            
            // お片付けミッションセクション＋タスクリスト（チェックボックス付き）
            VStack(alignment: .leading, spacing: 12) {
                Text("お片付けミッション")
                    .font(.headline)
                    .padding(.horizontal)
                
                if let record = latestRecord, !record.messyPointLabels.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(Array(record.messyPointLabels.prefix(3).enumerated()), id: \.offset) { index, label in
                            CleanupTaskRow(
                                label: label,
                                index: index
                            )
                            .padding(.horizontal)
                        }
                    }
                } else {
                    Text("撮影して部屋を分析しましょう！")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
            
            Spacer()
            
            // 最下部中央: カメラアイコンボタン（固定）
            Button(action: {
                navigationRouter.navigate(to: .capture)
            }) {
                Image(systemName: "camera.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            
            #if DEBUG
            // デバッグモード切替ボタン（DEBUG版のみ表示）
            VStack(spacing: 8) {
                Text(appDependencies.useMockAPI ? "Mock使用中" : "Real API使用中")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    appDependencies.toggleMockAPI()
                }) {
                    Text(appDependencies.useMockAPI ? "Real APIに切替" : "Mockに切替")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 30)
            #else
            Spacer().frame(height: 30)
            #endif
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(NavigationRouter())
            .modelContainer(for: LatestRoomRecord.self, inMemory: true)
    }
}