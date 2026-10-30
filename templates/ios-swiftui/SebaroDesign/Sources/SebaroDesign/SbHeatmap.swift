import SwiftUI

// MARK: - Heatmap (G6a, D93, D99 (7), D104 (21); spec/02 §3.7, spec/08 §14.25)

/// One class of a classed scale (spec/01 §8.1): values from `from` on, up to the next class; `label` its range.
public struct SbScaleClass: Sendable {
    public let from: Double
    public let label: String
    public init(from: Double, label: String) {
        self.from = from
        self.label = label
    }
}

/// One day of a heatmap: `day` spelled out („Mittwoch, 21.10.“), `value` (nil = keine Angabe), `valueText` the value
/// with its unit („7 Gläser“), `today` = the cobalt frame of D93.
public struct SbHeatmapDay: Sendable {
    public let day: String
    public let value: Double?
    public let valueText: String
    public let today: Bool
    public init(_ day: String, value: Double?, valueText: String = "", today: Bool = false) {
        self.day = day
        self.value = value
        self.valueText = valueText
        self.today = today
    }
}

/// One week row: `start` = its first date („28.09.“, shown „ab 28.09.“), `days` one per weekday head, nil = to come.
public struct SbHeatmapWeek: Sendable {
    public let start: String
    public let days: [SbHeatmapDay?]
    public init(start: String, days: [SbHeatmapDay?]) {
        self.start = start
        self.days = days
    }
}

/// The heatmap's state without a view: the days in reading order, the class of a value, the day the read-out shows
/// (VoiceOver focus first, else the last tap) and the same weekday a week on.
public struct SbHeatmapModel: Sendable {
    public let weeks: [SbHeatmapWeek]
    public let classes: [SbScaleClass]
    /// index[w][d] = the day's place in reading order, -1 for a day still to come.
    public let index: [[Int]]
    public let days: [SbHeatmapDay]
    public var focused: Int?
    public var tapped: Int?

    public init(weeks: [SbHeatmapWeek], classes: [SbScaleClass]) {
        self.weeks = weeks
        self.classes = classes
        var n = 0
        index = weeks.map { w in w.days.map { d -> Int in
            guard d != nil else { return -1 }
            defer { n += 1 }
            return n
        } }
        days = weeks.flatMap { $0.days.compactMap { $0 } }
    }

    /// The class of a value: the last whose `from` it reaches, the first below every class.
    public func classOf(_ value: Double) -> Int {
        max(classes.lastIndex { $0.from <= value } ?? 0, 0)
    }

    /// The day the read-out names: the focused one, else the tapped one, else none (the hint).
    public var shown: Int? { focused ?? tapped }

    /// The same weekday `dir` weeks on (±1), skipping days still to come; nil at the first or last week.
    public func sameWeekday(week w: Int, day d: Int, dir: Int) -> Int? {
        var row = w + dir
        while index.indices.contains(row) {
            if index[row][d] >= 0 { return index[row][d] }
            row += dir
        }
        return nil
    }
}

/// Heatmap (G6a, spec/02 §3.7): the legend above with the range of every class, „keine Angabe“ and „Rahmen: heute“;
/// weekday heads over one row per week; square cells 6 pt apart in the classes of `SebaroDataviz.sequential` (no
/// number on the fill); a day without a value is the empty cell with a 1 pt `borderStrong` frame; today is the 4 pt
/// accent frame on the cell's edge with a 1 pt `bg` joint inside (D93). One VoiceOver sentence per day („Mittwoch,
/// 21.10., heute: 7 Gläser“); the read-out under the grid shows the VoiceOver-focused or tapped day, else `hint`
/// (D99 (7)). The weekday heads keep their two letters (D82); when one does not fit its column every second head is
/// left out (D104 (21)). The week head („ab 28.09.“) wraps between words (D99 (1)) in a column of at most 30 % of the
/// width. `legendLabel` names the legend for VoiceOver („Legende, Gläser je Tag“; the legend is then one element).
public struct SbHeatmap: View {
    let caption: String
    let hint: String?
    let weekdays: [String]?
    let legendLabel: String?
    // the data is a plain property, so new weeks or classes show with the same view identity; only the focused and
    // the tapped day are state
    let data: SbHeatmapModel
    @State private var tapped: Int?
    @AccessibilityFocusState private var focus: Int?
    private var context = SbContext()
    @ScaledMetric(relativeTo: .body) private var rem: CGFloat = 1

    public init(_ weeks: [SbHeatmapWeek], classes: [SbScaleClass], caption: String, hint: String? = nil,
                weekdays: [String]? = nil, legendLabel: String? = nil) {
        precondition((1...SebaroDataviz.sequential.count).contains(classes.count), "SbHeatmap: 1 to 4 classes (spec/01 §8.1)")
        precondition(zip(classes, classes.dropFirst()).allSatisfy { $0.from < $1.from }, "SbHeatmap: the classes must rise")
        precondition(weeks.allSatisfy { $0.days.count == (weekdays?.count ?? 7) }, "SbHeatmap: one entry per weekday head")
        self.caption = caption
        self.hint = hint
        self.weekdays = weekdays
        self.legendLabel = legendLabel
        self.data = SbHeatmapModel(weeks: weeks, classes: classes)
    }

    /// The model with the current focus and tap; a tap on a day that is gone with new data counts as none.
    private var model: SbHeatmapModel {
        var m = data
        m.focused = focus.flatMap { m.days.indices.contains($0) ? $0 : nil }
        m.tapped = tapped.flatMap { m.days.indices.contains($0) ? $0 : nil }
        return m
    }

    private func sentence(_ d: SbHeatmapDay) -> String {
        let m = context.messages
        return m.chartDay(d.day, d.value == nil ? m.noValue : d.valueText, d.today)
    }

    public var body: some View {
        let m = context.messages
        let heads = weekdays ?? m.weekdays
        let gap = SebaroSpace.s1 + SebaroSpace.s0_5
        let font = sbChartLabelFont(context.scheme)
        SbChartFigure(caption, legend: { legend }) {
            VStack(alignment: .leading, spacing: gap) {
                SbHeatmapGrid(headWidth: (SebaroSpace.s16 + SebaroSpace.s2) * rem, gap: gap, columns: heads.count) {
                    ForEach(Array(heads.enumerated()), id: \.offset) { _, h in
                        Text(h).font(font).foregroundStyle(context.tone.textMuted).lineLimit(1).fixedSize()
                    }
                    ForEach(Array(model.weeks.enumerated()), id: \.offset) { w, week in
                        SbWrapText(m.weekFrom(week.start)).font(font).foregroundStyle(context.tone.textMuted)
                        ForEach(Array(week.days.enumerated()), id: \.offset) { d, day in
                            cell(day, k: model.index[w][d])
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                // the web's 26rem less its outer gaps
                .frame(maxWidth: (SebaroSpace.s16 * 6 + SebaroSpace.s8) * rem - 2 * gap, alignment: .leading)
                Text(model.shown.map { sentence(model.days[$0]) } ?? hint ?? m.heatmapHint)
                    .font(font).foregroundStyle(context.tone.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder private func cell(_ day: SbHeatmapDay?, k: Int) -> some View {
        if let day {
            SbScaleCell(fill: day.value.map { SebaroDataviz.sequential[model.classOf($0)] },
                        frame: day.value == nil, today: day.today)
                .contentShape(Rectangle())
                .onTapGesture { tapped = k }
                .accessibilityElement()
                .accessibilityLabel(Text(sentence(day)))
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { tapped = k }
                .accessibilityFocused($focus, equals: k)
        } else {
            Color.clear.accessibilityHidden(true)
        }
    }

    private var legend: some View {
        let m = context.messages
        let keys = model.classes.map(\.label) + [m.noValue, m.todayKey]
        return SbWrapRow(spacing: SebaroSpace.s4) {
            ForEach(Array(model.classes.enumerated()), id: \.offset) { i, c in
                key(c.label) { SbScaleCell(fill: SebaroDataviz.sequential[i], frame: false, today: false) }
            }
            key(m.noValue) { SbScaleCell(fill: nil, frame: true, today: false) }
            key(m.todayKey) { SbScaleCell(fill: nil, frame: false, today: true) }
        }
        .modifier(SbLegendName(name: legendLabel.map { ([$0] + keys).joined(separator: ", ") }))
    }

    private func key(_ label: String, @ViewBuilder swatch: () -> some View) -> some View {
        HStack(spacing: SebaroSpace.s2) {
            swatch().frame(width: SebaroSize.iconSm, height: SebaroSize.iconSm)
            Text(label).font(sbChartLabelFont(context.scheme)).foregroundStyle(context.tone.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct SbLegendName: ViewModifier {
    let name: String?
    func body(content: Content) -> some View {
        if let name { content.accessibilityElement(children: .ignore).accessibilityLabel(Text(name)) } else { content }
    }
}

/// One scale cell or swatch: `fill` (a class colour), else the 1 pt frame of „keine Angabe“; with `today` the 4 pt
/// accent frame (strong + hairline) on the edge, rounded like the cell, and the 1 pt `bg` joint inside it (D93).
struct SbScaleCell: View {
    let fill: Color?
    let frame: Bool
    let today: Bool
    @Environment(\.sebaroTone) private var tone

    var body: some View {
        let r = SebaroRadius.small, hair = SebaroBorderWidth.hairline, f = SebaroBorderWidth.strong + hair
        ZStack {
            if let fill {
                RoundedRectangle(cornerRadius: r, style: .continuous).fill(fill)
            } else if frame && !today {
                RoundedRectangle(cornerRadius: r, style: .continuous).strokeBorder(tone.borderStrong, lineWidth: hair)
            }
            if today {
                RoundedRectangle(cornerRadius: r, style: .continuous).strokeBorder(Color.sbAccent, lineWidth: f)
                Rectangle().strokeBorder(tone.bg, lineWidth: hair).padding(f)
            }
        }
    }
}

/// The heatmap's grid: the weekday heads (subviews 0 ..< columns), then per week its head and its days. The week head
/// column is `headWidth` but at most 30 % of the width; cells are square, `gap` apart. A head centred over its cell
/// stays whole; once a head is wider than its column (cell + gap) only every second head stands („Mo Mi Fr So“; see
/// `headStep`), and the last shown head is moved back to end with the grid.
struct SbHeatmapGrid: Layout {
    let headWidth: CGFloat
    let gap: CGFloat
    let columns: Int

    private func metrics(_ width: CGFloat) -> (head: CGFloat, cell: CGFloat) {
        let head = min(headWidth, width * 0.3)
        return (head, max((width - head - CGFloat(columns) * gap) / CGFloat(columns), 0))
    }

    private func rows(_ width: CGFloat, _ s: Subviews) -> (headH: CGFloat, weekH: [CGFloat]) {
        let m = metrics(width)
        let headH = (0..<columns).map { s[$0].sizeThatFits(.unspecified).height }.max() ?? 0
        let weeks = (s.count - columns) / (columns + 1)
        let weekH = (0..<weeks).map { w in
            max(m.cell, s[columns + w * (columns + 1)].sizeThatFits(ProposedViewSize(width: m.head, height: nil)).height)
        }
        return (headH, weekH)
    }

    /// Which heads stand: every one while the widest fits its column (cell + gap), else every second („Mo Mi Fr So“,
    /// D104 (21)), and when even that does not fit (AX5 on a 320 pt phone) every third, and so on (*provisional,
    /// agent*: D104 (21) names only every second). A head stays whole and is never broken (D82).
    static func headStep(widest: CGFloat, column: CGFloat, count: Int) -> Int {
        guard column > 0 else { return max(count, 1) }
        var step = 1
        while step < count && widest > CGFloat(step) * column - (step > 1 ? SebaroSpace.s1 : 0) { step += 1 }
        return step
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? SbLinePlotLayout.fallback
        let r = rows(w, subviews)
        return CGSize(width: w, height: r.headH + r.weekH.reduce(0) { $0 + gap + $1 })
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let m = metrics(bounds.width)
        let r = rows(bounds.width, subviews)
        let widths = (0..<columns).map { subviews[$0].sizeThatFits(.unspecified).width }
        let step = Self.headStep(widest: widths.max() ?? 0, column: m.cell + gap, count: columns)
        for i in 0..<columns {
            guard i % step == 0 else {
                subviews[i].place(at: CGPoint(x: -100_000, y: bounds.minY), proposal: .unspecified)
                continue
            }
            let centre = m.head + gap + CGFloat(i) * (m.cell + gap) + m.cell / 2
            let x = min(centre - widths[i] / 2, bounds.width - widths[i])
            subviews[i].place(at: CGPoint(x: bounds.minX + x, y: bounds.minY), proposal: .unspecified)
        }
        var y = bounds.minY + r.headH
        for (w, h) in r.weekH.enumerated() {
            y += gap
            let first = columns + w * (columns + 1)
            subviews[first].place(at: CGPoint(x: bounds.minX, y: y + h / 2), anchor: .leading,
                                  proposal: ProposedViewSize(width: m.head, height: nil))
            for d in 0..<columns {
                subviews[first + 1 + d].place(at: CGPoint(x: bounds.minX + m.head + gap + CGFloat(d) * (m.cell + gap),
                                                          y: y + (h - m.cell) / 2),
                                              proposal: ProposedViewSize(width: m.cell, height: m.cell))
            }
            y += h
        }
    }
}

// MARK: - Marked text (D73, D91 C2a; spec/02 §3.1b)

/// Running text with marks (D73, D91 C2a): every range of `marks` (character offsets into `text`) gets the mark fill
/// (`SebaroMark.fill`) behind its characters and the mark edge (`SebaroMark.edge`) under them; `current`, the current
/// search hit, takes the thick edge in text instead. Per line of a wrapped range; the text keeps its width and wraps
/// as `SbWrapText` does not (marks need the exact characters). The caller says „Treffer 1 von 2“ in words.
/// SwiftUI draws the edge as the font's underline (single for a mark, thick for the current hit), not the exact 2 / 3 pt
/// of the web (iOS 17 has no text renderer; *provisional, agent*).
public struct SbMarkedText: View {
    let text: String
    let marks: [Range<Int>]
    let current: Range<Int>?
    let style: SebaroTextStyle
    private var context = SbContext()

    public init(_ text: String, marks: [Range<Int>], current: Range<Int>? = nil, style: SebaroTextStyle = .body) {
        self.text = text
        self.marks = marks
        self.current = current
        self.style = style
    }

    /// The attributed text: fill and edge on every mark, the thick text-coloured edge on the current one.
    static func attributed(_ text: String, marks: [Range<Int>], current: Range<Int>?, ink: Color) -> AttributedString {
        var out = AttributedString(text)
        let count = text.count
        func range(_ r: Range<Int>) -> Range<AttributedString.Index>? {
            let lo = min(max(r.lowerBound, 0), count), hi = min(max(r.upperBound, 0), count)
            guard lo < hi else { return nil }
            let a = out.index(out.startIndex, offsetByCharacters: lo), b = out.index(out.startIndex, offsetByCharacters: hi)
            return a..<b
        }
        for r in marks + [current].compactMap({ $0 }) {
            guard let rr = range(r) else { continue }
            out[rr].backgroundColor = SebaroMark.fill
            out[rr].underlineStyle = Text.LineStyle(pattern: .solid, color: r == current ? ink : SebaroMark.edge)
        }
        return out
    }

    public var body: some View {
        Text(Self.attributed(text, marks: marks, current: current, ink: context.tone.text))
            .sbFont(style)
            .foregroundStyle(context.tone.text)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Video (B12b; spec/02 §3.26)

/// A length in words („3 Minuten 42 Sekunden“) for the play button's name.
func sbMediaLength(_ seconds: TimeInterval, _ m: SbMessages) -> String {
    let all = max(0, Int(seconds))
    return m.mediaLength(all / 3600, all / 60 % 60, all % 60)
}

/// Video (B12b; spec/02 §3.26): a 16:9 frame (1 pt `borderStrong`, radius container, ground `bg`). Before the start the
/// `poster` (content, no text in it) with its required `posterDescription` (VoiceOver reads it as the picture, D94) and
/// over it the button „Abspielen“ (play filled + the word, 48 pt, on `bg` with the 2 pt layer line, radius control;
/// VoiceOver „Abspielen: <title>, Video, 3 Minuten 42 Sekunden“): its press calls `onStart`, where the app loads and
/// plays; nothing plays or loads by itself. After the start (`started`) the frame shows `surface` (the player's
/// picture, e.g. an AVPlayerLayer view) and, with `captionsOn`, the current `cue` on `bg` with the layer line; under
/// the frame play / pause, the seek bar (as `SbAudioRow`), the time and, when the video has `captions`, the chip
/// „Untertitel“. Under it the caption „<title> · 0:06 · <captions>“ (caption, text-muted, tabular) with `demoMarker`
/// after it; `playback.failed` = „Das Video lässt sich nicht abspielen.“ after the danger glyph, announced. After the
/// start VoiceOver focus moves from „Abspielen“ to play / pause.
public struct SbVideo<Surface: View>: View {
    let title: String
    let length: TimeInterval
    let started: Bool
    let playback: SbPlayback
    let onStart: () -> Void
    let onPlayPause: () -> Void
    let onSeek: (TimeInterval) -> Void
    let poster: Image?
    let posterDescription: String?
    let captions: String?
    let captionsOn: Bool
    let onCaptionsChange: (Bool) -> Void
    let cue: String?
    let demoMarker: String?
    let surface: Surface
    private var context = SbContext()
    @AccessibilityFocusState private var toggleFocused: Bool

    public init(_ title: String, length: TimeInterval, started: Bool, playback: SbPlayback, onStart: @escaping () -> Void,
                onPlayPause: @escaping () -> Void, onSeek: @escaping (TimeInterval) -> Void, poster: Image? = nil,
                posterDescription: String? = nil, captions: String? = nil, captionsOn: Bool = false,
                onCaptionsChange: @escaping (Bool) -> Void = { _ in }, cue: String? = nil, demoMarker: String? = nil,
                @ViewBuilder surface: () -> Surface) {
        precondition(poster == nil || !(posterDescription ?? "").trimmingCharacters(in: .whitespaces).isEmpty,
                     "SbVideo: a poster needs its posterDescription (spec/02 §3.26, D94)")
        self.title = title
        self.length = length
        self.started = started
        self.playback = playback
        self.onStart = onStart
        self.onPlayPause = onPlayPause
        self.onSeek = onSeek
        self.poster = poster
        self.posterDescription = posterDescription
        self.captions = captions
        self.captionsOn = captionsOn
        self.onCaptionsChange = onCaptionsChange
        self.cue = cue
        self.demoMarker = demoMarker
        self.surface = surface()
    }

    public var body: some View {
        let m = context.messages
        let total = playback.duration > 0 ? playback.duration : length
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.container, style: .continuous)
        VStack(alignment: .leading, spacing: SebaroSpace.s2) {
            ZStack {
                context.tone.bg
                if !started {
                    if let poster {
                        poster.resizable().scaledToFit()
                            .accessibilityLabel(Text(posterDescription ?? ""))
                            .accessibilityAddTraits(.isImage)
                    }
                    Button(action: onStart) {
                        HStack(spacing: SebaroSpace.s2) {
                            SbIcon("play--filled", size: SebaroSize.iconLg, color: context.tone.text)
                            Text(m.videoPlay).sbFont(.bodyStrong).foregroundStyle(context.tone.text)
                        }
                        .padding(.leading, SebaroSpace.s3).padding(.trailing, SebaroSpace.s4)
                        .frame(minHeight: SebaroSize.targetTouch)
                        .background(context.tone.bg, in: RoundedRectangle(cornerRadius: SebaroRadius.control))
                        .overlay(RoundedRectangle(cornerRadius: SebaroRadius.control)
                            .strokeBorder(context.tone.layerLine, lineWidth: SebaroX.layerLineWidth))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(m.videoPlayName(title, sbMediaLength(total, m))))
                } else {
                    surface.frame(maxWidth: .infinity, maxHeight: .infinity)
                    if captionsOn, let cue, !cue.isEmpty {
                        Text(cue).sbFont(.body).foregroundStyle(context.tone.text).multilineTextAlignment(.center)
                            .padding(.horizontal, SebaroSpace.s3).padding(.vertical, SebaroSpace.s1)
                            .background(context.tone.bg, in: RoundedRectangle(cornerRadius: SebaroRadius.control))
                            .overlay(RoundedRectangle(cornerRadius: SebaroRadius.control)
                                .strokeBorder(context.tone.layerLine, lineWidth: SebaroX.layerLineWidth))
                            .padding(SebaroSpace.s2)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(shape)
            .overlay(shape.strokeBorder(context.tone.borderStrong, lineWidth: SebaroBorderWidth.hairline))
            if started {
                let now = sbMediaClock(playback.position), all = sbMediaClock(total)
                HStack(spacing: SebaroSpace.s1) {
                    SbIconButton(playback.playing ? "pause" : "play",
                                 label: playback.playing ? m.mediaPause(title) : m.mediaPlay(title), action: onPlayPause)
                        .accessibilityFocused($toggleFocused)
                    SbSeekBar(position: playback.position, duration: total, onSeek: onSeek)
                        .accessibilityLabel(Text(m.mediaSeek))
                        .accessibilityValue(Text(m.mediaPosition(now, all)))
                }
                SbWrapRow(spacing: SebaroSpace.s2) {
                    Text("\(now) / \(all)").sbFont(.caption).monospacedDigit().foregroundStyle(context.tone.textMuted)
                        .accessibilityLabel(Text(m.mediaPosition(now, all)))
                        .frame(minHeight: SebaroSize.targetTouch)
                    if captions != nil {
                        SbChip(label: m.videoCaptions, chosen: captionsOn, enabled: true) { onCaptionsChange(!captionsOn) }
                    }
                }
                .padding(.leading, SebaroSize.targetTouch + SebaroSpace.s1 + SebaroSpace.s3)
            }
            HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s1) {
                Text([title, sbMediaClock(length), captions].compactMap { $0 }.joined(separator: " · "))
                    .font(sbChartLabelFont(context.scheme)).foregroundStyle(context.tone.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                if let demoMarker { SbDemoMarker(demoMarker) }
            }
            if playback.failed {
                HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s1) {
                    SbIcon("error--filled", size: SebaroSize.iconSm, color: .sbDanger)
                    Text(m.videoFailed).sbFont(.caption).foregroundStyle(context.tone.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .onAppear { SbAnnounce.polite(m.videoFailed) }
            }
        }
        .onChange(of: started) { if started { toggleFocused = true } }
    }
}

public extension SbVideo where Surface == EmptyView {
    init(_ title: String, length: TimeInterval, started: Bool, playback: SbPlayback, onStart: @escaping () -> Void,
         onPlayPause: @escaping () -> Void, onSeek: @escaping (TimeInterval) -> Void, poster: Image? = nil,
         posterDescription: String? = nil, captions: String? = nil, demoMarker: String? = nil) {
        self.init(title, length: length, started: started, playback: playback, onStart: onStart, onPlayPause: onPlayPause,
                  onSeek: onSeek, poster: poster, posterDescription: posterDescription, captions: captions,
                  demoMarker: demoMarker) { EmptyView() }
    }
}
