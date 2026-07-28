import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: KeyboardView, didPress key: KeyView, event: UIEvent?)
    func keyboardView(_ view: KeyboardView, didRelease key: KeyView, flicked: Bool)
    func keyboardView(_ view: KeyboardView, didCancel key: KeyView)
    func keyboardView(_ view: KeyboardView, didLongPress key: KeyView, event: UIEvent?)
    /// A character was picked from the long-press popup; it replaces whatever
    /// the key already inserted on touch-down.
    func keyboardView(_ view: KeyboardView, didSelectAlternate text: String, for key: KeyView)
}

/// Lays out the whole keyboard: one panel when merged, two edge-anchored panels
/// when split.
final class KeyboardView: UIView, KeyViewDelegate {

    weak var delegate: KeyboardViewDelegate?

    var language: KBLanguage = .en { didSet { if language != oldValue { rebuild() } } }
    var plane: KeyPlane = .letters { didSet { if plane != oldValue { rebuild() } } }
    var isSplit = false { didSet { if isSplit != oldValue { rebuild() } } }
    var shiftState: ShiftState = .off { didSet { applyShift() } }
    var isPad = true

    /// Width to size the keys against. The controller sets this before the first
    /// layout pass, when our own bounds are still empty.
    var layoutWidth: CGFloat = 0

    /// Height the input view should request, derived from the built panels.
    private(set) var contentHeight: CGFloat = 300
    /// Called when a rebuild changes the height we want.
    var onContentHeightChange: (() -> Void)?

    private var panels: [KeyPanel] = []
    private var currentMetrics = Theme.merged(width: 1032, pad: true)
    private var activePopup: AlternatesPopup?
    private weak var popupKey: KeyView?
    private var leftRowUnits: CGFloat = 1
    private var rightRowUnits: CGFloat = 1

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Building

    private var effectiveWidth: CGFloat { max(layoutWidth, bounds.width, 1) }

    func rebuild() {
        dismissAlternates()
        panels.forEach { $0.removeFromSuperview() }
        panels.removeAll()

        let rows = Layouts.rows(language: language, plane: plane, split: isSplit)

        if isSplit {
            let metrics = Theme.split(width: effectiveWidth, pad: isPad)
            currentMetrics = metrics
            var left: [[KeySpec]] = []
            var right: [[KeySpec]] = []
            for row in rows {
                let cut = min(max(row.splitLeftCount, 0), row.keys.count)
                left.append(Array(row.keys[0..<cut]))
                right.append(Array(row.keys[cut...]))
            }
            left.append(Layouts.bottomRowSplitLeft(plane: plane))
            right.append(Layouts.bottomRowSplitRight(plane: plane))

            leftRowUnits = maxUnits(left)
            rightRowUnits = maxUnits(right)

            for spec in [left, right] {
                let panel = KeyPanel(keyRows: spec, metrics: metrics, delegate: self)
                panel.backgroundColor = Theme.backdrop
                panel.layer.cornerRadius = 10
                panel.layer.cornerCurve = .continuous
                addSubview(panel)
                panels.append(panel)
            }
        } else if usesExtendedLayout {
            let metrics = Theme.extended(width: effectiveWidth)
            currentMetrics = metrics
            let panel = KeyPanel(rows: Layouts.extendedRows(language: language, plane: plane),
                                 metrics: metrics, delegate: self)
            panel.fillsHeight = true
            panel.backgroundColor = .clear
            addSubview(panel)
            panels.append(panel)
        } else {
            let metrics = Theme.merged(width: effectiveWidth, pad: isPad)
            currentMetrics = metrics
            var specs = rows.map { $0.keys }
            specs.append(Layouts.bottomRowMerged(language: language, plane: plane,
                                                 splitAvailable: isPad))
            let panel = KeyPanel(keyRows: specs, metrics: metrics, delegate: self)
            panel.fillsHeight = true
            panel.backgroundColor = Theme.usesSystemBackdrop ? .clear : Theme.backdrop
            addSubview(panel)
            panels.append(panel)
        }

        applyLanguageHint()
        let newHeight = panels.map(\.intrinsicHeight).max() ?? 300
        let changed = abs(newHeight - contentHeight) > 0.5
        contentHeight = newHeight
        applyShift()
        setNeedsLayout()
        if changed { onContentHeightChange?() }
    }

    private func maxUnits(_ rows: [[KeySpec]]) -> CGFloat {
        rows.map { $0.reduce(0) { $0 + $1.width } }.max() ?? 1
    }

    // MARK: - Layout

    /// Large iPads get the hardware-style keyboard, exactly like the stock one.
    var usesExtendedLayout: Bool { isPad && !isSplit && effectiveWidth >= 800 }

    func preferredHeight(for width: CGFloat) -> CGFloat { contentHeight }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, !panels.isEmpty else { return }

        if isSplit, panels.count == 2 {
            let height = panels[0].intrinsicHeight
            let gap = bounds.width * Theme.splitCenterGapRatio
            let margin = Theme.splitOuterMargin
            let available = max(bounds.width - margin * 2 - gap, 100)
            let leftW = available * leftRowUnits / (leftRowUnits + rightRowUnits)
            let rightW = available - leftW
            let y = max(bounds.height - height, 0)
            panels[0].frame = CGRect(x: margin, y: y, width: leftW, height: height)
            panels[1].frame = CGRect(x: bounds.width - margin - rightW, y: y,
                                     width: rightW, height: height)
        } else {
            panels[0].frame = bounds
        }
    }

    // MARK: - Shift

    func applyShift() {
        let upper = shiftState.isUppercase
        for panel in panels {
            for key in panel.keyViews {
                switch key.spec.action {
                case .input(let s):
                    if key.spec.labelStyle != .dual {
                        key.displayText = upper ? s.uppercased() : s
                    }
                case .shift:
                    key.isActivated = shiftState != .off
                    key.updateSymbol(shiftState == .locked ? "capslock.fill"
                                     : (shiftState == .on ? "shift.fill" : (key.spec.symbol ?? "shift")))

                default:
                    break
                }
            }
        }
    }

    /// Text produced by a key right now (respects shift and flick state).
    func output(for key: KeyView, flicked: Bool) -> String? {
        if flicked, let secondary = key.spec.secondary { return secondary }
        if key.spec.labelStyle == .dual, shiftState.isUppercase,
           let shifted = key.spec.secondary { return shifted }
        if case .input(let s) = key.spec.action {
            return shiftState.isUppercase ? s.uppercased() : s
        }
        return nil
    }

    /// The stock keyboard prints the active language at the right end of the
    /// space bar; ours shows which of the two languages is live.
    private func applyLanguageHint() {
        let hint = language == .ru ? "ру" : "eng"
        forEachSpaceKey { $0.setTrailingCaption(hint) }
    }

    private func forEachSpaceKey(_ body: (KeyView) -> Void) {
        for panel in panels {
            for key in panel.keyViews where key.spec.action == .space { body(key) }
        }
    }

    // MARK: - Alternate characters popup

    private func showAlternates(for key: KeyView) -> Bool {
        guard case .input(let base) = key.spec.action else { return false }
        let text = key.displayText.isEmpty ? base : key.displayText
        let options = [text] + Alternates.list(for: text, language: language)
        guard options.count > 1, let panel = key.superview else { return false }

        let popup = AlternatesPopup(options: options, metrics: currentMetrics)
        let keyFrame = panel.convert(key.frame, to: self)
        let size = popup.intrinsicContentSize
        var x = keyFrame.midX - size.width / 2
        x = min(max(x, 4), max(bounds.width - size.width - 4, 4))
        var y = keyFrame.minY - size.height - 6
        if y < 2 { y = keyFrame.maxY + 6 }
        popup.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
        popup.alpha = 0
        addSubview(popup)
        UIView.animate(withDuration: 0.08) { popup.alpha = 1 }

        activePopup = popup
        popupKey = key
        key.isShowingAlternates = true
        return true
    }

    private func dismissAlternates() {
        popupKey?.isShowingAlternates = false
        activePopup?.removeFromSuperview()
        activePopup = nil
        popupKey = nil
    }

    // MARK: - KeyViewDelegate

    func keyViewPressed(_ key: KeyView, event: UIEvent?) {
        dismissAlternates()
        delegate?.keyboardView(self, didPress: key, event: event)
    }

    func keyViewReleased(_ key: KeyView, flicked: Bool) {
        if let popup = activePopup, popupKey === key {
            let text = popup.selectedText
            dismissAlternates()
            delegate?.keyboardView(self, didSelectAlternate: text, for: key)
            return
        }
        delegate?.keyboardView(self, didRelease: key, flicked: flicked)
    }

    func keyViewCancelled(_ key: KeyView) {
        if popupKey === key { dismissAlternates() }
        delegate?.keyboardView(self, didCancel: key)
    }

    func keyViewLongPressed(_ key: KeyView, event: UIEvent?) {
        if showAlternates(for: key) { return }
        delegate?.keyboardView(self, didLongPress: key, event: event)
    }

    func keyViewTouchMoved(_ key: KeyView, to pointInKey: CGPoint) {
        guard let popup = activePopup, popupKey === key else { return }
        let inSelf = key.convert(pointInKey, to: self)
        popup.updateSelection(atX: inSelf.x - popup.frame.minX)
    }
}
