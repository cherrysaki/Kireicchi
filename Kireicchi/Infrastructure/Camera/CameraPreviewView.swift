import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    /// true の間はプレビューレイヤーへのフレーム供給を止め、最後のフレームで静止させる。
    var isFrozen: Bool = false

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        // connection を無効化するとライブ更新が止まり、直前のフレームが画面に残る（セッションは止めない）。
        uiView.videoPreviewLayer.connection?.isEnabled = !isFrozen
    }
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // layerClass を AVCaptureVideoPreviewLayer に指定しているため確実に成功する
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }
}
