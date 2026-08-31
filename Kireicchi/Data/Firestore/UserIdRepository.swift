import Foundation
import FirebaseFirestore

/// userIds/{userId} → { uid } でユーザーIDの一意性を担保し、ともだち検索の引き当てに使う。
/// IDは紛らわしい文字（0/O, 1/I/L）を除いた大文字英数字8桁。
final class UserIdRepository: UserIdRepositoryProtocol {
    static let length = 8
    static let minLength = 4
    static let maxLength = 16
    private static let alphabet = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
    private static let maxAttempts = 5

    private var db: Firestore { Firestore.firestore() }

    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    static func isValid(_ userId: String) -> Bool {
        (minLength...maxLength).contains(userId.count)
            && userId.allSatisfy { $0.isASCII && ($0.isUppercase || $0.isNumber) }
    }

    func change(to newUserId: String, uid: String, previousUserId: String?) async throws {
        let normalized = Self.normalize(newUserId)
        guard Self.isValid(normalized) else { throw FriendError.invalidUserId }
        guard normalized != previousUserId else { return }

        let newRef = db.collection("userIds").document(normalized)
        let oldRef = previousUserId.map { db.collection("userIds").document($0) }
        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(newRef)
                if snapshot.exists, (snapshot.data()?["uid"] as? String) != uid {
                    errorPointer?.pointee = FriendError.userIdTaken as NSError
                    return nil
                }
                if let oldRef {
                    let old = try transaction.getDocument(oldRef)
                    if old.exists, (old.data()?["uid"] as? String) == uid {
                        transaction.deleteDocument(oldRef)
                    }
                }
                transaction.setData([
                    "uid": uid,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: newRef)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }

    static func generate() -> String {
        String((0..<length).compactMap { _ in alphabet.randomElement() })
    }

    func generateAndReserve(uid: String) async throws -> String {
        var lastError: Error?
        for _ in 0..<Self.maxAttempts {
            let candidate = Self.generate()
            do {
                try await reserve(userId: candidate, uid: uid)
                return candidate
            } catch FriendError.userIdTaken {
                continue
            } catch {
                lastError = error
                break
            }
        }
        throw lastError ?? FriendError.userIdTaken
    }

    func lookup(userId: String) async throws -> FriendProfile? {
        let normalized = Self.normalize(userId)
        guard !normalized.isEmpty else { return nil }
        let reservation = try await db.collection("userIds").document(normalized).getDocument()
        guard reservation.exists, let uid = reservation.data()?["uid"] as? String else { return nil }

        let user = try await db.collection("users").document(uid).getDocument()
        guard user.exists, let data = user.data() else { return nil }
        let username = (data["username"] as? String) ?? (data["displayName"] as? String) ?? "ともだち"
        let characterId = data["selectedCharacterId"] as? String ?? CharacterType.character01.rawValue
        return FriendProfile(uid: uid, username: username, selectedCharacterId: characterId, userId: normalized)
    }

    private func reserve(userId: String, uid: String) async throws {
        let ref = db.collection("userIds").document(userId)
        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(ref)
                if snapshot.exists {
                    errorPointer?.pointee = FriendError.userIdTaken as NSError
                    return nil
                }
                transaction.setData([
                    "uid": uid,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: ref)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }
}
