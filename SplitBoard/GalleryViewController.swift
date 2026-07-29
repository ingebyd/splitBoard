import UIKit

/// Debug-only screen that renders the real keyboard inside the app, so store
/// screenshots can be captured without going through the system input view.
///
///   xcrun simctl launch <device> com.sherkhan.splitboard -gallery split -galleryLang ru
final class GalleryViewController: UIViewController, KeyboardViewDelegate {

    private let keyboardView = KeyboardView(frame: .zero)
    private let sample = UITextView()
    private var heightConstraint: NSLayoutConstraint!

    private let split: Bool
    private let language: KBLanguage
    private let text: String

    init(split: Bool, language: KBLanguage, text: String) {
        self.split = split
        self.language = language
        self.text = text
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        sample.text = text
        sample.font = .systemFont(ofSize: 22)
        sample.isEditable = false
        sample.backgroundColor = .clear
        sample.textContainerInset = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        sample.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sample)

        keyboardView.delegate = self
        keyboardView.isPad = true
        keyboardView.language = language
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardView)

        heightConstraint = keyboardView.heightAnchor.constraint(equalToConstant: 320)
        NSLayoutConstraint.activate([
            sample.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sample.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sample.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sample.bottomAnchor.constraint(equalTo: keyboardView.topAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            heightConstraint,
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard view.bounds.width > 0 else { return }
        keyboardView.layoutWidth = view.bounds.width
        if keyboardView.isSplit != split {
            keyboardView.setSplit(split, animated: false, applyHeight: {})
        } else {
            keyboardView.rebuild()
        }
        heightConstraint.constant = keyboardView.contentHeight
        keyboardView.backgroundColor = Theme.backdrop
    }

    // Screenshots only: nothing types anywhere.
    func keyboardView(_ view: KeyboardView, didPress key: KeyView, event: UIEvent?) {}
    func keyboardView(_ view: KeyboardView, didRelease key: KeyView, flicked: Bool) {}
    func keyboardView(_ view: KeyboardView, didCancel key: KeyView) {}
    func keyboardView(_ view: KeyboardView, didLongPress key: KeyView, event: UIEvent?) {}
    func keyboardView(_ view: KeyboardView, didSelectAlternate text: String, for key: KeyView) {}
}
