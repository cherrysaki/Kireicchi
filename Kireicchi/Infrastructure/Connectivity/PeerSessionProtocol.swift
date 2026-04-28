import Foundation

@MainActor
protocol PeerSessionProtocol: AnyObject {
    var events: AsyncStream<PeerSessionEvent> { get }

    func start(displayName: String) async
    func stop()
    func send(_ message: FriendVisitMessage, to peerId: String?) async
}
