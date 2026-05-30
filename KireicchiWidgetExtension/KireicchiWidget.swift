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
        completion(KireicchiWidgetEntry(date: Date(), snapshot: store.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KireicchiWidgetEntry>) -> Void) {
        let entry = KireicchiWidgetEntry(date: Date(), snapshot: store.load())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60)))
        completion(timeline)
    }
}

struct KireicchiWidget: Widget {
    let kind: String = "KireicchiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KireicchiWidgetProvider()) { entry in
            KireicchiWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 1.0, green: 0.976, blue: 0.937) // cream
                }
        }
        .configurationDisplayName("きれいっち")
        .description("お部屋を覗き見るウィジェット")
        .supportedFamilies([.systemSmall])
    }
}
