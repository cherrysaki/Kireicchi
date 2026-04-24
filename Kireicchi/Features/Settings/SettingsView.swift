import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsRecords: [NotificationSettings]
    @State private var selectedHour = 19
    @State private var selectedMinute = 0
    @State private var notificationsEnabled = true
    @State private var selectedCharacter = 0
    @State private var showTimePicker = false

    private let characters = ["🐱", "🐶"]
    private let scheduleUseCase: ScheduleNotificationUseCaseProtocol = ScheduleNotificationUseCase()
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
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
                    // 「撮影時間」セクション: 設定時刻を大きく表示、タップでピッカーへ
                    VStack(alignment: .leading, spacing: 12) {
                        Text("撮影時間")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showTimePicker.toggle()
                        }) {
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
                    
                    // 「通知」セクション: ON/OFFトグル
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
                    
                    // キャラクター選択
                    VStack(alignment: .leading, spacing: 12) {
                        Text("キャラクター")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Picker("キャラクターを選択", selection: $selectedCharacter) {
                            ForEach(Array(characters.enumerated()), id: \.offset) { index, character in
                                HStack {
                                    Text(character)
                                        .font(.title)
                                    Text("キャラクター\(index + 1)")
                                }
                                .tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                    
                    // キャラクター＋吹き出しコメントエリア
                    HStack(spacing: 12) {
                        Text(characters[selectedCharacter])
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
                .padding(.bottom, 100)
            }
            
            Spacer()
            
            // 「閉じる」ボタン（最下部）
            Button(action: {
                saveSettings()
            }) {
                Text("設定を保存して閉じる")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .onAppear(perform: loadSettings)
    }

    private func loadSettings() {
        guard let record = settingsRecords.first else { return }
        selectedHour = record.hour
        selectedMinute = record.minute
        notificationsEnabled = record.isEnabled
    }

    private func saveSettings() {
        let record: NotificationSettings
        if let existing = settingsRecords.first {
            record = existing
        } else {
            record = NotificationSettings()
            modelContext.insert(record)
        }
        record.hour = selectedHour
        record.minute = selectedMinute
        record.isEnabled = notificationsEnabled
        try? modelContext.save()

        let isEnabled = notificationsEnabled
        let hour = selectedHour
        let minute = selectedMinute
        Task {
            await scheduleUseCase.execute(isEnabled: isEnabled, hour: hour, minute: minute)
        }

        navigationRouter.navigateBack()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(NavigationRouter())
    }
    .modelContainer(for: NotificationSettings.self, inMemory: true)
}