import Foundation

enum PostcardError: LocalizedError {
    case notSignedIn
    case usernameNotSet
    case noRecipient

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "サインインされていません"
        case .usernameNotSet: return "設定でユーザーネームを登録してください"
        case .noRecipient: return "送る相手を選んでください"
        }
    }
}
