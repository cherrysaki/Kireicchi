import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [LatestRoomRecord]

    @State private var selectedHour = 19
    @State private var selectedMinute = 0
    @State private var notificationsEnabled = true
    @State private var selectedCharacterId = "cat"
    @State private var showTimePicker = false
    @State private var isSaving = false

    private let characters: [(id: String, emoji: String, label: String)] = [
        ("cat", "🐱", "キャラクタsー1"),
        ("dog", "🐶", "キャラクター2")
    ]

    private var selectedEmoji: String {
        characters.first { $0.id == selectedCharacterId }?.emoji ?? "🐱"
    }

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
                    Button(action: {
                        navigationRouter.navigateBack()
                    }) {
                        Image(systemName: "xmark")
                            .font(DesignSystem.Font.subheadline)
                            .foregroundColor(DesignSystem.Color.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(
                                PixelCircle(pixelSize: 3)
                                    .fill(DesignSystem.Color.surface)
                            )
                            .overlay(
                                PixelCircleStroke(pixelSize: 3, lineWidth: 2)
                                    .fill(DesignSystem.Color.primary)
                            )
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 20) {
                        captureTimeSection
                        notificationToggleSection
                        characterSection
                        commentSection
                        AppleLoginSection()
                        
                        #if DEBUG
                        debugSection
                        #endif
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

    private var characterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("キャラクター")

            Picker("キャラクターを 選ぶ", selection: $selectedCharacterId) {
                ForEach(characters, id: \.id) { character in
                    HStack {
                        Text(character.emoji)
                            .font(DesignSystem.Font.title)
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
                .font(DesignSystem.Font.custom(size: 56))

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

    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("🎬 スクショ用デバッグ")
            
            // 現在の状態表示
            VStack(alignment: .leading, spacing: 4) {
                Text("現在の状態")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .padding(.horizontal)
                
                Text("レコード数: \(records.count)")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                    .padding(.horizontal)
                
                if let record = records.first {
                    Text("スコア: \(record.score)")
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                        .padding(.horizontal)
                    
                    Text("キャラクター状態: \(CharacterState.fromScore(record.score).rawValue)")
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.primary)
                        .padding(.horizontal)
                    
                    Text("撮影日: \(DateFormatter.localizedString(from: record.capturedAt, dateStyle: .short, timeStyle: .none))")
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                        .padding(.horizontal)
                    
                    let daysSince = Calendar.current.dateComponents([.day], from: record.capturedAt, to: Date()).day ?? 0
                    Text("経過日数: \(daysSince)日 \(daysSince >= 5 ? "(家出状態)" : "")")
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(daysSince >= 5 ? DesignSystem.Color.primary : DesignSystem.Color.textPrimary.opacity(0.7))
                        .padding(.horizontal)
                } else {
                    Text("レコードなし")
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                        .padding(.horizontal)
                }
            }
            
            // キャラクター状態の切替ボタン（4つ横並び）
            VStack(alignment: .leading, spacing: 8) {
                Text("キャラクター状態")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .padding(.horizontal)
                
                HStack(spacing: 8) {
                    debugStateButton(title: "元気", score: 90)
                    debugStateButton(title: "普通", score: 70)
                    debugStateButton(title: "不調", score: 50)
                    debugStateButton(title: "病気", score: 20)
                }
                .padding(.horizontal)
            }
            
            // 家出状態の切替ボタン
            VStack(alignment: .leading, spacing: 8) {
                Text("家出状態")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .padding(.horizontal)
                
                HStack(spacing: 12) {
                    debugRunawayButton(title: "家出させる", isRunaway: true)
                    debugRunawayButton(title: "家出解除", isRunaway: false)
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func debugStateButton(title: String, score: Int) -> some View {
        Button(action: {
            updateLatestRecordScore(score)
        }) {
            Text(title)
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textOnPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(PixelButtonStyle())
    }
    
    private func debugRunawayButton(title: String, isRunaway: Bool) -> some View {
        Button(action: {
            updateLatestRecordCapturedAt(isRunaway: isRunaway)
        }) {
            Text(title)
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textOnPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .buttonStyle(PixelButtonStyle())
    }
    
    private func updateLatestRecordScore(_ score: Int) {
        let newState = CharacterState.fromScore(score)
        print("🔧 Debug: スコア更新ボタンが押されました。スコア: \(score) → キャラクター状態: \(newState.rawValue)")
        
        if records.isEmpty {
            print("🔧 Debug: レコードが存在しません。ダミーレコードを作成します。")
            let dummyImageData = Data()
            let dummyRecord = LatestRoomRecord(
                pixelArtImageData: dummyImageData,
                capturedAt: Date(),
                score: score,
                comment: "デバッグ用レコード",
                messyPointLabels: ["床の服:3", "机の本:2", "ゴミ箱:1"]
            )
            modelContext.insert(dummyRecord)
        } else if let record = records.first {
            let oldState = CharacterState.fromScore(record.score)
            print("🔧 Debug: 既存レコードのスコアを \(record.score)(\(oldState.rawValue)) から \(score)(\(newState.rawValue)) に更新します。")
            record.score = score
        }
        
        do {
            try modelContext.save()
            print("🔧 Debug: データ保存成功 - 新しい状態: \(newState.rawValue)")
        } catch {
            print("🔧 Debug: データ保存失敗: \(error)")
        }
    }
    
    private func updateLatestRecordCapturedAt(isRunaway: Bool) {
        print("🔧 Debug: 家出状態変更ボタンが押されました。家出状態: \(isRunaway)")
        
        if records.isEmpty {
            print("🔧 Debug: レコードが存在しません。ダミーレコードを作成します。")
            let dummyImageData = Data()
            let capturedAt = isRunaway 
                ? Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
                : Date()
            let dummyRecord = LatestRoomRecord(
                pixelArtImageData: dummyImageData,
                capturedAt: capturedAt,
                score: 50,
                comment: "デバッグ用レコード",
                messyPointLabels: ["床の服:3", "机の本:2", "ゴミ箱:1"]
            )
            modelContext.insert(dummyRecord)
        } else if let record = records.first {
            let newDate = isRunaway 
                ? Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
                : Date()
            print("🔧 Debug: 既存レコードのcapturedAtを \(record.capturedAt) から \(newDate) に更新します。")
            record.capturedAt = newDate
        }
        
        do {
            try modelContext.save()
            print("🔧 Debug: データ保存成功")
        } catch {
            print("🔧 Debug: データ保存失敗: \(error)")
        }
    }
    #endif

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
