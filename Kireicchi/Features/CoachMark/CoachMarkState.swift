import Foundation
import Combine

class CoachMarkState: ObservableObject {
    @Published var currentStep: Int = UserDefaults.standard.integer(forKey: "coachMarkStep") {
        didSet { UserDefaults.standard.set(currentStep, forKey: "coachMarkStep") }
    }
    @Published var hasCompleted: Bool = UserDefaults.standard.bool(forKey: "hasCompletedCoachMark") {
        didSet { UserDefaults.standard.set(hasCompleted, forKey: "hasCompletedCoachMark") }
    }

    func shouldShow(step: Int) -> Bool {
        !hasCompleted && currentStep == step
    }

    func advance() {
        if currentStep < 10 {
            currentStep += 1
        } else {
            hasCompleted = true
        }
    }

    func reset() {
        currentStep = 0
        hasCompleted = false
    }
}
