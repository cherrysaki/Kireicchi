import SwiftUI

/// 解析中の進捗を表す横向きステッパー（ピクセル調）。
/// チェックマーク付きのピクセルノードを水色のバーで連結し、各ノード下にラベルを表示。
struct HorizontalStepProgressView: View {
    let steps: [String]
    let currentStep: Int
    /// 0...1 の擬似進捗。バーの塗り幅に使う（数値は表示しない）。
    let progress: Double
    /// 解析中フラグ。現在ノードのパルス演出に使う。
    var isAnimating: Bool = true

    private let nodeSize: CGFloat = 32
    private let trackHeight: CGFloat = 10
    private let pixelSize: CGFloat = 1.5

    private var fillColor: SwiftUI.Color { DesignSystem.Color.primary }
    private var borderColor: SwiftUI.Color { DesignSystem.Color.primaryDark }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let clamped = CGFloat(max(0, min(1, progress)))
            let centers = nodeCenters(width: width)

            ZStack(alignment: .leading) {
                // 背景トラック（角丸なし）
                Rectangle()
                    .fill(borderColor.opacity(0.12))
                    .frame(width: width, height: trackHeight)

                // 進捗（水色・角丸なし）
                Rectangle()
                    .fill(fillColor)
                    .frame(width: max(trackHeight, width * clamped), height: trackHeight)

                // ノード
                ForEach(Array(steps.enumerated()), id: \.offset) { index, _ in
                    node(index: index)
                        .position(x: centers[index], y: trackHeight / 2)
                }
            }
            .frame(width: width, height: nodeSize)
            // ラベル
            .overlay(alignment: .top) {
                ZStack(alignment: .top) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(DesignSystem.Font.caption)
                            .foregroundColor(index <= currentStep
                                             ? DesignSystem.Color.textPrimary
                                             : DesignSystem.Color.textPrimary.opacity(0.4))
                            .fixedSize()
                            .position(x: centers[index], y: nodeSize + 12)
                    }
                }
            }
        }
        .frame(height: nodeSize + 28)
    }

    private func nodeCenters(width: CGFloat) -> [CGFloat] {
        let count = steps.count
        guard count > 1 else { return [width / 2] }
        let inset = nodeSize / 2
        let usable = width - nodeSize
        return (0..<count).map { inset + usable * CGFloat($0) / CGFloat(count - 1) }
    }

    @ViewBuilder
    private func node(index: Int) -> some View {
        let isDone = index < currentStep
        let isCurrent = index == currentStep
        let reached = index <= currentStep

        ZStack {
            // ピクセル円（階段状）。到達済みは水色、未到達は薄い水色。
            PixelCircle(pixelSize: pixelSize)
                .fill(reached ? fillColor : borderColor.opacity(0.15))
                .frame(width: nodeSize, height: nodeSize)

            // ピクセル枠
            PixelCircleStroke(pixelSize: pixelSize, lineWidth: pixelSize)
                .fill(reached ? borderColor : borderColor.opacity(0.3))
                .frame(width: nodeSize, height: nodeSize)

            if isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(borderColor)
            } else if isCurrent {
                Rectangle()
                    .fill(borderColor)
                    .frame(width: pixelSize * 2, height: pixelSize * 2)
                    .scaleEffect(isAnimating ? 1.4 : 0.7)
                    .animation(isAnimating
                               ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                               : .default,
                               value: isAnimating)
            }
        }
    }
}

#Preview("途中") {
    HorizontalStepProgressView(
        steps: ["準備", "解析", "変換", "完了"],
        currentStep: 1,
        progress: 0.45
    )
    .padding(28)
    .background(DesignSystem.Color.background)
}

#Preview("完了") {
    HorizontalStepProgressView(
        steps: ["準備", "解析", "変換", "完了"],
        currentStep: 3,
        progress: 1.0,
        isAnimating: false
    )
    .padding(28)
    .background(DesignSystem.Color.background)
}
