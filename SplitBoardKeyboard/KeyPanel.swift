import UIKit

/// One rectangular block of keys: either the whole merged keyboard or one half
/// of the split keyboard.
final class KeyPanel: UIView {

    let rows: [PanelRow]
    private(set) var keyViews: [KeyView] = []
    private var metrics: Theme.Metrics
    /// Stretches the rows so the panel always fills the height the system gives us.
    var fillsHeight = false

    init(rows: [PanelRow], metrics: Theme.Metrics, delegate: KeyViewDelegate?) {
        self.rows = rows
        self.metrics = metrics
        super.init(frame: .zero)
        isMultipleTouchEnabled = true

        for row in rows {
            for spec in row.keys {
                let key = KeyView(spec: spec, metrics: metrics)
                key.delegate = delegate
                key.hitInset = metrics.keyGap / 2
                addSubview(key)
                keyViews.append(key)
            }
        }
    }

    convenience init(keyRows: [[KeySpec]], metrics: Theme.Metrics, delegate: KeyViewDelegate?) {
        self.init(rows: keyRows.map { PanelRow(keys: $0) }, metrics: metrics, delegate: delegate)
    }

    required init?(coder: NSCoder) { fatalError() }

    var intrinsicHeight: CGFloat {
        let content = rows.reduce(0) { $0 + metrics.rowHeight * $1.heightFactor }
        let gaps = metrics.rowGap * CGFloat(max(rows.count - 1, 0))
        return metrics.topInset + metrics.bottomInset + content + gaps
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }

        var index = 0
        var y = metrics.topInset
        let stretch = heightStretch
        for row in rows {
            let rowHeight = metrics.rowHeight * row.heightFactor * stretch
            let weightSum = row.keys.reduce(0) { $0 + $1.width }
            let gaps = metrics.keyGap * CGFloat(max(row.keys.count - 1, 0))
            let usable = bounds.width - metrics.sideInset * 2 - gaps
            let unit = weightSum > 0 ? usable / weightSum : 0
            var x = metrics.sideInset
            for spec in row.keys {
                let w = unit * spec.width
                let h = spec.extendsIntoRowGap ? rowHeight + metrics.rowGap : rowHeight
                keyViews[index].frame = CGRect(x: x, y: y, width: w, height: h)
                x += w + metrics.keyGap
                index += 1
            }
            y += rowHeight + metrics.rowGap
        }
    }

    /// Factor applied to every row height so the rows fill `bounds.height`.
    private var heightStretch: CGFloat {
        guard fillsHeight, bounds.height > 0 else { return 1 }
        let gaps = metrics.rowGap * CGFloat(max(rows.count - 1, 0))
        let available = bounds.height - metrics.topInset - metrics.bottomInset - gaps
        let content = rows.reduce(0) { $0 + metrics.rowHeight * $1.heightFactor }
        guard content > 0 else { return 1 }
        return min(max(available / content, 0.75), 1.35)
    }
}
