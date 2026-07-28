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
        dark:  UIColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1))   // #1C1C1E

    /// Regular character key. iPadOS 26 uses the same colour for modifier keys.
    static let keyNormal = dynamic(
        light: .white,
        dark:  UIColor(red: 0.290, green: 0.290, blue: 0.302, alpha: 1))   // #4A4A4D

    static let keyNormalPressed = dynamic(
        light: UIColor(red: 0.839, green: 0.847, blue: 0.867, alpha: 1),
        dark:  UIColor(red: 0.400, green: 0.400, blue: 0.416, alpha: 1))

    /// Modifier keys: shift, delete, plane switch, globe, dismiss.
    static let keySpecial = keyNormal
    static let keySpecialPressed = keyNormalPressed

    /// Shift / caps-lock engaged.
    static let keyActivated = dynamic(
        light: UIColor(red: 0.780, green: 0.792, blue: 0.816, alpha: 1),
        dark:  UIColor(red: 0.475, green: 0.475, blue: 0.490, alpha: 1))

    static let keyLabel = dynamic(light: .black, dark: .white)

    static let keySecondaryLabel = dynamic(
        light: UIColor(red: 0.443, green: 0.455, blue: 0.486, alpha: 1),
        dark:  UIColor(white: 1.0, alpha: 0.55))

    static let keyShadow = dynamic(
        light: UIColor(white: 0.0, alpha: 0.10),
        dark:  UIColor(white: 0.0, alpha: 0.35))

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
                       cornerRadius: 9 * scale,
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
                       cornerRadius: 9 * scale,
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
                       cornerRadius: 7 * scale,
                       fontSize: 22 * scale,
                       secondaryFontSize: 11 * scale,
                       symbolSize: 19 * scale,
                       captionFontSize: 15 * scale)
    }

    /// Horizontal gap between the two halves, as a fraction of the total width.
    static let splitCenterGapRatio: CGFloat = 0.285
    static let splitOuterMargin: CGFloat = 10
}
