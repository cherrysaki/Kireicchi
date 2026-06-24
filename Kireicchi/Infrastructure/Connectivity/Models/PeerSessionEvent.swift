import Foundation

enum PeerSessionEvent: Sendable {
    case peerFound(peerId: String, displayName: String)
    case peerLost(peerId: String)
    case peerConnecting(peerId: String, displayName: String)
    case peerConnected(peerId: String, displayName: String)
    case peerDisconnected(peerId: String)
    case messageReceived(peerId: String, message: FriendVisitMessage)
    case error(String)
}
