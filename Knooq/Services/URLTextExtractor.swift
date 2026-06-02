import WebKit
import KnooqKit

/// Loads a page in a headless WKWebView, runs Mozilla Readability.js, returns article text.
/// Main app only (memory) — never the extension. URL-focused (SRP); the pipeline's
/// `TextExtractor` composite routes to it for `.url` items.
final class URLTextExtractor: NSObject, @unchecked Sendable {
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<String, Error>?
    private var timeoutTask: Task<Void, Never>?
    private let timeout: TimeInterval

    init(timeout: TimeInterval = 30) {
        self.timeout = timeout
    }

    func extract(from url: URL) async throws -> String {
        try await run { [timeout] webView in
            webView.load(URLRequest(url: url, timeoutInterval: timeout))
        }
    }

    /// Testable entry: render literal HTML, then extract. Used with fixtures.
    func extract(fromHTML html: String, baseURL: URL? = nil) async throws -> String {
        try await run { webView in
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }

    private func run(_ start: @escaping @MainActor (WKWebView) -> Void) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            Task { @MainActor in
                let config = WKWebViewConfiguration()
                config.websiteDataStore = .nonPersistent()
                let webView = WKWebView(frame: .zero, configuration: config)
                webView.navigationDelegate = self
                self.webView = webView
                start(webView)
                self.timeoutTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(self.timeout))
                    self.fail(URLError(.timedOut))
                }
            }
        }
    }

    @MainActor
    private func runReadability() {
        guard let webView else { return }
        guard let jsURL = Bundle.main.url(forResource: "Readability", withExtension: "js"),
              let readabilityJS = try? String(contentsOf: jsURL, encoding: .utf8) else {
            fail(URLError(.cannotParseResponse))
            return
        }

        let script = """
        \(readabilityJS)
        (function() {
            try {
                var article = new Readability(document.cloneNode(true)).parse();
                return article && article.textContent ? article.textContent : document.body.innerText;
            } catch (e) {
                return document.body ? document.body.innerText : "";
            }
        })();
        """

        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let error {
                self?.fail(error)
            } else if let text = result as? String {
                self?.succeed(text)
            } else {
                self?.fail(URLError(.cannotParseResponse))
            }
        }
    }

    @MainActor
    private func succeed(_ text: String) {
        finish { $0.resume(returning: text) }
    }

    @MainActor
    private func fail(_ error: Error) {
        finish { $0.resume(throwing: error) }
    }

    @MainActor
    private func finish(_ resume: (CheckedContinuation<String, Error>) -> Void) {
        guard let continuation else { return }  // first caller wins
        self.continuation = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        webView?.stopLoading()
        webView = nil
        resume(continuation)
    }
}

extension URLTextExtractor: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in runReadability() }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in fail(error) }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in fail(error) }
    }
}
