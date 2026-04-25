import Foundation

protocol UserRepositoryProtocol {
    func fetch(uid: String) async throws -> AppUser?
    func createIfMissing(uid: String, authProvider: String) async throws -> AppUser
    func update(uid: String, mutation: @Sendable (inout AppUser) -> Void) async throws -> AppUser
}
