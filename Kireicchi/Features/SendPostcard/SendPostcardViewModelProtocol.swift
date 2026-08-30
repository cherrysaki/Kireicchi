import Foundation
import Combine

@MainActor
protocol SendPostcardViewModelProtocol: ObservableObject {
    /// 送信される画像（includeCharacter に応じてキャラ合成済み／素のドット絵）
    var postcardImageData: Data { get }
    var includeCharacter: Bool { get set }
    var score: Int { get }
    var rank: String { get }
    var myProfile: FriendProfile? { get }
    var friends: [FriendProfile] { get }
    var selectedUids: Set<String> { get set }
    var isLoading: Bool { get }
    var isSending: Bool { get }
    var didSend: Bool { get set }
    var errorMessage: String? { get set }

    func load() async
    func toggle(_ friend: FriendProfile)
    func send() async
}
