import Foundation

@MainActor
final class MockNearbyDistanceTracker: NearbyDistanceTrackerProtocol {
    let distances: AsyncStream<Float>
    private let continuation: AsyncStream<Float>.Continuation

    private var simulationTask: Task<Void, Never>?

    init() {
        var c: AsyncStream<Float>.Continuation!
        self.distances = AsyncStream { continuation in
            c = continuation
        }
        self.continuation = c
    }

    func start() -> Data? {
        beginOscillating()
        return Data([0xCC, 0xDD]) // 擬似ローカルトークン
    }

    func setRemoteToken(_ data: Data) {
        // Mock: 既に start() で測定開始済み
    }

    func stop() {
        simulationTask?.cancel()
        simulationTask = nil
    }

    private func beginOscillating() {
        simulationTask?.cancel()
        simulationTask = Task { [continuation] in
            // 距離を 2.0m → 0.3m → 2.0m と振動させて UI を一巡確認できるようにする
            let pattern: [Float] = [2.5, 2.0, 1.5, 1.2, 0.8, 0.5, 0.3, 0.3, 0.4, 0.7, 1.0, 1.6, 2.2]
            var index = 0
            while !Task.isCancelled {
                continuation.yield(pattern[index % pattern.count])
                index += 1
                try? await Task.sleep(for: .milliseconds(800))
            }
        }
    }
}
