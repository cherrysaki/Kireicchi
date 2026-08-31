//
//  KireicchiApp.swift
//  Kireicchi
//
//  Created by 神林沙希 on 2026/04/22.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseMessaging
import UserNotifications


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self

    return true
  }

  // APNsトークンをFCMに渡す。以降 messaging(_:didReceiveRegistrationToken:) が呼ばれる。
  func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }

  // lowScoreWarning（家出予告等）のプッシュ用にFCMトークンを保存する。
  // サインイン未完了のタイミングで呼ばれた場合は AppDependencies 側で保留される。
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let fcmToken else { return }
    Task { @MainActor in
      AppDependencies.shared.registerFCMToken(fcmToken)
    }
  }

  // アプリがフォアグラウンドでもプッシュをバナー表示する。
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
    [.banner, .sound, .badge]
  }
}

@main
struct KireicchiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var deps = AppDependencies.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deps)
                .task {
                    await deps.bootstrap()
                }
        }
        .modelContainer(for: [LatestRoomRecord.self, RoomHistoryRecord.self, PostcardRecord.self])
    }
}
