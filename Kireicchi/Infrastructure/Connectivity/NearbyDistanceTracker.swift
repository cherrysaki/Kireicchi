import Foundation
import NearbyInteraction

@MainActor
final class NearbyDistanceTracker: NSObject, NearbyDistanceTrackerProtocol {
    let distances: AsyncStream<Float>
    private let continuation: AsyncStream<Float>.Continuation

    private var session: NISession?

    override init() {
        var c: AsyncStream<Float>.Continuation!
        self.distances = AsyncStream(bufferingPolicy: .bufferingNewest(8)) { continuation in
            c = continuation
        }
        self.continuation = c
        super.init()
    }

    func start() -> Data? {
        let session = NISession()
        session.delegate = self
        self.session = session

        guard let token = session.discoveryToken else { return nil }
        return try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
    }

    func setRemoteToken(_ data: Data) {
        guard let session else { return }
        guard let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
            return
        }
        let config = NINearbyPeerConfiguration(peerToken: token)
        session.run(config)
    }

    func stop() {
        session?.invalidate()
        session?.delegate = nil
        session = nil
    }

    private func emit(_ distance: Float) {
        continuation.yield(distance)
    }
}

// MARK: - NISessionDelegate

extension NearbyDistanceTracker: NISessionDelegate {
    nonisolated func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        let distance = nearbyObjects.first?.distance
        guard let distance else { return }
        Task { @MainActor in
            self.emit(distance)
        }
    }

    nonisolated func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        // 範囲外。距離は配信しない(直前の値が UI に残る)
    }

    nonisolated func sessionWasSuspended(_ session: NISession) {}
    nonisolated func sessionSuspensionEnded(_ session: NISession) {
        // セッション再開時は再 run 必要だが、相手のトークンを保持していないと再開不可。
        // MVP では切断扱いにせず、Coordinator 側で再接続させる。
    }

    nonisolated func session(_ session: NISession, didInvalidateWith error: Error) {
        // 何もしない。Coordinator が PeerSession 切断で stop する。
    }
}
