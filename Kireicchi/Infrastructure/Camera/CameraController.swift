@preconcurrency import AVFoundation
import Foundation
import Combine

final class CameraController: NSObject, ObservableObject {

    @Published private(set) var isAuthorized = false
    @Published private(set) var permissionDenied = false
    @Published private(set) var isConfigured = false

    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "kireicchi.camera.session")
    private var captureCompletion: ((Data?) -> Void)?

    override init() {
        super.init()
    }

    func startSession() {
        checkPermissionAndConfigure()
    }

    func stopSession() {
        let session = self.session
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    func capturePhoto(completion: @escaping (Data?) -> Void) {
        guard isAuthorized, isConfigured else {
            completion(nil)
            return
        }

        captureCompletion = completion

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off

        let photoOutput = self.photoOutput
        sessionQueue.async { [weak self] in
            guard let self else { return }
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func checkPermissionAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            updateAuthorized(true)
            configureSessionIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    self.permissionDenied = !granted
                }
                if granted {
                    self.configureSessionIfNeeded()
                }
            }
        case .denied, .restricted:
            updateAuthorized(false, denied: true)
        @unknown default:
            updateAuthorized(false, denied: true)
        }
    }

    private func updateAuthorized(_ authorized: Bool, denied: Bool = false) {
        if Thread.isMainThread {
            isAuthorized = authorized
            permissionDenied = denied
        } else {
            DispatchQueue.main.async {
                self.isAuthorized = authorized
                self.permissionDenied = denied
            }
        }
    }

    private func configureSessionIfNeeded() {
        let session = self.session
        let photoOutput = self.photoOutput

        sessionQueue.async { [weak self] in
            guard let self else { return }

            if session.isRunning {
                return
            }

            let alreadyConfigured = !session.inputs.isEmpty && !session.outputs.isEmpty

            if !alreadyConfigured {
                session.beginConfiguration()
                session.sessionPreset = .photo

                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: device),
                      session.canAddInput(input) else {
                    session.commitConfiguration()
                    return
                }
                session.addInput(input)

                if session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                }

                session.commitConfiguration()

                DispatchQueue.main.async {
                    self.isConfigured = true
                }
            } else {
                DispatchQueue.main.async {
                    self.isConfigured = true
                }
            }

            session.startRunning()
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        let data = error == nil ? photo.fileDataRepresentation() : nil
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.captureCompletion?(data)
            self.captureCompletion = nil
        }
    }
}
