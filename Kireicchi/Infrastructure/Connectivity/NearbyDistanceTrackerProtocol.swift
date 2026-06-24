import Foundation

@MainActor
protocol NearbyDistanceTrackerProtocol: AnyObject {
    /// 距離を m 単位で配信(NI 取得値そのまま)
    var distances: AsyncStream<Float> { get }

    /// セッションを開始し、ローカルトークンの Data 表現を返す。
    /// MultipeerConnectivity 経由で相手に送るのに使う。
    /// 失敗時(NI非対応など)は nil を返す。
    func start() -> Data?

    /// 相手から受け取ったトークン Data をセットして測定を開始
    func setRemoteToken(_ data: Data)

    func stop()
}
