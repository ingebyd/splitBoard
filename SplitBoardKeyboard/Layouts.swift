import UIKit

/// Builds the key rows for every language / plane / split combination.
///
/// Two families of layouts:
///   * compact  - the classic three-letter-row iPad keyboard, also used for
///                each half of the split keyboard;
///   * extended - the hardware-style layout iPadOS shows on large iPads
///                (number row, tab, caps lock, ISO return).
///
/// The split rule mirrors the stock keyboard (see UIKBSplitRowHints.plist in
/// TextInputUI.framework): each row is cut at a fixed index and the space bar
/// exists in both halves.
enum Layouts {

    // MARK: - Alphabets

    private static let enRows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
    private static let ruRows = ["йцукенгшщзхъ", "фывапролджэ", "ячсмитьбю"]

    /// Character shown in the corner of a key and inserted on a downward flick.
    private static let secondary: [Character: String] = [
        "q": "1", "w": "2", "e": "3", "r": "4", "t": "5",
        "y": "6", "u": "7", "i": "8", "o": "9", "p": "0",
        "a": "@", "s": "#", "d": "$", "f": "&", "g": "*",
        "h": "(", "j": ")", "k": "'", "l": "\"",
        "z": "%", "x": "-", "c": "+", "v": "=", "b": "/",
        "n": ";", "m": ":",
        "й": "1", "ц": "2", "у": "3", "к": "4", "е": "5", "н": "6",
        "г": "7", "ш": "8", "щ": "9", "з": "0", "х": "-", "ъ": "+",
        "ф": "@", "ы": "#", "в": "₽", "а": "&", "п": "*", "р": "(",
        "о": ")", "л": "'", "д": "\"", "ж": ":", "э": ";",
        "я": "%", "ч": "!", "с": "?", "м": "=", "и": "/", "т": "№",
        "ь": "«", "б": "»", "ю": "…",
        ",": "!", ".": "?",
    ]

    // MARK: - Compact layout (also used by both halves when split)

    static func rows(language: KBLanguage, plane: KeyPlane, split: Bool) -> [KeyRow] {
        switch plane {
        case .letters: return letterRows(language)
        case .numbers: return numberRows()
        case .symbols: return symbolRows()
        }
    }

    static func bottomRowMerged(language: KBLanguage, plane: KeyPlane, splitAvailable: Bool) -> [KeySpec] {
        let planeKey = planeSwitchKey(for: plane, width: 1.3)
        var keys: [KeySpec] = [
            planeKey,
            KeySpec(action: .globe, symbol: "globe", width: 1.3, style: .special),
            KeySpec(action: .space, label: "", width: 5.4, style: .normal),
        ]
        if splitAvailable {
            keys.append(KeySpec(action: .splitToggle, symbol: "rectangle.split.2x1",
                                width: 1.3, style: .special))
        }
        keys.append(planeKey)
        keys.append(KeySpec(action: .dismiss, symbol: "keyboard.chevron.compact.down",
                            width: 1.3, style: .special))
        return keys
    }

    static func bottomRowSplitLeft(plane: KeyPlane) -> [KeySpec] {
        [
            planeSwitchKey(for: plane, width: 1.25),
            KeySpec(action: .globe, symbol: "globe", width: 1.1, style: .special),
            KeySpec(action: .space, label: "", width: 2.65, style: .normal),
        ]
    }

    static func bottomRowSplitRight(plane: KeyPlane) -> [KeySpec] {
        [
            KeySpec(action: .space, label: "", width: 2.4, style: .normal),
            KeySpec(action: .splitToggle, symbol: "rectangle", width: 1.2, style: .special),
            planeSwitchKey(for: plane, width: 1.2),
            KeySpec(action: .dismiss, symbol: "keyboard.chevron.compact.down",
                    width: 1.2, style: .special),
        ]
    }

    // MARK: - Extended layout (large iPads, merged)

    /// Total width of every extended row, in key units.
    private static let extendedUnits: CGFloat = 14.5

    static func extendedRows(language: KBLanguage, plane: KeyPlane) -> [PanelRow] {
        var rows: [PanelRow] = [PanelRow(keys: numberRowExtended(language), heightFactor: 0.86)]

        switch plane {
        case .letters:
            let letters = language == .en ? enRows : ruRows
            rows.append(PanelRow(keys: lettersRow1(language, letters)))
            rows.append(PanelRow(keys: lettersRow2(language, letters)))
            rows.append(PanelRow(keys: lettersRow3(language, letters)))
        case .numbers:
            rows.append(PanelRow(keys: extendedSymbolRow(
                ["€", "£", "¥", "₽", "§", "¶", "°", "±", "×", "÷", "≠", "≈"], topOf: 1)))
            rows.append(PanelRow(keys: extendedSymbolRow(
                ["(", ")", "[", "]", "{", "}", "<", ">", "«", "»", "„", "“"], topOf: 2)))
            rows.append(PanelRow(keys: extendedSymbolRow(
                ["—", "–", "•", "…", "‰", "†", "©", "®", "™", "№"], topOf: 3)))
        case .symbols:
            rows.append(PanelRow(keys: extendedSymbolRow(
                ["¡", "¿", "‹", "›", "‚", "‘", "’", "“", "”", "„", "″", "′"], topOf: 1)))
            rows.append(PanelRow(keys: extendedSymbolRow(
                ["α", "β", "π", "μ", "Ω", "∞", "√", "∫", "∑", "∆", "≤", "≥"], topOf: 2)))
            rows.append(PanelRow(keys: extendedSymbolRow(
                ["←", "→", "↑", "↓", "⇅", "☑", "✓", "✕", "★", "☆"], topOf: 3)))
        }

        rows.append(PanelRow(keys: bottomRowExtended(plane: plane)))
        return rows
    }

    private static func numberRowExtended(_ language: KBLanguage) -> [KeySpec] {
        let pairs: [(String, String)]
        if language == .en {
            pairs = [("`", "~"), ("1", "!"), ("2", "@"), ("3", "#"), ("4", "$"), ("5", "%"),
                     ("6", "^"), ("7", "&"), ("8", "*"), ("9", "("), ("0", ")"),
                     ("-", "_"), ("=", "+")]
        } else {
            pairs = [(">", "<"), ("1", "!"), ("2", "\""), ("3", "№"), ("4", "%"), ("5", ":"),
                     ("6", ","), ("7", "."), ("8", ";"), ("9", "("), ("0", ")"),
                     ("-", "_"), ("=", "+")]
        }
        var keys = pairs.map { dualKey(base: $0.0, shifted: $0.1) }
        keys.append(KeySpec(action: .backspace, symbol: "delete.left", width: 1.5, style: .special))
        return keys
    }

    private static func lettersRow1(_ language: KBLanguage, _ letters: [String]) -> [KeySpec] {
        var keys: [KeySpec] = [KeySpec(action: .tab, symbol: "arrow.right.to.line",
                                       width: 1.5, style: .special, leftAligned: true)]
        keys += Array(letters[0]).map { characterKey($0, flickHints: false) }
        if language == .en {
            keys.append(dualKey(base: "[", shifted: "{"))
            keys.append(dualKey(base: "]", shifted: "}"))
        }
        keys.append(returnTop())
        return keys
    }

    private static func lettersRow2(_ language: KBLanguage, _ letters: [String]) -> [KeySpec] {
        var keys: [KeySpec] = [KeySpec(action: .capsLock, label: "abc", width: 1.5,
                                       style: .special, leftAligned: true)]
        keys += Array(letters[1]).map { characterKey($0, flickHints: false) }
        if language == .en {
            keys.append(dualKey(base: ";", shifted: ":"))
            keys.append(dualKey(base: "'", shifted: "\""))
            keys.append(dualKey(base: "\\", shifted: "|"))
        } else {
            keys.append(characterKey("ё", flickHints: false))
        }
        keys.append(returnBottom(language))
        return keys
    }

    private static func lettersRow3(_ language: KBLanguage, _ letters: [String]) -> [KeySpec] {
        var keys: [KeySpec] = [KeySpec(action: .shift, symbol: "shift.fill",
                                       width: 1.75, style: .special, leftAligned: true)]
        if language == .en {
            keys.append(dualKey(base: "`", shifted: "~"))
        } else {
            keys.append(dualKey(base: "]", shifted: "["))
        }
        keys += Array(letters[2]).map { characterKey($0, flickHints: false) }
        if language == .en {
            keys.append(dualKey(base: ",", shifted: "<"))
            keys.append(dualKey(base: ".", shifted: ">"))
            keys.append(dualKey(base: "/", shifted: "?"))
        } else {
            keys.append(dualKey(base: "/", shifted: "?"))
        }
        keys.append(KeySpec(action: .shift, symbol: "shift.fill", width: 1.75, style: .special))
        return keys
    }

    private static func extendedSymbolRow(_ items: [String], topOf row: Int) -> [KeySpec] {
        var keys: [KeySpec] = []
        switch row {
        case 1:
            keys.append(KeySpec(action: .tab, symbol: "arrow.right.to.line", width: 1.5,
                                style: .special, leftAligned: true))
        case 2:
            keys.append(KeySpec(action: .plane(.letters), label: "abc", width: 1.5,
                                style: .special, leftAligned: true))
        default:
            keys.append(KeySpec(action: .plane(.symbols), label: "#+=", width: 1.75,
                                style: .special, leftAligned: true))
        }
        keys += items.map { KeySpec(action: .input($0), label: $0) }
        switch row {
        case 1: keys.append(returnTop())
        case 2: keys.append(returnBottom(.en))
        default: keys.append(KeySpec(action: .plane(.symbols), label: "#+=", width: 1.75, style: .special))
        }
        // Pad the row so that every extended row spans the same width.
        let used = keys.reduce(0) { $0 + $1.width }
        if used < extendedUnits, let last = keys.indices.last {
            keys[last].width += extendedUnits - used
        }
        return keys
    }

    private static func bottomRowExtended(plane: KeyPlane) -> [KeySpec] {
        let planeKey = planeSwitchKey(for: plane, width: 1.75)
        return [
            KeySpec(action: .globe, symbol: "globe", width: 1.25, style: .special, leftAligned: true),
            planeKey,
            KeySpec(action: .splitToggle, symbol: "rectangle.split.2x1", width: 1.25, style: .special),
            KeySpec(action: .space, label: "", width: 6.5, style: .normal),
            planeKey,
            KeySpec(action: .dismiss, symbol: "keyboard.chevron.compact.down", width: 2.0, style: .special),
        ]
    }

    private static func returnTop() -> KeySpec {
        KeySpec(action: .ret, label: "", width: 1.0, style: .special,
                corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
                extendsIntoRowGap: true)
    }

    private static func returnBottom(_ language: KBLanguage) -> KeySpec {
        KeySpec(action: .ret, symbol: "return.left", width: 1.0, style: .special,
                corners: [.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
    }

    private static func dualKey(base: String, shifted: String) -> KeySpec {
        KeySpec(action: .input(base), label: base, secondary: shifted,
                labelStyle: .dual)
    }

    // MARK: - Compact planes

    private static func planeSwitchKey(for plane: KeyPlane, width: CGFloat) -> KeySpec {
        switch plane {
        case .letters:
            return KeySpec(action: .plane(.numbers), label: ".?123", width: width, style: .special)
        case .numbers, .symbols:
            return KeySpec(action: .plane(.letters), label: "abc", width: width, style: .special)
        }
    }

    private static func letterRows(_ language: KBLanguage) -> [KeyRow] {
        let source = language == .en ? enRows : ruRows
        let letters = source.map { Array($0).map { characterKey($0) } }

        var row0 = letters[0]
        row0.append(KeySpec(action: .backspace, symbol: "delete.left", width: 1.5, style: .special))

        var row1 = letters[1]
        row1.append(KeySpec(action: .ret, label: language.returnTitle,
                            width: returnWidth(total: letters[0].count, used: letters[1].count),
                            style: .special))

        var row2: [KeySpec] = [shiftKey(width: 1.3)]
        row2 += letters[2]
        row2.append(characterKey(","))
        row2.append(characterKey("."))
        row2.append(shiftKey(width: 1.3))

        return [
            KeyRow(keys: row0, splitLeftCount: (letters[0].count + 1) / 2),
            KeyRow(keys: row1, splitLeftCount: (letters[1].count + 1) / 2),
            KeyRow(keys: row2, splitLeftCount: 1 + (letters[2].count + 1) / 2),
        ]
    }

    private static func numberRows() -> [KeyRow] {
        let r0 = chars("1234567890") + [KeySpec(action: .backspace, symbol: "delete.left",
                                                width: 1.5, style: .special)]
        let r1 = chars(["@", "#", "$", "&", "*", "(", ")", "'", "\""])
            + [KeySpec(action: .ret, label: "return", width: 2.5, style: .special)]
        var r2: [KeySpec] = [KeySpec(action: .plane(.symbols), label: "#+=", width: 1.3, style: .special)]
        r2 += chars(["%", "-", "+", "=", "/", ";", ":", ",", "."])
        r2.append(KeySpec(action: .plane(.symbols), label: "#+=", width: 1.3, style: .special))
        return [
            KeyRow(keys: r0, splitLeftCount: 5),
            KeyRow(keys: r1, splitLeftCount: 5),
            KeyRow(keys: r2, splitLeftCount: 5),
        ]
    }

    private static func symbolRows() -> [KeyRow] {
        let r0 = chars(["[", "]", "{", "}", "#", "%", "^", "*", "+", "="])
            + [KeySpec(action: .backspace, symbol: "delete.left", width: 1.5, style: .special)]
        let r1 = chars(["_", "\\", "|", "~", "<", ">", "€", "£", "¥"])
            + [KeySpec(action: .ret, label: "return", width: 2.5, style: .special)]
        var r2: [KeySpec] = [KeySpec(action: .plane(.numbers), label: "123", width: 1.3, style: .special)]
        r2 += chars(["°", "±", "§", "«", "»", "—", "–", "…", "•"])
        r2.append(KeySpec(action: .plane(.numbers), label: "123", width: 1.3, style: .special))
        return [
            KeyRow(keys: r0, splitLeftCount: 5),
            KeyRow(keys: r1, splitLeftCount: 5),
            KeyRow(keys: r2, splitLeftCount: 5),
        ]
    }

    // MARK: - Helpers

    private static func returnWidth(total: Int, used: Int) -> CGFloat {
        max(CGFloat(total) + 1.5 - CGFloat(used), 1.8)
    }

    private static func shiftKey(width: CGFloat) -> KeySpec {
        KeySpec(action: .shift, symbol: "shift", width: width, style: .special)
    }

    private static func characterKey(_ c: Character, flickHints: Bool = true) -> KeySpec {
        KeySpec(action: .input(String(c)), label: String(c),
                secondary: flickHints ? secondary[c] : nil)
    }

    private static func chars(_ s: String) -> [KeySpec] {
        Array(s).map { characterKey($0) }
    }

    private static func chars(_ list: [String]) -> [KeySpec] {
        list.map { KeySpec(action: .input($0), label: $0) }
    }
}
