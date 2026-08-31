import Foundation
import Combine

@MainActor
final class SendPostcardViewModel: SendPostcardViewModelProtocol {
    let score: Int
    let rank: String
    let myProfile: FriendProfile?

    @Published var includeCharacter = true
    @Published private(set) var friends: [FriendProfile] = []
    @Published var selectedUids: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSending = false
    @Published var didSend = false
    @Published var errorMessage: String?

    private let pixelArtData: Data
    private let composedImageData: Data
    private let fetchFriendsUseCase: FetchFriendsUseCaseProtocol
    private let sendPostcardUseCase: SendPostcardUseCaseProtocol

    init(
        pixelArtData: Data,
        score: Int,
        rank: String,
        characterType: CharacterType,
        characterState: CharacterState,
        myProfile: FriendProfile?,
        fetchFriendsUseCase: FetchFriendsUseCaseProtocol,
        sendPostcardUseCase: SendPostcardUseCaseProtocol,
        composePostcardImageUseCase: ComposePostcardImageUseCaseProtocol
    ) {
        self.pixelArtData = pixelArtData
        self.score = score
        self.rank = rank
        self.myProfile = myProfile
        self.fetchFriendsUseCase = fetchFriendsUseCase
        self.sendPostcardUseCase = sendPostcardUseCase
        self.composedImageData = composePostcardImageUseCase.execute(
            pixelArtData: pixelArtData,
            characterType: characterType,
            characterState: characterState
        )
    }

    var postcardImageData: Data {
        includeCharacter ? composedImageData : pixelArtData
    }

    func load() async {
        guard let me = myProfile else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            friends = try await fetchFriendsUseCase.execute(uid: me.uid).friends
        } catch {
            errorMessage = error.localizedDescription
            print("[SendPostcardViewModel] load failed: \(error)")
        }
    }

    func toggle(_ friend: FriendProfile) {
        if selectedUids.contains(friend.uid) {
            selectedUids.remove(friend.uid)
        } else {
            selectedUids.insert(friend.uid)
        }
    }

    func send() async {
        guard let me = myProfile else {
            errorMessage = PostcardError.usernameNotSet.localizedDescription
            return
        }
        let recipients = friends.filter { selectedUids.contains($0.uid) }
        isSending = true
        defer { isSending = false }
        do {
            try await sendPostcardUseCase.execute(
                imageData: postcardImageData,
                from: me,
                to: recipients,
                score: score,
                rank: rank
            )
            didSend = true
        } catch {
            errorMessage = error.localizedDescription
            print("[SendPostcardViewModel] send failed: \(error)")
        }
    }
}
