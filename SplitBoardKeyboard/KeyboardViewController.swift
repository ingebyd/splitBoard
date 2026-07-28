import UIKit

final class KeyboardViewController: UIInputViewController, KeyboardViewDelegate {

    private var keyboardView: KeyboardView!
    private var heightConstraint: NSLayoutConstraint!
    private var lastLayoutWidth: CGFloat = 0

    private var backspaceTimer: Timer?
    private var backspaceRepeats = 0
    private var lastShiftTap: TimeInterval = 0
    /// Characters already inserted by keys that are still held down, so that a
    /// cancelled touch can take them back.
    private var pendingInsertions: [ObjectIdentifier: String] = [:]
    /// Backdrop colour of the system-provided host view, restored when merging.
    private var hostBackdropColor: UIColor?

    private enum Defaults {
        static let split = "SplitBoard.isSplit"
        static let language = "SplitBoard.language"
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let kb = KeyboardView(frame: .zero)
        kb.delegate = self
        kb.isPad = traitCollection.userInterfaceIdiom == .pad
        kb.translatesAutoresizingMaskIntoConstraints = false
        kb.language = KBLanguage(rawValue: UserDefaults.standard.string(forKey: Defaults.language) ?? "en") ?? .en
        kb.isSplit = kb.isPad && UserDefaults.standard.bool(forKey: Defaults.split)
        view.addSubview(kb)
        keyboardView = kb
        kb.onContentHeightChange = { [weak self] in self?.updateHeight() }

        NSLayoutConstraint.activate([
            kb.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            kb.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            kb.topAnchor.constraint(equalTo: view.topAnchor),
            kb.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        heightConstraint = view.heightAnchor.constraint(equalToConstant: 300)
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.isActive = true

        updateBackdrop()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let width = view.bounds.width
        guard width > 0 else { return }
        if abs(width - lastLayoutWidth) > 0.5 {
            lastLayoutWidth = width
            keyboardView.layoutWidth = width
            keyboardView.rebuild()
            updateHeight()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateBackdrop()
        updateAutoShift()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        updateAutoShift()
    }

    /// Merged: let the system keyboard backdrop show through unchanged.
    /// Split: clear it as well, so the gap between the halves is see-through.
    private func updateBackdrop() {
        view.backgroundColor = .clear
        if hostBackdropColor == nil { hostBackdropColor = view.superview?.backgroundColor ?? .clear }
        view.superview?.backgroundColor = keyboardView.isSplit ? .clear : hostBackdropColor
    }

    private func updateHeight() {
        let h = keyboardView.preferredHeight(for: max(view.bounds.width, 1))
        if abs(heightConstraint.constant - h) > 0.5 {
            heightConstraint.constant = h
        }
    }

    // MARK: - Key handling

    func keyboardView(_ view: KeyboardView, didPress key: KeyView, event: UIEvent?) {
        UIDevice.current.playInputClick()

        switch key.spec.action {
        case .input:
            if let text = view.output(for: key, flicked: false) {
                insert(text)
                pendingInsertions[ObjectIdentifier(key)] = text
            }
        case .space:
            insertSpace()
            pendingInsertions[ObjectIdentifier(key)] = " "
        case .ret:
            textDocumentProxy.insertText("\n")
            updateAutoShift()
        case .backspace:
            deleteBackward()
            startBackspaceRepeat()
        case .shift:
            handleShiftTap()
        case .capsLock:
            keyboardView.shiftState = keyboardView.shiftState == .locked ? .off : .locked
        case .tab:
            textDocumentProxy.insertText("\t")
        case .plane(let plane):
            view.plane = plane
            if plane == .letters { updateAutoShift() } else { view.shiftState = .off }
        case .globe, .splitToggle, .dismiss:
            break // handled on release
        }
    }

    func keyboardView(_ view: KeyboardView, didRelease key: KeyView, flicked: Bool) {
        stopBackspaceRepeat()
        pendingInsertions.removeValue(forKey: ObjectIdentifier(key))

        switch key.spec.action {
        case .input:
            if flicked, let secondary = key.spec.secondary {
                textDocumentProxy.deleteBackward()
                textDocumentProxy.insertText(secondary)
            }
        case .globe:
            switchLanguage()
        case .splitToggle:
            toggleSplit()
        case .dismiss:
            dismissKeyboard()
        default:
            break
        }
    }

    func keyboardView(_ view: KeyboardView, didCancel key: KeyView) {
        stopBackspaceRepeat()
        if let text = pendingInsertions.removeValue(forKey: ObjectIdentifier(key)) {
            for _ in 0..<text.count { textDocumentProxy.deleteBackward() }
        }
    }

    func keyboardView(_ view: KeyboardView, didLongPress key: KeyView, event: UIEvent?) {
        switch key.spec.action {
        case .globe:
            // Long press leaves for the next system keyboard; a tap switches
            // between our own languages.
            advanceToNextInputMode()
        default:
            break
        }
    }

    // MARK: - Text input

    private func insert(_ text: String) {
        textDocumentProxy.insertText(text)
        if keyboardView.shiftState == .on {
            keyboardView.shiftState = .off
        }
    }

    private func insertSpace() {
        // Double space inserts a period, like the stock keyboard.
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        if before.count >= 2, before.hasSuffix(" "),
           let prev = before.dropLast().last, prev.isLetter || prev.isNumber {
            textDocumentProxy.deleteBackward()
            textDocumentProxy.insertText(". ")
        } else {
            textDocumentProxy.insertText(" ")
        }
        if keyboardView.shiftState == .on { keyboardView.shiftState = .off }
        updateAutoShift()
    }

    private func deleteBackward() {
        textDocumentProxy.deleteBackward()
        updateAutoShift()
    }

    private func startBackspaceRepeat() {
        backspaceRepeats = 0
        backspaceTimer?.invalidate()
        backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.42, repeats: false) { [weak self] _ in
            self?.beginFastBackspace()
        }
    }

    private func beginFastBackspace() {
        backspaceTimer?.invalidate()
        backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.085, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.backspaceRepeats += 1
            if self.backspaceRepeats > 18 {
                self.deleteWordBackward()
            } else {
                self.textDocumentProxy.deleteBackward()
            }
        }
    }

    private func stopBackspaceRepeat() {
        backspaceTimer?.invalidate()
        backspaceTimer = nil
        backspaceRepeats = 0
        updateAutoShift()
    }

    private func deleteWordBackward() {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        guard !before.isEmpty else { return }
        var deleted = 0
        var sawWord = false
        for ch in before.reversed() {
            if ch == "\n" && deleted > 0 { break }
            if ch.isWhitespace {
                if sawWord { break }
            } else {
                sawWord = true
            }
            deleted += 1
            if deleted > 40 { break }
        }
        for _ in 0..<max(deleted, 1) { textDocumentProxy.deleteBackward() }
    }

    // MARK: - Modifiers

    private func handleShiftTap() {
        let now = Date.timeIntervalSinceReferenceDate
        let isDoubleTap = now - lastShiftTap < 0.35
        lastShiftTap = now

        if isDoubleTap {
            keyboardView.shiftState = .locked
            return
        }
        switch keyboardView.shiftState {
        case .off: keyboardView.shiftState = .on
        case .on, .locked: keyboardView.shiftState = .off
        }
    }

    private func switchLanguage() {
        let next = keyboardView.language.next
        keyboardView.language = next
        UserDefaults.standard.set(next.rawValue, forKey: Defaults.language)
        updateAutoShift()
    }

    private func toggleSplit() {
        setSplit(!keyboardView.isSplit)
    }

    private func setSplit(_ split: Bool) {
        keyboardView.isSplit = split
        updateBackdrop()
        UserDefaults.standard.set(split, forKey: Defaults.split)
        updateHeight()
        UIView.animate(withDuration: 0.18) { self.view.layoutIfNeeded() }
    }

    // MARK: - Auto capitalisation

    private func updateAutoShift() {
        guard keyboardView != nil, keyboardView.plane == .letters else { return }
        guard keyboardView.shiftState != .locked else { return }
        guard textDocumentProxy.autocapitalizationType == .sentences
                || textDocumentProxy.autocapitalizationType == nil else { return }

        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let trimmed = before.trimmingCharacters(in: .whitespaces)
        let shouldShift: Bool
        if before.isEmpty {
            shouldShift = true
        } else if before.hasSuffix(" "), let last = trimmed.last {
            shouldShift = ".!?".contains(last)
        } else if before.hasSuffix("\n") {
            shouldShift = true
        } else {
            shouldShift = false
        }
        keyboardView.shiftState = shouldShift ? .on : .off
    }
}
