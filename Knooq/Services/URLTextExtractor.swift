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

    // SPA pages render the article via JS after `didFinish`. Retry the content read a few
    // times before falling back to meta tags, so JS-rendered articles aren't missed.
    private static let contentMinLength = 200
    private static let maxContentAttempts = 6
    private static let retryDelay: Duration = .milliseconds(600)

    @MainActor
    private func runReadability(attempt: Int = 0) {
        guard let webView else { return }
        guard let jsURL = Bundle.main.url(forResource: "Readability", withExtension: "js"),
              let readabilityJS = try? String(contentsOf: jsURL, encoding: .utf8) else {
            fail(URLError(.cannotParseResponse))
            return
        }

        // Best real content: Readability article, else rendered body text. "" = nothing yet.
        let contentScript = """
        \(readabilityJS)
        (function() {
            try {
                var article = new Readability(document.cloneNode(true)).parse();
                if (article && article.textContent && article.textContent.trim().length > \(Self.contentMinLength)) {
                    return article.textContent;
                }
            } catch (e) {}
            var body = document.body ? document.body.innerText : "";
            if (body.trim().length > \(Self.contentMinLength)) { return body; }
            return "";
        })();
        """

        webView.evaluateJavaScript(contentScript) { [weak self] result, error in
            guard let self else { return }
            if let error { self.fail(error); return }
            let text = (result as? String) ?? ""
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.succeed(text)
            } else if attempt + 1 < Self.maxContentAttempts {
                Task { @MainActor in
                    try? await Task.sleep(for: Self.retryDelay)
                    self.runReadability(attempt: attempt + 1)
                }
            } else {
                self.runMetaFallback()  // truly empty SPA / login wall
            }
        }
    }

    // Last resort for pages with no readable body (login-walled SPAs): OG + meta tags.
    @MainActor
    private func runMetaFallback() {
        guard let webView else { return }
        let script = """
        (function() {
            function meta(sel) { var e = document.querySelector(sel); return e ? (e.content || "") : ""; }
            return [
                document.title || "",
                meta('meta[property="og:title"]'),
                meta('meta[property="og:description"]'),
                meta('meta[name="description"]'),
                meta('meta[property="og:site_name"]'),
            ].filter(Boolean).join("\\n");
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
