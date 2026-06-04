import SwiftUI
import WidgetKit
import os

private enum WidgetColor {
    static let primaryPink = Color(red: 0.76, green: 0.384, blue: 0.494)  // #C2627E secondaryDark
    static let lightPink = Color(red: 1.0, green: 0.776, blue: 0.851)     // #FFC6D9 secondary
    static let cream = Color(red: 1.0, green: 0.976, blue: 0.937)         // #FFF9EF background
    static let textBrown = Color(red: 0.298, green: 0.243, blue: 0.235)   // #4C3E3C textPrimary
}

struct KireicchiWidgetEntryView: View {
    let entry: KireicchiWidgetEntry

    // DEBUG: iOS のウィジェット描画モード（fullColor / accented / vibrant）を確認する用
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    private var renderingModeText: String {
        switch widgetRenderingMode {
        case .fullColor: return "fullColor"
        case .accented:  return "accented"
        case .vibrant:   return "vibrant"
        default:         return "unknown"
        }
    }

    private var happiness: Int? { entry.snapshot?.happiness }
    private var isGone: Bool { entry.snapshot?.isGone ?? false }
    private var characterState: String { entry.snapshot?.characterState ?? "元気" }

    private var characterAssetName: String? {
        if isGone { return nil }
        // CharacterState rawValue（日本語）→ static asset 名
        switch characterState {
        case "元気": return "character01_happy_static"
        case "普通": return "character01_normal_static"
        case "不調": return "character01_sad_static"
        case "病気": return "character01_sick_static"
        default:    return "character01_happy_static"
        }
    }

    private var roomImage: UIImage? {
        entry.snapshot?.latestPixelRoomImageData.flatMap { UIImage(data: $0) }
    }

    private func logRenderState() {
        let assetName = characterAssetName ?? "<nil>"
        let imageData = entry.snapshot?.latestPixelRoomImageData
        let decoded = roomImage
        let roomDecoded = decoded != nil
        let decodedSize = decoded.map { "\(Int($0.size.width))x\(Int($0.size.height))@\($0.scale)" } ?? "<nil>"
        let happinessText = happiness.map(String.init) ?? "<nil>"
        Logger.widget.debug("[view] renderMode=\(renderingModeText, privacy: .public) snapshotNil=\(entry.snapshot == nil) happiness=\(happinessText, privacy: .public) characterState=\(characterState, privacy: .public) isGone=\(isGone) assetName=\(assetName, privacy: .public) roomDataNil=\(imageData == nil) roomDataCount=\(imageData?.count ?? -1) roomDecoded=\(roomDecoded) decodedSize=\(decodedSize, privacy: .public)")
        WidgetDebugLog.append("view.RENDER renderMode=\(renderingModeText) snapshotNil=\(entry.snapshot == nil) happiness=\(happinessText) state=\(characterState) isGone=\(isGone) assetName=\(assetName) roomDataNil=\(imageData == nil) roomDataCount=\(imageData?.count ?? -1) roomDecoded=\(roomDecoded) decodedSize=\(decodedSize)")
    }

    var body: some View {
        let _ = logRenderState()
        return GeometryReader { geo in
            ZStack {
                // 最背面：部屋ドット絵を全面に敷く（明示 frame + clipped）
                // === DEBUG: 描画領域・描画モードの可視化（確認後に削除）===
                ZStack {
                    Color.blue                 // 画像が見えなくても描画矩形が確保されていれば青が見える
                    roomBackground
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .border(Color.red, width: 3)   // 実際の描画矩形の輪郭
                .overlay(alignment: .topLeading) {
                    Text("mode=\(renderingModeText)\nimg=\(roomImage.map { "\(Int($0.size.width))x\(Int($0.size.height))" } ?? "nil")")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(2)
                        .background(Color.white)
                }
                // === DEBUG ここまで ===

                // 中面：キャラクター（家出時はお手紙）
                if isGone {
                    Image("okitegami")
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                } else if let assetName = characterAssetName {
                    VStack {
                        Spacer()
                        Image(assetName)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .padding(.bottom, 28)
                    }
                }

                // 最前面：幸福度ゲージ
                VStack {
                    HStack {
                        happyGauge
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)

                // 最前面：スコア
                VStack {
                    Spacer()
                    Text(happiness.map(String.init) ?? "--")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(WidgetColor.primaryPink)
                        .shadow(color: .white.opacity(0.85), radius: 2, x: 0, y: 0)
                        .padding(.bottom, 4)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder
    private var roomBackground: some View {
        if let roomImage {
            let _ = WidgetDebugLog.append("view.roomBackground=IMAGE size=\(Int(roomImage.size.width))x\(Int(roomImage.size.height))")
            Image(uiImage: roomImage)
                .resizable()
                .interpolation(.none)
                .scaledToFill()
        } else {
            let _ = WidgetDebugLog.append("view.roomBackground=CREAM(roomImage=nil)")
            WidgetColor.cream
        }
    }

    private var happyGauge: some View {
        let value = happiness ?? 0
        let clamped = min(max(Double(value) / 100.0, 0), 1)

        return HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.system(size: 11))
                .foregroundColor(WidgetColor.primaryPink)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.6))
                    Capsule()
                        .fill(WidgetColor.lightPink)
                        .frame(width: geo.size.width * clamped)
                }
                .overlay(
                    Capsule()
                        .stroke(WidgetColor.primaryPink, lineWidth: 1)
                )
            }
            .frame(width: 56, height: 8)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(Color.white.opacity(0.7))
        )
    }
}
