//
//  KireicchiIntroAnimationView.swift
//  Kireicchi
//
//  CG課題として別プロジェクト（Kireicchi_onboarding、Three.js/WebGL）で作られた
//  「きれいっち誕生」3Dアニメーションを、本アプリのオンボーディングに組み込むためのラッパー。
//
//  アニメーション本体はビルド時にJS/CSS/画像をすべて1個のHTMLファイルへインライン化した
//  自己完結ファイル（kireicchi_intro.html）としてこのターゲットにバンドルしており、
//  WKWebViewでfile://読み込みする。複数ファイルの相対パス解決に依存しないため、
//  Xcodeのリソース管理まわりで壊れる心配がない。
//
//  更新したい場合は、Kireicchi_onboardingプロジェクト側で
//  `npm run build` を実行し、生成された dist/index.html を
//  このファイル（kireicchi_intro.html）として差し替える。
//

import SwiftUI
import WebKit

// MARK: - WKWebView ラッパー

/// kireicchi_intro.html をロードし、アニメーションが最後まで進んだときの
/// JS→Native通知（window.webkit.messageHandlers.kireicchiIntro.postMessage("done")）を
/// 受け取ってSwiftUI側に橋渡しする。
struct KireicchiIntroWebView: UIViewRepresentable {
    /// アニメーションが最後まで再生され、ネイティブ側に完了通知が届いたときに呼ばれる。
    /// メインスレッドで呼ばれる
    var onFinished: () -> Void

    fileprivate static let messageName = "kireicchiIntro"

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: Self.messageName)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        // デフォルトのままだと UIScrollView がセーフエリア分の contentInset を自動で
        // 追加してしまい、下部（ホームインジケーター領域）にこの View の背景色
        // （Color.black、下記body参照）がその分だけ帯状に透けて見えてしまう。
        // HTML側はすでに画面いっぱいに広がる作りなので、ここでも無効化しておく
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsLinkPreview = false
        webView.contentMode = .scaleAspectFit

        if let url = Bundle.main.url(forResource: "kireicchi_intro", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url)
        } else {
            assertionFailure("kireicchi_intro.html がアプリバンドルに見つかりません。Xcodeプロジェクトに含まれているか確認してください")
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // アニメーションは読み込み時に一度だけ再生されるため、更新時に行うことはない
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: messageName)
        uiView.stopLoading()
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        private let onFinished: () -> Void
        private var didFinish = false

        init(onFinished: @escaping () -> Void) {
            self.onFinished = onFinished
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == KireicchiIntroWebView.messageName, !didFinish else { return }
            didFinish = true
            let callback = onFinished
            DispatchQueue.main.async {
                callback()
            }
        }
    }
}

// MARK: - オンボーディング用フルスクリーン画面

/// オンボーディング冒頭で「きれいっち誕生」の3Dアニメーションをフルスクリーン再生する画面。
/// - アニメーションが最後まで再生されるか、ユーザーが「スキップ」をタップすると onFinished を呼ぶ
/// - WebView側からの完了通知が万一届かない場合に備え、タイムアウトで自動的に先へ進める
///   フォールバックを用意している（アニメーション本編は卵タップの間も含めて約26秒）
struct KireicchiIntroAnimationView: View {
    var onFinished: () -> Void

    private static let fallbackTimeout: TimeInterval = 40

    @State private var didFinish = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            KireicchiIntroWebView(onFinished: finish)
                .ignoresSafeArea()

            Button(action: finish) {
                Text("スキップ")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.35), in: Capsule())
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
        .task {
            try? await Task.sleep(nanoseconds: UInt64(Self.fallbackTimeout * 1_000_000_000))
            finish()
        }
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }
}

#Preview {
    KireicchiIntroAnimationView(onFinished: {})
}
