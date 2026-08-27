import Foundation
import FirebaseFunctions

/// Cloud Functions の unlinkParent(callable)を呼び出す。
/// 呼び出し元uidはFirebase AuthのIDトークンからサーバー側で検証されるため、パラメータは不要。
final class ParentLinkRepository: ParentLinkRepositoryProtocol {
    private var functions: Functions { Functions.functions(region: "asia-northeast1") }

    func unlink() async throws {
        _ = try await functions.httpsCallable("unlinkParent").call()
    }
}
