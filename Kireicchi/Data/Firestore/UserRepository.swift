import Foundation
import FirebaseFirestore

final class UserRepository: UserRepositoryProtocol {
    private var db: Firestore { Firestore.firestore() }

    private func doc(_ uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }

    func fetch(uid: String) async throws -> AppUser? {
        let snapshot = try await doc(uid).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: AppUser.self)
    }

    func createIfMissing(uid: String, authProvider: String) async throws -> AppUser {
        if let existing = try await fetch(uid: uid) {
            return existing
        }
        let user = AppUser.makeDefault(uid: uid, authProvider: authProvider)
        try doc(uid).setData(from: user)
        return user
    }

    func update(uid: String, mutation: @Sendable (inout AppUser) -> Void) async throws -> AppUser {
        var user = try await fetch(uid: uid) ?? AppUser.makeDefault(uid: uid, authProvider: "anonymous")
        mutation(&user)
        user.updatedAt = Date()
        try doc(uid).setData(from: user, merge: true)
        return user
    }
}
