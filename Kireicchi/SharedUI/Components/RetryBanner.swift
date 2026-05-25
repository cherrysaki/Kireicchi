import SwiftUI

struct RetryBanner: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textOnPrimary)

            Text(message)
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textOnPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            Button(action: onRetry) {
                Text("リトライ")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.accentWarm)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DesignSystem.Color.surface)
                    .overlay(
                        Rectangle().stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.accentWarm)
        .overlay(
            Rectangle().stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
        )
    }
}

#Preview {
    VStack {
        RetryBanner(
            message: "サーバーと つながれないみたい",
            onRetry: {}
        )
        Spacer()
    }
    .background(DesignSystem.Color.background)
}
