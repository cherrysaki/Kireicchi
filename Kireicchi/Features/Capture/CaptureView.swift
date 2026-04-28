import SwiftUI
import UIKit

struct CaptureView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @StateObject private var cameraController = CameraController()
    @State private var isCapturing = false

    var body: some View {
        ZStack {
            if cameraController.permissionDenied {
                permissionDeniedView
            } else {
                CameraPreviewView(session: cameraController.session)
                    .ignoresSafeArea()
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

                Text("1×")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(.white)
                    .pixelFrame(pixelSize: 3, background: Color.black.opacity(0.4))

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
        cameraController.capturePhoto { data in
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
