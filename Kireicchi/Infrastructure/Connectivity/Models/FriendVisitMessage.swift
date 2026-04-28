import Foundation

enum FriendVisitMessage: Codable, Sendable {
    case hello(HelloPayload)
    case niToken(tokenData: Data)
    case scoreUpdate(score: Int)
    case bye

    struct HelloPayload: Codable, Sendable {
        let characterId: String
        let displayName: String
    }

    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    static func decode(from data: Data) -> FriendVisitMessage? {
        try? JSONDecoder().decode(FriendVisitMessage.self, from: data)
    }
}
