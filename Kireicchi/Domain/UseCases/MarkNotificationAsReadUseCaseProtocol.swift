import Foundation

protocol MarkNotificationAsReadUseCaseProtocol {
    func execute(id: String) async throws
}
