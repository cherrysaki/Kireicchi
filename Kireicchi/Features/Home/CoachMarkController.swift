import SwiftUI
import Combine
import Instructions
import UIKit

// MARK: - CoachMarkItem

struct CoachMarkItem {
    let view: UIView
    let hint: String
    let position: Position

    enum Position {
        case top, bottom
    }
}

// MARK: - CoachMarkManager

class CoachMarkManager: NSObject, ObservableObject,
    CoachMarksControllerDataSource,
    CoachMarksControllerDelegate {

    let objectWillChange = ObservableObjectPublisher()
    let coachController = CoachMarksController()
    private var items: [CoachMarkItem] = []
    var onComplete: (() -> Void)?

    override init() {
        super.init()
        coachController.dataSource = self
        coachController.delegate = self
    }

    func start(in viewController: UIViewController, items: [CoachMarkItem], onComplete: @escaping () -> Void) {
        self.items = items
        self.onComplete = onComplete
        coachController.start(in: .window(over: viewController))
    }

    func stop() {
        coachController.stop(immediately: true)
    }

    // MARK: - DataSource

    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        items.count
    }

    func coachMarksController(
        _ coachMarksController: CoachMarksController,
        coachMarkAt index: Int
    ) -> CoachMark {
        let item = items[index]
        var mark = coachMarksController.helper.makeCoachMark(for: item.view)
        mark.arrowOrientation = item.position == .top ? .bottom : .top
        return mark
    }

    func coachMarksController(
        _ coachMarksController: CoachMarksController,
        coachMarkViewsAt index: Int,
        madeFrom coachMark: CoachMark
    ) -> (bodyView: (UIView & CoachMarkBodyView), arrowView: (UIView & CoachMarkArrowView)?) {
        let views = coachMarksController.helper.makeDefaultCoachViews(
            withArrow: true,
            arrowOrientation: coachMark.arrowOrientation
        )
        views.bodyView.hintLabel.text = items[index].hint
        views.bodyView.nextLabel.text = index == items.count - 1 ? "OK" : "つぎへ"
        return (bodyView: views.bodyView, arrowView: views.arrowView)
    }

    // MARK: - Delegate

    func coachMarksController(
        _ coachMarksController: CoachMarksController,
        didEndShowingBySkipping skipped: Bool
    ) {
        onComplete?()
    }
}

// MARK: - ViewAnchor

struct ViewAnchor: UIViewRepresentable {
    let id: String
    @Binding var uiView: UIView?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let current = self.uiView, current === uiView { return }
        DispatchQueue.main.async {
            self.uiView = uiView
        }
    }
}

// MARK: - UIView Extension

extension UIView {
    func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let vc = next as? UIViewController {
                return vc
            }
            responder = next
        }
        return nil
    }
}
