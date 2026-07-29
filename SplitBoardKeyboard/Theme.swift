import UIKit

/// Colors and metrics tuned to match the stock iPadOS keyboard.
enum Theme {

    /// When true the merged keyboard leaves its background transparent so the
    /// system input-view material shows through (exactly the stock look).
    static let usesSystemBackdrop = true

    // MARK: - Colors

    private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }

    /// Backdrop behind the keys (matches the stock iPadOS 26 keyboard).
    static let backdrop = dynamic(
        light: UIColor(red: 0.886, green: 0.894, blue: 0.910, alpha: 1),   // #E2E4E8
        dark:  UIColor(red: 0.090, green: 0.090, blue: 0.090, alpha: 1))   // #171717

    /// Regular character key. iPadOS 26 uses the same colour for modifier keys.
    static let keyNormal = dynamic(
        light: .white,
        dark:  UIColor(red: 0.239, green: 0.239, blue: 0.239, alpha: 1))   // #3D3D3D

    static let keyNormalPressed = dynamic(
        light: UIColor(red: 0.839, green: 0.847, blue: 0.867, alpha: 1),
        dark:  UIColor(red: 0.365, green: 0.365, blue: 0.365, alpha: 1))

    /// Modifier keys: shift, delete, plane switch, globe, dismiss. A touch
    /// darker than the letters, unlike iPadOS 26 where every key is one colour.
    static let keySpecial = dynamic(
        light: UIColor(red: 0.933, green: 0.937, blue: 0.949, alpha: 1),   // #EEEFF2
        dark:  UIColor(red: 0.196, green: 0.196, blue: 0.200, alpha: 1))   // #323233

    static let keySpecialPressed = dynamic(
        light: UIColor(red: 0.851, green: 0.859, blue: 0.878, alpha: 1),
        dark:  UIColor(red: 0.310, green: 0.310, blue: 0.318, alpha: 1))

    /// Shift / caps-lock engaged: the glyph does the talking, the key keeps its
    /// modifier colour.
    static let keyActivated = keySpecial

    static let keyLabel = dynamic(light: .black, dark: .white)

    /// Long-press popup with alternate characters.
    static let popupBackground = dynamic(
        light: .white,
        dark:  UIColor(red: 0.361, green: 0.361, blue: 0.373, alpha: 1))

    static let keySecondaryLabel = dynamic(
        light: UIColor(red: 0.443, green: 0.455, blue: 0.486, alpha: 1),
        dark:  UIColor(white: 1.0, alpha: 0.55))

    static let keyShadow = dynamic(
        light: UIColor(white: 0.0, alpha: 0.10),
        dark:  UIColor(white: 0.0, alpha: 0.35))

    // MARK: - Type

    /// Keycap typeface: the system font in its rounded design. Same metrics and
    /// legibility as the stock keyboard, visibly not the same face.
    static func keycapFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }

    // MARK: - Metrics

    struct Metrics {
        var rowHeight: CGFloat
        var rowGap: CGFloat
        var keyGap: CGFloat
        var topInset: CGFloat
        var bottomInset: CGFloat
        var sideInset: CGFloat
        var cornerRadius: CGFloat
        var fontSize: CGFloat
        var secondaryFontSize: CGFloat
        var symbolSize: CGFloat
        var captionFontSize: CGFloat

        var totalHeight: CGFloat {
            topInset + bottomInset + rowHeight * 4 + rowGap * 3
        }
    }

    /// Metrics for the merged (full width) keyboard.
    static func merged(width: CGFloat, pad: Bool) -> Metrics {
        if !pad {
            let unit = min(max(width / 11.0, 26), 44)
            return Metrics(rowHeight: unit * 1.05, rowGap: 11, keyGap: 6, topInset: 8,
                           bottomInset: 4, sideInset: 3, cornerRadius: 5,
                           fontSize: 24, secondaryFontSize: 0, symbolSize: 19,
                           captionFontSize: 15)
        }
        // iPad: key unit derived from the screen width, clamped for the huge 13" panel.
        let scale = min(max(width / 1032.0, 0.55), 1.35)
        return Metrics(rowHeight: 62 * scale,
                       rowGap: 12 * scale,
                       keyGap: 11 * scale,
                       topInset: 10 * scale,
                       bottomInset: 8 * scale,
                       sideInset: 6 * scale,
                       cornerRadius: 8 * scale,
                       fontSize: 26 * scale,
                       secondaryFontSize: 13 * scale,
                       symbolSize: 22 * scale,
                       captionFontSize: 18 * scale)
    }

    /// Metrics for the hardware-style layout used on large iPads.
    static func extended(width: CGFloat) -> Metrics {
        let scale = min(max(width / 1032.0, 0.7), 1.3)
        return Metrics(rowHeight: 57 * scale,
                       rowGap: 8 * scale,
                       keyGap: 8 * scale,
                       topInset: 9 * scale,
                       bottomInset: 9 * scale,
                       sideInset: 8 * scale,
                       cornerRadius: 8 * scale,
                       fontSize: 25 * scale,
                       secondaryFontSize: 12 * scale,
                       symbolSize: 21 * scale,
                       captionFontSize: 18 * scale)
    }

    /// Metrics for one half of the split keyboard.
    static func split(width: CGFloat, pad: Bool) -> Metrics {
        let scale = min(max(width / 1032.0, 0.55), 1.35)
        return Metrics(rowHeight: 46 * scale,
                       rowGap: 9 * scale,
                       keyGap: 8 * scale,
                       topInset: 9 * scale,
                       bottomInset: 7 * scale,
                       sideInset: 8 * scale,
                       cornerRadius: 6 * scale,
                       fontSize: 22 * scale,
                       // The halves stay clean: no corner hints on the small keys.
                       secondaryFontSize: 0,
                       symbolSize: 19 * scale,
                       captionFontSize: 15 * scale)
    }

    /// Horizontal gap between the two halves, as a fraction of the total width.
    static let splitCenterGapRatio: CGFloat = 0.285
    static let splitOuterMargin: CGFloat = 10
}
