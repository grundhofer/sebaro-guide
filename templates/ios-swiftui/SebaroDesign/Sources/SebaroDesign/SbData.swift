import SwiftUI

// MARK: - Big number and stats (spec/02 §3.6; spec/08 §14.10)

/// Big number: `value` in display with tabular figures („5 / 8“) over `label` in caption text-muted; both wrap whole
/// at large text (spec/08 §14.10). One VoiceOver element.
public struct SbBigNumber: View {
    let value: String?
    let parts: [(number: String, unit: String)]
    let lead: String?
    let label: String?
    private var context = SbContext()

    public init(_ value: String, label: String) {
        self.value = value
        self.parts = []
        self.lead = nil
        self.label = label
    }

    /// A big number in parts (spec/08 §14.10): `lead` („noch“), then each number in display and its word in label („38 Wochen
    /// 1 Tag“), one line that wraps between words; `label` in caption text-muted under it.
    public init(parts: [(number: String, unit: String)], lead: String? = nil, label: String? = nil) {
        self.value = nil
        self.parts = parts
        self.lead = lead
        self.label = label
    }

    /// The parts as one line: lead and words in the exact label cut of `scheme` (400/430 by light and dark, D44), the
    /// numbers in the surrounding display role.
    static func line(parts: [(number: String, unit: String)], lead: String?, scheme: ColorScheme) -> AttributedString {
        var line = AttributedString()
        let word = AttributeContainer().font(SebaroTextStyle.label.exactFont(for: scheme))
        if let lead { line.append(AttributedString(lead, attributes: word)) }
        for (number, unit) in parts {
            if !line.characters.isEmpty { line.append(AttributedString(" ")) }
            line.append(AttributedString(number + "\u{00A0}"))
            line.append(AttributedString(unit, attributes: word))
        }
        return line
    }

    public var body: some View {
        let value = self.value.map { Text($0) } ?? Text(Self.line(parts: parts, lead: lead, scheme: context.scheme))
        VStack(alignment: .leading, spacing: SebaroSpace.s1) {
            value.sbFont(.display).monospacedDigit().foregroundStyle(context.tone.text)
                .fixedSize(horizontal: false, vertical: true)
            if let label {
                Text(label).sbFont(.caption).foregroundStyle(context.tone.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// One stat: `label` („Serie“) and `value` („12 Tage“); `spark` = the sparkline after the number (G3a).
public struct SbStatItem: Identifiable, Sendable {
    public let id = UUID()
    public let label: String
    public let value: String
    public let spark: [Double]?

    public init(_ label: String, value: String, spark: [Double]? = nil) {
        self.label = label
        self.value = value
        self.spark = spark
    }
}

/// Stats: flat columns at least 96 pt wide (growing with the text, so a word never breaks; fewer columns per row then)
/// that wrap into rows, a 1 pt border line at the start of every column but the first, 12 pt inside; no fill, no
/// frame, no card. Label in caption text-muted over the value in title with tabular figures. One VoiceOver element per
/// stat (the sparkline has none: the number says it).
public struct SbStats: View {
    let items: [SbStatItem]
    private var context = SbContext()
    @ScaledMetric(relativeTo: .title) private var column: CGFloat = SebaroSpace.s12 * 2

    public init(_ items: [SbStatItem]) {
        precondition(!items.isEmpty, "SbStats: no stats")
        self.items = items
    }

    public var body: some View {
        SbColumnsLayout(minColumn: column, rowSpacing: SebaroSpace.s2) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                VStack(alignment: .leading, spacing: SebaroSpace.s0_5) {
                    Text(item.label).sbFont(.caption).foregroundStyle(context.tone.textMuted)
                    SbWrapRow(spacing: SebaroSpace.s3) {
                        Text(item.value).sbFont(.title).monospacedDigit().foregroundStyle(context.tone.text)
                        if let spark = item.spark, spark.count >= 2 { SbSparkline(spark) }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, index == 0 ? 0 : SebaroSpace.s3)
                .padding(.trailing, SebaroSpace.s3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .overlay(alignment: .leading) {
                    if index > 0 { Rectangle().fill(context.tone.border).frame(width: SebaroBorderWidth.hairline) }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// Equal columns of at least `minColumn` that wrap into rows (the web's `minmax(96px, 1fr)`).
struct SbColumnsLayout: Layout {
    let minColumn: CGFloat
    let rowSpacing: CGFloat

    private func grid(_ width: CGFloat, _ count: Int) -> (perRow: Int, column: CGFloat) {
        let perRow = min(max(Int(width / minColumn), 1), max(count, 1))
        return (perRow, width / CGFloat(perRow))
    }

    private func rowHeights(_ width: CGFloat, _ subviews: Subviews) -> [CGFloat] {
        let (perRow, column) = grid(width, subviews.count)
        return stride(from: 0, to: subviews.count, by: perRow).map { start in
            subviews[start..<min(start + perRow, subviews.count)]
                .map { $0.sizeThatFits(ProposedViewSize(width: column, height: nil)).height }.max() ?? 0
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? minColumn * CGFloat(subviews.count)
        let rows = rowHeights(width, subviews)
        return CGSize(width: width, height: rows.reduce(0, +) + rowSpacing * CGFloat(max(rows.count - 1, 0)))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let (perRow, column) = grid(bounds.width, subviews.count)
        let rows = rowHeights(bounds.width, subviews)
        var y = bounds.minY
        for (r, h) in rows.enumerated() {
            for k in 0..<perRow where r * perRow + k < subviews.count {
                subviews[r * perRow + k].place(at: CGPoint(x: bounds.minX + CGFloat(k) * column, y: y),
                                               proposal: ProposedViewSize(width: column, height: h))
            }
            y += h + rowSpacing
        }
    }
}

/// Sparkline (G3a): 96 × 28 pt, the line in `chartBar` (2 pt, round joins and caps), the last point a dot of radius
/// 3 pt in `chartBarCurrent`; no axis, hidden from VoiceOver. It never stands without its number (`SbStatItem.spark`).
public struct SbSparkline: View {
    let values: [Double]
    public init(_ values: [Double]) {
        precondition(values.count >= 2, "SbSparkline: at least two values")
        self.values = values
    }

    public var body: some View {
        Canvas { ctx, size in
            let lo = values.min()!, span = max(values.max()! - lo, .ulpOfOne)
            let dot: CGFloat = 3, inset = SebaroSpace.s1
            func at(_ i: Int) -> CGPoint {
                CGPoint(x: dot + (size.width - 2 * dot) * CGFloat(i) / CGFloat(values.count - 1),
                        y: inset + (size.height - 2 * inset) * (1 - CGFloat((values[i] - lo) / span)))
            }
            var line = Path()
            line.move(to: at(0))
            for i in 1..<values.count { line.addLine(to: at(i)) }
            ctx.stroke(line, with: .color(SebaroX.chartBar),
                       style: StrokeStyle(lineWidth: SebaroX.chartLineWidth, lineCap: .round, lineJoin: .round))
            let last = at(values.count - 1)
            ctx.fill(Path(ellipseIn: CGRect(x: last.x - dot, y: last.y - dot, width: 2 * dot, height: 2 * dot)),
                     with: .color(SebaroX.chartBarCurrent))
        }
        .frame(width: SebaroSpace.s12 * 2, height: SebaroSpace.s6 + SebaroSpace.s1)
        .accessibilityHidden(true)
    }
}

// MARK: - Charts (spec/02 §3.7; D91 G1a, G4b, G8a; spec/08 §14.10)

/// The frame of every chart (`figure.sb-chart`): `legend` above, the chart, then `caption` (what, unit, period;
/// „(Beispieldaten)“ on demo data) in caption text-muted, 12 pt apart. VoiceOver reads the caption first.
public struct SbChartFigure<Content: View, Legend: View>: View {
    let caption: String
    let legend: Legend
    let content: Content
    private var context = SbContext()

    public init(_ caption: String, @ViewBuilder legend: () -> Legend, @ViewBuilder content: () -> Content) {
        self.caption = caption
        self.legend = legend()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SebaroSpace.s3) {
            legend
            content
            SbWrapText(caption, style: .caption).foregroundStyle(context.tone.textMuted)
                .accessibilitySortPriority(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

public extension SbChartFigure where Legend == EmptyView {
    init(_ caption: String, @ViewBuilder content: () -> Content) {
        self.init(caption, legend: { EmptyView() }, content: content)
    }
}

/// A value on a chart's scale and its number as text: the target (8, "8" → „Ziel 8“) or a grid line.
public struct SbChartValue: Sendable {
    public let value: Double
    public let text: String
    public init(_ value: Double, text: String) {
        self.value = value
        self.text = text
    }
}

/// One bar (G1a): `label` under it (two-letter weekdays, spelled-out months), `value` its height, `valueText` its
/// number under the label; `current` = the current period (accent bar, title weight).
public struct SbBar: Sendable {
    public let label: String
    public let value: Double
    public let valueText: String
    public let current: Bool
    public init(_ label: String, value: Double, valueText: String, current: Bool = false) {
        self.label = label
        self.value = value
        self.valueText = valueText
        self.current = current
    }
}

/// Bars, one series (G1a): grey bars (`chartBar`), the current period in `chartBarCurrent`, on a 1 pt base line
/// (`chartAxis`) in a 128 pt plot under one caption line of head room. `grid` lines are 1 pt `chartGrid` with their
/// number after the plot; the `target` is 1 pt dashed text-muted with „Ziel n“ after the plot (both hidden from
/// VoiceOver: the caption names the target). Under each bar its label (text-muted) over its value (text); a label that
/// would touch the next is left out, read from the end (D99 (2)), its words stay for VoiceOver, which reads one
/// element per bar („Fr, 6“, the current one with „aktueller Zeitraum“). `max` = the top of the scale; bars start
/// at 0; all values 0 draw the empty chart (OR-5).
public struct SbBarChart: View {
    let bars: [SbBar]
    let caption: String
    let target: SbChartValue?
    let grid: [SbChartValue]
    let max: Double?
    private var context = SbContext()

    public init(_ bars: [SbBar], caption: String, target: SbChartValue? = nil, grid: [SbChartValue] = [],
                max: Double? = nil) {
        precondition(!bars.isEmpty, "SbBarChart: no bars")
        precondition(max.map { $0 > 0 } ?? true, "SbBarChart: the top of the scale must be above 0")
        self.bars = bars
        self.caption = caption
        self.target = target
        self.grid = grid
        self.max = max
    }

    public var body: some View {
        let m = context.messages
        let highest = ([bars.map(\.value).max() ?? 0, target?.value ?? 0] + grid.map(\.value)).max() ?? 0
        let top = max ?? (highest > 0 ? highest : 1)
        let ends = (target.map { [($0.value, m.chartTarget($0.text))] } ?? []) + grid.map { ($0.value, $0.text) }
        SbChartFigure(caption) {
            HStack(alignment: .top, spacing: SebaroSpace.s2) {
                VStack(spacing: SebaroSpace.s1) {
                    plot(top: top)
                        .padding(.top, SebaroSpace.s4)   // one caption line of head room
                        .frame(height: SebaroSpace.s16 * 2 + SebaroSpace.s4)
                    SbBarLabels(gap: SebaroSpace.s1) {
                        ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                            VStack(spacing: 0) {
                                Text(bar.label).foregroundStyle(bar.current ? context.tone.text : context.tone.textMuted)
                                Text(bar.valueText).foregroundStyle(context.tone.text)
                            }
                            .font(labelFont(current: bar.current)).monospacedDigit()
                            .lineLimit(1)
                            .fixedSize()
                        }
                    }
                    .accessibilityHidden(true)
                }
                if !ends.isEmpty {
                    SbChartEnds(ends: ends, top: top)
                        .padding(.top, SebaroSpace.s4)
                        .frame(height: SebaroSpace.s16 * 2 + SebaroSpace.s4)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func labelFont(current: Bool) -> Font {
        let caption = SebaroTextStyle.caption.resolve(context.scheme)
        guard current else { return SebaroFonts.font(caption, relativeTo: .caption, monospacedDigits: true) }
        let title = SebaroTextStyle.title.resolve(context.scheme)
        return SebaroFonts.font(SebaroTextFace(family: caption.family, size: caption.size, lineHeight: caption.lineHeight,
                                               weight: title.weight, weightValue: title.weightValue,
                                               tracking: caption.tracking),
                                relativeTo: .caption, monospacedDigits: true)
    }

    private func plot(top: Double) -> some View {
        let m = context.messages
        let muted = context.tone.textMuted
        return Canvas { ctx, size in
            let hair = SebaroBorderWidth.hairline
            func y(_ v: Double) -> CGFloat { size.height * (1 - CGFloat(Swift.min(Swift.max(v / top, 0), 1))) }
            for g in grid {
                ctx.fill(Path(CGRect(x: 0, y: y(g.value) - hair / 2, width: size.width, height: hair)),
                         with: .color(SebaroX.chartGrid))
            }
            let slot = size.width / CGFloat(bars.count), floor = size.height - hair
            for (i, b) in bars.enumerated() {
                let h = floor * CGFloat(Swift.min(Swift.max(b.value / top, 0), 1))
                ctx.fill(Path(CGRect(x: CGFloat(i) * slot + slot * 0.18, y: floor - h, width: slot * 0.64, height: h)),
                         with: .color(b.current ? SebaroX.chartBarCurrent : SebaroX.chartBar))
            }
            ctx.fill(Path(CGRect(x: 0, y: size.height - hair, width: size.width, height: hair)),
                     with: .color(SebaroX.chartAxis))
            if let target {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y(target.value)))
                line.addLine(to: CGPoint(x: size.width, y: y(target.value)))
                ctx.stroke(line, with: .color(muted),
                           style: StrokeStyle(lineWidth: hair, dash: [SebaroSpace.s1, SebaroSpace.s1]))
            }
        }
        .flipsForRightToLeftLayoutDirection(true)
        // one VoiceOver element per bar, over its slot (the labels under the plot are hidden)
        .overlay {
            HStack(spacing: 0) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                    Color.clear
                        .contentShape(Rectangle())
                        .accessibilityElement()
                        .accessibilityLabel(Text("\(bar.label), \(bar.valueText)"))
                        .accessibilityValue(Text(bar.current ? m.chartCurrent : ""))
                }
            }
        }
    }
}

/// The labels under the bars: each centred on its slot, moved back inside at the ends; read from the end, a label
/// stays when it ends at least `gap` before the next one shown (D99 (2)); one left out is placed outside and clipped.
struct SbBarLabels: Layout {
    let gap: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? 0,
               height: subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let slot = bounds.width / CGFloat(max(subviews.count, 1))
        var limit = CGFloat.greatestFiniteMagnitude
        for i in subviews.indices.reversed() {
            let size = subviews[i].sizeThatFits(.unspecified)
            let from = max(min(slot * (CGFloat(i) + 0.5) - size.width / 2, bounds.width - size.width), 0)
            if from + size.width <= limit {
                subviews[i].place(at: CGPoint(x: bounds.minX + from, y: bounds.minY), proposal: .unspecified)
                limit = from - gap
            } else {
                subviews[i].place(at: CGPoint(x: -100_000, y: bounds.minY), proposal: .unspecified)
            }
        }
    }
}

/// Labels after the plot (`sb-chart__ends`): each centred on its value, caption text-muted; the column is as wide as
/// its widest label (it grows with the text).
struct SbChartEnds: View {
    let ends: [(Double, String)]
    let top: Double
    @Environment(\.sebaroTone) private var tone
    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(ends.enumerated()), id: \.offset) { _, end in label(end.1).hidden() }
        }
        .frame(maxHeight: .infinity)
        .overlay {
            GeometryReader { geo in
                ForEach(Array(ends.enumerated()), id: \.offset) { _, end in
                    label(end.1)
                        .frame(width: geo.size.width, alignment: .leading)
                        .position(x: geo.size.width / 2,
                                  y: geo.size.height * (1 - CGFloat(min(max(end.0 / top, 0), 1))))
                }
            }
        }
    }
    private func label(_ text: String) -> some View {
        Text(text).sbFont(.caption).monospacedDigit().foregroundStyle(tone.textMuted).lineLimit(1).fixedSize()
    }
}

/// One row of a share chart (G4b): `name` and `valueText` as text, `value` the length of the fill on the scale;
/// `current` = the current period. `expected` (D105 (34)): the expected count on the same scale, a thin text-muted line
/// across the bar, `expectedText` its value as VoiceOver reads it.
public struct SbShareRow: Sendable {
    public let name: String
    public let value: Double
    public let valueText: String
    public let current: Bool
    public let expected: Double?
    public let expectedText: String?
    public init(_ name: String, value: Double, valueText: String, current: Bool = false, expected: Double? = nil,
                expectedText: String? = nil) {
        self.name = name
        self.value = value
        self.valueText = valueText
        self.current = current
        self.expected = expected
        self.expectedText = expectedText
    }
}

/// Shares as labelled rows (G4b, `sb-chart__rows`): per row the name in caption with its value at the label weight,
/// in a column of 128 pt (growing with the text, the web's 8rem), then a 12 pt bar: the fill (`chartBar`,
/// `chartBarCurrent`) on the track (`surfaceSunken`) when `track`. `total` is the whole. A row with `expected` gets a
/// 2 pt text-muted line at that value, 4 pt past the bar above and below, with a 1 pt `bg` joint on both sides, and
/// „erwartet“ stands once in a legend under the rows (D105 (34), D106 (13)). At the accessibility sizes the bar goes
/// under its name. One VoiceOver element per row („Gesundheit 42, erwartet 30“).
public struct SbShareRows: View {
    let rows: [SbShareRow]
    let caption: String
    let total: Double
    let track: Bool
    private var context = SbContext()
    @ScaledMetric(relativeTo: .caption) private var nameWidth: CGFloat = SebaroSpace.s16 * 2
    @Environment(\.dynamicTypeSize) private var typeSize

    public init(_ rows: [SbShareRow], caption: String, total: Double = 100, track: Bool = true) {
        precondition(!rows.isEmpty, "SbShareRows: no rows")
        precondition(total > 0, "SbShareRows: the whole must be above 0")
        self.rows = rows
        self.caption = caption
        self.total = total
        self.track = track
    }

    public var body: some View {
        let m = context.messages
        let marked = rows.contains { $0.expected != nil }
        let stacked = typeSize.isAccessibilitySize
        SbChartFigure(caption) {
            VStack(alignment: .leading, spacing: SebaroSpace.s2) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, r in
                    let layout = stacked ? AnyLayout(VStackLayout(alignment: .leading, spacing: SebaroSpace.s1))
                                         : AnyLayout(HStackLayout(spacing: SebaroSpace.s3))
                    layout {
                        (Text(r.name + " ") + Text(r.valueText).font(SebaroTextStyle.label.exactFont(for: context.scheme)).monospacedDigit())
                            .sbFont(.caption).foregroundStyle(context.tone.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: stacked ? nil : nameWidth, alignment: .leading)
                        SbShareBar(row: r, total: total, track: track, marked: marked)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(r.expected != nil
                        ? "\(r.name) \(r.valueText), \(m.chartExpected) \(r.expectedText ?? "")" : "\(r.name) \(r.valueText)"))
                }
                if marked {
                    HStack(spacing: SebaroSpace.s2) {
                        Rectangle().fill(context.tone.textMuted).frame(width: SebaroSpace.s0_5, height: SebaroSpace.s5)
                        Text(m.chartExpected).sbFont(.caption).foregroundStyle(context.tone.textMuted)
                    }
                    .accessibilityHidden(true)
                }
            }
        }
    }
}

struct SbShareBar: View {
    let row: SbShareRow
    let total: Double
    let track: Bool
    let marked: Bool
    @Environment(\.sebaroTone) private var tone

    var body: some View {
        let bg = tone.bg, sunken = tone.surfaceSunken, muted = tone.textMuted
        Canvas { ctx, size in
            let bar = SebaroSpace.s3, top = (size.height - bar) / 2
            if track { ctx.fill(Path(CGRect(x: 0, y: top, width: size.width, height: bar)), with: .color(sunken)) }
            let w = size.width * CGFloat(min(max(row.value / total, 0), 1))
            ctx.fill(Path(CGRect(x: 0, y: top, width: w, height: bar)),
                     with: .color(row.current ? SebaroX.chartBarCurrent : SebaroX.chartBar))
            if let e = row.expected {
                let line = SebaroSpace.s0_5, joint = SebaroBorderWidth.hairline
                let x = size.width * CGFloat(min(max(e / total, 0), 1)) - line / 2
                ctx.fill(Path(CGRect(x: x - joint, y: top, width: line + 2 * joint, height: bar)), with: .color(bg))
                ctx.fill(Path(CGRect(x: x, y: top - SebaroSpace.s1, width: line, height: bar + 2 * SebaroSpace.s1)),
                         with: .color(muted))
            }
        }
        .flipsForRightToLeftLayoutDirection(true)
        .frame(maxWidth: .infinity)
        .frame(height: marked ? SebaroSpace.s5 : SebaroSpace.s3)
    }
}

/// Goal ring (G8a): 112 pt (growing with the text inside it; when that is wider than the room, the ring takes the room's
/// width and the count stands under it), one arc per unit (1 to 12) on a 48 pt radius with 9°
/// gaps, clockwise from twelve o'clock; done parts in text 8 pt, open parts in border-strong 2 pt, butt caps. In the
/// middle the count in title over „von 8“ in caption text-muted, then `caption` under the ring; `reached` adds
/// `SbStatus(.success, „erreicht“)` below (no green in the ring). One VoiceOver element.
public struct SbGoalRing: View {
    let done: Int
    let total: Int
    let caption: String
    let reached: Bool
    private var context = SbContext()
    @ScaledMetric(relativeTo: .title) private var scale: CGFloat = 1

    public init(done: Int, total: Int, caption: String, reached: Bool? = nil) {
        precondition((1...12).contains(total), "SbGoalRing: 1 to 12 units (G8a); above 12 use SbShareRows")
        self.done = done
        self.total = total
        self.caption = caption
        self.reached = reached ?? (done >= total)
    }

    public var body: some View {
        let m = context.messages
        let full = (SebaroSpace.s16 + SebaroSpace.s12) * scale
        VStack(spacing: SebaroSpace.s2) {
            // the ring with the count inside while it fits the width offered; else a ring as wide as the room,
            // with the count under it (no fixed width wider than the room at any text size)
            ViewThatFits(in: .horizontal) {
                ZStack { ring; count }.frame(width: full, height: full)
                VStack(spacing: SebaroSpace.s2) {
                    ring.aspectRatio(1, contentMode: .fit).frame(maxWidth: full)
                    count
                }
            }
            Text(caption).sbFont(.caption).foregroundStyle(context.tone.textMuted).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if reached { SbStatus(.success, word: m.goalReached) }
        }
        .accessibilityElement(children: .combine)
    }

    /// The arcs, drawn to the square they get: the 48 pt radius and the 8 / 2 pt strokes of a 112 pt ring, scaled.
    private var ring: some View {
        let text = context.tone.text, open = context.tone.borderStrong
        let done = done, total = total
        return Canvas { ctx, size in
            let unitScale = min(size.width, size.height) / (SebaroSpace.s16 + SebaroSpace.s12)
            let r = SebaroSpace.s12 * unitScale
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let unit = 360 / Double(total), gap = 9.0
            for i in 0..<total {
                var arc = Path()
                arc.addArc(center: c, radius: r, startAngle: .degrees(-90 + Double(i) * unit + gap / 2),
                           endAngle: .degrees(-90 + Double(i + 1) * unit - gap / 2), clockwise: false)
                ctx.stroke(arc, with: .color(i < done ? text : open),
                           style: StrokeStyle(lineWidth: (i < done ? 8 : 2) * unitScale, lineCap: .butt))
            }
        }
    }

    private var count: some View {
        let locale = context.currentLocale
        return VStack(spacing: 0) {
            Text(SbMessages.formatCount(done, locale: locale)).sbFont(.title).monospacedDigit()
            Text(context.messages.goalOf(SbMessages.formatCount(total, locale: locale))).sbFont(.caption).monospacedDigit()
                .foregroundStyle(context.tone.textMuted)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(context.tone.text)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Progress (spec/02 §3.12; D85; spec/08 §14.20)

/// Linear progress for remote work over 1 s: `label` in text and `valueText` („60 %“) in text-muted on one caption
/// line with tabular figures, 4 pt above a 4 pt bar: `fraction` (0…1) in text on a border track from the start edge,
/// square ends, no gap and no stop dot (D85). One VoiceOver element: the label with the value.
public struct SbProgressBar: View {
    let fraction: Double
    let label: String
    let valueText: String
    private var context = SbContext()

    public init(_ fraction: Double, label: String, valueText: String) {
        self.fraction = fraction
        self.label = label
        self.valueText = valueText
    }

    public var body: some View {
        let share = min(max(fraction, 0), 1)
        VStack(alignment: .leading, spacing: SebaroSpace.s1) {
            HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s3) {
                Text(label).foregroundStyle(context.tone.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(valueText).foregroundStyle(context.tone.textMuted)
            }
            .sbFont(.caption).monospacedDigit()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(context.tone.border)
                    Rectangle().fill(context.tone.text).frame(width: geo.size.width * share)
                }
            }
            .frame(height: SebaroSpace.s1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(valueText))
    }
}

/// Ring progress for loading with a known share: 48 pt, a 4 pt ring on a 20 pt radius, `fraction` in text clockwise
/// from twelve o'clock on a border track, butt caps (D85), `valueText` in label-small in the middle; ring and stroke
/// grow with the text (D99 (2)), never stretched. Not the goal ring. One VoiceOver element: `label` with the value.
public struct SbProgressRing: View {
    let fraction: Double
    let label: String
    let valueText: String
    private var context = SbContext()
    @ScaledMetric(relativeTo: .caption) private var scale: CGFloat = 1

    public init(_ fraction: Double, label: String, valueText: String) {
        self.fraction = fraction
        self.label = label
        self.valueText = valueText
    }

    public var body: some View {
        let share = min(max(fraction, 0), 1)
        let stroke = SebaroSpace.s1 * scale
        let track = context.tone.border, ink = context.tone.text
        SbRingLayout(scale: scale) {
            Text(valueText).sbFont(.labelSmall).monospacedDigit().foregroundStyle(context.tone.text)
                .lineLimit(1).fixedSize()
        }
        .background {
            Canvas { ctx, size in
                let r = min(size.width, size.height) / 2 - stroke
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                           with: .color(track), lineWidth: stroke)
                var arc = Path()
                arc.addArc(center: c, radius: r, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * share),
                           clockwise: false)
                ctx.stroke(arc, with: .color(ink), style: StrokeStyle(lineWidth: stroke, lineCap: .butt))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(valueText))
    }
}

/// The square of the progress ring: 48 pt × the text scale, larger until the corners of the value's figures (0.72 of
/// the label-small size high) keep 2 pt from the ring's inner edge („100 %“); box = inner diameter + 3 strokes.
struct SbRingLayout: Layout {
    let scale: CGFloat

    private func edge(_ subviews: Subviews) -> CGFloat {
        let value = subviews.first?.sizeThatFits(.unspecified) ?? .zero
        let figures = SebaroTextStyle.labelSmall.resolve(.light).size * scale * 0.72
        let inner = hypot(value.width / 2, figures / 2) + SebaroSpace.s0_5 * scale
        return max(SebaroSpace.s12 * scale, (2 * inner + 3 * SebaroSpace.s1 * scale).rounded(.up) + 1)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let e = edge(subviews)
        return CGSize(width: e, height: e)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: .unspecified)
    }
}

// MARK: - Rating and signed number (spec/02 §3.20, §3.1b; D82, D73, D91 C3a)

/// Rating: one filled star (20 pt, in text), the value with its reference in body-strong („4,2 von 5“, one decimal
/// in the screen's language) and „· 38 Bewertungen“ in body text-muted, tabular, 4 pt apart; the count wraps under the
/// value. Never five stars, half stars or a yellow star. One VoiceOver element „Bewertung: 4,2 von 5, 38 Bewertungen“.
public struct SbRating: View {
    let value: Double
    let count: Int
    let max: Int
    private var context = SbContext()

    public init(_ value: Double, count: Int, max: Int = 5) {
        self.value = value
        self.count = count
        self.max = max
    }

    public var body: some View {
        let m = context.messages, locale = context.currentLocale
        let number = value.formatted(.number.precision(.fractionLength(1)).locale(locale))
        let of = m.ratingOf(number, SbMessages.formatCount(max, locale: locale))
        let counted = m.ratingCount(count, SbMessages.formatCount(count, locale: locale))
        SbWrapRow(spacing: SebaroSpace.s1) {
            SbIcon("star--filled", size: SebaroSize.iconMd, color: context.tone.text)
            Text(of).sbFont(.bodyStrong).monospacedDigit().foregroundStyle(context.tone.text)
            Text("· \(counted)").sbFont(.body).monospacedDigit().foregroundStyle(context.tone.textMuted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(m.ratingLabel + of + ", " + counted))
    }
}

/// The direction of a signed number (D91 C3a): plus, minus, or zero („±0“).
public enum SbSign: Sendable { case plus, minus, zero }

/// Signed number (D73, D91 C3a) for number apps: `text` with its sign („+3“, „−12 %“ with U+2212, „±0“), the 16 pt
/// arrow up or down before it; plus in success, minus in danger, zero without an arrow in text. Body-strong weight,
/// tabular, one line. The colour says the direction, never whether it is good.
public struct SbSignedNumber: View {
    let text: String
    let sign: SbSign
    private var context = SbContext()

    public init(_ text: String, sign: SbSign) {
        self.text = text
        self.sign = sign
    }

    public var body: some View {
        let color: Color = switch sign {
        case .plus: .sbSuccess
        case .minus: .sbDanger
        case .zero: context.tone.text
        }
        HStack(spacing: SebaroSpace.s1) {
            switch sign {
            case .plus: SbIcon("arrow-up--16", size: SebaroSize.iconSm, color: color)
            case .minus: SbIcon("arrow-down--16", size: SebaroSize.iconSm, color: color)
            case .zero: EmptyView()
            }
            Text(text).sbFont(.bodyStrong).monospacedDigit().foregroundStyle(color).lineLimit(1).fixedSize()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - File names (D100 (6), D101 (6); spec/08 §16)

/// A file name as it may break (D100 (6), D101 (6)): a zero-width space after - . _ /, so it breaks only there and
/// without a hyphen; never after the dot of a short extension („.csv“, spec/08 §16), inside a run of separators or after
/// the separators it begins with. Identifiers („DAT-02“, „1.4.0“) stay plain text. Put the result into a `Text`, and
/// give VoiceOver the plain name (`SbFileNameText` does both).
public func sbFileNameBreaks(_ name: String) -> String {
    let chars = Array(name)
    let separators: Set<Character> = ["-", ".", "_", "/"]
    var dot = -1
    if let last = chars.lastIndex(of: "."), last > 0 {
        let ext = chars[(last + 1)...]
        if (1...4).contains(ext.count) && ext.allSatisfy({ $0.isLetter || $0.isNumber }) { dot = last }
    }
    var out = ""
    for (i, ch) in chars.enumerated() {
        out.append(ch)
        guard separators.contains(ch), i < chars.count - 1, i != dot, !separators.contains(chars[i + 1]),
              chars[..<i].contains(where: { !separators.contains($0) }) else { continue }
        out.append("\u{200B}")
    }
    return out
}

/// A file name in a text role that breaks only after - . _ / (`sbFileNameBreaks`); VoiceOver reads the name as written.
public struct SbFileNameText: View {
    let name: String
    let style: SebaroTextStyle
    public init(_ name: String, style: SebaroTextStyle = .body) {
        self.name = name
        self.style = style
    }
    public var body: some View {
        Text(sbFileNameBreaks(name)).sbFont(style)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(Text(name))
    }
}

// MARK: - Sortable table (spec/02 §3.9; D91 B5a, B6a, D101 (3), (4); spec/08 §14.30)

/// What a column holds and how it sorts.
public enum SbColumnKind: Sendable { case text, number, date }

public struct SbTableColumn: Sendable {
    public let title: String
    public let kind: SbColumnKind
    public let sortable: Bool
    public init(_ title: String, kind: SbColumnKind = .text, sortable: Bool = true) {
        self.title = title
        self.kind = kind
        self.sortable = sortable
    }
}

/// A cell: `text` as shown („1.250,00 €“, „keine Angabe“); a number column sorts by `number`, a date column by `date`;
/// nil = no value, which sorts last in both directions (D82). A text column sorts by `text`; blank = no value.
public struct SbTableCell: Sendable {
    public let text: String
    public let number: Double?
    public let date: Date?
    public init(_ text: String, number: Double? = nil, date: Date? = nil) {
        self.text = text
        self.number = number
        self.date = date
    }
}

/// The sum row (D91 B6a): `label` before the first sum; `values` maps a column index to its sum. Always last.
public struct SbTableSum: Sendable {
    public let label: String
    public let values: [Int: String]
    public init(_ label: String, values: [Int: String]) {
        self.label = label
        self.values = values
    }
}

/// The order of `rows` by column `index` as sb-table.js sorts: numbers and dates by value, words by the locale's
/// collation (numeric, base letters), a cell without a value last in both directions, equal rows in their order.
public func sbTableOrder(_ rows: [[SbTableCell]], column index: Int, kind: SbColumnKind, descending: Bool,
                         locale: Locale) -> [Int] {
    func compare(_ a: SbTableCell, _ b: SbTableCell) -> ComparisonResult? {
        switch kind {
        case .number:
            guard let x = a.number, let y = b.number else { return nil }
            return x < y ? .orderedAscending : (x > y ? .orderedDescending : .orderedSame)
        case .date:
            guard let x = a.date, let y = b.date else { return nil }
            return x.compare(y)
        case .text:
            let x = a.text.trimmingCharacters(in: .whitespaces), y = b.text.trimmingCharacters(in: .whitespaces)
            guard !x.isEmpty, !y.isEmpty else { return nil }
            return x.compare(y, options: [.caseInsensitive, .diacriticInsensitive, .numeric], locale: locale)
        }
    }
    func hasValue(_ c: SbTableCell) -> Bool {
        switch kind {
        case .number: c.number != nil
        case .date: c.date != nil
        case .text: !c.text.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    return rows.indices.sorted { i, j in
        let a = rows[i][index], b = rows[j][index]
        switch (hasValue(a), hasValue(b)) {
        case (true, false): return true
        case (false, true): return false
        case (false, false): return i < j
        case (true, true):
            let r = compare(a, b) ?? .orderedSame
            if r == .orderedSame { return i < j }
            return descending ? r == .orderedDescending : r == .orderedAscending
        }
    }
}

/// Sortable table: `caption` above it (caption text-muted), the heads (label; a sortable head a 48 pt button, the
/// sorted one in the title weight with the 16 pt arrow, before the word in a number column), a border-strong line
/// under them, then the rows (body; `rowHeads` = the first cell in body-strong; numbers end-aligned, tabular; 12 pt
/// around, a border hairline under each row), then `sum`. The table sorts by `sortIndex` (nil = the order given) and
/// `sortDescending`; a press calls `onSort` with the new column and direction (the same head turns round; another
/// sorts numbers and dates descending, words ascending first). Columns take their text's width; when they do not fit,
/// the table scrolls sideways inside its own frame, never the screen. VoiceOver: the sorted head's value is
/// „Sortiert nach <Spalte>, absteigend“.
public struct SbSortableTable: View {
    let caption: String
    let columns: [SbTableColumn]
    let rows: [[SbTableCell]]
    let sortIndex: Int?
    let sortDescending: Bool
    let rowHeads: Bool
    let sum: SbTableSum?
    let onSort: (Int, Bool) -> Void
    private var context = SbContext()

    public init(_ caption: String, columns: [SbTableColumn], rows: [[SbTableCell]], sortIndex: Int? = nil,
                sortDescending: Bool = false, rowHeads: Bool = false, sum: SbTableSum? = nil,
                onSort: @escaping (_ column: Int, _ descending: Bool) -> Void) {
        precondition(rows.allSatisfy { $0.count == columns.count }, "SbSortableTable: one cell per column")
        self.caption = caption
        self.columns = columns
        self.rows = rows
        self.sortIndex = sortIndex
        self.sortDescending = sortDescending
        self.rowHeads = rowHeads
        self.sum = sum
        self.onSort = onSort
    }

    public var body: some View {
        let order = sortIndex.map { sbTableOrder(rows, column: $0, kind: columns[$0].kind, descending: sortDescending,
                                                  locale: context.currentLocale) } ?? Array(rows.indices)
        VStack(alignment: .leading, spacing: SebaroSpace.s2) {
            Text(caption).sbFont(.caption).foregroundStyle(context.tone.textMuted)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                grid(order)
                ScrollView(.horizontal) { grid(order).padding(.horizontal, SebaroSpace.s2) }
                    .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private func alignment(_ k: Int) -> Alignment { columns[k].kind == .number ? .trailing : .leading }

    private func grid(_ order: [Int]) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                ForEach(columns.indices, id: \.self) { k in head(k).gridColumnAlignment(alignment(k).horizontal) }
            }
            Rectangle().fill(context.tone.borderStrong).frame(height: SebaroBorderWidth.control)
                .gridCellUnsizedAxes(.horizontal)
            ForEach(order, id: \.self) { r in
                GridRow {
                    ForEach(columns.indices, id: \.self) { k in
                        let cell = rows[r][k]
                        Text(cell.text)
                            .sbFont(rowHeads && k == 0 ? .bodyStrong : .body)
                            .monospacedDigit()
                            .foregroundStyle(context.tone.text)
                            .multilineTextAlignment(columns[k].kind == .number ? .trailing : .leading)
                            .fixedSize()
                            .padding(SebaroSpace.s3)
                    }
                }
                Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline)
                    .gridCellUnsizedAxes(.horizontal)
            }
            if let sum {
                let first = sum.values.keys.min() ?? columns.count
                GridRow {
                    ForEach(columns.indices, id: \.self) { k in
                        Group {
                            if k == 0 && first > 0 {
                                Text(sum.label)
                            } else if let v = sum.values[k] {
                                Text(v)
                            } else {
                                Text("")
                            }
                        }
                        .sbFont(.bodyStrong).monospacedDigit().foregroundStyle(context.tone.text)
                        .fixedSize()
                        .padding(SebaroSpace.s3)
                    }
                }
            }
        }
    }

    @ViewBuilder private func head(_ k: Int) -> some View {
        let column = columns[k]
        let sorted = sortIndex == k
        let label = HStack(spacing: SebaroSpace.s1) {
            if sorted && column.kind == .number { arrow }
            Text(column.title).font(headFont(sorted: sorted)).foregroundStyle(context.tone.text)
                .fixedSize()
            if sorted && column.kind != .number { arrow }
        }
        if column.sortable {
            Button {
                if sorted { onSort(k, !sortDescending) } else { onSort(k, column.kind != .text) }
            } label: {
                label.padding(.horizontal, SebaroSpace.s3)
                    .frame(minHeight: SebaroSize.targetTouch)
                    .contentShape(Rectangle())
            }
            .buttonStyle(SbRowButtonStyle())
            .accessibilityValue(Text(sorted ? context.messages.tableSorted(column.title, sortDescending) : ""))
            .accessibilityAddTraits(.isHeader)
        } else {
            label.padding(.horizontal, SebaroSpace.s3).frame(minHeight: SebaroSize.targetTouch)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var arrow: some View {
        SbIcon(sortDescending ? "arrow-down--16" : "arrow-up--16", size: SebaroSize.iconSm, color: context.tone.text)
            .accessibilityHidden(true)
    }

    private func headFont(sorted: Bool) -> Font {
        let label = SebaroTextStyle.label.resolve(context.scheme)
        let weight = sorted ? SebaroTextStyle.title.resolve(context.scheme) : label
        return SebaroFonts.font(SebaroTextFace(family: label.family, size: label.size, lineHeight: label.lineHeight,
                                               weight: weight.weight, weightValue: weight.weightValue,
                                               tracking: label.tracking),
                                relativeTo: .subheadline, monospacedDigits: false)
    }
}
