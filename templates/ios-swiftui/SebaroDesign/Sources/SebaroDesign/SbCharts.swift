import SwiftUI

// MARK: - The other charts (spec/02 §3.7; D91 G2a, G5a, G7a, G9a, D101 (7); spec/08 §14.22–§14.24)

/// The caption cut with tabular digits; `strong` = the caption size in the title weight (the latest value, D44).
func sbChartLabelFont(_ scheme: ColorScheme, strong: Bool = false) -> Font {
    let caption = SebaroTextStyle.caption.resolve(scheme)
    guard strong else { return SebaroFonts.font(caption, relativeTo: .caption, monospacedDigits: true) }
    let title = SebaroTextStyle.title.resolve(scheme)
    return SebaroFonts.font(SebaroTextFace(family: caption.family, size: caption.size, lineHeight: caption.lineHeight,
                                           weight: title.weight, weightValue: title.weightValue,
                                           tracking: caption.tracking),
                            relativeTo: .caption, monospacedDigits: true)
}

/// A label under the slots of a line (G2a): `text` over `span` points from the first of them (a month over its weeks);
/// "" keeps the place of a month too short for its word. The spans add up to the points.
public struct SbAxisLabel: Sendable {
    public let text: String
    public let span: Int
    public init(_ text: String, span: Int = 1) {
        self.text = text
        self.span = span
    }
}

/// One point of a line (G2a): `label` names it for VoiceOver („Woche ab 03.08.“), `value` its place on the scale
/// (nil = no value: a gap, never bridged), `valueText` its number („6,1“; VoiceOver says „keine Angabe“ for a gap).
public struct SbLinePoint: Sendable {
    public let label: String
    public let value: Double?
    public let valueText: String
    public init(_ label: String, value: Double?, valueText: String = "") {
        self.label = label
        self.value = value
        self.valueText = valueText
    }
}

/// One line of `SbSeriesChart` (G9a): `name` („Wasser“) and one point per slot, nil = no value there (a gap).
public struct SbSeries: Sendable {
    public let name: String
    public let points: [SbChartValue?]
    public init(_ name: String, points: [SbChartValue?]) {
        self.name = name
        self.points = points
    }
}

/// A label at a value beside the plot: `strong` = the latest value (title weight), `kept` = never left out,
/// `muted` = text-muted (target, grid and base numbers).
struct SbValueLabel: Sendable {
    let value: Double
    let text: String
    var strong = false
    var kept = false
    var muted = false
}

/// The pure geometry of the line plots (the Compose `sbValueY`, `sbLabelColumn`, `sbLabelSpots`).
enum SbChartGeometry {
    /// The y of `value`, from the head room's top: the plot runs from `head` (top) to `base` (bottom).
    static func valueY(_ value: Double, bottom: Double, top: Double, head: CGFloat, base: CGFloat) -> CGFloat {
        head + (base - head) * (1 - CGFloat(min(max((value - bottom) / (top - bottom), 0), 1)))
    }

    /// The width of a label column beside the plot: half the row less the gap, or the widest word if wider.
    static func labelColumn(row: CGFloat, gap: CGFloat, widestWord: CGFloat) -> CGFloat {
        let room = max(row - gap, 0)
        return min(max(room / 2, widestWord), room)
    }

    /// Where labels at values stand: each centred on its value; kept labels move apart when they would touch, never
    /// above the top, and below the base line only when there is no room left; any other label that would touch one
    /// is left out. Returns the shown labels (kept first) and the top of each.
    static func spots(_ labels: [SbValueLabel], heights: [CGFloat], bottom: Double, top: Double, head: CGFloat,
                      base: CGFloat) -> (shown: [Int], tops: [CGFloat]) {
        var tops = labels.indices.map { valueY(labels[$0].value, bottom: bottom, top: top, head: head, base: base) - heights[$0] / 2 }
        let kept = labels.indices.filter { labels[$0].kept }.sorted { tops[$0] < tops[$1] }
        var floor: CGFloat = 0
        for i in kept {
            tops[i] = max(tops[i], floor)
            floor = tops[i] + heights[i]
        }
        for n in kept.indices.reversed() {
            let i = kept[n]
            let limit = n == kept.count - 1 ? base + heights[i] / 2 : tops[kept[n + 1]]
            let ceiling = n == 0 ? 0 : tops[kept[n - 1]] + heights[kept[n - 1]]
            tops[i] = max(ceiling, min(tops[i], limit - heights[i]))
        }
        var shown = kept
        for i in labels.indices where !labels[i].kept {
            let touches = shown.contains { j in tops[i] < tops[j] + heights[j] && tops[j] < tops[i] + heights[i] }
            if !touches { shown.append(i) }
        }
        return (shown, tops)
    }

    /// The x of each axis label (centred on its slot, or start-aligned over its span when any label spans several
    /// points) and, read from the end, the labels shown: one stays when it ends inside `room` and before the next one
    /// shown.
    static func axis(_ labels: [SbAxisLabel], widths: [CGFloat], plot: CGFloat, room: CGFloat, count: Int)
        -> (xs: [CGFloat], shown: [Int]) {
        let slot = plot / CGFloat(max(count, 1))
        let start = labels.contains { $0.span > 1 }
        var at = 0
        let xs = labels.indices.map { i -> CGFloat in
            let x = start ? CGFloat(at) * slot : CGFloat(at) * slot + (slot * CGFloat(labels[i].span) - widths[i]) / 2
            at += labels[i].span
            return x
        }
        var shown: [Int] = []
        var limit = room
        for i in labels.indices.reversed() where !labels[i].text.isEmpty {
            if xs[i] + widths[i] <= limit {
                shown.append(i)
                limit = xs[i]
            }
        }
        return (xs, shown)
    }

    /// The scale's top: `max`, else the largest of the values (and target and grid); a flat chart at the base gets 1.
    static func top(_ max: Double?, values: [Double], bottom: Double) -> Double {
        if let max { return max }
        let highest = values.max() ?? bottom
        return highest > bottom ? highest : bottom + 1
    }
}

/// The line style of series `k` (`.sb-chart__line--1…6`): 1 and 4 solid, 2 and 5 dashed 6 · 4, 3 and 6 dotted.
func sbSeriesStroke(_ k: Int) -> StrokeStyle {
    let width = SebaroX.chartLineWidth
    switch k % 3 {
    case 1: return StrokeStyle(lineWidth: width, lineCap: .butt, lineJoin: .round, dash: [6, 4])
    case 2: return StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: [0, 5])
    default: return StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }
}

/// A line through `values` at the slot centres; nil splits it (a gap, never bridged); a lone point is a dot.
func sbDrawLine(_ ctx: GraphicsContext, _ values: [Double?], x: (Int) -> CGFloat, y: (Double) -> CGFloat, color: Color,
                stroke: StrokeStyle) {
    var i = 0
    while i < values.count {
        guard let first = values[i] else { i += 1; continue }
        var j = i
        while j + 1 < values.count, values[j + 1] != nil { j += 1 }
        if j == i {
            let r = stroke.lineWidth
            ctx.fill(Path(ellipseIn: CGRect(x: x(i) - r, y: y(first) - r, width: 2 * r, height: 2 * r)), with: .color(color))
        } else {
            var path = Path()
            path.move(to: CGPoint(x: x(i), y: y(first)))
            for k in (i + 1)...j { path.addLine(to: CGPoint(x: x(k), y: y(values[k]!))) }
            ctx.stroke(path, with: .color(color), style: stroke)
        }
        i = j + 1
    }
}

/// What a subview of `SbLinePlotLayout` is.
enum SbPlotRole: Equatable {
    case area, tick(Int), end(Int), valueEnd(Int), axis(Int)
}

struct SbPlotRoleKey: LayoutValueKey {
    static let defaultValue: SbPlotRole = .area
}

/// The plot of a line (`sb-chart__plot`), as the Compose `SbLinePlot`: ticks before it (end-aligned), a 128 pt area
/// under one caption line of head room, the end labels after it, the axis labels under it. With `valueEnds` (the
/// series chart) the end labels come in two sets, with the names (`.end`) and with the values only (`.valueEnd`):
/// the names stand while each end stays on one line and covers the height where its line ends (D101 (7)), measured
/// at every text size; `namesStand` reports the choice after the layout pass (the legend above depends on it).
struct SbLinePlotLayout: Layout {
    let ticks: [SbValueLabel]
    let ends: [SbValueLabel]
    let valueEnds: [SbValueLabel]?
    let axis: [SbAxisLabel]
    let count: Int
    let bottom: Double
    let top: Double
    let head: CGFloat
    var namesStand: Binding<Bool>?

    static let plot = SebaroSpace.s16 * 2
    static let gap = SebaroSpace.s2
    /// The width of a figure whose parent sets none (a horizontal scroll row): a 360 pt phone less its two gutters.
    static let fallback = 360 - 2 * SebaroSpacing.gutter

    struct Arrangement {
        var size: CGSize
        var places: [Int: CGRect] = [:]
        var names = true
    }

    func arrange(_ width: CGFloat?, _ subviews: Subviews) -> Arrangement {
        let w = width.flatMap { $0.isFinite ? $0 : nil } ?? Self.fallback
        let base = head + Self.plot
        var out = Arrangement(size: .zero)
        func indices(_ match: (SbPlotRole) -> Int?) -> [Int: Int] {
            var map: [Int: Int] = [:]
            for (n, s) in subviews.enumerated() { if let k = match(s[SbPlotRoleKey.self]) { map[k] = n } }
            return map
        }
        let tickViews = indices { if case .tick(let k) = $0 { k } else { nil } }
        let endViews = indices { if case .end(let k) = $0 { k } else { nil } }
        let valueViews = indices { if case .valueEnd(let k) = $0 { k } else { nil } }
        let axisViews = indices { if case .axis(let k) = $0 { k } else { nil } }
        let area = subviews.indices.first { subviews[$0][SbPlotRoleKey.self] == .area }

        // one column of labels: its column width, each label's size there, the spots
        func column(_ labels: [SbValueLabel], _ views: [Int: Int], row: CGFloat)
            -> (sizes: [CGSize], spots: (shown: [Int], tops: [CGFloat]), inner: CGFloat, oneLine: [Bool]) {
            guard !labels.isEmpty else { return ([], ([], []), 0, []) }
            let widest = labels.indices.map { subviews[views[$0]!].sizeThatFits(ProposedViewSize(width: 0, height: nil)).width }.max() ?? 0
            let col = SbChartGeometry.labelColumn(row: row, gap: Self.gap, widestWord: widest)
            let sizes = labels.indices.map { subviews[views[$0]!].sizeThatFits(ProposedViewSize(width: col, height: nil)) }
            let oneLine = labels.indices.map { subviews[views[$0]!].sizeThatFits(.unspecified).width <= col + 0.5 }
            let spots = SbChartGeometry.spots(labels, heights: sizes.map(\.height), bottom: bottom, top: top, head: head, base: base)
            return (sizes, spots, spots.shown.map { sizes[$0].width }.max() ?? 0, oneLine)
        }

        let t = column(ticks, tickViews, row: w)
        let tickW = ticks.isEmpty ? 0 : t.inner + Self.gap
        var e = column(ends, endViews, row: w - tickW)
        var shownEnds = endViews
        if let valueEnds {
            // D101 (7): every named end on one line and over the height where its line ends
            out.names = ends.indices.allSatisfy { i in
                let y = SbChartGeometry.valueY(ends[i].value, bottom: bottom, top: top, head: head, base: base)
                return e.oneLine[i] && e.spots.tops[i] <= y && y <= e.spots.tops[i] + e.sizes[i].height
            }
            if !out.names {
                e = column(valueEnds, valueViews, row: w - tickW)
                shownEnds = valueViews
            }
        }
        let endW = ends.isEmpty ? 0 : e.inner + Self.gap
        let areaW = max(w - tickW - endW, 0)
        for i in t.spots.shown {
            let s = t.sizes[i]
            out.places[tickViews[i]!] = CGRect(x: t.inner - s.width, y: t.spots.tops[i], width: s.width, height: s.height)
        }
        var endsBottom = base
        for i in e.spots.shown {
            let s = e.sizes[i]
            out.places[shownEnds[i]!] = CGRect(x: tickW + areaW + Self.gap, y: e.spots.tops[i], width: s.width, height: s.height)
            endsBottom = max(endsBottom, e.spots.tops[i] + s.height)
        }
        if let area { out.places[area] = CGRect(x: tickW, y: head, width: areaW, height: Self.plot) }
        var axisH: CGFloat = 0
        if !axis.isEmpty {
            let sizes = axis.indices.map { subviews[axisViews[$0]!].sizeThatFits(.unspecified) }
            let room = endsBottom > base ? areaW : areaW + endW
            let placed = SbChartGeometry.axis(axis, widths: sizes.map(\.width), plot: areaW, room: room, count: count)
            for i in placed.shown {
                out.places[axisViews[i]!] = CGRect(x: tickW + placed.xs[i], y: base + SebaroSpace.s1,
                                                   width: sizes[i].width, height: sizes[i].height)
            }
            axisH = SebaroSpace.s1 + (sizes.map(\.height).max() ?? 0)
        }
        let tickBottom = t.spots.shown.map { t.spots.tops[$0] + t.sizes[$0].height }.max() ?? 0
        out.size = CGSize(width: w, height: max(base + axisH, tickBottom, endsBottom))
        return out
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal.width, subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let a = arrange(bounds.width, subviews)
        for (n, s) in subviews.enumerated() {
            if let r = a.places[n] {
                s.place(at: CGPoint(x: bounds.minX + r.minX, y: bounds.minY + r.minY),
                        proposal: ProposedViewSize(width: r.width, height: r.height))
            } else {
                s.place(at: CGPoint(x: -100_000, y: bounds.minY), proposal: ProposedViewSize(width: 0, height: 0))
            }
        }
        if let namesStand, namesStand.wrappedValue != a.names {
            let names = a.names
            DispatchQueue.main.async { if namesStand.wrappedValue != names { namesStand.wrappedValue = names } }
        }
    }
}

/// The plot views of a line chart: labels, the drawn area with one VoiceOver element per slot, axis labels.
struct SbLinePlot: View {
    let layout: SbLinePlotLayout
    let sentences: [String]
    let draw: (GraphicsContext, CGSize, _ x: (Int) -> CGFloat, _ y: (Double) -> CGFloat) -> Void
    private var context = SbContext()

    init(layout: SbLinePlotLayout, sentences: [String],
         draw: @escaping (GraphicsContext, CGSize, _ x: (Int) -> CGFloat, _ y: (Double) -> CGFloat) -> Void) {
        self.layout = layout
        self.sentences = sentences
        self.draw = draw
    }

    var body: some View {
        let count = layout.count, bottom = layout.bottom, top = layout.top
        layout {
            ForEach(Array(layout.ticks.enumerated()), id: \.offset) { k, l in
                label(l, before: true).layoutValue(key: SbPlotRoleKey.self, value: .tick(k))
            }
            ForEach(Array(layout.ends.enumerated()), id: \.offset) { k, l in
                label(l, before: false).layoutValue(key: SbPlotRoleKey.self, value: .end(k))
            }
            ForEach(Array((layout.valueEnds ?? []).enumerated()), id: \.offset) { k, l in
                label(l, before: false).layoutValue(key: SbPlotRoleKey.self, value: .valueEnd(k))
            }
            ForEach(Array(layout.axis.enumerated()), id: \.offset) { k, a in
                Text(a.text).font(sbChartLabelFont(context.scheme)).foregroundStyle(context.tone.textMuted)
                    .lineLimit(1).fixedSize()
                    .accessibilityHidden(true)
                    .layoutValue(key: SbPlotRoleKey.self, value: .axis(k))
            }
            Canvas { ctx, size in
                draw(ctx, size,
                     { i in size.width * (CGFloat(i) + 0.5) / CGFloat(count) },
                     { v in size.height * (1 - CGFloat(min(max((v - bottom) / (top - bottom), 0), 1))) })
            }
            .flipsForRightToLeftLayoutDirection(true)
            // the web's „Werte als Tabelle“ for VoiceOver: one element per slot, over its column of the plot
            .overlay {
                HStack(spacing: 0) {
                    ForEach(Array(sentences.enumerated()), id: \.offset) { _, s in
                        Color.clear.contentShape(Rectangle())
                            .accessibilityElement()
                            .accessibilityLabel(Text(s))
                    }
                }
            }
            .layoutValue(key: SbPlotRoleKey.self, value: .area)
        }
    }

    private func label(_ l: SbValueLabel, before: Bool) -> some View {
        Text(l.text).font(sbChartLabelFont(context.scheme, strong: l.strong))
            .foregroundStyle(l.muted ? context.tone.textMuted : context.tone.text)
            .multilineTextAlignment(before ? .trailing : .leading)
            .accessibilityHidden(true)
    }
}

/// Line, one series (G2a, spec/02 §3.7): one grey line (`chartBar`, 2 pt, round joins and caps) through the slot centres
/// in a 128 pt plot under one caption line of head room, the latest point with a value a 4 pt dot in `chartBarCurrent`;
/// a nil value splits the line (a gap, never bridged). `grid` lines 1 pt `chartGrid`, the `target` 1 pt dashed
/// text-muted, the base line 1 pt `chartAxis` at `from` (nil = 0; with it the axis starts above 0 and its number is
/// written there). After the plot „Ziel n“, the latest value (text, title weight) and the grid and base numbers
/// (text-muted), each centred on its value; a number that would touch the target or the latest value is left out. Under
/// the plot the `axis` labels (one per point, or a month over its weeks). At least one point needs a value: with none
/// yet, show `SbEmptyState`. VoiceOver reads the caption, then one element per point („Woche ab 03.08.: 6,1“;
/// „keine Angabe“ for a gap).
public struct SbLineChart: View {
    let points: [SbLinePoint]
    let caption: String
    let axis: [SbAxisLabel]
    let target: SbChartValue?
    let grid: [SbChartValue]
    let from: SbChartValue?
    let max: Double?
    private var context = SbContext()
    @ScaledMetric(relativeTo: .caption) private var head: CGFloat = SebaroTextStyle.caption.resolve(.light).lineHeight

    public init(_ points: [SbLinePoint], caption: String, axis: [SbAxisLabel] = [], target: SbChartValue? = nil,
                grid: [SbChartValue] = [], from: SbChartValue? = nil, max: Double? = nil) {
        precondition(points.count >= 2, "SbLineChart: at least two points")
        precondition(points.contains { $0.value != nil }, "SbLineChart: no point has a value")
        precondition(axis.isEmpty || (axis.allSatisfy { $0.span >= 1 } && axis.reduce(0) { $0 + $1.span } == points.count),
                     "SbAxisLabel: the spans add up to the points")
        self.points = points
        self.caption = caption
        self.axis = axis
        self.target = target
        self.grid = grid
        self.from = from
        self.max = max
    }

    public var body: some View {
        let m = context.messages
        let latest = points.lastIndex { $0.value != nil }!
        let now = points[latest], nowValue = now.value!
        let bottom = from?.value ?? 0
        let top = SbChartGeometry.top(max, values: points.compactMap(\.value) + [target?.value].compactMap { $0 }
                                        + grid.map(\.value), bottom: bottom)
        var ends: [SbValueLabel] = []
        if let target { ends.append(SbValueLabel(value: target.value, text: m.chartTarget(target.text), kept: true, muted: true)) }
        ends.append(SbValueLabel(value: nowValue, text: now.valueText, strong: true, kept: true))
        ends += grid.map { SbValueLabel(value: $0.value, text: $0.text, muted: true) }
        if let from { ends.append(SbValueLabel(value: from.value, text: from.text, muted: true)) }
        let muted = context.tone.textMuted
        let layout = SbLinePlotLayout(ticks: [], ends: ends, valueEnds: nil, axis: axis, count: points.count,
                                      bottom: bottom, top: top, head: head)
        return SbChartFigure(caption) {
            SbLinePlot(layout: layout, sentences: points.map { m.chartPoint($0.label, $0.value == nil ? m.noValue : $0.valueText) }) {
                ctx, size, x, y in
                let hair = SebaroBorderWidth.hairline
                for g in grid {
                    ctx.fill(Path(CGRect(x: 0, y: y(g.value) - hair / 2, width: size.width, height: hair)), with: .color(SebaroX.chartGrid))
                }
                if let target {
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y(target.value)))
                    line.addLine(to: CGPoint(x: size.width, y: y(target.value)))
                    ctx.stroke(line, with: .color(muted), style: StrokeStyle(lineWidth: hair, dash: [SebaroSpace.s1, SebaroSpace.s1]))
                }
                ctx.fill(Path(CGRect(x: 0, y: size.height - hair, width: size.width, height: hair)), with: .color(SebaroX.chartAxis))
                sbDrawLine(ctx, points.map(\.value), x: x, y: y, color: SebaroX.chartBar,
                           stroke: StrokeStyle(lineWidth: SebaroX.chartLineWidth, lineCap: .round, lineJoin: .round))
                let r = SebaroSpace.s1, c = CGPoint(x: x(latest), y: y(nowValue))
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(SebaroX.chartBarCurrent))
            }
        }
    }
}

/// Several series (G9a, spec/02 §3.7): 2 to 6 lines in `SebaroDataviz.categorical` in fixed order, each with its own
/// line style so they stay apart without colour (1 and 4 solid, 2 and 5 dashed 6 · 4, 3 and 6 dotted), one point per
/// `labels` entry (nil = a gap). The `grid` and `from` numbers stand before the plot, the name and last value of each
/// series at its line end („Wasser 90 %“). From three series a legend above the plot (key with colour and line style,
/// then the name) in the order of the line ends from the top; two series have only the end labels. Once an end with its
/// name can no longer stand at its line (D101 (7), measured at every text size), the legend names the series, also two,
/// and each end keeps only its last value. VoiceOver reads the caption, the legend as one element („Legende, Wasser, …“),
/// then one element per slot („Woche ab 24.08.: Wasser 70 %, Spaziergang 40 %, …“).
public struct SbSeriesChart: View {
    let series: [SbSeries]
    let labels: [String]
    let caption: String
    let axis: [SbAxisLabel]
    let grid: [SbChartValue]
    let from: SbChartValue?
    let max: Double?
    private var context = SbContext()
    @State private var namesStand = true
    @ScaledMetric(relativeTo: .caption) private var head: CGFloat = SebaroTextStyle.caption.resolve(.light).lineHeight

    public init(_ series: [SbSeries], labels: [String], caption: String, axis: [SbAxisLabel] = [],
                grid: [SbChartValue] = [], from: SbChartValue? = nil, max: Double? = nil) {
        precondition((2...6).contains(series.count), "SbSeriesChart: 2 to 6 series (G9a); one series is SbLineChart")
        precondition(labels.count >= 2, "SbSeriesChart: at least two points")
        precondition(series.allSatisfy { $0.points.count == labels.count }, "SbSeriesChart: one point per label in every series")
        precondition(series.allSatisfy { $0.points.contains { $0 != nil } }, "SbSeriesChart: every series needs a value")
        self.series = series
        self.labels = labels
        self.caption = caption
        self.axis = axis
        self.grid = grid
        self.from = from
        self.max = max
    }

    /// The legend's order: by the last value, from the top.
    static func legendOrder(_ series: [SbSeries]) -> [Int] {
        let last = series.map { s in s.points.last { $0 != nil }!!.value }
        return series.indices.sorted { last[$0] > last[$1] || (last[$0] == last[$1] && $0 < $1) }
    }

    public var body: some View {
        let m = context.messages
        let last = series.map { s in s.points.last { $0 != nil }!! }
        let bottom = from?.value ?? 0
        let top = SbChartGeometry.top(max, values: series.flatMap { $0.points.compactMap { $0?.value } } + grid.map(\.value),
                                      bottom: bottom)
        let named = series.indices.map { SbValueLabel(value: last[$0].value, text: series[$0].name + " " + last[$0].text, kept: true) }
        let valued = series.indices.map { SbValueLabel(value: last[$0].value, text: last[$0].text, kept: true) }
        let ticks = (grid + [from].compactMap { $0 }).map { SbValueLabel(value: $0.value, text: $0.text, muted: true) }
        let layout = SbLinePlotLayout(ticks: ticks, ends: named, valueEnds: valued, axis: axis, count: labels.count,
                                      bottom: bottom, top: top, head: head, namesStand: $namesStand)
        let plot = SbLinePlot(layout: layout, sentences: labels.indices.map { i in
            m.chartPoint(labels[i], series.map { $0.name + " " + ($0.points[i]?.text ?? m.noValue) }.joined(separator: ", "))
        }) { ctx, size, x, y in
            let hair = SebaroBorderWidth.hairline
            for g in grid {
                ctx.fill(Path(CGRect(x: 0, y: y(g.value) - hair / 2, width: size.width, height: hair)), with: .color(SebaroX.chartGrid))
            }
            ctx.fill(Path(CGRect(x: 0, y: size.height - hair, width: size.width, height: hair)), with: .color(SebaroX.chartAxis))
            for (k, s) in series.enumerated() {
                sbDrawLine(ctx, s.points.map { $0?.value }, x: x, y: y, color: SebaroDataviz.categorical[k], stroke: sbSeriesStroke(k))
            }
        }
        return Group {
            if series.count >= 3 || !namesStand {
                SbChartFigure(caption, legend: { SbSeriesLegend(series: series, order: Self.legendOrder(series)) }) { plot }
            } else {
                SbChartFigure(caption) { plot }
            }
        }
    }
}

/// The legend of `SbSeriesChart` (`sb-chart__legend`): one key per series, colour and line style, then its name.
struct SbSeriesLegend: View {
    let series: [SbSeries]
    let order: [Int]
    private var context = SbContext()

    // explicit, because a private stored property makes the memberwise initializer private (Swift 6.0/6.1, Xcode 26)
    init(series: [SbSeries], order: [Int]) {
        self.series = series
        self.order = order
    }

    var body: some View {
        SbWrapRow(spacing: SebaroSpace.s4) {
            ForEach(order, id: \.self) { k in
                HStack(spacing: SebaroSpace.s2) {
                    Canvas { ctx, size in
                        var p = Path()
                        p.move(to: CGPoint(x: SebaroBorderWidth.hairline, y: size.height / 2))
                        p.addLine(to: CGPoint(x: size.width - SebaroBorderWidth.hairline, y: size.height / 2))
                        ctx.stroke(p, with: .color(SebaroDataviz.categorical[k]), style: sbSeriesStroke(k))
                    }
                    .frame(width: SebaroSize.iconLg, height: SebaroSpace.s2)
                    Text(series[k].name).sbFont(.caption).foregroundStyle(context.tone.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(([context.messages.chartLegend] + order.map { series[$0].name }).joined(separator: ", ")))
    }
}

// MARK: - Histogram (G5a)

/// One bin of a histogram (G5a): `range` names it for VoiceOver („10 bis unter 20 Min.“), `count` its height on the
/// scale, `countText` the number on the bin.
public struct SbBin: Sendable {
    public let range: String
    public let count: Double
    public let countText: String
    public init(_ range: String, count: Double, countText: String) {
        self.range = range
        self.count = count
        self.countText = countText
    }
}

/// Histogram (G5a, spec/02 §3.7 `sb-chart__bars--dense`): equal classes without gaps in the values, all bins grey
/// (`chartBar`), 2 pt apart on a 1 pt `chartAxis` base line in a 128 pt plot under one caption line of head room; the
/// count on each bin (caption, text, 2 pt above it); the `edges` (n + 1 boundaries) centred on the edges of the bins
/// and the `unit` once below them, both text-muted and hidden from VoiceOver. The count axis starts at 0; `max` = its
/// top (else the largest count; with every count 0 the bins stay empty on the base line, their „0“ on it). VoiceOver
/// reads the caption, then one element per bin („10 bis unter 20 Min.: 5“).
public struct SbHistogram: View {
    let bins: [SbBin]
    let edges: [String]
    let unit: String
    let caption: String
    let max: Double?
    private var context = SbContext()
    @ScaledMetric(relativeTo: .caption) private var head: CGFloat = SebaroTextStyle.caption.resolve(.light).lineHeight

    public init(_ bins: [SbBin], edges: [String], unit: String, caption: String, max: Double? = nil) {
        precondition(!bins.isEmpty, "SbHistogram: no bins")
        precondition(edges.count == bins.count + 1, "SbHistogram: one boundary more than bins")
        precondition(max.map { $0 > 0 } ?? true, "SbHistogram: max must be above 0")
        self.bins = bins
        self.edges = edges
        self.unit = unit
        self.caption = caption
        self.max = max
    }

    public var body: some View {
        let m = context.messages
        let top = SbChartGeometry.top(max, values: bins.map(\.count), bottom: 0)
        let font = sbChartLabelFont(context.scheme)
        SbChartFigure(caption) {
            VStack(spacing: 0) {
                HStack(spacing: SebaroSpace.s0_5) {
                    ForEach(Array(bins.enumerated()), id: \.offset) { _, b in
                        let share = CGFloat(Swift.min(Swift.max(b.count / top, 0), 1))
                        GeometryReader { g in
                            let floor = g.size.height - SebaroBorderWidth.hairline
                            Rectangle().fill(SebaroX.chartBar)
                                .frame(width: g.size.width, height: floor * share)
                                .position(x: g.size.width / 2, y: floor * (1 - share / 2))
                            // the count stands on its bin (sb-chart__count), a full bin's in the head room
                            Text(b.countText).font(font).foregroundStyle(context.tone.text).lineLimit(1).fixedSize()
                                .position(x: g.size.width / 2, y: floor * (1 - share) - SebaroSpace.s0_5 - head / 2)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(m.chartPoint(b.range, b.countText)))
                    }
                }
                .frame(height: SebaroSpace.s16 * 2)
                .background(alignment: .bottom) {
                    Rectangle().fill(SebaroX.chartAxis).frame(height: SebaroBorderWidth.hairline)
                }
                .padding(.top, head)
                SbEdgeLabels(edges: edges, font: font)
                    .padding(.top, SebaroSpace.s1)
                    .accessibilityHidden(true)
                Text(unit).sbFont(.caption).foregroundStyle(context.tone.textMuted)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, SebaroSpace.s1)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// The class boundaries under a histogram (`sb-chart__edges`): n + 1 labels centred on the edges of n bins; the first
/// and the last are moved back inside, so none is cut at the edges.
struct SbEdgeLabels: View {
    let edges: [String]
    let font: Font
    @Environment(\.sebaroTone) private var tone

    var body: some View {
        SbEdgeLayout {
            ForEach(Array(edges.enumerated()), id: \.offset) { _, e in
                Text(e).font(font).foregroundStyle(tone.textMuted).lineLimit(1).fixedSize()
            }
        }
    }
}

struct SbEdgeLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? SbLinePlotLayout.fallback,
               height: subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let widths = subviews.map { $0.sizeThatFits(.unspecified).width }
        let placed = SbEdgeLayout.edges(widths: widths, width: bounds.width, gap: SebaroSpace.s1)
        for (i, s) in subviews.enumerated() {
            let x = placed.shown.contains(i) ? bounds.minX + placed.xs[i] : -100_000
            s.place(at: CGPoint(x: x, y: bounds.minY), proposal: .unspecified)
        }
    }

    /// Each boundary centred on its edge and moved back inside at the ends; read from the end, a boundary stays when it
    /// ends at least `gap` before the next one shown (as the bar labels, D99 (2); at large text „0 · 20 · 40“ instead of
    /// numbers run together; *provisional, agent*: Compose and the web place every boundary).
    static func edges(widths: [CGFloat], width: CGFloat, gap: CGFloat) -> (xs: [CGFloat], shown: Set<Int>) {
        let step = width / CGFloat(max(widths.count - 1, 1))
        let xs = widths.indices.map { min(max(CGFloat($0) * step - widths[$0] / 2, 0), max(width - widths[$0], 0)) }
        var shown = Set<Int>()
        var limit = CGFloat.greatestFiniteMagnitude
        for i in widths.indices.reversed() where xs[i] + widths[i] <= limit {
            shown.insert(i)
            limit = xs[i] - gap
        }
        return (xs, shown)
    }
}

// MARK: - Deviation (G7a)

/// One row of a deviation chart (G7a): `name` („Mo“), `value` its signed difference from the midpoint on the scale,
/// `valueText` the same as text with its sign and unit („+0,5 Std.“, „−1,0 Std.“ with U+2212 and U+00A0, spec/07).
public struct SbDeviation: Sendable {
    public let name: String
    public let value: Double
    public let valueText: String
    public init(_ name: String, value: Double, valueText: String) {
        self.name = name
        self.value = value
        self.valueText = valueText
    }
}

/// Deviation (G7a, spec/02 §3.7 `sb-chart__diverging`): one column grid for all rows, name (caption) · bar · value (the
/// 16 pt arrow up or down, none at 0, and `valueText` in caption, tabular), 12 pt apart. The bar is 32 pt high
/// (`controlSm`, the row's minimum), the fill 16 pt in its middle: less from the 1 pt `chartAxis` zero line towards the
/// start in `diverging[1]`, more towards the end in `diverging[3]` (tones, never good or bad); `max` = the difference a
/// half bar shows (else the largest; all 0 = only the zero line). Over the bar column the head: `less` at the start,
/// `midpoint` („0 = 7 Std.“) on the zero line, `more` at the end, caption text-muted; when the sides do not fit beside
/// the midpoint, the three stand one under the other. A row grows with its text. VoiceOver: the caption, the head as
/// one element, then one element per row („Mo: +0,5 Std.“).
public struct SbDeviationChart: View {
    let rows: [SbDeviation]
    let midpoint: String
    let caption: String
    let less: String?
    let more: String?
    let max: Double?
    private var context = SbContext()

    public init(_ rows: [SbDeviation], midpoint: String, caption: String, less: String? = nil, more: String? = nil,
                max: Double? = nil) {
        precondition(!rows.isEmpty, "SbDeviationChart: no rows")
        precondition(max.map { $0 > 0 } ?? true, "SbDeviationChart: max must be above 0")
        self.rows = rows
        self.midpoint = midpoint
        self.caption = caption
        self.less = less
        self.more = more
        self.max = max
    }

    public var body: some View {
        let m = context.messages
        let lessText = less ?? m.chartLess, moreText = more ?? m.chartMore
        let largest = rows.map { abs($0.value) }.max() ?? 0
        let scale = max ?? (largest > 0 ? largest : 1)
        let font = sbChartLabelFont(context.scheme)
        SbChartFigure(caption) {
            SbDeviationLayout {
                // the labels are drawn only; VoiceOver reads the head element and one element per row
                ForEach([lessText, midpoint, moreText], id: \.self) { t in
                    Text(t).font(font).foregroundStyle(context.tone.textMuted).fixedSize(horizontal: false, vertical: true)
                        .accessibilityHidden(true)
                }
                Color.clear.accessibilityElement().accessibilityLabel(Text([lessText, midpoint, moreText].joined(separator: ", ")))
                ForEach(Array(rows.enumerated()), id: \.offset) { _, r in
                    Text(r.name).sbFont(.caption).foregroundStyle(context.tone.text).fixedSize(horizontal: false, vertical: true)
                        .accessibilityHidden(true)
                    SbDeviationBar(value: r.value, scale: scale)
                    HStack(spacing: SebaroSpace.s1) {
                        if r.value > 0 { SbIcon("arrow-up--16", size: SebaroSize.iconSm, color: context.tone.text) }
                        if r.value < 0 { SbIcon("arrow-down--16", size: SebaroSize.iconSm, color: context.tone.text) }
                        Text(r.valueText).font(font).foregroundStyle(context.tone.text).fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityHidden(true)
                    Color.clear.accessibilityElement().accessibilityLabel(Text(m.chartPoint(r.name, r.valueText)))
                }
            }
            .accessibilityElement(children: .contain)
        }
    }
}

struct SbDeviationBar: View {
    let value: Double
    let scale: Double
    @Environment(\.layoutDirection) private var direction
    var body: some View {
        Canvas { ctx, size in
            let zero = size.width / 2
            let half = zero * CGFloat(min(abs(value) / scale, 1))
            let toLeft = (value < 0) != (direction == .rightToLeft)
            let fill = SebaroSize.controlSm / 2
            if half > 0 {
                ctx.fill(Path(CGRect(x: toLeft ? zero - half : zero, y: (size.height - fill) / 2, width: half, height: fill)),
                         with: .color(value < 0 ? SebaroDataviz.diverging[1] : SebaroDataviz.diverging[3]))
            }
            ctx.fill(Path(CGRect(x: zero - SebaroBorderWidth.hairline / 2, y: 0, width: SebaroBorderWidth.hairline, height: size.height)),
                     with: .color(SebaroX.chartAxis))
        }
        .accessibilityHidden(true)
    }
}

/// The deviation grid (the Compose measure block): subviews less, midpoint, more, the head element, then four per row
/// (name, bar, value, row element). The name and value columns take at most 40 % of the width each.
struct SbDeviationLayout: Layout {
    struct Arrangement {
        var size: CGSize
        var places: [CGRect]
    }

    func arrange(_ width: CGFloat?, _ s: Subviews) -> Arrangement {
        let w = width.flatMap { $0.isFinite ? $0 : nil } ?? SbLinePlotLayout.fallback
        let gap = SebaroSpace.s3
        let rows = (s.count - 4) / 4
        let col = ProposedViewSize(width: w * 0.4, height: nil)
        let names = (0..<rows).map { s[4 + 4 * $0].sizeThatFits(col) }
        let values = (0..<rows).map { s[6 + 4 * $0].sizeThatFits(col) }
        let nameW = names.map(\.width).max() ?? 0
        let barW = max(w - nameW - (values.map(\.width).max() ?? 0) - 2 * gap, 0)
        let x0 = nameW + gap
        let whole = ProposedViewSize(width: w, height: nil)
        let less = s[0].sizeThatFits(whole), mid = s[1].sizeThatFits(whole), more = s[2].sizeThatFits(whole)
        let side = (barW - mid.width) / 2 - SebaroSpace.s2
        let oneLine = less.width <= side && more.width <= side
        let midY = oneLine ? 0 : less.height
        let moreY = oneLine ? 0 : midY + mid.height
        let headH = oneLine ? max(less.height, mid.height, more.height) : moreY + more.height
        var places = Array(repeating: CGRect.zero, count: s.count)
        places[0] = CGRect(x: min(x0, max(w - less.width, 0)), y: 0, width: less.width, height: less.height)
        places[1] = CGRect(x: min(max(x0 + (barW - mid.width) / 2, 0), max(w - mid.width, 0)), y: midY, width: mid.width, height: mid.height)
        places[2] = CGRect(x: max(x0 + barW - more.width, 0), y: moreY, width: more.width, height: more.height)
        places[3] = CGRect(x: 0, y: 0, width: w, height: headH)
        var y = headH + SebaroSpace.s1
        for i in 0..<rows {
            let h = max(SebaroSize.controlSm, names[i].height, values[i].height)
            places[4 + 4 * i] = CGRect(x: 0, y: y + (h - names[i].height) / 2, width: names[i].width, height: names[i].height)
            places[5 + 4 * i] = CGRect(x: x0, y: y, width: barW, height: h)
            places[6 + 4 * i] = CGRect(x: w - values[i].width, y: y + (h - values[i].height) / 2, width: values[i].width, height: values[i].height)
            places[7 + 4 * i] = CGRect(x: 0, y: y, width: w, height: h)
            y += h
        }
        return Arrangement(size: CGSize(width: w, height: y), places: places)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal.width, subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let a = arrange(bounds.width, subviews)
        for (i, s) in subviews.enumerated() {
            let r = a.places[i]
            s.place(at: CGPoint(x: bounds.minX + r.minX, y: bounds.minY + r.minY),
                    proposal: ProposedViewSize(width: r.width, height: r.height))
        }
    }
}
