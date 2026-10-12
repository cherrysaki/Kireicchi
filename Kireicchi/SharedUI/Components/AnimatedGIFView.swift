import SwiftUI
import UIKit

struct AnimatedGIFView: UIViewRepresentable {
    let assetName: String

    final class Coordinator {
        var displayedAssetName: String?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.magnificationFilter = .nearest
        imageView.layer.minificationFilter = .nearest
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UIImageView,
        context: Context
    ) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        guard context.coordinator.displayedAssetName != assetName else { return }
        context.coordinator.displayedAssetName = assetName

        guard let gif = AnimatedGIFCache.shared.gif(named: assetName) else {
            uiView.stopAnimating()
            uiView.animationImages = nil
            uiView.image = nil
            return
        }

        uiView.animationImages = gif.images
        uiView.animationDuration = gif.duration
        uiView.animationRepeatCount = 0
        uiView.startAnimating()
    }
}

#Preview {
    AnimatedGIFView(assetName: "character01_normal")
        .frame(width: 160, height: 160)
}
