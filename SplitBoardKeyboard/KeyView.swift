import UIKit

protocol KeyViewDelegate: AnyObject {
    func keyViewPressed(_ key: KeyView, event: UIEvent?)
    func keyViewReleased(_ key: KeyView, flicked: Bool)
    func keyViewCancelled(_ key: KeyView)
    func keyViewLongPressed(_ key: KeyView, event: UIEvent?)
    func keyViewTouchMoved(_ key: KeyView, to pointInKey: CGPoint)
}

/// A single key. Draws itself like a stock iPadOS key: rounded rect, one point
/// of drop shadow, centred glyph, optional small "flick" character in the corner.
final class KeyView: UIView {

    let spec: KeySpec
    weak var delegate: KeyViewDelegate?

    private let titleLabel = UILabel()
    private let secondaryLabel = UILabel()
    private let topLabel = UILabel()       // shifted glyph of a dual key
    private let trailingLabel = UILabel()  // language hint on the space bar
    private let iconView = UIImageView()

    private var metrics: Theme.Metrics
    private var longPressTimer: Timer?
    private var touchStart: CGPoint = .zero
    private(set) var isFlicked = false

    /// Set by the keyboard view: the glyph actually produced by this key right now
    /// (uppercase when shift is engaged).
    var displayText: String = "" {
        didSet { if displayText != oldValue { refreshText() } }
    }

    /// Shift / caps-lock highlight for modifier keys.
    var isActivated = false {
        didSet { if isActivated != oldValue { refreshColors() } }
    }

    var isPressed = false {
        didSet { if isPressed != oldValue { refreshColors() } }
    }

    /// Extra invisible touch area around the key.
    var hitInset: CGFloat = 0

    /// True while the alternate-characters popup is open above this key.
    var isShowingAlternates = false

    init(spec: KeySpec, metrics: Theme.Metrics) {
        self.spec = spec
        self.metrics = metrics
        super.init(frame: .zero)

        isMultipleTouchEnabled = false
        isExclusiveTouch = false
        layer.cornerRadius = metrics.cornerRadius
        layer.cornerCurve = .continuous
        if let corners = spec.corners { layer.maskedCorners = corners }
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 1.5
        layer.shadowOpacity = 1

        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.isUserInteractionEnabled = false
        addSubview(titleLabel)

        secondaryLabel.textAlignment = .center
        secondaryLabel.isUserInteractionEnabled = false
        secondaryLabel.font = .systemFont(ofSize: metrics.secondaryFontSize, weight: .regular)
        addSubview(secondaryLabel)

        topLabel.textAlignment = .center
        topLabel.isUserInteractionEnabled = false
        topLabel.isHidden = spec.labelStyle != .dual
        topLabel.text = spec.secondary
        topLabel.font = .systemFont(ofSize: metrics.fontSize * 0.72, weight: .regular)
        addSubview(topLabel)

        trailingLabel.textAlignment = .right
        trailingLabel.isUserInteractionEnabled = false
        trailingLabel.font = .systemFont(ofSize: max(metrics.secondaryFontSize, 10), weight: .regular)
        trailingLabel.isHidden = true
        addSubview(trailingLabel)

        iconView.contentMode = .center
        iconView.isUserInteractionEnabled = false
        addSubview(iconView)

        configureContent()
        refreshColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: KeyView, _) in
            view.refreshColors()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Content

    private func configureContent() {
        displayText = spec.label

        if let symbol = spec.symbol {
            iconView.isHidden = false
            titleLabel.isHidden = true
            iconView.image = UIImage(systemName: symbol, withConfiguration:
                UIImage.SymbolConfiguration(pointSize: metrics.symbolSize, weight: .light))
        } else {
            iconView.isHidden = true
            titleLabel.isHidden = false
        }

        secondaryLabel.text = spec.secondary
        secondaryLabel.isHidden = spec.labelStyle == .dual
            || spec.secondary == nil || metrics.secondaryFontSize < 6
        refreshText()
    }

    /// Swaps the SF Symbol (shift -> shift.fill -> capslock.fill).
    func updateSymbol(_ name: String) {
        guard spec.symbol != nil else { return }
        iconView.image = UIImage(systemName: name, withConfiguration:
            UIImage.SymbolConfiguration(pointSize: metrics.symbolSize, weight: .light))
    }

    /// Small hint at the right edge of the space bar (current language).
    func setTrailingCaption(_ text: String?) {
        trailingLabel.text = text
        trailingLabel.isHidden = text == nil
        trailingLabel.textColor = Theme.keySecondaryLabel
        setNeedsLayout()
    }

    /// Temporary caption in the middle of a key (used for the space bar).
    func setCaption(_ text: String?) {
        titleLabel.isHidden = false
        titleLabel.text = text
        titleLabel.font = .systemFont(ofSize: metrics.captionFontSize * 0.95, weight: .regular)
        titleLabel.textColor = Theme.keySecondaryLabel
        setNeedsLayout()
    }

    private func refreshText() {
        let isCaption = !spec.isCharacter
        titleLabel.text = displayText
        let size: CGFloat
        switch spec.labelStyle {
        case .dual: size = metrics.fontSize * 0.72
        case .single: size = isCaption ? metrics.captionFontSize : metrics.fontSize
        }
        titleLabel.font = .systemFont(ofSize: size, weight: .regular)
        setNeedsLayout()
    }

    private func refreshColors() {
        let bg: UIColor
        let fg: UIColor
        switch spec.style {
        case .normal:
            bg = isPressed ? Theme.keyNormalPressed : Theme.keyNormal
            fg = Theme.keyLabel
        case .special:
            if isActivated {
                bg = Theme.keyActivated
                fg = Theme.keyLabel
            } else {
                bg = isPressed ? Theme.keySpecialPressed : Theme.keySpecial
                fg = Theme.keyLabel
            }
        }
        backgroundColor = bg
        topLabel.textColor = fg
        titleLabel.textColor = fg
        iconView.tintColor = fg
        secondaryLabel.textColor = Theme.keySecondaryLabel
        layer.shadowColor = Theme.keyShadow.cgColor
    }



    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds,
                                        cornerRadius: metrics.cornerRadius).cgPath

        if spec.labelStyle == .dual {
            let half = bounds.height / 2
            topLabel.frame = CGRect(x: 0, y: bounds.height * 0.10, width: bounds.width, height: half * 0.85)
            titleLabel.frame = CGRect(x: 0, y: bounds.height * 0.50, width: bounds.width, height: half * 0.85)
            iconView.frame = bounds
            return
        }

        let hasSecondary = !secondaryLabel.isHidden
        let contentDrop: CGFloat = hasSecondary ? metrics.secondaryFontSize * 0.35 : 0
        if spec.leftAligned {
            let inset = min(bounds.width * 0.16, metrics.fontSize * 0.75)
            titleLabel.textAlignment = .left
            titleLabel.frame = CGRect(x: inset, y: contentDrop,
                                      width: bounds.width - inset - 2,
                                      height: bounds.height - contentDrop)
            iconView.frame = CGRect(x: inset - metrics.symbolSize * 0.1, y: 0,
                                    width: metrics.symbolSize * 1.4, height: bounds.height)
        } else {
            titleLabel.textAlignment = .center
            titleLabel.frame = CGRect(x: 2, y: contentDrop,
                                      width: bounds.width - 4, height: bounds.height - contentDrop)
            iconView.frame = bounds
        }

        if !trailingLabel.isHidden {
            let w = bounds.width * 0.4
            trailingLabel.frame = CGRect(x: bounds.width - w - metrics.fontSize * 0.5,
                                         y: 0, width: w, height: bounds.height)
        }

        if hasSecondary {
            let w = metrics.secondaryFontSize * 1.6
            secondaryLabel.frame = CGRect(x: bounds.width - w - metrics.secondaryFontSize * 0.28,
                                          y: metrics.secondaryFontSize * 0.18,
                                          width: w, height: metrics.secondaryFontSize * 1.25)
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: -hitInset, dy: -hitInset).contains(point)
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchStart = touch.location(in: self)
        isFlicked = false
        isPressed = true
        delegate?.keyViewPressed(self, event: event)
        startLongPressTimer(event: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if isShowingAlternates {
            delegate?.keyViewTouchMoved(self, to: touch.location(in: self))
            return
        }
        guard spec.secondary != nil else { return }
        let dy = touch.location(in: self).y - touchStart.y
        let dx = abs(touch.location(in: self).x - touchStart.x)
        if abs(dy) > 4 || dx > 4 { cancelLongPressTimer() }
        let shouldFlick = dy > bounds.height * 0.42 && dy > dx
        if shouldFlick != isFlicked {
            isFlicked = shouldFlick
            cancelLongPressTimer()
            UIView.transition(with: self, duration: 0.08, options: .transitionCrossDissolve) {
                self.titleLabel.text = shouldFlick ? self.spec.secondary : self.displayText
                self.secondaryLabel.alpha = shouldFlick ? 0 : 1
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelLongPressTimer()
        isPressed = false
        let flicked = isFlicked
        if flicked { resetFlickAppearance() }
        delegate?.keyViewReleased(self, flicked: flicked)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelLongPressTimer()
        isPressed = false
        if isFlicked { resetFlickAppearance() }
        delegate?.keyViewCancelled(self)
    }

    private func resetFlickAppearance() {
        isFlicked = false
        titleLabel.text = displayText
        secondaryLabel.alpha = 1
    }

    private func startLongPressTimer(event: UIEvent?) {
        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.delegate?.keyViewLongPressed(self, event: event)
        }
    }

    private func cancelLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }
}
