import WidgetKit
import SwiftUI

struct KireicchiWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: KireicchiWidgetSnapshot?
}

struct KireicchiWidgetProvider: TimelineProvider {
    private let store: KireicchiWidgetDataStoreProtocol = KireicchiWidgetDataStore()

    func placeholder(in context: Context) -> KireicchiWidgetEntry {
        KireicchiWidgetEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (KireicchiWidgetEntry) -> Void) {
        let snapshot = store.load()
        completion(KireicchiWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KireicchiWidgetEntry>) -> Void) {
        let snapshot = store.load()
        let entry = KireicchiWidgetEntry(date: Date(), snapshot: snapshot)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60)))
        completion(timeline)
    }
}

struct KireicchiWidget: Widget {
    let kind: String = "KireicchiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KireicchiWidgetProvider()) { entry in
            KireicchiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("きれいっち")
        .description("きれいっちの様子を確認しよう！")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}
