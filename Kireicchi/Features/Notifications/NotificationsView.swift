import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notifications.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    markAsRead(notification)
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(DesignSystem.Color.background.ignoresSafeArea())
            .navigationTitle("お知らせ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .task {
            await loadNotifications()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.4))
            Text("お知らせはありません")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadNotifications() async {
        isLoading = true
        do {
            notifications = try await deps.fetchNotifications()
        } catch {
            print("[NotificationsView] loadNotifications failed: \(error)")
        }
        isLoading = false
    }

    private func markAsRead(_ notification: AppNotification) {
        guard !notification.isRead else { return }
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        notifications[index].isRead = true
        Task {
            try? await deps.markNotificationAsRead(id: notification.id)
        }
    }
}

private struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(DesignSystem.Font.subheadline)
                    .fontWeight(notification.isRead ? .regular : .bold)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                Text(notification.body)
                    .font(DesignSystem.Font.footnote)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.4))
            }

            Spacer(minLength: 0)

            if !notification.isRead {
                Circle()
                    .fill(DesignSystem.Color.primary)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 6)
        .opacity(notification.isRead ? 0.6 : 1.0)
    }

    private var iconName: String {
        switch notification.kind {
        case .parentMessage: return "message.fill"
        case .lowScoreWarning: return "exclamationmark.triangle.fill"
        case .friendRequest: return "person.crop.circle.badge.plus"
        }
    }

    private var iconColor: Color {
        switch notification.kind {
        case .parentMessage: return DesignSystem.Color.secondary
        case .lowScoreWarning: return .red
        case .friendRequest: return DesignSystem.Color.primary
        }
    }
}

#Preview {
    NotificationsView()
        .environmentObject(AppDependencies())
}
