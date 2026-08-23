import WidgetKit
import SwiftUI

struct KireicchiWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: KireicchiWidgetSnapshot?
}

struct KireicchiWidgetProvider: TimelineProvider {
    private let store: KireicchiWidgetDataStoreProtocol = KireicchiWidgetDataStore()

    func placeholder(in context: Context) -> KireicchiWidgetEntry {
        WidgetDebugLog.append("provider.placeholder called isPreview=\(context.isPreview) family=\(context.family)")
        return KireicchiWidgetEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (KireicchiWidgetEntry) -> Void) {
        let snapshot = store.load()
        WidgetDebugLog.append("provider.getSnapshot called isPreview=\(context.isPreview) family=\(context.family) snapshotNil=\(snapshot == nil)")
        completion(KireicchiWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KireicchiWidgetEntry>) -> Void) {
        let snapshot = store.load()
        WidgetDebugLog.append("provider.getTimeline called isPreview=\(context.isPreview) family=\(context.family) snapshotNil=\(snapshot == nil)")
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
        .description("お部屋を覗き見るウィジェット")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}
