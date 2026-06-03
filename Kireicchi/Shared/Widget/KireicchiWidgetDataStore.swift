import Foundation
import WidgetKit
import os

enum KireicchiWidgetConstants {
    static let appGroupID = "group.app.kambayashi.yukke.sakai.Kireicchi"
    static let snapshotKey = "kireicchi_widget_snapshot"
}

final class KireicchiWidgetDataStore: KireicchiWidgetDataStoreProtocol {
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: KireicchiWidgetConstants.appGroupID)
    }

    func save(snapshot: KireicchiWidgetSnapshot) {
        guard let userDefaults else {
            Logger.widget.error("[save] UserDefaults(suiteName:) == nil — App Group 未設定/未プロビジョニングの可能性")
            return
        }
        guard let data = try? JSONEncoder().encode(snapshot) else {
            Logger.widget.error("[save] JSON エンコード失敗")
            return
        }
        userDefaults.set(data, forKey: KireicchiWidgetConstants.snapshotKey)
        Logger.widget.debug("[save:store] bytes=\(data.count) imageNil=\(snapshot.latestPixelRoomImageData == nil) imageCount=\(snapshot.latestPixelRoomImageData?.count ?? -1)")
        WidgetDebugLog.append("store.SAVE→UserDefaults bytes=\(data.count) imageNil=\(snapshot.latestPixelRoomImageData == nil) imageCount=\(snapshot.latestPixelRoomImageData?.count ?? -1)")
        WidgetCenter.shared.reloadAllTimelines()
    }

    func load() -> KireicchiWidgetSnapshot? {
        guard let userDefaults else {
            Logger.widget.error("[load] UserDefaults(suiteName:) == nil — App Group 未設定/未プロビジョニングの可能性")
            return nil
        }
        guard let data = userDefaults.data(forKey: KireicchiWidgetConstants.snapshotKey) else {
            Logger.widget.error("[load] snapshot データ無し (key 不在)")
            return nil
        }
        guard let snapshot = try? JSONDecoder().decode(KireicchiWidgetSnapshot.self, from: data) else {
            Logger.widget.error("[load] JSON デコード失敗 bytes=\(data.count)")
            return nil
        }
        Logger.widget.debug("[load] happiness=\(snapshot.happiness) state=\(snapshot.characterState, privacy: .public) isGone=\(snapshot.isGone) imageNil=\(snapshot.latestPixelRoomImageData == nil) imageCount=\(snapshot.latestPixelRoomImageData?.count ?? -1)")
        WidgetDebugLog.append("store.LOAD←UserDefaults happiness=\(snapshot.happiness) state=\(snapshot.characterState) isGone=\(snapshot.isGone) imageNil=\(snapshot.latestPixelRoomImageData == nil) imageCount=\(snapshot.latestPixelRoomImageData?.count ?? -1)")
        return snapshot
    }
}
