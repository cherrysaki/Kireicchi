import Foundation

/// 親子連携(parentLinks)の解除を行う。
/// parentLinksはクライアントから直接読み書きできないため、Cloud Functions(unlinkParent)経由で操作する。
protocol ParentLinkRepositoryProtocol: Sendable {
    func unlink() async throws
}
