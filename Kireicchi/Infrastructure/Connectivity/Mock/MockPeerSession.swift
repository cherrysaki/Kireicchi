import Foundation

@MainActor
final class MockPeerSession: PeerSessionProtocol {
    let events: AsyncStream<PeerSessionEvent>
    private let continuation: AsyncStream<PeerSessionEvent>.Continuation

    private var simulationTask: Task<Void, Never>?
    private var fakePeerId: String?

    init() {
        var c: AsyncStream<PeerSessionEvent>.Continuation!
        self.events = AsyncStream { continuation in
            c = continuation
        }
        self.continuation = c
    }

    func start(displayName: String) async {
        let peerId = "mock-peer-\(UUID().uuidString.prefix(6))"
        fakePeerId = peerId
        simulationTask?.cancel()
        simulationTask = Task { [continuation] in
            try? await Task.sleep(for: .seconds(1.5))
            if Task.isCancelled { return }
            continuation.yield(.peerFound(peerId: peerId, displayName: "ぽろこ"))
            continuation.yield(.peerConnecting(peerId: peerId, displayName: "ぽろこ"))
            try? await Task.sleep(for: .seconds(0.8))
            if Task.isCancelled { return }
            continuation.yield(.peerConnected(peerId: peerId, displayName: "ぽろこ"))

            // 擬似的な hello 受信
            try? await Task.sleep(for: .seconds(0.3))
            if Task.isCancelled { return }
            let hello = FriendVisitMessage.hello(
                .init(characterId: CharacterType.character01.rawValue, displayName: "ぽろこ")
            )
            continuation.yield(.messageReceived(peerId: peerId, message: hello))

            // 擬似的な niToken 受信
            try? await Task.sleep(for: .seconds(0.3))
            if Task.isCancelled { return }
            continuation.yield(.messageReceived(peerId: peerId, message: .niToken(tokenData: Data([0xAA, 0xBB]))))
        }
    }

    func stop() {
        simulationTask?.cancel()
        simulationTask = nil
        if let peerId = fakePeerId {
            continuation.yield(.peerDisconnected(peerId: peerId))
        }
        fakePeerId = nil
    }

    func send(_ message: FriendVisitMessage, to peerId: String?) async {
        // Mock: 何もしない(送信扱い)
    }
}
