import SwiftUI
import UIKit

struct CaptureView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @StateObject private var cameraController = CameraController()
    @State private var isCapturing = false
    /// プレビュー表示領域（＝ガイド枠が乗っている領域）のサイズ。クロップ範囲の算出に使用。
    @State private var viewportSize: CGSize = .zero

    var body: some View {
        ZStack {
            if cameraController.permissionDenied {
                permissionDeniedView
            } else {
                CameraPreviewView(session: cameraController.session)
                    .ignoresSafeArea()
                squareViewfinder
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
                .disabled(isCapturing || cameraController.permissionDenied || !cameraController.isConfigured)
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
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
                                RoundedRectangle(cornerRadius: 12)
                                    .frame(width: side, height: side)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    }
                    .allowsHitTesting(false)

                // 正方形の境界にスカイ枠 (HomeView と同じ太さ・角丸)
                RoundedRectangle(cornerRadius: 12)
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
            Text("カメラへの アクセスが きょかされて いません")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text("せってい アプリで カメラの アクセスを きょかして ください")
                .font(DesignSystem.Font.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("せっていを ひらく")
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
        let aspect = viewportSize.height > 0 ? viewportSize.width / viewportSize.height : 1
        cameraController.capturePhoto(viewportAspect: aspect) { data in
            isCapturing = false
            guard let data else { return }
            navigationRouter.navigate(to: .analyzing(imageData: data))
        }
    }
}

#Preview {
    NavigationStack {
        CaptureView()
            .environmentObject(NavigationRouter())
    }
}
