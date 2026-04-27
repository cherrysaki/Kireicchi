import Foundation

@MainActor
protocol CleanupTimerViewModelProtocol: ObservableObject {
    var remainingSeconds: Int { get }
    var isRunning: Bool { get }
    var selectedMinutes: Int { get set }
    var progress: Double { get }
    var isFinished: Bool { get }
    
    func start()
    func pause()
    func reset()
}