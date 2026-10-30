import SwiftUI

// MARK: - Steps, intro, timeline, sticky head, tabs (spec/02 §3.12, §3.17, §3.18, §3.23, §4.4; D100 (1), D101 (1), (2), (5))

/// Lays out nothing visible: its subviews are hidden probes of the step words (subview 0 one line, then per word
/// the word plain and with every soft hyphen) measured at the offered width; whether every word fits its column on
/// two lines goes to `result` after the layout pass (D101 (1), measured at every text size).
struct SbStepProbe: Layout {
    let result: Binding<Bool>
    let count: Int
    let gap: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? 0, height: 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for s in subviews { s.place(at: CGPoint(x: -100_000, y: bounds.minY), proposal: .unspecified) }
        guard bounds.width > 0, subviews.count == 1 + 2 * count else { return }
        let column = SbStepFit.column(width: bounds.width, count: count, gap: gap)
        let line = subviews[0].sizeThatFits(.unspecified).height
        let lines = (0..<count).map { i -> Int in
            let plain = subviews[1 + 2 * i], hyphened = subviews[2 + 2 * i]
            let probe = plain.sizeThatFits(.unspecified).width > column ? hyphened : plain
            return Int((probe.sizeThatFits(ProposedViewSize(width: column, height: nil)).height / max(line, 1)).rounded())
        }
        let answer = SbStepFit.wordsFit(lines: lines)
        if result.wrappedValue != answer {
            let r = result
            DispatchQueue.main.async { if r.wrappedValue != answer { r.wrappedValue = answer } }
        }
    }
}

/// The pure rule of the step words (D101 (1)): every word fits its column on at most two lines; `lines` gives a
/// word's line count at the column width (hyphenated only when the word alone is wider than the column).
enum SbStepFit {
    static func column(width: CGFloat, count: Int, gap: CGFloat) -> CGFloat {
        max((width - gap * CGFloat(count - 1)) / CGFloat(count), 1)
    }

    static func wordsFit(lines: [Int]) -> Bool { lines.allSatisfy { $0 <= 2 } }
}

/// Step indicator (spec/02 §3.12): `steps` are the words (2 to 4 on a phone, D101 (1)), `current` the 0-based current
/// step; steps before it are done, after it next; `current == steps.count` means all done. `showHead` shows „Schritt n
/// von m“. While every word fits its column on two lines (hyphenated only when wider than the column, measured at the
/// current step's weight) each word stands under its bar; else (D100 (1), D101 (1), (2)) the bars stay, the checks
/// stay under the done bars, and only the current step's word stands on its own line under the bars. VoiceOver hears
/// every step's word and state either way.
public struct SbSteps: View {
    let steps: [String]
    let current: Int
    let showHead: Bool
    private var context = SbContext()
    @State private var wordsFit = true

    public init(_ steps: [String], current: Int, showHead: Bool = true) {
        precondition(!steps.isEmpty, "SbSteps: no steps")
        self.steps = steps
        self.current = current
        self.showHead = showHead
    }

    private var strong: Font { sbChartLabelFont(context.scheme, strong: true) }

    public var body: some View {
        let m = context.messages
        let named = min(max(current, 0), steps.count - 1)
        let gap = SebaroSpace.s1
        VStack(alignment: .leading, spacing: SebaroSpace.s2) {
            if showHead {
                Text(m.stepOf(named + 1, steps.count)).sbFont(.caption).foregroundStyle(context.tone.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .top, spacing: gap) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, word in
                    segment(i, word)
                }
            }
            if !wordsFit {
                let now = named == current
                SbWrapText(steps[named]).font(now ? strong : sbCaption)
                    .foregroundStyle(now ? Color.sbLink : context.tone.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
            }
        }
        .background {
            // the probes: each word in the current step's weight, plain and with every soft hyphen, and one line
            let probe = SbStepProbe(result: $wordsFit, count: steps.count, gap: gap)
            probe {
                Text("Xg").font(strong)
                ForEach(Array(steps.enumerated()), id: \.offset) { _, w in
                    Text(w).font(strong)
                    Text(SbHyphenation.shown([.words(w)], overlong: Set(SbHyphenation.words(w)), locale: context.currentLocale))
                        .font(strong)
                }
            }
            .hidden()
            .accessibilityHidden(true)
        }
    }

    private var sbCaption: Font { SebaroTextStyle.caption.exactFont(for: context.scheme) }

    private func segment(_ i: Int, _ word: String) -> some View {
        let m = context.messages
        let done = i < current, now = i == current
        let edge: Color = now ? .sbAccent : (done ? context.tone.text : context.tone.border)
        let ink: Color = now ? .sbLink : (done ? context.tone.text : context.tone.textMuted)
        return VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(edge).frame(height: SebaroBorderWidth.strong)
            SbWrapRow(spacing: SebaroSpace.s1) {
                if done { SbIcon("check--16", size: SebaroSize.iconSm, color: ink) }
                if wordsFit { SbWrapText(word).font(now ? strong : sbCaption).foregroundStyle(ink) }
            }
            .padding(.top, SebaroSpace.s2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(word))
        .accessibilityValue(Text(done ? m.stepDone : (now ? m.stepCurrent : "")))
    }
}

/// Intro step (spec/02 §3.23, D101 (5)): the `spot` (a `--spot` sprite id, 128 × 96 pt, text-muted; nil = none), the
/// `title` in title (a heading), the `text` in body text-muted and „Einführung überspringen“ as a text action calling
/// `onSkip`; start-aligned, 8 pt apart, 32 pt above and below, the gutter at the sides. The screen puts `SbSteps` under
/// its top bar and „Weiter: <Ziel>“ into `SbScreen`'s bottom zone.
public struct SbIntroStep: View {
    let title: String
    let text: String
    let spot: String?
    let onSkip: () -> Void
    private var context = SbContext()

    public init(_ title: String, text: String, spot: String? = "onboarding--spot", onSkip: @escaping () -> Void) {
        self.title = title
        self.text = text
        self.spot = spot
        self.onSkip = onSkip
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SebaroSpace.s2) {
            if let spot {
                SbIcon(spot, size: SebaroSpace.s16 * 2, color: context.tone.textMuted)
                    .frame(width: SebaroSpace.s16 * 2, height: SebaroSpace.s12 * 2)
                    .accessibilityHidden(true)
            }
            SbWrapText(title, style: .title).foregroundStyle(context.tone.text).accessibilityAddTraits(.isHeader)
            SbWrapText(text, style: .body).foregroundStyle(context.tone.textMuted)
            Button(action: onSkip) { SbWrapText(context.messages.introSkip) }.buttonStyle(SbTextActionStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SebaroSpacing.gutter)
        .padding(.vertical, SebaroSpace.s8)
    }
}

/// One entry of a timeline (B4b, spec/02 §3.18): `date` (caption text-muted, tabular, a 112 pt column that grows with
/// the text; on its own line above once the title would be narrower than that column), the kind as a 16 pt `icon` in
/// text-muted, `title` in label at the body weight, an optional `meta` line. A 1 pt border hairline above (`hairline`
/// = false for the first entry), no vertical stroke. `warning` = an event that asks for something: the warning glyph in
/// warning. `onTap` makes the whole entry the target. At least 48 pt.
public struct SbTimelineEntry: View {
    let date: String
    let title: String
    let icon: String?
    let meta: String?
    let warning: Bool
    let hairline: Bool
    let onTap: (() -> Void)?
    private var context = SbContext()
    @ScaledMetric(relativeTo: .caption) private var column: CGFloat = SebaroSpace.s16 + SebaroSpace.s12

    public init(date: String, title: String, icon: String? = nil, meta: String? = nil, warning: Bool = false,
                hairline: Bool = true, onTap: (() -> Void)? = nil) {
        self.date = date
        self.title = title
        self.icon = icon
        self.meta = meta
        self.warning = warning
        self.hairline = hairline
        self.onTap = onTap
    }

    public var body: some View {
        let content = ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: SebaroSpace.s3) {
                dateText.frame(width: column, alignment: .leading)
                mark
                main.frame(minWidth: column, maxWidth: .infinity, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: SebaroSpace.s1) {
                dateText
                HStack(alignment: .top, spacing: SebaroSpace.s3) {
                    mark
                    main.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, SebaroSpacing.gutter)
        .padding(.vertical, SebaroSpace.s3)
        .frame(maxWidth: .infinity, minHeight: SebaroSize.targetTouch, alignment: .leading)
        .overlay(alignment: .top) {
            if hairline { Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline) }
        }
        if let onTap {
            Button(action: onTap) { content.contentShape(Rectangle()) }.buttonStyle(SbRowPressStyle())
        } else {
            content.accessibilityElement(children: .combine)
        }
    }

    private var dateText: some View {
        Text(date).font(sbChartLabelFont(context.scheme)).foregroundStyle(context.tone.textMuted)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var mark: some View {
        Group {
            if warning {
                SbIcon("warning--16", size: SebaroSize.iconSm, color: .sbWarning)
            } else if let icon {
                SbIcon(icon, size: SebaroSize.iconSm, color: context.tone.textMuted)
            } else {
                Color.clear
            }
        }
        .frame(width: SebaroSize.iconSm, height: SebaroSize.iconSm)
        .padding(.top, SebaroSpace.s0_5)
        .accessibilityHidden(true)
    }

    private var main: some View {
        let label = SebaroTextStyle.label.resolve(context.scheme), body = SebaroTextStyle.body.resolve(context.scheme)
        return VStack(alignment: .leading, spacing: 0) {
            SbWrapText(title).font(SebaroFonts.font(SebaroTextFace(family: label.family, size: label.size,
                                                                 lineHeight: label.lineHeight, weight: body.weight,
                                                                 weightValue: body.weightValue, tracking: label.tracking),
                                                    relativeTo: .subheadline, monospacedDigits: false))
                .foregroundStyle(context.tone.text)
            if let meta {
                Text(meta).font(sbChartLabelFont(context.scheme)).foregroundStyle(context.tone.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A whole row as target: the pressed fill, the inset focus ring; no ripple.
struct SbRowPressStyle: ButtonStyle {
    @Environment(\.sebaroTone) private var tone
    @Environment(\.isFocused) private var focused
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? tone.pressedFill : Color.clear)
            .modifier(SbFocusRing(shape: Rectangle(), focused: focused))
    }
}

/// Sticky group head (B3b, spec/02 §3.17): `SbListHeader` on `bg`; while `pinned` (it stands at the top over the rows)
/// and only then, the 2 pt layer line under it (D46), drawn inside its height so the head never changes size. Use it as
/// the header of a `Section` in a `LazyVStack(pinnedViews: [.sectionHeaders])`; `pinned` comes from the caller's scroll
/// position (e.g. `onScrollGeometryChange` or a `GeometryReader` in the scroll view's space).
public struct SbStickyListHeader: View {
    let label: String
    let pinned: Bool
    let count: Int?
    private var context = SbContext()

    public init(_ label: String, pinned: Bool, count: Int? = nil) {
        self.label = label
        self.pinned = pinned
        self.count = count
    }

    public var body: some View {
        SbListHeader(label, count: count)
            .background(context.tone.bg)
            .overlay(alignment: .bottom) {
                if pinned { Rectangle().fill(context.tone.layerLine).frame(height: SebaroX.layerLineWidth) }
            }
    }
}

/// Tabs (spec/02 §4.4): a row with a 1 pt border hairline under its whole width, tabs from the start edge, each ≥ 48 pt,
/// 16 pt at the sides, the word in label text-muted; selected = the 3 pt accent bottom edge + link + title weight;
/// `disabledTabs`: the word text-subtle, no target. `label` names the row for VoiceOver. The row scrolls sideways when
/// it is wider than the screen; a word never breaks.
public struct SbTabs: View {
    let tabs: [String]
    @Binding var selected: Int
    let label: String
    let disabledTabs: Set<Int>
    private var context = SbContext()

    public init(_ tabs: [String], selected: Binding<Int>, label: String, disabledTabs: Set<Int> = []) {
        self.tabs = tabs
        self._selected = selected
        self.label = label
        self.disabledTabs = disabledTabs
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { i, word in
                    let on = !disabledTabs.contains(i), chosen = i == selected
                    Button { selected = i } label: {
                        Text(word).font(tabFont(chosen)).lineLimit(1).fixedSize()
                            .foregroundStyle(!on ? context.tone.textSubtle : (chosen ? Color.sbLink : context.tone.textMuted))
                            .padding(.horizontal, SebaroSpace.s4)
                            .frame(minWidth: SebaroSize.targetTouch, minHeight: SebaroSize.targetTouch)
                            .overlay(alignment: .bottom) {
                                if chosen {
                                    Rectangle().fill(on ? Color.sbAccent : context.tone.borderStrong)
                                        .frame(height: SebaroBorderWidth.strong)
                                }
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!on)
                    .accessibilityAddTraits(chosen ? [.isSelected] : [])
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .background(alignment: .bottom) {
            Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(label))
    }

    private func tabFont(_ chosen: Bool) -> Font {
        let label = SebaroTextStyle.label.resolve(context.scheme)
        let weight = chosen ? SebaroTextStyle.title.resolve(context.scheme) : label
        return SebaroFonts.font(SebaroTextFace(family: label.family, size: label.size, lineHeight: label.lineHeight,
                                               weight: weight.weight, weightValue: weight.weightValue, tracking: label.tracking),
                                relativeTo: .subheadline, monospacedDigits: false)
    }
}

// MARK: - Calendar (B7a, spec/02 §3.21; spec/08 §14.14)

/// A calendar day without a time zone.
public struct SbDay: Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    public init(_ year: Int, _ month: Int, _ day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
    public static func < (a: SbDay, b: SbDay) -> Bool { (a.year, a.month, a.day) < (b.year, b.month, b.day) }

    var date: Date { SbCalendarModel.gregorian.date(from: DateComponents(year: year, month: month, day: day))! }
}

/// One entry of a calendar day: `time` („07:30“) and `text` („Vitamin D“).
public struct SbCalendarEntry: Sendable {
    public let time: String
    public let text: String
    public init(time: String, text: String) {
        self.time = time
        self.text = text
    }
}

/// The calendar's arithmetic: the grid of a month from a week start, the next and previous month, the locale's week
/// start (a locale without a region takes its likely region, „de“ → „de-DE“, as the web's Intl does).
public enum SbCalendarModel {
    static let gregorian = Calendar(identifier: .gregorian)

    /// 1 = Sunday … 7 = Saturday.
    public static func weekStart(_ locale: Locale) -> Int {
        let full = locale.region == nil ? Locale(identifier: locale.language.maximalIdentifier) : locale
        var cal = Calendar(identifier: .gregorian)
        cal.locale = full
        return cal.firstWeekday
    }

    /// The month moved by `by` months: (year, month).
    public static func move(year: Int, month: Int, by: Int) -> (year: Int, month: Int) {
        let n = year * 12 + (month - 1) + by
        return (Int((Double(n) / 12).rounded(.down)), ((n % 12) + 12) % 12 + 1)
    }

    /// The weeks of a month, each 7 cells from `firstWeekday`; nil = a day of another month (stays empty).
    public static func weeks(year: Int, month: Int, firstWeekday: Int) -> [[SbDay?]] {
        let first = SbDay(year, month, 1).date
        let weekday = gregorian.component(.weekday, from: first)
        let count = gregorian.range(of: .day, in: .month, for: first)!.count
        let lead = (weekday - firstWeekday + 7) % 7
        let cells: [SbDay?] = Array(repeating: nil, count: lead) + (1...count).map { SbDay(year, month, $0) }
        let padded = cells + Array(repeating: nil, count: (7 - cells.count % 7) % 7)
        return stride(from: 0, to: padded.count, by: 7).map { Array(padded[$0..<($0 + 7)]) }
    }

    /// The weekday heads from `firstWeekday`, from a Monday-first list of two-letter words.
    public static func heads(_ mondayFirst: [String], firstWeekday: Int) -> [String] {
        let start = (firstWeekday + 5) % 7
        return (0..<7).map { mondayFirst[(start + $0) % 7] }
    }
}

/// Calendar (B7a, spec/02 §3.21): the month and year with „Voriger Monat“ / „Nächster Monat“, the two-letter weekday
/// heads from the locale's week start, one cell per day (days of other months stay empty), the drawn day 40 pt. Today =
/// 1 pt border-strong frame + title weight; `selected` = the 3 pt accent place line at its foot + title weight; a day
/// in `entries` = a 6 pt text-muted dot and „mit Eintrag“ for VoiceOver. `month` and `selected` are the caller's.
/// `agenda` = the chosen day's heading and entries below, „Nichts eingetragen.“ for a day without. The gutter shrinks
/// before the days do; when the days at large text no longer fit the width, the month scrolls sideways (a day number
/// never breaks).
public struct SbCalendar: View {
    let year: Int
    let month: Int
    let selected: SbDay?
    let entries: [SbDay: [SbCalendarEntry]]
    let agenda: Bool
    let today: SbDay
    let firstWeekday: Int?
    let onMonthChange: (_ year: Int, _ month: Int) -> Void
    let onChange: (SbDay) -> Void
    private var context = SbContext()
    @ScaledMetric(relativeTo: .body) private var dayEdge: CGFloat = SebaroSpace.s10

    public init(year: Int, month: Int, selected: SbDay?, today: SbDay, entries: [SbDay: [SbCalendarEntry]] = [:],
                agenda: Bool = true, firstWeekday: Int? = nil, onMonthChange: @escaping (_ year: Int, _ month: Int) -> Void,
                onChange: @escaping (SbDay) -> Void) {
        self.year = year
        self.month = month
        self.selected = selected
        self.today = today
        self.entries = entries
        self.agenda = agenda
        self.firstWeekday = firstWeekday
        self.onMonthChange = onMonthChange
        self.onChange = onChange
    }

    private func format(_ day: SbDay, _ template: String) -> String {
        let f = DateFormatter()
        f.locale = context.currentLocale
        f.setLocalizedDateFormatFromTemplate(template)
        return f.string(from: day.date)
    }

    public var body: some View {
        let m = context.messages
        let start = firstWeekday ?? SbCalendarModel.weekStart(context.currentLocale)
        let weeks = SbCalendarModel.weeks(year: year, month: month, firstWeekday: start)
        let cell = max(SebaroSize.targetTouch, dayEdge + SebaroSpace.s2)
        VStack(alignment: .leading, spacing: SebaroSpace.s6) {
            VStack(alignment: .leading, spacing: SebaroSpace.s2) {
                HStack(spacing: 0) {
                    SbWrapText(format(SbDay(year, month, 1), "MMMMy"), style: .title).foregroundStyle(context.tone.text)
                        .accessibilityAddTraits(.isHeader)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    SbIconButton("chevron-left", label: m.calendarPrevious) {
                        let p = SbCalendarModel.move(year: year, month: month, by: -1)
                        onMonthChange(p.year, p.month)
                    }
                    SbIconButton("chevron-right", label: m.calendarNext) {
                        let p = SbCalendarModel.move(year: year, month: month, by: 1)
                        onMonthChange(p.year, p.month)
                    }
                }
                ViewThatFits(in: .horizontal) {
                    grid(weeks, start: start, cell: nil, least: cell)
                    ScrollView(.horizontal) { grid(weeks, start: start, cell: cell, least: cell) }
                }
            }
            if agenda, let selected { agendaView(selected) }
        }
        .padding(.horizontal, SebaroSpace.s3)
        .padding(.top, SebaroSpace.s2)
        .padding(.bottom, SebaroSpace.s4)
    }

    /// The weeks: each cell `cell` wide (nil = a seventh of the width, at least `least` ideally).
    private func grid(_ weeks: [[SbDay?]], start: Int, cell: CGFloat?, least: CGFloat) -> some View {
        let heads = SbCalendarModel.heads(context.messages.weekdays, firstWeekday: start)
        return Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                ForEach(Array(heads.enumerated()), id: \.offset) { _, h in
                    Text(h).font(sbChartLabelFont(context.scheme)).foregroundStyle(context.tone.textMuted)
                        .lineLimit(1).fixedSize()
                        .frame(minWidth: cell ?? least * 0.8, idealWidth: cell ?? least, maxWidth: cell ?? .infinity,
                               minHeight: SebaroSize.targetTouch - SebaroSpace.s2)
                        .accessibilityHidden(true)
                }
            }
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                GridRow {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        Group {
                            if let day { dayCell(day) } else { Color.clear.accessibilityHidden(true) }
                        }
                        .frame(minWidth: cell ?? least * 0.8, idealWidth: cell ?? least, maxWidth: cell ?? .infinity,
                               minHeight: SebaroSize.targetTouch)
                    }
                }
            }
        }
        .fixedSize(horizontal: cell != nil, vertical: false)
    }

    private func dayCell(_ day: SbDay) -> some View {
        let m = context.messages
        let isToday = day == today, chosen = day == selected, has = !(entries[day] ?? []).isEmpty
        let body = SebaroTextStyle.body.resolve(context.scheme), title = SebaroTextStyle.title.resolve(context.scheme)
        let weight = isToday || chosen ? title : body
        let font = SebaroFonts.font(SebaroTextFace(family: body.family, size: body.size, lineHeight: body.lineHeight,
                                                   weight: weight.weight, weightValue: weight.weightValue, tracking: body.tracking),
                                    relativeTo: .body, monospacedDigits: true)
        return Button { onChange(day) } label: {
            VStack(spacing: SebaroSpace.s0_5) {
                Text("\(day.day)").font(font).foregroundStyle(context.tone.text).lineLimit(1).fixedSize()
                Circle().fill(has ? context.tone.textMuted : Color.clear).frame(width: 6, height: 6)   // the web's 6px dot
            }
            .frame(minWidth: dayEdge, minHeight: dayEdge)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: SebaroRadius.control).strokeBorder(context.tone.borderStrong,
                                                                                      lineWidth: SebaroBorderWidth.control)
                }
            }
            .overlay(alignment: .bottom) {
                if chosen { Rectangle().fill(Color.sbAccent).frame(height: SebaroBorderWidth.strong) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text([format(day, "EEEEdMMMM"), isToday ? m.calendarToday : nil, has ? m.calendarWithEntry : nil]
            .compactMap { $0 }.joined(separator: ", ")))
        .accessibilityAddTraits(chosen ? [.isSelected] : [])
    }

    private func agendaView(_ day: SbDay) -> some View {
        let list = entries[day] ?? []
        return VStack(alignment: .leading, spacing: 0) {
            SbWrapText(format(day, "EEEEdMMMM"), style: .label).foregroundStyle(context.tone.text)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, SebaroSpace.s1)
            if list.isEmpty {
                SbWrapText(context.messages.calendarNone, style: .body).foregroundStyle(context.tone.textMuted)
                    .padding(.vertical, SebaroSpace.s3)
            }
            ForEach(Array(list.enumerated()), id: \.offset) { i, e in
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s2) {
                        Text(e.time).font(sbChartLabelFont(context.scheme)).foregroundStyle(context.tone.textMuted)
                            .frame(width: SebaroSpace.s12 + SebaroSpace.s2, alignment: .leading)
                        Text(e.text).sbFont(.body).foregroundStyle(context.tone.text).fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(e.time).font(sbChartLabelFont(context.scheme)).foregroundStyle(context.tone.textMuted)
                        SbWrapText(e.text, style: .body).foregroundStyle(context.tone.text)
                    }
                }
                .padding(.vertical, SebaroSpace.s3)
                .frame(maxWidth: .infinity, minHeight: SebaroSize.targetTouch, alignment: .leading)
                .overlay(alignment: .top) {
                    if i > 0 { Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline) }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - Overflow menu (spec/02 §4.10; native on iOS)

/// The overflow menu (spec/02 §4.10) as the system menu: a 48 pt icon button („Menü öffnen“, the overflow glyph) that
/// opens `items`, then `danger` (the one destructive entry, always last after a divider; it opens the confirmation
/// dialog, D39). An item with `checked` shows the system check mark (a single choice); `group` heads become sections.
/// iOS draws the menu (no sebaro layer, as `sbContextMenu`); words, order and the destructive rule are sebaro's.
public struct SbOverflowMenu: View {
    let items: [SbMenuItem]
    let danger: SbMenuItem?
    let label: String?
    private var context = SbContext()

    public init(_ items: [SbMenuItem], danger: SbMenuItem? = nil, label: String? = nil) {
        self.items = items
        self.danger = danger
        self.label = label
    }

    /// The items in their groups, in order of first appearance (nil = no head).
    static func groups(_ items: [SbMenuItem]) -> [(head: String?, items: [SbMenuItem])] {
        var out: [(head: String?, items: [SbMenuItem])] = []
        for item in items {
            if let i = out.lastIndex(where: { $0.head == item.group }), i == out.count - 1 {
                out[i].items.append(item)
            } else {
                out.append((item.group, [item]))
            }
        }
        return out
    }

    public var body: some View {
        Menu {
            SbMenuContent(items, danger: danger)
        } label: {
            SbIcon("more-vertical", size: SebaroSize.iconLg, color: context.tone.text)
                .frame(width: SebaroSize.targetTouch, height: SebaroSize.targetTouch)
                .contentShape(Rectangle())
        }
        .menuIndicator(.hidden)
        .accessibilityLabel(Text(label ?? context.messages.openMenu))
    }
}

/// The rows of a sebaro menu for any system `Menu` (the counterpart of the Compose `SbMenu`; iOS draws the layer):
/// `items` in their order, a `group` head as a section, a `checked` row with the system check mark, a disabled row
/// shown but not choosable, then `danger` last after a divider (it opens the confirmation dialog, D39).
/// `Menu { SbMenuContent(items, danger: delete) } label: { … }`.
public struct SbMenuContent: View {
    let items: [SbMenuItem]
    let danger: SbMenuItem?

    public init(_ items: [SbMenuItem], danger: SbMenuItem? = nil) {
        self.items = items
        self.danger = danger
    }

    public var body: some View {
        ForEach(Array(SbOverflowMenu.groups(items).enumerated()), id: \.offset) { _, g in
            Section(g.head ?? "") {
                ForEach(g.items) { item in
                    if let checked = item.checked {
                        Toggle(isOn: Binding(get: { checked }, set: { _ in item.run() })) { SbMenuLabel(item: item) }
                            .disabled(!item.enabled)
                    } else {
                        Button(action: item.run) { SbMenuLabel(item: item) }.disabled(!item.enabled)
                    }
                }
            }
        }
        if let danger {
            Divider()
            Button(role: .destructive, action: danger.run) { SbMenuLabel(item: danger) }.disabled(!danger.enabled)
        }
    }
}
