import Foundation
import Combine

@MainActor
protocol FriendVisitViewModelProtocol: ObservableObject {
    var state: VisitConnectionState { get }
    var friend: FriendPresence? { get }
    var distance: Float? { get }

    func onAppear()
    func onDisappear()
}
