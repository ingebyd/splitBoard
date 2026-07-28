import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: KeyboardView, didPress key: KeyView, event: UIEvent?)
    func keyboardView(_ view: KeyboardView, didRelease key: KeyView, flicked: Bool)
    func keyboardView(_ view: KeyboardView, didCancel key: KeyView)
    func keyboardView(_ view: KeyboardView, didLongPress key: KeyView, event: UIEvent?)
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
        panels.forEach { $0.removeFromSuperview() }
        panels.removeAll()

        let rows = Layouts.rows(language: language, plane: plane, split: isSplit)

        if isSplit {
            let metrics = Theme.split(width: effectiveWidth, pad: isPad)
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
            let panel = KeyPanel(rows: Layouts.extendedRows(language: language, plane: plane),
                                 metrics: metrics, delegate: self)
            panel.fillsHeight = true
            panel.backgroundColor = .clear
            addSubview(panel)
            panels.append(panel)
        } else {
            let metrics = Theme.merged(width: effectiveWidth, pad: isPad)
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
                case .capsLock:
                    key.isActivated = shiftState == .locked
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

    // MARK: - KeyViewDelegate

    func keyViewPressed(_ key: KeyView, event: UIEvent?) {
        delegate?.keyboardView(self, didPress: key, event: event)
    }

    func keyViewReleased(_ key: KeyView, flicked: Bool) {
        delegate?.keyboardView(self, didRelease: key, flicked: flicked)
    }

    func keyViewCancelled(_ key: KeyView) {
        delegate?.keyboardView(self, didCancel: key)
    }

    func keyViewLongPressed(_ key: KeyView, event: UIEvent?) {
        delegate?.keyboardView(self, didLongPress: key, event: event)
    }
}
