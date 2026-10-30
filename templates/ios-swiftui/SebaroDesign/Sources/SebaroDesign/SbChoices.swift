import SwiftUI

// MARK: - Search field (spec/02 §2.2; spec/08 §14.12)

/// Search field: the field of `SbTextField` with the 24 pt search icon (text-muted) at the start and, while the value is
/// not empty, the 48 pt button „Suche leeren“ (close) at the end, which empties it and keeps the focus. With a
/// `placeholder` the label is only the field's name for VoiceOver, else it stands above. The return key is Search:
/// `onSearch` gets the value. `error` as `SbTextField` („Kein Treffer für „Glas“.“).
public struct SbSearchField: View {
    let label: String
    @Binding var text: String
    let placeholder: String?
    let error: String?
    let onSearch: (String) -> Void
    private var context = SbContext()
    @FocusState private var focused: Bool
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = SebaroSize.controlMd

    public init(_ label: String, text: Binding<String>, placeholder: String? = nil, error: String? = nil,
                onSearch: @escaping (String) -> Void = { _ in }) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.error = error
        self.onSearch = onSearch
    }

    public var body: some View {
        let prompt = placeholder.map {
            Text($0).font(SebaroTextStyle.body.exactFont(for: context.scheme)).foregroundStyle(context.tone.textMuted)
        }
        VStack(alignment: .leading, spacing: SebaroSpace.s1) {
            if placeholder == nil {
                Text(label).sbFont(.label).foregroundStyle(context.tone.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            }
            HStack(spacing: SebaroSpace.s2) {
                SbIcon("search", size: SebaroSize.iconLg, color: context.tone.textMuted).accessibilityHidden(true)
                TextField("", text: $text, prompt: prompt)
                    .sbFont(.body)
                    .foregroundStyle(context.tone.text)
                    .focused($focused)
                    .submitLabel(.search)
                    .onSubmit { onSearch(text) }
                    .accessibilityLabel(Text(label))
                    .accessibilityHint(Text(error ?? ""))
                if !text.isEmpty {
                    SbIconButton("close", label: context.messages.clearSearch) {
                        text = ""
                        focused = true
                    }
                }
            }
            .padding(.leading, SebaroSpace.s3)
            .frame(minHeight: height)
            .background(context.tone.surfaceSunken,
                        in: UnevenRoundedRectangle(topLeadingRadius: SebaroRadius.control, topTrailingRadius: SebaroRadius.control))
            .overlay(alignment: .bottom) {
                Rectangle().fill(error == nil ? context.tone.borderStrong : Color.sbDanger)
                    .frame(height: error == nil ? SebaroBorderWidth.control : SebaroX.layerLineWidth)
            }
            if let error {
                HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s1) {
                    SbIcon("error--filled", size: SebaroSize.iconSm, color: .sbDanger)
                    Text(error).sbFont(.caption).foregroundStyle(context.tone.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - Select field and segmented control (spec/02 §2.3, §2.7; D99 (1); spec/08 §14.12, §14.13)

/// Select: the field of `SbTextField` with the chosen word in body (or `placeholder`, „Bitte wählen“, in text-muted)
/// and chevron-down at the end; label and control are one target. A press opens the system menu with the options and
/// the check mark at the chosen one (native on iOS); a choice sets `selection`. A long chosen word wraps, the control
/// grows. `optional` as `SbTextField` (D99 (3), D100 (4)).
public struct SbSelectField<Value: Hashable>: View {
    let label: String
    let options: [(value: Value, label: String)]
    @Binding var selection: Value?
    let placeholder: String?
    let help: String?
    let error: String?
    private var context = SbContext()
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = SebaroSize.controlMd

    public init(_ label: String, options: [(value: Value, label: String)], selection: Binding<Value?>,
                placeholder: String? = nil, help: String? = nil, error: String? = nil) {
        self.label = label
        self.options = options
        self._selection = selection
        self.placeholder = placeholder
        self.help = help
        self.error = error
    }

    public var body: some View {
        let chosen = options.first { $0.value == selection }?.label
        VStack(alignment: .leading, spacing: SebaroSpace.s1) {
            Text(label).sbFont(.label).foregroundStyle(context.tone.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            Menu {
                Picker(label, selection: $selection) {
                    ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                        Text(option.label).tag(Optional(option.value))
                    }
                }
            } label: {
                HStack(spacing: SebaroSpace.s2) {
                    Text(chosen ?? placeholder ?? context.messages.selectPlaceholder)
                        .sbFont(.body)
                        .foregroundStyle(chosen == nil ? context.tone.textMuted : context.tone.text)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    SbIcon("chevron-down", size: SebaroSize.iconLg, color: context.tone.textMuted)
                }
                .padding(.leading, SebaroSpace.s3)
                .padding(.trailing, SebaroSpace.s2)
                .padding(.vertical, SebaroSpace.s1)
                .frame(minHeight: height)
                .background(context.tone.surfaceSunken,
                            in: UnevenRoundedRectangle(topLeadingRadius: SebaroRadius.control,
                                                       topTrailingRadius: SebaroRadius.control))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(error == nil ? context.tone.borderStrong : Color.sbDanger)
                        .frame(height: error == nil ? SebaroBorderWidth.control : SebaroX.layerLineWidth)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(label))
            .accessibilityValue(Text(chosen ?? ""))
            .accessibilityHint(Text(error ?? help ?? ""))
            if let error {
                HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s1) {
                    SbIcon("error--filled", size: SebaroSize.iconSm, color: .sbDanger)
                    Text(error).sbFont(.caption).foregroundStyle(context.tone.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
            if let help {
                Text(help).sbFont(.caption).foregroundStyle(context.tone.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Segmented control: `label` (the legend) over 2–4 equal faces in one 1 pt border-strong frame (radius 8) with 1 pt
/// lines between; each face at least 48 pt, the word in label, centred. Chosen = the 3 pt accent bottom edge, the
/// 16 pt check, the title weight and the link colour, never filled; pressed `pressedFill`. VoiceOver: buttons with
/// „ausgewählt“. D99 (1), D101 (1): every option must fit its face on at most two lines with its words whole, measured
/// at the title weight with room for the check whichever option is chosen (as Compose); else the whole control becomes
/// `SbSelectField` with the same options.
public struct SbSegmented<Value: Hashable>: View {
    let label: String
    let options: [(value: Value, label: String)]
    @Binding var selection: Value
    private var context = SbContext()

    public init(_ label: String, options: [(value: Value, label: String)], selection: Binding<Value>) {
        precondition((2...4).contains(options.count), "SbSegmented: 2 to 4 options")
        self.label = label
        self.options = options
        self._selection = selection
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            segments
            SbSelectField(label, options: options,
                          selection: Binding(get: { selection }, set: { if let v = $0 { selection = v } }))
        }
    }

    private var segments: some View {
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.control, style: .continuous)
        return VStack(alignment: .leading, spacing: SebaroSpace.s1) {
            Text(label).sbFont(.label).foregroundStyle(context.tone.text)
                .accessibilityAddTraits(.isHeader)
            SbEqualColumns(extra: Self.faceExtra) {
                // the words and each option whole, at the chosen weight, measured but never drawn (D99 (1))
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    Text(option.label).font(faceFont(chosen: true)).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden().accessibilityHidden(true).layoutValue(key: SbSegmentProbeKey.self, value: .whole)
                    ForEach(Array(Set(option.label.split(whereSeparator: \.isWhitespace).map(String.init))), id: \.self) {
                        Text($0).font(faceFont(chosen: true)).fixedSize()
                            .hidden().accessibilityHidden(true).layoutValue(key: SbSegmentProbeKey.self, value: .word)
                    }
                }
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    let chosen = option.value == selection
                    Button { selection = option.value } label: {
                        HStack(spacing: SebaroSpace.s1) {
                            if chosen { SbIcon("check--16", size: SebaroSize.iconSm, color: .sbLink) }
                            Text(option.label).font(faceFont(chosen: chosen)).lineLimit(2)
                                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                                .foregroundStyle(chosen ? Color.sbLink : context.tone.text)
                        }
                        .padding(.horizontal, SebaroSpace.s1)   // as Compose: the column less 4 pt at both sides
                        .frame(maxWidth: .infinity, minHeight: SebaroSize.controlMd)
                        .overlay(alignment: .bottom) {
                            if chosen { Rectangle().fill(Color.sbAccent).frame(height: SebaroBorderWidth.strong) }
                        }
                        .overlay(alignment: .leading) {
                            if index > 0 { Rectangle().fill(context.tone.borderStrong).frame(width: SebaroBorderWidth.control) }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(SbRowButtonStyle())
                    .accessibilityAddTraits(chosen ? [.isSelected] : [])
                }
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(context.tone.borderStrong, lineWidth: SebaroBorderWidth.control))
        }
    }

    /// What a face needs beside its word: the side padding, the 16 pt check and its gap, the 1 pt line.
    static var faceExtra: CGFloat { 2 * SebaroSpace.s1 + SebaroSize.iconSm + SebaroSpace.s1 + SebaroBorderWidth.control }

    private func faceFont(chosen: Bool) -> Font {
        let label = SebaroTextStyle.label.resolve(context.scheme)
        let weight = chosen ? SebaroTextStyle.title.resolve(context.scheme) : label
        return SebaroFonts.font(SebaroTextFace(family: label.family, size: label.size, lineHeight: label.lineHeight,
                                               weight: weight.weight, weightValue: weight.weightValue,
                                               tracking: label.tracking),
                                relativeTo: .subheadline, monospacedDigits: false)
    }
}

/// Equal columns for the segments. Children: the faces, and before them per option a probe of the whole option and one
/// per word (`SbSegmentProbeKey`, in option order). The ideal width is count × the narrowest face in which every option
/// fits on two lines with its words whole (`SbSegmentFit`), so `ViewThatFits` can tell when it does not fit.
struct SbEqualColumns: Layout {
    let extra: CGFloat

    private func split(_ subviews: Subviews) -> (faces: [LayoutSubview], options: [(whole: LayoutSubview, words: [LayoutSubview])]) {
        var options: [(whole: LayoutSubview, words: [LayoutSubview])] = []
        var faces: [LayoutSubview] = []
        for s in subviews {
            switch s[SbSegmentProbeKey.self] {
            case .whole: options.append((s, []))
            case .word: options[options.count - 1].words.append(s)
            case .none: faces.append(s)
            }
        }
        return (faces, options)
    }

    /// The narrowest face that holds every option (nil: no probes, the faces' own widths).
    private func faceNeed(_ subviews: Subviews) -> CGFloat {
        let (faces, options) = split(subviews)
        guard !options.isEmpty else { return faces.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0 }
        let inner = options.map { o in
            SbSegmentFit.minInner(widestWord: o.words.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0,
                                  oneLine: o.whole.sizeThatFits(.unspecified),
                                  height: { o.whole.sizeThatFits(ProposedViewSize(width: $0, height: nil)).height })
        }.max() ?? 0
        return inner + extra
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let faces = split(subviews).faces
        let need = faceNeed(subviews) * CGFloat(faces.count)
        let w = proposal.width.map { $0.isFinite ? max($0, need) : need } ?? need
        let column = w / CGFloat(max(faces.count, 1))
        let height = faces.map { $0.sizeThatFits(ProposedViewSize(width: column, height: nil)).height }.max() ?? 0
        return CGSize(width: w, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let faces = split(subviews).faces
        let w = bounds.width / CGFloat(max(faces.count, 1))
        let h = faces.map { $0.sizeThatFits(ProposedViewSize(width: w, height: nil)).height }.max() ?? 0
        for (i, s) in faces.enumerated() {
            s.place(at: CGPoint(x: bounds.minX + CGFloat(i) * w, y: bounds.minY),
                    proposal: ProposedViewSize(width: w, height: max(h, bounds.height)))
        }
        for s in subviews where s[SbSegmentProbeKey.self] != nil { s.place(at: bounds.origin, proposal: .zero) }
    }
}

enum SbSegmentProbe: Sendable { case whole, word }
struct SbSegmentProbeKey: LayoutValueKey { static let defaultValue: SbSegmentProbe? = nil }

/// D99 (1), D101 (1): the narrowest room in which an option stands on at most two lines with its words whole.
enum SbSegmentFit {
    /// `widestWord` = its widest word, `oneLine` = the option on one line, `height(w)` = its height at width w.
    static func minInner(widestWord: CGFloat, oneLine: CGSize, height: (CGFloat) -> CGFloat) -> CGFloat {
        let twoLines = 2 * oneLine.height + 0.5
        var lo = widestWord, hi = max(oneLine.width, widestWord)
        if height(lo) <= twoLines { return lo }
        // height falls as the width grows: the narrowest width with at most two lines, to half a point
        while hi - lo > 0.5 {
            let mid = (lo + hi) / 2
            if height(mid) <= twoLines { hi = mid } else { lo = mid }
        }
        return hi
    }
}

// MARK: - Chips (spec/02 §2.9; spec/08 §14.9)

/// Filter chips: `labels` are the words, `selected` the chosen indices. `single` = exactly one chosen, pressing
/// another moves the choice. `groupLabel` names the group and stands above it. `max` (multiple choice): at the limit
/// the others are disabled and „Höchstens 3 auswählbar.“ stands under the group. One chip: a 48 pt target with a frame
/// of at least 36 pt (1 pt border-strong, radius 8), chosen = the 3 pt accent bottom edge, the 16 pt check, the title
/// weight and the link colour; the word wraps at large text, the chip grows; chips wrap into rows.
public struct SbChips: View {
    let groupLabel: String
    let labels: [String]
    @Binding var selected: Set<Int>
    let single: Bool
    let max: Int?
    let disabledOptions: Set<Int>
    let disabledReason: String?
    let help: String?
    let error: String?
    private var context = SbContext()

    /// `disabledOptions` cannot be chosen (`disabledReason` under the group); `help` and `error` as a field's notes
    /// (the error said once when it appears), as the Compose `SbChips`.
    public init(_ groupLabel: String, labels: [String], selected: Binding<Set<Int>>, single: Bool = false,
                max: Int? = nil, disabledOptions: Set<Int> = [], disabledReason: String? = nil, help: String? = nil,
                error: String? = nil) {
        self.groupLabel = groupLabel
        self.labels = labels
        self._selected = selected
        self.single = single
        self.max = max
        self.disabledOptions = disabledOptions
        self.disabledReason = disabledReason
        self.help = help
        self.error = error
    }

    /// The new choice after a press on chip `i` (single: exactly that one; multiple: toggled; a disabled chip or one
    /// past the limit changes nothing).
    static func press(_ i: Int, selected: Set<Int>, single: Bool, max: Int?, disabled: Set<Int>) -> Set<Int> {
        guard !disabled.contains(i) else { return selected }
        if single { return [i] }
        if selected.contains(i) { return selected.subtracting([i]) }
        if let max, selected.count >= max { return selected }
        return selected.union([i])
    }

    public var body: some View {
        let full = !single && max.map { selected.count >= $0 } ?? false
        VStack(alignment: .leading, spacing: SebaroSpace.s1) {
            Text(groupLabel).sbFont(.label).foregroundStyle(context.tone.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            SbWrapRow(spacing: SebaroSpace.s2) {
                ForEach(Array(labels.enumerated()), id: \.offset) { i, word in
                    let chosen = selected.contains(i)
                    SbChip(label: word, chosen: chosen, enabled: !disabledOptions.contains(i) && (chosen || !full)) {
                        selected = Self.press(i, selected: selected, single: single, max: max, disabled: disabledOptions)
                    }
                }
            }
            if full, let max {
                Text(context.messages.chipsMax(max)).sbFont(.caption).foregroundStyle(context.tone.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !disabledOptions.isEmpty, let disabledReason {
                SbWrapText(disabledReason, style: .caption).foregroundStyle(context.tone.textMuted)
            }
            if help != nil || error != nil { SbGroupNotes(help: help, error: error, announce: true) }
        }
    }
}

struct SbChip: View {
    let label: String
    let chosen: Bool
    let enabled: Bool
    let press: () -> Void
    private var context = SbContext()

    init(label: String, chosen: Bool, enabled: Bool, press: @escaping () -> Void) {
        self.label = label
        self.chosen = chosen
        self.enabled = enabled
        self.press = press
    }

    var body: some View {
        let ink: Color = !enabled ? context.tone.textMuted : (chosen ? .sbLink : context.tone.text)
        Button(action: press) {
            HStack(spacing: SebaroSpace.s1) {
                if chosen { SbIcon("check--16", size: SebaroSize.iconSm, color: ink) }
                Text(label).font(font).foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .buttonStyle(SbChipStyle(chosen: chosen))
        .disabled(!enabled)
        .accessibilityAddTraits(chosen ? [.isSelected] : [])
    }

    private var font: Font {
        let label = SebaroTextStyle.label.resolve(context.scheme)
        let weight = chosen ? SebaroTextStyle.title.resolve(context.scheme) : SebaroTextStyle.caption.resolve(context.scheme)
        return SebaroFonts.font(SebaroTextFace(family: label.family, size: label.size, lineHeight: label.lineHeight,
                                               weight: weight.weight, weightValue: weight.weightValue,
                                               tracking: label.tracking),
                                relativeTo: .subheadline, monospacedDigits: false)
    }
}

/// The chip's frame: 1 pt border-strong (border while disabled, text while pressed), radius 8, at least 36 pt in a
/// 48 pt target; chosen adds the 3 pt accent bottom edge (border-strong while disabled). No system dimming.
struct SbChipStyle: ButtonStyle {
    let chosen: Bool
    @Environment(\.isEnabled) private var enabled
    @Environment(\.isFocused) private var focused
    @Environment(\.sebaroTone) private var tone

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.control, style: .continuous)
        let frame = !enabled ? tone.border : (configuration.isPressed ? tone.text : tone.borderStrong)
        configuration.label
            .padding(.horizontal, SebaroSpace.s3)
            .padding(.vertical, SebaroSpace.s1)
            .frame(minHeight: SebaroSize.targetTouch - SebaroSpace.s3)
            .overlay(alignment: .bottom) {
                if chosen { Rectangle().fill(enabled ? Color.sbAccent : tone.borderStrong).frame(height: SebaroBorderWidth.strong) }
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(frame, lineWidth: SebaroBorderWidth.control))
            .modifier(SbFocusRing(shape: RoundedRectangle(cornerRadius: SebaroRadius.control + SebaroFocus.offset,
                                                          style: .continuous), focused: focused))
            .padding(.vertical, SebaroSpace.s1)
            .frame(minHeight: SebaroSize.targetTouch)
            .contentShape(Rectangle())
    }
}

// MARK: - Value tile (spec/02 §3.30; D105 (33), D106 (12); spec/08 §14.37)

/// The state a value tile shows under its number.
public enum SbValueState: Sendable { case plain, kept, struck }

/// A value tile: `value` in display (tabular) in a frame (1 pt border-strong, radius 8, no fill, at least 64 × 64 pt);
/// under it the state as glyph and word in caption, without colour: „behalten“ (check) and „gestrichen“ (close); the
/// plain tile keeps that line's room, so holding moves nothing. With `onToggle` it is a toggle (VoiceOver: „Würfel 3: 5,
/// behalten“ and „ausgewählt“ while held); `enabled` = false: it cannot be held now.
public struct SbValueTile: View {
    let value: String
    let state: SbValueState
    let name: String?
    let enabled: Bool
    let onToggle: ((Bool) -> Void)?
    private var context = SbContext()

    public init(_ value: String, state: SbValueState = .plain, name: String? = nil, enabled: Bool = true,
                onToggle: ((Bool) -> Void)? = nil) {
        self.value = value
        self.state = state
        self.name = name
        self.enabled = enabled
        self.onToggle = onToggle
    }

    public var body: some View {
        let m = context.messages
        let word: String? = switch state {
        case .kept: m.valueKept
        case .struck: m.valueStruck
        case .plain: nil
        }
        let spoken = [name.map { "\($0): \(value)" } ?? value, word].compactMap { $0 }.joined(separator: ", ")
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.control, style: .continuous)
        let tile = VStack(spacing: SebaroSpace.s1) {
            Text(value).sbFont(.display).monospacedDigit().foregroundStyle(context.tone.text)
            ZStack {
                line(m.valueKept, "check--16").hidden()
                line(m.valueStruck, "close--16").hidden()
                if state == .kept { line(m.valueKept, "check--16") }
                if state == .struck { line(m.valueStruck, "close--16") }
            }
        }
        .padding(SebaroSpace.s2)
        .frame(minWidth: SebaroSpace.s16, minHeight: SebaroSpace.s16)
        .overlay(shape.strokeBorder(context.tone.borderStrong, lineWidth: SebaroBorderWidth.control))
        .contentShape(shape)
        if let onToggle {
            Button { onToggle(state != .kept) } label: { tile }
                .buttonStyle(SbValueTileStyle())
                .disabled(!enabled)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(spoken))
                .accessibilityAddTraits(state == .kept ? [.isButton, .isSelected] : [.isButton])
        } else {
            tile.accessibilityElement(children: .ignore).accessibilityLabel(Text(spoken))
        }
    }

    private func line(_ word: String, _ glyph: String) -> some View {
        HStack(spacing: SebaroSpace.s1) {
            SbIcon(glyph, size: SebaroSize.iconSm, color: context.tone.text)
            Text(word).sbFont(.caption).foregroundStyle(context.tone.text).lineLimit(1).fixedSize()
        }
    }
}

struct SbValueTileStyle: ButtonStyle {
    @Environment(\.sebaroTone) private var tone
    @Environment(\.isFocused) private var focused
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.control, style: .continuous)
        configuration.label
            .background(configuration.isPressed ? tone.pressedFill : Color.clear, in: shape)
            .modifier(SbFocusRing(shape: RoundedRectangle(cornerRadius: SebaroRadius.control + SebaroFocus.offset,
                                                          style: .continuous), focused: focused))
    }
}
