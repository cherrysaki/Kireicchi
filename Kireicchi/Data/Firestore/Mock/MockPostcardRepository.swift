import Foundation

final class MockPostcardRepository: PostcardRepositoryProtocol {
    var incoming: [Postcard] = []
    var images: [String: Data] = [:]

    func send(imageData: Data, from: FriendProfile, to recipients: [FriendProfile], score: Int, rank: String) async throws {}

    func fetchIncoming(uid: String) async throws -> [Postcard] {
        incoming.filter { $0.toUid == uid }
    }

    func downloadImage(path: String) async throws -> Data {
        images[path] ?? Data()
    }

    func delete(id: String) async throws {
        incoming.removeAll { $0.id == id }
    }
}
