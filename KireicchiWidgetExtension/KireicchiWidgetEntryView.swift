import SwiftUI
import WidgetKit

private enum WidgetColor {
    static let primaryPink = Color(red: 0.76, green: 0.384, blue: 0.494)  // #C2627E secondaryDark
    static let lightPink = Color(red: 1.0, green: 0.776, blue: 0.851)     // #FFC6D9 secondary
    static let cream = Color(red: 1.0, green: 0.976, blue: 0.937)         // #FFF9EF background
    static let textBrown = Color(red: 0.298, green: 0.243, blue: 0.235)   // #4C3E3C textPrimary
}

struct KireicchiWidgetEntryView: View {
    let entry: KireicchiWidgetEntry

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

    var body: some View {
        ZStack {
            roomBackground

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

            VStack {
                HStack {
                    happyGauge
                    Spacer()
                }
                Spacer()
            }
            .padding(8)

            VStack {
                Spacer()
                Text(happiness.map(String.init) ?? "--")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(WidgetColor.primaryPink)
                    .shadow(color: .white.opacity(0.85), radius: 2, x: 0, y: 0)
                    .padding(.bottom, 4)
            }
        }
    }

    @ViewBuilder
    private var roomBackground: some View {
        if let roomImage {
            Image(uiImage: roomImage)
                .resizable()
                .interpolation(.none)
                .scaledToFill()
        } else {
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
