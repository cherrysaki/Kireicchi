import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @EnvironmentObject var deps: AppDependencies

    @State private var selectedHour = 19
    @State private var selectedMinute = 0
    @State private var notificationsEnabled = true
    @State private var showTimePicker = false
    @State private var isSaving = false

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(DesignSystem.Font.title3)
                        .foregroundColor(DesignSystem.Color.primary)
                    Text("設定")
                        .font(DesignSystem.Font.title2)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                    Spacer()
                }
                .padding()

                ScrollView {
                    VStack(spacing: 20) {
                        captureTimeSection
                        notificationToggleSection
                        commentSection
                    }
                    .padding(.bottom, 100)
                }

                Spacer()

                Button(action: saveSettings) {
                    Text(isSaving ? "保存中..." : "設定を保存して閉じる")
                        .font(DesignSystem.Font.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(PixelButtonStyle())
                .frame(width: 360, height: 40)
                .fixedSize()
                .disabled(isSaving)
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: loadSettings)
        .onChange(of: deps.currentUser) { _, _ in loadSettings() }
    }

    private var captureTimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("撮影時間")

            Button(action: { showTimePicker.toggle() }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("毎日の撮影時刻")
                            .font(DesignSystem.Font.subheadline)
                            .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                        Text("\(selectedHour):\(String(format: "%02d", selectedMinute))")
                            .font(DesignSystem.Font.custom(size: 32))
                            .foregroundColor(DesignSystem.Color.primaryDark)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(DesignSystem.Color.primary)
                }
                .padding(14)
                .pixelSquareCard(
                    fill: DesignSystem.Color.surface,
                    border: DesignSystem.Color.primary,
                    borderWidth: 2,
                    shadowOffset: 3
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .padding(.trailing, 3)

            if showTimePicker {
                VStack(spacing: 12) {
                    HStack {
                        Picker("時", selection: $selectedHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour) 時")
                            }
                        }
                        .pickerStyle(.wheel)

                        Picker("分", selection: $selectedMinute) {
                            ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                Text("\(minute) 分")
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(height: 140)

                    Button(action: {
                        showTimePicker = false
                    }) {
                        Text("決定")
                            .font(DesignSystem.Font.subheadline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(PixelButtonStyle())
                }
                .padding(14)
                .pixelSquareCard(
                    fill: DesignSystem.Color.secondary.opacity(0.25),
                    border: DesignSystem.Color.primary,
                    borderWidth: 2,
                    shadowOffset: 3
                )
                .padding(.horizontal)
                .padding(.trailing, 3)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Font.headline)
            .foregroundColor(DesignSystem.Color.textPrimary)
            .padding(.horizontal)
    }

    private var notificationToggleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("通知")

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("撮影リマインダー")
                        .font(DesignSystem.Font.subheadline)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                    Text("設定時刻に通知を送ります")
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                }
                Spacer()
                Toggle("", isOn: $notificationsEnabled)
                    .tint(DesignSystem.Color.primary)
            }
            .padding(14)
            .pixelSquareCard(
                fill: DesignSystem.Color.surface,
                border: DesignSystem.Color.primary,
                borderWidth: 2,
                shadowOffset: 3
            )
            .padding(.horizontal)
            .padding(.trailing, 3)
        }
    }

    private var commentSection: some View {
        HStack(spacing: 12) {
            CharacterView(
                characterType: .character01,
                characterState: nil,
                forceGif: .cheer
            )
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text("設定ありがとう！")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                Text("一緒にお部屋をきれいにしようね🌟")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
            }
            .padding(12)
            .pixelSquareCard(
                fill: DesignSystem.Color.secondary.opacity(0.4),
                border: DesignSystem.Color.primary,
                borderWidth: 2,
                shadowOffset: 3
            )

            Spacer()
        }
        .padding(.horizontal)
        .padding(.trailing, 3)
        .padding(.top, 8)
    }

    private func loadSettings() {
        guard let user = deps.currentUser else { return }
        selectedHour = user.notificationSettings.hour
        selectedMinute = user.notificationSettings.minute
        notificationsEnabled = user.notificationSettings.isEnabled
    }

    private func saveSettings() {
        isSaving = true
        let hour = selectedHour
        let minute = selectedMinute
        let isEnabled = notificationsEnabled
        let characterId = deps.currentUser?.selectedCharacterId ?? "cat"
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
            .environmentObject(AppDependencies())
    }
}
