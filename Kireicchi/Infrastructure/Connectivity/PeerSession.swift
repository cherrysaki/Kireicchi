import Foundation
import MultipeerConnectivity

private let kServiceType = "kireicchi-fv"

@MainActor
final class PeerSession: NSObject, PeerSessionProtocol {
    let events: AsyncStream<PeerSessionEvent>
    private let continuation: AsyncStream<PeerSessionEvent>.Continuation

    private var localPeerID: MCPeerID?
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private var connectedPeers: [String: MCPeerID] = [:]
    private var invitedPeerIds: Set<String> = []
    private var hasActivePeer: Bool { !connectedPeers.isEmpty }

    override init() {
        var c: AsyncStream<PeerSessionEvent>.Continuation!
        self.events = AsyncStream(bufferingPolicy: .unbounded) { continuation in
            c = continuation
        }
        self.continuation = c
        super.init()
    }

    func start(displayName: String) async {
        // 既存のセッションがあれば破棄
        stop()

        // 表示名は MCPeerID 制約 (≤63bytes UTF-8) に収める
        let safeName = String(displayName.prefix(40))
        let peerID = MCPeerID(displayName: safeName)
        localPeerID = peerID

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: kServiceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser

        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: kServiceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser?.delegate = nil
        browser?.delegate = nil
        session?.delegate = nil
        advertiser = nil
        browser = nil
        session = nil
        localPeerID = nil
        connectedPeers.removeAll()
        invitedPeerIds.removeAll()
    }

    func send(_ message: FriendVisitMessage, to peerId: String?) async {
        guard let session, let data = try? message.encoded() else { return }
        let targets: [MCPeerID]
        if let peerId, let target = connectedPeers[peerId] {
            targets = [target]
        } else {
            targets = Array(connectedPeers.values)
        }
        guard !targets.isEmpty else { return }
        try? session.send(data, toPeers: targets, with: .reliable)
    }

    private func emit(_ event: PeerSessionEvent) {
        continuation.yield(event)
    }
}

// MARK: - MCSessionDelegate

extension PeerSession: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            let id = peerID.displayName
            switch state {
            case .connected:
                self.connectedPeers[id] = peerID
                self.emit(.peerConnected(peerId: id, displayName: peerID.displayName))
            case .connecting:
                self.emit(.peerConnecting(peerId: id, displayName: peerID.displayName))
            case .notConnected:
                self.connectedPeers.removeValue(forKey: id)
                self.invitedPeerIds.remove(id)
                self.emit(.peerDisconnected(peerId: id))
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            guard let message = FriendVisitMessage.decode(from: data) else { return }
            self.emit(.messageReceived(peerId: peerID.displayName, message: message))
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName name: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName name: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension PeerSession: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            // 既に他の peer と接続/招待中なら拒否
            if self.hasActivePeer || self.invitedPeerIds.contains(peerID.displayName) {
                invitationHandler(false, nil)
                return
            }
            self.invitedPeerIds.insert(peerID.displayName)
            invitationHandler(true, self.session)
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            self.emit(.error("Advertiser failed: \(error.localizedDescription)"))
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension PeerSession: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             foundPeer peerID: MCPeerID,
                             withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            let id = peerID.displayName
            self.emit(.peerFound(peerId: id, displayName: peerID.displayName))

            guard let session = self.session else { return }
            // 既に接続/招待済みならスキップ
            if self.hasActivePeer || self.invitedPeerIds.contains(id) { return }
            // 自動 invite (decision tie-break: localPeerID の displayName が小さい方が招待する)
            if let local = self.localPeerID, local.displayName < peerID.displayName {
                self.invitedPeerIds.insert(id)
                browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.emit(.peerLost(peerId: peerID.displayName))
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            self.emit(.error("Browser failed: \(error.localizedDescription)"))
        }
    }
}
