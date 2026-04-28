import Foundation
import Combine

@MainActor
protocol FriendVisitCoordinatorProtocol: ObservableObject {
    var state: VisitConnectionState { get }
    var friend: FriendPresence? { get }
    var distance: Float? { get }

    func start(myCharacterId: String, myDisplayName: String) async
    func stop()
}
