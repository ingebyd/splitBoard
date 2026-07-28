import UIKit

/// The bar of alternate characters shown while a key is held down, like the
/// stock keyboard. The finger slides over it and the highlighted glyph is
/// inserted on release.
final class AlternatesPopup: UIView {

    let options: [String]
    private(set) var selectedIndex = 0

    private var itemViews: [UILabel] = []
    private let highlight = UIView()
    private let itemSize: CGSize
    private let padding: CGFloat

    init(options: [String], metrics: Theme.Metrics) {
        self.options = options
        self.itemSize = CGSize(width: max(metrics.rowHeight * 0.78, 34),
                               height: max(metrics.rowHeight * 0.82, 36))
        self.padding = 5
        super.init(frame: .zero)

        backgroundColor = Theme.popupBackground
        layer.cornerRadius = min(itemSize.height * 0.32, 12)
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 3)

        highlight.backgroundColor = .systemBlue
        highlight.layer.cornerRadius = min(itemSize.height * 0.26, 9)
        highlight.layer.cornerCurve = .continuous
        addSubview(highlight)

        for option in options {
            let label = UILabel()
            label.text = option
            label.textAlignment = .center
            label.font = .systemFont(ofSize: metrics.fontSize * 0.92)
            label.textColor = Theme.keyLabel
            addSubview(label)
            itemViews.append(label)
        }

        bounds = CGRect(origin: .zero, size: intrinsicContentSize)
        updateSelection(index: 0)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        CGSize(width: itemSize.width * CGFloat(options.count) + padding * 2,
               height: itemSize.height + padding * 2)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for (index, label) in itemViews.enumerated() {
            label.frame = CGRect(x: padding + CGFloat(index) * itemSize.width,
                                 y: padding, width: itemSize.width, height: itemSize.height)
        }
        moveHighlight()
    }

    var selectedText: String {
        options.indices.contains(selectedIndex) ? options[selectedIndex] : (options.first ?? "")
    }

    /// Highlights the item under the finger.
    func updateSelection(atX x: CGFloat) {
        let local = x - padding
        let index = Int(floor(local / itemSize.width))
        updateSelection(index: min(max(index, 0), options.count - 1))
    }

    private func updateSelection(index: Int) {
        guard index != selectedIndex || highlight.frame == .zero else {
            moveHighlight()
            return
        }
        selectedIndex = index
        for (i, label) in itemViews.enumerated() {
            label.textColor = i == index ? .white : Theme.keyLabel
        }
        moveHighlight()
    }

    private func moveHighlight() {
        guard itemViews.indices.contains(selectedIndex) else { return }
        highlight.frame = itemViews[selectedIndex].frame.insetBy(dx: 1, dy: 1)
    }
}
