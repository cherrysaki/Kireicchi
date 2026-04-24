import Foundation
import Combine

@MainActor
final class PixelArtStore: ObservableObject {
    @Published var latestPixelArtData: Data?
}
