import Foundation

protocol KireicchiWidgetDataStoreProtocol {
    func save(snapshot: KireicchiWidgetSnapshot)
    func load() -> KireicchiWidgetSnapshot?
}
