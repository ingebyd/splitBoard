import UIKit

/// Host app: a short paged walkthrough plus a field to try the keyboard in.
final class RootViewController: UIViewController, UIScrollViewDelegate {

    private struct Page {
        var image: String
        var title: String
        var body: String
        var buttonTitle: String? = nil
        var showsPlayground: Bool = false
    }

    private let pages: [Page] = [
        Page(image: "onb-split",
             title: "The split keyboard is back",
             body: "iPadOS 26 dropped the split keyboard. SplitBoard brings it back: two halves "
                 + "pinned to the edges of the screen, sized for typing with your thumbs while "
                 + "you hold the iPad."),
        Page(image: "onb-settings",
             title: "Turn it on",
             body: "Settings → General → Keyboard → Keyboards → Add New Keyboard → SplitBoard.\n"
                 + "Full Access is not needed: the keyboard sends nothing anywhere.",
             buttonTitle: "Open Settings"),
        Page(image: "onb-globe",
             title: "Switch to it",
             body: "In any text field, touch and hold the globe key and pick SplitBoard.\n"
                 + "A short tap on the globe switches English ⇄ Russian, and so does the "
                 + "abc / абв key next to A."),
        Page(image: "onb-splitkey",
             title: "Split and merge",
             body: "Tap the key with the two-panel icon in the bottom row to split the keyboard "
                 + "in half, and tap it again to merge it back. SplitBoard remembers your choice.",
             showsPlayground: true),
    ]

    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    private let textView = UITextView()
    private var didFocusPlayground = false
    private var bottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        pageControl.numberOfPages = pages.count
        pageControl.currentPageIndicatorTintColor = .label
        pageControl.pageIndicatorTintColor = .quaternaryLabel
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)
        view.addSubview(pageControl)

        bottomConstraint = pageControl.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)

        let row = UIStackView(arrangedSubviews: pages.map(makePage))
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(row)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageControl.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 4),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomConstraint,

            row.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            row.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            row.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            row.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor,
                                       multiplier: CGFloat(pages.count)),
        ])
    }

    // MARK: - Keyboard avoidance

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardFrameChanged),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardHidden),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardFrameChanged(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                as? CGRect else { return }
        let overlap = max(view.bounds.maxY - view.convert(frame, from: nil).minY, 0)
        bottomConstraint.constant = -8 - max(overlap - view.safeAreaInsets.bottom, 0)
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardHidden() {
        bottomConstraint.constant = -8
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    // MARK: - Page building

    private func makePage(_ page: Page) -> UIView {
        let container = UIView()

        let card = UIImageView(image: UIImage(named: page.image))
        card.contentMode = .scaleAspectFit
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.clipsToBounds = true
        card.setContentHuggingPriority(.defaultLow, for: .vertical)

        let title = UILabel()
        title.text = page.title
        title.font = .systemFont(ofSize: 30, weight: .bold)
        title.textAlignment = .center
        title.numberOfLines = 0

        let body = UILabel()
        body.text = page.body
        body.font = .systemFont(ofSize: 17)
        body.textColor = .secondaryLabel
        body.textAlignment = .center
        body.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [card, title, body])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.setCustomSpacing(28, after: card)
        stack.setCustomSpacing(10, after: title)
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        if let buttonTitle = page.buttonTitle {
            let button = UIButton(configuration: {
                var c = UIButton.Configuration.filled()
                c.title = buttonTitle
                c.cornerStyle = .large
                c.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24,
                                                          bottom: 14, trailing: 24)
                return c
            }())
            button.addAction(UIAction { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }

        if page.showsPlayground {
            textView.font = .systemFont(ofSize: 20)
            textView.layer.borderColor = UIColor.separator.cgColor
            textView.layer.borderWidth = 1
            textView.layer.cornerRadius = 14
            textView.autocapitalizationType = .sentences
            textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
            textView.accessibilityIdentifier = "playground"
            textView.heightAnchor.constraint(equalToConstant: 150).isActive = true
            stack.addArrangedSubview(textView)

            let hint = UILabel()
            hint.text = "Try typing above"
            hint.font = .systemFont(ofSize: 14)
            hint.textColor = .tertiaryLabel
            hint.textAlignment = .center
            stack.addArrangedSubview(hint)
            stack.setCustomSpacing(8, after: textView)
        }

        // Wide screenshots may use the full width; text stays comfortably narrow.
        var limits: [NSLayoutConstraint] = []
        for (view, maxWidth) in [(card, 920.0), (title, 620.0), (body, 620.0)] as [(UIView, CGFloat)] {
            let fill = view.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -48)
            fill.priority = .defaultHigh
            limits += [view.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth), fill]
        }
        for extra in stack.arrangedSubviews.dropFirst(3) {
            let fill = extra.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -48)
            fill.priority = .defaultHigh
            limits += [extra.widthAnchor.constraint(lessThanOrEqualToConstant: 620), fill]
        }

        NSLayoutConstraint.activate(limits + [
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -24),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.topAnchor.constraint(greaterThanOrEqualTo: container.safeAreaLayoutGuide.topAnchor,
                                       constant: 24),
            card.heightAnchor.constraint(lessThanOrEqualToConstant: 430),
        ])
        return container
    }

    // MARK: - Paging

    @objc private func pageControlChanged() {
        let x = CGFloat(pageControl.currentPage) * scrollView.bounds.width
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let page = Int((scrollView.contentOffset.x / scrollView.bounds.width).rounded())
        pageControl.currentPage = page
        // Bring the keyboard up once the reader reaches the last page.
        if page == pages.count - 1, !didFocusPlayground {
            didFocusPlayground = true
            textView.becomeFirstResponder()
        }
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        let page = pageControl.currentPage
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.scrollView.setContentOffset(
                CGPoint(x: CGFloat(page) * size.width, y: 0), animated: false)
        })
    }
}
