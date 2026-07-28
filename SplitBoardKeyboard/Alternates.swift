import Foundation

/// Characters offered in the long-press popup, mirroring the stock keyboard.
enum Alternates {

    static func list(for text: String, language: KBLanguage) -> [String] {
        let key = text.lowercased()
        let uppercase = text != key && text.count == 1
        guard let base = table[key] else { return [] }
        return uppercase ? base.map { $0.uppercased() } : base
    }

    private static let table: [String: [String]] = [
        // English letters
        "a": ["à", "á", "â", "ä", "æ", "ã", "å", "ā"],
        "c": ["ç", "ć", "č"],
        "e": ["è", "é", "ê", "ë", "ē", "ė", "ę"],
        "i": ["î", "ï", "í", "ī", "į", "ì"],
        "l": ["ł"],
        "n": ["ñ", "ń"],
        "o": ["ô", "ö", "ò", "ó", "œ", "ø", "ō", "õ"],
        "s": ["ß", "ś", "š"],
        "u": ["û", "ü", "ù", "ú", "ū"],
        "y": ["ÿ"],
        "z": ["ž", "ź", "ż"],
        // Russian letters
        "е": ["ё"],
        "ь": ["ъ"],
        "и": ["й"],
        "ц": ["ц̈"],
        "ч": ["ҷ"],
        // Punctuation and symbols
        "-": ["–", "—", "•"],
        "/": ["\\"],
        "$": ["₽", "¢", "£", "€", "¥", "₩"],
        "&": ["§"],
        "\"": ["»", "«", "„", "“", "”"],
        "'": ["’", "‘", "‚", "‹", "›"],
        "?": ["¿"],
        "!": ["¡"],
        "%": ["‰"],
        "=": ["≠", "≈"],
        "(": ["[", "{", "<"],
        ")": ["]", "}", ">"],
        ".": ["…"],
        ",": ["„"],
        "0": ["°"],
        "€": ["₽", "¢", "£", "¥", "₩", "$"],
        "₽": ["$", "€", "£", "¥"],
    ]
}
