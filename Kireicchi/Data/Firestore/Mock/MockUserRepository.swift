import Foundation

final class MockUserRepository: UserRepositoryProtocol {
    private var storage: [String: AppUser] = [:]

    func fetch(uid: String) async throws -> AppUser? {
        storage[uid]
    }

    func createIfMissing(uid: String, authProvider: String) async throws -> AppUser {
        if let existing = storage[uid] { return existing }
        let user = AppUser.makeDefault(uid: uid, authProvider: authProvider)
        storage[uid] = user
        return user
    }

    func update(uid: String, mutation: @Sendable (inout AppUser) -> Void) async throws -> AppUser {
        var user = storage[uid] ?? AppUser.makeDefault(uid: uid, authProvider: "anonymous")
        mutation(&user)
        user.updatedAt = Date()
        storage[uid] = user
        return user
    }
}
