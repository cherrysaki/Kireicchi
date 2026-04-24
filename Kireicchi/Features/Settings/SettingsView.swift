import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @EnvironmentObject var deps: AppDependencies

    @State private var selectedHour = 19
    @State private var selectedMinute = 0
    @State private var notificationsEnabled = true
    @State private var selectedCharacterId = "cat"
    @State private var showTimePicker = false
    @State private var isSaving = false

    private let characters: [(id: String, emoji: String, label: String)] = [
        ("cat", "🐱", "キャラクター1"),
        ("dog", "🐶", "キャラクター2")
    ]

    private var selectedEmoji: String {
        characters.first { $0.id == selectedCharacterId }?.emoji ?? "🐱"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("設定")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("✕") {
                    navigationRouter.navigateBack()
                }
                .font(.title2)
                .foregroundColor(.secondary)
            }
            .padding()

            ScrollView {
                VStack(spacing: 24) {
                    captureTimeSection
                    notificationToggleSection
                    characterSection
                    commentSection
                    AppleLoginSection()
                }
                .padding(.bottom, 100)
            }

            Spacer()

            Button(action: saveSettings) {
                Text(isSaving ? "保存中..." : "設定を保存して閉じる")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(isSaving)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .onAppear(perform: loadSettings)
        .onChange(of: deps.currentUser) { _, _ in loadSettings() }
    }

    private var captureTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("撮影時間")
                .font(.headline)
                .padding(.horizontal)

            Button(action: { showTimePicker.toggle() }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("毎日の撮影時刻")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(selectedHour):\(String(format: "%02d", selectedMinute))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)

            if showTimePicker {
                VStack {
                    HStack {
                        Picker("時", selection: $selectedHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour)時")
                            }
                        }
                        .pickerStyle(.wheel)

                        Picker("分", selection: $selectedMinute) {
                            ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                Text("\(minute)分")
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(height: 150)

                    Button("決定") {
                        showTimePicker = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

    private var notificationToggleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("通知")
                .font(.headline)
                .padding(.horizontal)

            HStack {
                VStack(alignment: .leading) {
                    Text("撮影リマインダー")
                        .font(.subheadline)
                    Text("設定時刻に通知を送信します")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $notificationsEnabled)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var characterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("キャラクター")
                .font(.headline)
                .padding(.horizontal)

            Picker("キャラクターを選択", selection: $selectedCharacterId) {
                ForEach(characters, id: \.id) { character in
                    HStack {
                        Text(character.emoji)
                            .font(.title)
                        Text(character.label)
                    }
                    .tag(character.id)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }

    private var commentSection: some View {
        HStack(spacing: 12) {
            Text(selectedEmoji)
                .font(.system(size: 60))

            VStack(alignment: .leading, spacing: 4) {
                Text("設定ありがとう！")
                    .font(.subheadline)
                    .bold()
                Text("一緒にお部屋をきれいにしようね🌟")
                    .font(.subheadline)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func loadSettings() {
        guard let user = deps.currentUser else { return }
        selectedHour = user.notificationSettings.hour
        selectedMinute = user.notificationSettings.minute
        notificationsEnabled = user.notificationSettings.isEnabled
        selectedCharacterId = user.selectedCharacterId
    }

    private func saveSettings() {
        isSaving = true
        let hour = selectedHour
        let minute = selectedMinute
        let isEnabled = notificationsEnabled
        let characterId = selectedCharacterId
        Task {
            await deps.updateSettings(
                hour: hour,
                minute: minute,
                isEnabled: isEnabled,
                characterId: characterId
            )
            isSaving = false
            navigationRouter.navigateBack()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(NavigationRouter())
            .environmentObject(AppDependencies(
                authService: MockAuthService(preAuthenticatedUid: "mock-uid"),
                userRepository: MockUserRepository()
            ))
    }
}
