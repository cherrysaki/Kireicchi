import UIKit

final class CharacterAssetCatalog: @unchecked Sendable {
    static let shared = CharacterAssetCatalog()

    private let assetExists: (String) -> Bool
    private let resolvedAssetNames = NSCache<NSString, NSString>()

    init(assetExists: @escaping (String) -> Bool = { NSDataAsset(name: $0) != nil }) {
        self.assetExists = assetExists
    }

    func assetName(for presentation: CharacterPresentation) -> String {
        let cacheKey = [
            presentation.characterType.rawValue,
            presentation.formID.rawValue,
            presentation.mood.assetSuffix,
            presentation.action.rawValue
        ].joined(separator: "|") as NSString

        if let cached = resolvedAssetNames.object(forKey: cacheKey) {
            return cached as String
        }

        let candidates = assetCandidates(for: presentation)
        let resolved = candidates.first(where: assetExists) ?? "character01_normal"
        resolvedAssetNames.setObject(resolved as NSString, forKey: cacheKey)
        return resolved
    }

    func assetCandidates(for presentation: CharacterPresentation) -> [String] {
        let requestedSuffix = suffix(mood: presentation.mood, action: presentation.action)
        var candidates = [
            assetName(
                characterType: presentation.characterType,
                formID: presentation.formID,
                suffix: requestedSuffix
            ),
            assetName(
                characterType: presentation.characterType,
                formID: .base,
                suffix: requestedSuffix
            ),
            assetName(
                characterType: presentation.characterType,
                formID: .base,
                suffix: CharacterMood.normal.assetSuffix
            ),
            assetName(
                characterType: .character01,
                formID: .base,
                suffix: requestedSuffix
            ),
            assetName(
                characterType: .character01,
                formID: .base,
                suffix: CharacterMood.normal.assetSuffix
            )
        ]

        var seen = Set<String>()
        candidates = candidates.filter { seen.insert($0).inserted }
        return candidates
    }

    private func suffix(mood: CharacterMood, action: CharacterAction) -> String {
        action == .idle ? mood.assetSuffix : action.rawValue
    }

    private func assetName(
        characterType: CharacterType,
        formID: CharacterFormID,
        suffix: String
    ) -> String {
        if formID == .base {
            return "\(characterType.rawValue)_\(suffix)"
        }
        return "\(characterType.rawValue)_\(formID.rawValue)_\(suffix)"
    }
}
