import Foundation

final class MockOpenAIClient: OpenAIClientProtocol {
    private let delay: TimeInterval
    private let shouldSucceed: Bool
    
    init(delay: TimeInterval = 1.0, shouldSucceed: Bool = true) {
        self.delay = delay
        self.shouldSucceed = shouldSucceed
    }
    
    func analyzeRoom(imageData: Data) async throws -> RoomAnalysisResponse {
        // 実際のAPIコールを模倣するため、少し遅延を入れる
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        if !shouldSucceed {
            throw MockError.simulatedFailure
        }

        // 仕様通りのダミーデータを返す
        return RoomAnalysisResponse(
            score: 65,
            messyPoints: [
                MessyPoint(label: "床の上の服", priority: 3),
                MessyPoint(label: "机の上の紙", priority: 2),
                MessyPoint(label: "カバン", priority: 1)
            ],
            characterComment: "ちょっと散らかってるみたい…"
        )
    }

    func generatePixelArt(imageData: Data) async throws -> Data {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        if !shouldSucceed {
            throw MockError.simulatedFailure
        }

        return imageData
    }
}

// Mock用のエラー定義
enum MockError: LocalizedError {
    case simulatedFailure
    
    var errorDescription: String? {
        switch self {
        case .simulatedFailure:
            return "Mock: シミュレートされた失敗"
        }
    }
}