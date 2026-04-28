import Foundation
import Combine

@MainActor
final class FriendVisitViewModel: FriendVisitViewModelProtocol {
    @Published private(set) var state: VisitConnectionState = .idle
    @Published private(set) var friend: FriendPresence? = nil
    @Published private(set) var distance: Float? = nil

    private let coordinator: FriendVisitCoordinator
    private let myCharacterId: String
    private let myDisplayName: String

    private var cancellables: Set<AnyCancellable> = []

    init(
        coordinator: FriendVisitCoordinator,
        myCharacterId: String,
        myDisplayName: String
    ) {
        self.coordinator = coordinator
        self.myCharacterId = myCharacterId
        self.myDisplayName = myDisplayName

        coordinator.$state.assign(to: &$state)
        coordinator.$friend.assign(to: &$friend)
        coordinator.$distance.assign(to: &$distance)
    }

    func onAppear() {
        Task {
            await coordinator.start(myCharacterId: myCharacterId, myDisplayName: myDisplayName)
        }
    }

    func onDisappear() {
        coordinator.stop()
    }
}
