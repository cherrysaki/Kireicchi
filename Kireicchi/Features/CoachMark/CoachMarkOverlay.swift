import SwiftUI

// MARK: - Anchor Preference Keys

struct CaptureButtonAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

struct CharacterFieldAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

struct SettingsButtonAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

struct ScoreImageAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

struct MissionListAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

struct TimerButtonAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

struct HomeButtonAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

struct RecaptureButtonAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

struct CaptureTimeSectionAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

// MARK: - Reversed Mask

extension View {
    func reversedMask<M: View>(@ViewBuilder _ mask: () -> M) -> some View {
        self.mask(
            ZStack {
                Rectangle().ignoresSafeArea()
                mask().blendMode(.destinationOut)
            }
            .compositingGroup()
        )
    }
}

// MARK: - Arrow Triangle

private struct ArrowTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}

// MARK: - CoachBubble

struct CoachBubble: View {
    let text: String
    let buttonText: String
    var arrowDirection: ArrowDirection = .down
    let onAction: () -> Void

    enum ArrowDirection { case up, down, none }

    var body: some View {
        VStack(spacing: 0) {
            if arrowDirection == .up {
                ArrowTriangle()
                    .fill(DesignSystem.Color.primary)
                    .frame(width: 24, height: 12)
                    .rotationEffect(.degrees(180))
            }

            VStack(spacing: 12) {
                Text(text)
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onAction) {
                    Text(buttonText)
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.textOnPrimary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(DesignSystem.Color.primary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DesignSystem.Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(DesignSystem.Color.primary, lineWidth: 2)
                    )
            )

            if arrowDirection == .down {
                ArrowTriangle()
                    .fill(DesignSystem.Color.primary)
                    .frame(width: 24, height: 12)
            }
        }
    }
}

// MARK: - CoachMarkOverlay

struct CoachMarkOverlay: View {
    let message: String
    let buttonText: String
    let highlightFrame: CGRect?
    let proxySize: CGSize
    let onAction: () -> Void

    private var showBubbleBelow: Bool {
        guard let frame = highlightFrame else { return false }
        return frame.midY < proxySize.height * 0.55
    }

    private var bubbleX: CGFloat {
        guard let frame = highlightFrame else { return proxySize.width / 2 }
        return min(max(frame.midX, 140), proxySize.width - 140)
    }

    private var bubbleY: CGFloat {
        guard let frame = highlightFrame else { return proxySize.height / 2 }
        if showBubbleBelow {
            return min(frame.maxY + 70, proxySize.height - 90)
        } else {
            return max(frame.minY - 70, 90)
        }
    }

    var body: some View {
        ZStack {
            // Touch blocker — blocks all touches from reaching the view below
            Rectangle()
                .fill(Color.black.opacity(0.001))
                .contentShape(Rectangle())
                .ignoresSafeArea()

            // Dimming layer with optional cutout
            if let frame = highlightFrame {
                Color.black.opacity(0.5)
                    .reversedMask {
                        RoundedRectangle(cornerRadius: 12)
                            .frame(width: frame.width + 20, height: frame.height + 20)
                            .position(x: frame.midX, y: frame.midY)
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            } else {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Bubble
            CoachBubble(
                text: message,
                buttonText: buttonText,
                arrowDirection: highlightFrame == nil ? .none : (showBubbleBelow ? .up : .down),
                onAction: onAction
            )
            .position(x: bubbleX, y: bubbleY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
