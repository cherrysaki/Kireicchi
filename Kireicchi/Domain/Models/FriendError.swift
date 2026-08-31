import Foundation

enum FriendError: LocalizedError, Equatable {
    case notSignedIn
    case usernameNotSet
    case userNotFound
    case cannotAddSelf
    case alreadyFriends
    case requestAlreadySent
    case requestAlreadyReceived
    case userIdTaken
    case invalidUserId

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "サインインされていません"
        case .usernameNotSet: return "設定でユーザーネームを登録してください"
        case .userNotFound: return "そのユーザーIDは見つかりませんでした"
        case .cannotAddSelf: return "自分自身は追加できません"
        case .alreadyFriends: return "すでにともだちです"
        case .requestAlreadySent: return "すでに申請を送っています"
        case .requestAlreadyReceived: return "相手から申請が届いています。届いた申請から承認してください"
        case .userIdTaken: return "そのユーザーIDはすでに使われています"
        case .invalidUserId: return "ユーザーIDは英数字\(UserIdRepository.minLength)〜\(UserIdRepository.maxLength)文字で入力してください"
        }
    }
}
