import Foundation
import Combine

@MainActor
final class MockFriendVisitViewModel: FriendVisitViewModelProtocol {
    @Published var state: VisitConnectionState
    @Published var friend: FriendPresence?
    @Published var distance: Float?

    init(
        state: VisitConnectionState = .visiting,
        friend: FriendPresence? = FriendPresence(peerId: "p", displayName: "ぽろこ", characterId: CharacterType.character01.rawValue),
        distance: Float? = 0.4
    ) {
        self.state = state
        self.friend = friend
        self.distance = distance
    }

    func onAppear() {}
    func onDisappear() {}
}
