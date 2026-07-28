import UIKit

enum KeyPlane: Int {
    case letters, numbers, symbols
}

enum KBLanguage: String, CaseIterable {
    case en, ru

    var next: KBLanguage { self == .en ? .ru : .en }

    /// Shown briefly on the space bar after switching.
    var displayName: String { self == .en ? "English" : "Русский" }

    var returnTitle: String { self == .en ? "return" : "ввод" }
}

enum KeyAction: Equatable {
    case input(String)
    case backspace
    case shift
    case capsLock
    case tab
    case space
    case ret
    case plane(KeyPlane)
    case globe
    case splitToggle
    case dismiss
}

extension KeyPlane: Equatable {}

enum KeyStyle {
    case normal   // white key
    case special  // modifier key
}

/// How the glyphs are arranged on the key face.
enum KeyLabelStyle {
    /// One centred glyph, optional small flick hint in the top-right corner.
    case single
    /// Two stacked glyphs: shifted on top, base below (iPad hardware-style rows).
    case dual
}

struct KeySpec {
    var action: KeyAction
    var label: String = ""
    /// Inserted on a downward flick (compact layout) or by shift (dual keys).
    var secondary: String? = nil
    var symbol: String? = nil
    var width: CGFloat = 1
    var style: KeyStyle = .normal
    var labelStyle: KeyLabelStyle = .single
    /// Rounded corners; nil means all four.
    var corners: CACornerMask? = nil
    /// Grows downwards into the row gap (top half of the ISO return key).
    var extendsIntoRowGap: Bool = false
    /// Glyph is left aligned instead of centred (wide modifier keys on iPad).
    var leftAligned: Bool = false

    var isCharacter: Bool {
        if case .input = action { return true }
        return false
    }
}

/// A row inside a panel.
struct PanelRow {
    var keys: [KeySpec]
    /// Multiplier on the panel's base row height.
    var heightFactor: CGFloat = 1
}

struct KeyRow {
    var keys: [KeySpec]
    /// How many of the keys belong to the left half when the keyboard is split.
    var splitLeftCount: Int
}

enum ShiftState {
    case off, on, locked

    var isUppercase: Bool { self != .off }
}
