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
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                Text("1×")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(16)

                Spacer().frame(height: 40)

                Button(action: shutterTapped) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                        Circle()
                            .fill(isCapturing ? Color.gray : Color.white)
                            .frame(width: 64, height: 64)
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
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
            Text("カメラへのアクセスが許可されていません")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text("設定アプリでカメラのアクセスを許可してください")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding(.top, 8)
            .foregroundColor(.white)
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
