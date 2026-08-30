import Foundation

protocol PostcardRepositoryProtocol {
    /// 画像を1回アップロードし、宛先ごとに postcards ドキュメントを作成する。
    func send(imageData: Data, from: FriendProfile, to recipients: [FriendProfile], score: Int, rank: String) async throws
    func fetchIncoming(uid: String) async throws -> [Postcard]
    func downloadImage(path: String) async throws -> Data
    func delete(id: String) async throws
}
