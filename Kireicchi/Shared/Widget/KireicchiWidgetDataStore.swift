import Foundation
import WidgetKit

enum KireicchiWidgetConstants {
    static let appGroupID = "group.app.kambayashi.yukke.sakai.Kireicchi"
    static let snapshotKey = "kireicchi_widget_snapshot"
}

final class KireicchiWidgetDataStore: KireicchiWidgetDataStoreProtocol {
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: KireicchiWidgetConstants.appGroupID)
    }

    func save(snapshot: KireicchiWidgetSnapshot) {
        guard let userDefaults else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: KireicchiWidgetConstants.snapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func load() -> KireicchiWidgetSnapshot? {
        guard let userDefaults else { return nil }
        guard let data = userDefaults.data(forKey: KireicchiWidgetConstants.snapshotKey) else { return nil }
        return try? JSONDecoder().decode(KireicchiWidgetSnapshot.self, from: data)
    }
}
