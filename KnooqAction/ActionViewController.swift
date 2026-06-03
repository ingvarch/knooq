import UIKit
import KnooqKit

/// Quick Action Extension (the gray bottom row of the share sheet). Captures the input to the
/// App Group queue and closes immediately — no UI, no AI. The app processes on next launch.
final class ActionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        Task { @MainActor in
            let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
            let queue = CaptureQueue.appGroup()
            for capture in await CaptureIngest.captures(from: items) {
                try? queue.enqueue(capture)
            }
            extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
