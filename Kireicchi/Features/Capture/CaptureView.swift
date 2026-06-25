import SwiftUI
import UIKit

struct CaptureView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @StateObject private var cameraController = CameraController()
    @State private var isCapturing = false
    /// プレビュー表示領域（＝ガイド枠が乗っている領域）のサイズ。クロップ範囲の算出に使用。
    @State private var viewportSize: CGSize = .zero
    /// 撮影完了後、解析画面へ遷移するまで表示し続ける静止画。ライブ映像の上に重ねる。
    @State private var frozenImage: UIImage?
    /// シャッターを押した瞬間にライブプレビューを静止させるフラグ。
    @State private var isPreviewFrozen = false

    var body: some View {
        ZStack {
            if cameraController.permissionDenied {
                permissionDeniedView
            } else {
                CameraPreviewView(session: cameraController.session, isFrozen: isPreviewFrozen)
                    .ignoresSafeArea()
                squareViewfinder
            }

            // 撮影直後の静止画。ライブ映像・ガイド枠を覆い、遷移するまで表示し続ける。
            if let frozenImage {
                frozenStill(frozenImage)
            }

            VStack {
                HStack {
                    Button(action: {
                        navigationRouter.navigateBack()
                    }) {
                        Image(systemName: "xmark")
                            .font(DesignSystem.Font.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                PixelCircle(pixelSize: 4)
                                    .fill(Color.black.opacity(0.4))
                            )
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                Spacer().frame(height: 40)

                Button(action: shutterTapped) {
                    ZStack {
                        PixelCircleStroke(pixelSize: 5, lineWidth: 6)
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                        PixelCircle(pixelSize: 5)
                            .fill(isCapturing ? Color.gray : Color.white)
                            .frame(width: 60, height: 60)
                    }
                }
                .disabled(isCapturing || frozenImage != nil || cameraController.permissionDenied || !cameraController.isConfigured)
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            frozenImage = nil
            isPreviewFrozen = false
            cameraController.startSession()
        }
        .onDisappear {
            cameraController.stopSession()
        }
    }

    // 撮影される正方形領域だけ明るく、それ以外をマスクして撮影範囲を明示
    private var squareViewfinder: some View {
        GeometryReader { geo in
            let side = geo.size.width
            ZStack {
                // 全面を半透明黒で覆い、正方形 (角丸 12) だけ穴を空ける
                Color.black.opacity(0.55)
                    .mask {
                        Rectangle()
                            .overlay(
                                PixelCornerRectangle(cornerRadius: 12)
                                    .frame(width: side, height: side)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    }
                    .allowsHitTesting(false)

                // 正方形の境界にスカイ枠 (HomeView と同じ太さ・角丸)
                PixelCornerRectangle(cornerRadius: 12)
                    .stroke(DesignSystem.Color.primary, lineWidth: 5)
                    .frame(width: side, height: side)
                    .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear { viewportSize = geo.size }
            .onChange(of: geo.size) { _, newValue in viewportSize = newValue }
        }
        .ignoresSafeArea()
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.slash")
                .font(DesignSystem.Font.custom(size: 60))
                .foregroundColor(.white.opacity(0.7))
            Text("カメラへのアクセスが許可されていません")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text("設定アプリでカメラのアクセスを許可してください")
                .font(DesignSystem.Font.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("設定を開く")
                    .font(DesignSystem.Font.subheadline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(PixelButtonStyle())
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }

    private func shutterTapped() {
        guard !isCapturing else { return }
        isCapturing = true
        isPreviewFrozen = true   // タップ直後にライブ映像を即停止（最後のフレームで静止）
        let aspect = viewportSize.height > 0 ? viewportSize.width / viewportSize.height : 1
        cameraController.capturePhoto(viewportAspect: aspect) { data in
            isCapturing = false
            guard let data else {
                isPreviewFrozen = false   // 失敗時はライブへ戻す
                return
            }
            // 撮影した瞬間の画像で固定表示してから解析へ遷移
            frozenImage = UIImage(data: data)
            navigationRouter.navigate(to: .analyzing(imageData: data))
        }
    }

    // ガイド枠と同じ「中央・一辺＝画面幅の正方形」で撮影画像を静止表示する。
    private func frozenStill(_ image: UIImage) -> some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.width)
                    .clipped()
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        CaptureView()
            .environmentObject(NavigationRouter())
    }
}
