import Foundation
import Combine

@MainActor
final class FriendVisitCoordinator: FriendVisitCoordinatorProtocol {
    @Published private(set) var state: VisitConnectionState = .idle
    @Published private(set) var friend: FriendPresence? = nil
    @Published private(set) var distance: Float? = nil

    private let peerSession: PeerSessionProtocol
    private let distanceTracker: NearbyDistanceTrackerProtocol

    private var connectedPeerId: String?
    private var helloReceived = false
    private var niTokenSent = false

    private var eventTask: Task<Void, Never>?
    private var distanceTask: Task<Void, Never>?

    private let visitEnterThreshold: Float = 0.5
    private let visitExitThreshold: Float = 1.5

    init(peerSession: PeerSessionProtocol, distanceTracker: NearbyDistanceTrackerProtocol) {
        self.peerSession = peerSession
        self.distanceTracker = distanceTracker
    }

    func start(myCharacterId: String, myDisplayName: String) async {
        state = .discovering
        await peerSession.start(displayName: myDisplayName)

        eventTask = Task { [weak self, peerSession] in
            for await event in peerSession.events {
                guard let self else { return }
                await MainActor.run {
                    self.handle(event: event, myCharacterId: myCharacterId, myDisplayName: myDisplayName)
                }
            }
        }

        distanceTask = Task { [weak self, distanceTracker] in
            for await meters in distanceTracker.distances {
                guard let self else { return }
                await MainActor.run {
                    self.handle(distance: meters)
                }
            }
        }
    }

    func stop() {
        eventTask?.cancel()
        distanceTask?.cancel()
        eventTask = nil
        distanceTask = nil
        distanceTracker.stop()
        peerSession.stop()
        state = .idle
        friend = nil
        distance = nil
        connectedPeerId = nil
        helloReceived = false
        niTokenSent = false
    }

    // MARK: - Event handling

    private func handle(event: PeerSessionEvent, myCharacterId: String, myDisplayName: String) {
        switch event {
        case .peerFound(_, let displayName):
            if connectedPeerId == nil {
                state = .connecting(peerName: displayName)
            }

        case .peerLost:
            break

        case .peerConnecting(_, let displayName):
            state = .connecting(peerName: displayName)

        case .peerConnected(let peerId, _):
            connectedPeerId = peerId
            let hello = FriendVisitMessage.hello(
                .init(characterId: myCharacterId, displayName: myDisplayName)
            )
            Task {
                await peerSession.send(hello, to: peerId)
            }
            // ローカル NI トークンを生成して送る
            if let tokenData = distanceTracker.start() {
                Task {
                    await peerSession.send(.niToken(tokenData: tokenData), to: peerId)
                    niTokenSent = true
                    advanceStateAfterHandshake()
                }
            }

        case .peerDisconnected:
            distanceTracker.stop()
            connectedPeerId = nil
            helloReceived = false
            niTokenSent = false
            friend = nil
            distance = nil
            state = .discovering

        case .messageReceived(let peerId, let message):
            switch message {
            case .hello(let payload):
                friend = FriendPresence(
                    peerId: peerId,
                    displayName: payload.displayName,
                    characterId: payload.characterId
                )
                helloReceived = true
                advanceStateAfterHandshake()
            case .niToken(let tokenData):
                distanceTracker.setRemoteToken(tokenData)
                advanceStateAfterHandshake()
            case .scoreUpdate:
                break
            case .bye:
                stop()
            }

        case .error(let msg):
            state = .error(msg)
        }
    }

    private func advanceStateAfterHandshake() {
        if helloReceived && niTokenSent {
            state = .tracking
        } else if helloReceived {
            state = .connected
        }
    }

    private func handle(distance meters: Float) {
        distance = meters
        switch state {
        case .visiting:
            if meters > visitExitThreshold {
                state = .tracking
            }
        case .tracking:
            if meters < visitEnterThreshold {
                state = .visiting
            }
        default:
            break
        }
    }
}
