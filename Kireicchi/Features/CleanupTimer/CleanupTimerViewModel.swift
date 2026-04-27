import Foundation
import Combine

@MainActor
final class CleanupTimerViewModel: CleanupTimerViewModelProtocol, ObservableObject {
    @Published var remainingSeconds: Int = 300
    @Published var isRunning: Bool = false
    @Published var selectedMinutes: Int = 5 {
        didSet {
            if !isRunning {
                remainingSeconds = selectedMinutes * 60
            }
        }
    }
    
    private var timer: Timer?
    
    var progress: Double {
        guard selectedMinutes > 0 else { return 0.0 }
        let totalSeconds = selectedMinutes * 60
        return Double(remainingSeconds) / Double(totalSeconds)
    }
    
    init() {
        remainingSeconds = selectedMinutes * 60
    }
    
    func start() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func reset() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        remainingSeconds = selectedMinutes * 60
    }
    
    private func updateTimer() {
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            remainingSeconds = 0
            pause()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}