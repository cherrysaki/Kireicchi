import Foundation

protocol ScheduleNotificationUseCaseProtocol {
    @discardableResult
    func execute(isEnabled: Bool, hour: Int, minute: Int) async -> Bool
}
