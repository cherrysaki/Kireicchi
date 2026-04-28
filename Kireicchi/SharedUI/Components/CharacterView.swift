import SwiftUI
import UIKit

enum CharacterGifType: String {
    case happy = "happy"
    case normal = "normal"
    case sad = "sad" 
    case sick = "sick"
    case cheer = "cheer"
    case walk = "walk"
    case run = "run"
}

struct CharacterView: View {
    let characterType: CharacterType
    let characterState: CharacterState?
    let forceGif: CharacterGifType?
    
    @State private var showingWalk = false
    @State private var timer: Timer?
    
    init(characterType: CharacterType, characterState: CharacterState) {
        self.characterType = characterType
        self.characterState = characterState
        self.forceGif = nil
    }
    
    init(characterType: CharacterType, characterState: CharacterState?, forceGif: CharacterGifType) {
        self.characterType = characterType
        self.characterState = characterState
        self.forceGif = forceGif
    }
    
    var body: some View {
        AnimatedGIFView(gifName: currentGifName)
            .onAppear {
                if forceGif == nil {
                    startTimer()
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
    }
    
    private var currentGifName: String {
        if let forceGif = forceGif {
            return "\(characterType.rawValue)_\(forceGif.rawValue)"
        }
        
        guard let characterState = characterState else {
            return "\(characterType.rawValue)_happy"
        }
        
        if showingWalk {
            return characterType.walkGifName
        } else {
            return characterType.gifName(for: characterState)
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation {
                showingWalk.toggle()
            }
        }
    }
}

struct AnimatedGIFView: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIImageView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        guard let gifData = NSDataAsset(name: gifName)?.data else {
            return
        }
        
        guard let source = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            return
        }
        
        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var totalDuration: TimeInterval = 0
        
        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)
                
                // フレームの持続時間を取得
                if let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, i, nil),
                   let gifProperties = (frameProperties as NSDictionary)[kCGImagePropertyGIFDictionary] as? [String: Any],
                   let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                    totalDuration += delayTime
                } else {
                    totalDuration += 0.1 // デフォルトのフレーム時間
                }
            }
        }
        
        if !images.isEmpty {
            uiView.animationImages = images
            uiView.animationDuration = max(totalDuration, 0.1)
            uiView.animationRepeatCount = 0 // 無限ループ
            uiView.startAnimating()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CharacterView(characterType: .character01, characterState: .happy)
            .frame(width: 100, height: 100)
        
        CharacterView(characterType: .character01, characterState: .normal)
            .frame(width: 100, height: 100)
        
        CharacterView(characterType: .character01, characterState: .sad)
            .frame(width: 100, height: 100)
        
        CharacterView(characterType: .character01, characterState: nil, forceGif: .cheer)
            .frame(width: 100, height: 100)
    }
    .padding()
}