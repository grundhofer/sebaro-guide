import SwiftUI

// MARK: - Required fields (D98 V2, D99 (3), STA-03; spec/02 §5.4.1, spec/08 §14.12)

/// The check of a form's required fields when „Sichern“ is pressed (D98 V2): every empty one gets „<Beschriftung>
/// fehlt.“ (`SbMessages.fieldMissing`), nothing is saved, and focus moves to the first of them. „Sichern“ stays
/// enabled while they are empty; an optional field is never checked; typing removes the error (the form clears its
/// entry in `errors`).
///
/// ```swift
/// enum Field: Hashable { case name, goal }
/// @FocusState private var focus: Field?
/// @State private var errors: [Field: String] = [:]
/// let missing = SbRequiredFields.check([(.name, "Name", name), (.goal, "Tagesziel", goal)], messages: m)
/// errors = missing.errors
/// if let first = missing.first { focus = first } else { save() }
/// ```
public enum SbRequiredFields {
    public struct Result<ID: Hashable> {
        /// „Name fehlt.“ per empty required field.
        public let errors: [ID: String]
        /// The first empty field in the order given: where focus goes; nil = all filled, save.
        public let first: ID?
    }

    /// `fields` in screen order: the id, the label as shown, the value. A value of only spaces counts as empty.
    public static func check<ID: Hashable>(_ fields: [(id: ID, label: String, value: String)],
                                           messages: SbMessages) -> Result<ID> {
        let empty = fields.filter { $0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return Result(errors: Dictionary(uniqueKeysWithValues: empty.map { ($0.id, messages.fieldMissing($0.label)) }),
                      first: empty.first?.id)
    }

    /// The same with the built-in table of a language („de“, „en-GB“).
    public static func check<ID: Hashable>(_ fields: [(id: ID, label: String, value: String)],
                                           locale: Locale) -> Result<ID> {
        check(fields, messages: SbMessages.forLanguage(locale.identifier))
    }
}

// MARK: - Icon button (spec/02 §1.5, OR-6; spec/08 SbIconButton)

/// The icon button: a 48 pt target (`SebaroSize.targetTouch`), the 24 pt sprite icon in text-muted, the room
/// radius 8; pressed `pressedFill` with the icon in text, the focus ring of a hardware keyboard, no glass. `label`
/// names it for VoiceOver („Zurück“, „Suche leeren“). Disabled: the icon in text-subtle, no fill.
public struct SbIconButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    public init(_ icon: String, label: String, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) { SbIcon(icon, size: SebaroSize.iconLg) }
            .buttonStyle(SbIconButtonStyle())
            .accessibilityLabel(Text(label))
    }
}

struct SbIconButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.isFocused) private var focused
    @Environment(\.sebaroTone) private var tone

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.control, style: .continuous)
        configuration.label
            .foregroundStyle(!enabled ? tone.textSubtle : (configuration.isPressed ? tone.text : tone.textMuted))
            .frame(width: SebaroSize.targetTouch, height: SebaroSize.targetTouch)
            .background(configuration.isPressed && enabled ? tone.pressedFill : Color.clear, in: shape)
            .contentShape(shape)
            .modifier(SbFocusRing(shape: RoundedRectangle(cornerRadius: SebaroRadius.control + SebaroFocus.offset,
                                                          style: .continuous), focused: focused))
    }
}

// MARK: - Stepper (spec/02 §2.11; D105 (12))

/// Stepper (D105 (12)): `label` above, then minus, the value (label size, tabular, centred in the room of the widest
/// value of `range`), plus; each 48 pt. `step` is the amount of one press (5 for minutes in fives). VoiceOver: one
/// adjustable element („Wiederholungen“, value `spoken` of the value, „13 Wiederholungen“; swipe up and down), the
/// iOS stepper's way instead of two buttons and a live region (provisional, agent). At every text size the row fits:
/// two 48 pt buttons and the value; the label wraps.
public struct SbStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let spoken: (Int) -> String
    private var context = SbContext()

    public init(_ label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int = 1,
                spoken: ((Int) -> String)? = nil) {
        precondition(step > 0, "SbStepper: step > 0")
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.spoken = spoken ?? { "\($0) \(label)" }
    }

    private func change(_ by: Int) { value = min(max(value + by, range.lowerBound), range.upperBound) }

    public var body: some View {
        let m = context.messages
        let locale = context.currentLocale
        VStack(alignment: .leading, spacing: SebaroSpace.s1) {
            Text(label).sbFont(.label).foregroundStyle(context.tone.text)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 0) {
                SbIconButton("minus", label: m.stepperLess(label)) { change(-step) }
                    .disabled(value <= range.lowerBound)
                ZStack {
                    // the widest value holds the room, so the buttons never move (spec/02 §2.11)
                    Text(SbMessages.formatCount(range.upperBound, locale: locale)).hidden()
                    Text(SbMessages.formatCount(value, locale: locale))
                }
                .sbFont(.label).monospacedDigit().foregroundStyle(context.tone.text)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, SebaroSpace.s2)
                SbIconButton("plus", label: m.stepperMore(label)) { change(step) }
                    .disabled(value >= range.upperBound)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(spoken(value)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: change(step)
            case .decrement: change(-step)
            @unknown default: break
            }
        }
    }
}

// MARK: - Time of day (spec/02 §2.12; D105 (13), (14))

/// A time of day without a date („19:00“), the twin of `LocalTime` in Compose.
public struct SbTimeOfDay: Hashable, Comparable, Sendable {
    public let hour: Int
    public let minute: Int

    public init(_ hour: Int, _ minute: Int = 0) {
        precondition((0..<24).contains(hour) && (0..<60).contains(minute), "SbTimeOfDay: 00:00 to 23:59")
        self.hour = hour
        self.minute = minute
    }

    var minutes: Int { hour * 60 + minute }

    public static func < (a: SbTimeOfDay, b: SbTimeOfDay) -> Bool { a.minutes < b.minutes }

    /// „19:00“, 24 hours with Latin digits in German and English (as `timeOfDay` in Compose).
    public var text: String { String(format: "%02d:%02d", hour, minute) }

    /// The steps of a time list (D105 (14)): from `from` to `to` every `step` minutes; default the half hours
    /// 05:00–23:30.
    public static func steps(from: SbTimeOfDay = SbTimeOfDay(5), to: SbTimeOfDay = SbTimeOfDay(23, 30),
                             step: Int = 30) -> [SbTimeOfDay] {
        precondition(step > 0, "SbTimeOfDay.steps: step > 0")
        return stride(from: from.minutes, through: to.minutes, by: step).map { SbTimeOfDay($0 / 60, $0 % 60) }
    }
}

/// A time row (D105 (13)): `label` in body, `text` in caption text-muted under it, the time in body-strong tabular and
/// the clock icon at the end; at least 56 pt, the whole row opens `SbTimeSheet` with `times`, a choice there sets
/// `time` and closes it. At the accessibility sizes the time moves under the label (as the trail of `SbListRow`).
public struct SbTimeRow: View {
    let label: String
    @Binding var time: SbTimeOfDay
    let text: String?
    let times: [SbTimeOfDay]
    let hairline: Bool
    private var context = SbContext()
    @State private var open = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = SebaroSize.controlLg

    public init(_ label: String, time: Binding<SbTimeOfDay>, text: String? = nil,
                times: [SbTimeOfDay] = SbTimeOfDay.steps(), hairline: Bool = true) {
        self.label = label
        self._time = time
        self.text = text
        self.times = times
        self.hairline = hairline
    }

    public var body: some View {
        let stacked = typeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: SebaroSpace.s1))
            : AnyLayout(HStackLayout(alignment: .center, spacing: SebaroSpace.s3))
        Button { open = true } label: {
            layout {
                VStack(alignment: .leading, spacing: 0) {
                    Text(label).sbFont(.body).foregroundStyle(context.tone.text)
                    if let text { Text(text).sbFont(.caption).foregroundStyle(context.tone.textMuted) }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: stacked ? .infinity : nil, alignment: .leading)
                if !stacked { Spacer(minLength: 0) }
                HStack(spacing: SebaroSpace.s3) {
                    Text(time.text).sbFont(.bodyStrong).monospacedDigit().foregroundStyle(context.tone.text)
                    SbIcon("clock", size: SebaroSize.iconLg, color: context.tone.textMuted)
                }
            }
            .padding(.horizontal, SebaroSpacing.gutter)
            .padding(.vertical, SebaroSpace.s2)
            .frame(maxWidth: .infinity, minHeight: rowHeight, alignment: .leading)
            .overlay(alignment: .top) {
                if hairline {
                    Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SbRowButtonStyle())
        .accessibilityElement(children: .combine)   // label, text and time once each; the clock icon is not read
        .sheet(isPresented: $open) {
            SbTimeSheet(times: times, selected: time, onPick: { time = $0; open = false }, onDismiss: { open = false })
        }
    }
}

/// The time sheet (D105 (13)): a sheet for a choice (spec/02 §4.7) with the head `title` („Uhrzeit wählen“) and one
/// row per entry of `times` with the check mark of iOS at the chosen one (D67 (4), the rows of `SbCheckChoice`); it
/// opens at the medium height with `selected` in view and two rows before it. A `selected` that is not in `times`
/// stands in its place and is chosen. A choice calls `onPick` (the caller closes the sheet). Ground `bg`, the ink line
/// along the top edge, no grabber, „Abbrechen“ at the top leading place.
public struct SbTimeSheet: View {
    let times: [SbTimeOfDay]
    let selected: SbTimeOfDay
    let title: String?
    let onPick: (SbTimeOfDay) -> Void
    let onDismiss: () -> Void
    private var context = SbContext()
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = SebaroSize.controlLg
    /// The first row in view: two before the chosen one (every open starts there).
    @State private var top: Int?

    public init(times: [SbTimeOfDay], selected: SbTimeOfDay, title: String? = nil,
                onPick: @escaping (SbTimeOfDay) -> Void, onDismiss: @escaping () -> Void) {
        self.times = times
        self.selected = selected
        self.title = title
        self.onPick = onPick
        self.onDismiss = onDismiss
        let shown = times.contains(selected) ? times : (times + [selected]).sorted()
        _top = State(initialValue: max((shown.firstIndex(of: selected) ?? 0) - 2, 0))
    }

    public var body: some View {
        let shown = times.contains(selected) ? times : (times + [selected]).sorted()
        NavigationStack {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(shown.enumerated()), id: \.element) { index, time in
                            let chosen = time == selected
                            Button { onPick(time) } label: {
                                HStack(spacing: SebaroSpace.s3) {
                                    Text(time.text).sbFont(chosen ? .bodyStrong : .body).monospacedDigit()
                                        .foregroundStyle(context.tone.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    if chosen { SbIcon("check", size: SebaroSize.iconLg, color: .sbAccent) }
                                }
                                .padding(.horizontal, SebaroSpacing.gutter)
                                .frame(maxWidth: .infinity, minHeight: rowHeight)
                                .overlay(alignment: .top) {
                                    if index > 0 {
                                        Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline)
                                            .padding(.leading, SebaroSpacing.gutter)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(SbRowButtonStyle())
                            .accessibilityAddTraits(chosen ? [.isSelected] : [])
                            .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $top, anchor: .top)
            .background(context.tone.bg)
            .navigationTitle(title ?? context.messages.timeChoose)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                SbToolbarItem(placement: .cancellationAction) {
                    Button(action: onDismiss) {
                        Text(context.messages.cancel).sbFont(.body).foregroundStyle(context.tone.text)
                    }
                }
            }
        }
        .modifier(SbHardScrollEdge())
        .overlay(alignment: .top) { SbSheetTopEdge() }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(context.tone.bg)
        .presentationCornerRadius(SebaroRadius.sheet)
    }
}
