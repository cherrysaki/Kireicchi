import Foundation
import Combine

@MainActor
final class MockCleanupTimerViewModel: CleanupTimerViewModelProtocol, ObservableObject {
    @Published var remainingSeconds: Int = 300
    @Published var isRunning: Bool = false
    @Published var selectedMinutes: Int = 5
    
    var progress: Double {
        guard selectedMinutes > 0 else { return 0.0 }
        let totalSeconds = selectedMinutes * 60
        return Double(remainingSeconds) / Double(totalSeconds)
    }
    
    func start() {
        isRunning = true
    }
    
    func pause() {
        isRunning = false
    }
    
    func reset() {
        isRunning = false
        remainingSeconds = selectedMinutes * 60
    }
}