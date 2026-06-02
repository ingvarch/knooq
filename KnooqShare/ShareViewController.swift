import UIKit

// Raw-capture only: extension writes raw payload to the shared store and closes.
// No AI, no network, no OCR here (extension memory budget). Implemented in task 6.
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        extensionContext?.completeRequest(returningItems: nil)
    }
}
