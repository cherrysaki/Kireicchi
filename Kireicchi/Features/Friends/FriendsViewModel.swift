import Foundation
import Combine

@MainActor
final class FriendsViewModel: FriendsViewModelProtocol {
    @Published private(set) var myProfile: FriendProfile?
    @Published private(set) var friends: [FriendProfile] = []
    @Published private(set) var incomingRequests: [FriendRequest] = []
    @Published private(set) var outgoingRequests: [FriendRequest] = []
    @Published var searchText: String = ""
    @Published private(set) var searchResult: FriendProfile?
    @Published private(set) var isLoading = false
    @Published private(set) var isSearching = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let myUid: String?
    private let fetchFriendsUseCase: FetchFriendsUseCaseProtocol
    private let searchFriendUseCase: SearchFriendUseCaseProtocol
    private let sendFriendRequestUseCase: SendFriendRequestUseCaseProtocol
    private let respondFriendRequestUseCase: RespondFriendRequestUseCaseProtocol
    private let cancelFriendRequestUseCase: CancelFriendRequestUseCaseProtocol
    private let removeFriendUseCase: RemoveFriendUseCaseProtocol

    init(
        myProfile: FriendProfile?,
        myUid: String?,
        fetchFriendsUseCase: FetchFriendsUseCaseProtocol,
        searchFriendUseCase: SearchFriendUseCaseProtocol,
        sendFriendRequestUseCase: SendFriendRequestUseCaseProtocol,
        respondFriendRequestUseCase: RespondFriendRequestUseCaseProtocol,
        cancelFriendRequestUseCase: CancelFriendRequestUseCaseProtocol,
        removeFriendUseCase: RemoveFriendUseCaseProtocol
    ) {
        self.myProfile = myProfile
        self.myUid = myUid
        self.fetchFriendsUseCase = fetchFriendsUseCase
        self.searchFriendUseCase = searchFriendUseCase
        self.sendFriendRequestUseCase = sendFriendRequestUseCase
        self.respondFriendRequestUseCase = respondFriendRequestUseCase
        self.cancelFriendRequestUseCase = cancelFriendRequestUseCase
        self.removeFriendUseCase = removeFriendUseCase
    }

    func load() async {
        guard let uid = myUid else {
            errorMessage = FriendError.notSignedIn.localizedDescription
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let snapshot = try await fetchFriendsUseCase.execute(uid: uid)
            friends = snapshot.friends
            incomingRequests = snapshot.incomingRequests
            outgoingRequests = snapshot.outgoingRequests
        } catch {
            errorMessage = error.localizedDescription
            print("[FriendsViewModel] load failed: \(error)")
        }
    }

    func search() async {
        guard let uid = myUid else {
            errorMessage = FriendError.notSignedIn.localizedDescription
            return
        }
        isSearching = true
        defer { isSearching = false }
        searchResult = nil
        do {
            searchResult = try await searchFriendUseCase.execute(userId: searchText, myUid: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendRequest(to profile: FriendProfile) async {
        guard let me = myProfile else {
            errorMessage = FriendError.usernameNotSet.localizedDescription
            return
        }
        do {
            try await sendFriendRequestUseCase.execute(from: me, to: profile)
            infoMessage = "「\(profile.username)」さんに申請を送りました"
            searchResult = nil
            searchText = ""
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func accept(_ request: FriendRequest) async {
        await perform { try await self.respondFriendRequestUseCase.accept(request) }
    }

    func decline(_ request: FriendRequest) async {
        await perform { try await self.respondFriendRequestUseCase.decline(request) }
    }

    func cancel(_ request: FriendRequest) async {
        await perform { try await self.cancelFriendRequestUseCase.execute(request) }
    }

    func removeFriend(_ friend: FriendProfile) async {
        guard let uid = myUid else { return }
        await perform { try await self.removeFriendUseCase.execute(uid: uid, friendUid: friend.uid) }
    }

    func relation(with profile: FriendProfile) -> FriendRelation {
        if friends.contains(where: { $0.uid == profile.uid }) { return .friend }
        if outgoingRequests.contains(where: { $0.toUid == profile.uid }) { return .requestSent }
        if incomingRequests.contains(where: { $0.fromUid == profile.uid }) { return .requestReceived }
        return .none
    }

    private func perform(_ action: () async throws -> Void) async {
        do {
            try await action()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
