import SwiftUI

// MARK: - Choice rows with a check mark (D75, D91 I8a)

/// A group of choice rows: the group title (label, text), then flat 56 pt rows with hairlines (not the filled groups
/// of iOS). The chosen row carries the `check` icon at its end in `sbAccent` and its word at body-strong; the whole
/// row is the target; VoiceOver reads „ausgewählt“. The check mark is how iOS and the desktop menus show a choice
/// (D67 (4), (8)); Android keeps its radio rings (spec/08 §12).
public struct SbCheckChoice<Value: Hashable>: View {
    let title: String
    let options: [(value: Value, label: String)]
    @Binding var selection: Value
    private var context = SbContext()
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = SebaroSize.controlLg

    public init(_ title: String, options: [(value: Value, label: String)], selection: Binding<Value>) {
        self.title = title
        self.options = options
        self._selection = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).sbFont(.label).foregroundStyle(context.tone.text)
                .padding(.horizontal, SebaroSpacing.gutter)
                .padding(.vertical, SebaroSpace.s2)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                let chosen = option.value == selection
                Button { selection = option.value } label: {
                    HStack(spacing: SebaroSpace.s3) {
                        Text(option.label).sbFont(chosen ? .bodyStrong : .body).foregroundStyle(context.tone.text)
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
            }
        }
    }
}

/// Pressed fill for a full-width row, the inset focus ring (spec/08 §3).
struct SbRowButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var focused
    @Environment(\.sebaroTone) private var tone
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? tone.pressedFill : Color.clear)
            .overlay {
                if focused {
                    Rectangle().strokeBorder(Color.sbFocus, lineWidth: SebaroFocus.width).allowsHitTesting(false)
                }
            }
            .focusEffectDisabled()
    }
}

/// Einstellungen › „Hell oder Dunkel“ (D75, D91 I8a): „Wie das System“, „Hell“, „Dunkel“ with a check mark, stored as
/// `sb-theme`; `SebaroAppRoot` applies it to the windows. Words from the words table.
public struct SbThemeChoice: View {
    @AppStorage(SbThemeMode.storageKey) private var raw = SbThemeMode.system.rawValue
    private var context = SbContext()
    public init() {}

    public var body: some View {
        let m = context.messages
        SbCheckChoice(m.themeGroup,
                      options: [(SbThemeMode.system, m.themeSystem), (.light, m.themeLight), (.dark, m.themeDark)],
                      selection: Binding(get: { SbThemeMode(rawValue: raw) ?? .system }, set: { raw = $0.rawValue }))
    }
}

/// Einstellungen › „Farbton“: „Kühl“ (the standard palette) or „Warm“ (the warm palette „Papier“, D90, D91 C4c),
/// stored as `sb-tone` = "warm" (nothing stored = cool), next to Hell/Dunkel. The tone replaces only the grey roles
/// (`SebaroTone` in SebaroTokens.swift); cobalt, lime, status colours and tiles stay.
public struct SbToneChoice: View {
    @AppStorage(SbSettingKeys.tone) private var raw = ""
    private var context = SbContext()
    public init() {}

    public var body: some View {
        let m = context.messages
        SbCheckChoice(m.toneGroup, options: [(SebaroTone.cool, m.toneCool), (.warm, m.toneWarm)],
                      selection: Binding(get: { raw == "warm" ? .warm : .cool }, set: { raw = $0 == .warm ? "warm" : "" }))
    }
}

/// A switch row (spec/02 §2.6, 2026-10-26; provisional, agent): [title] in body, the optional [help] sentence in caption
/// `text-muted` under it, the system toggle at the end in `sbAccent` (never lime); at least 56 pt, the whole row
/// toggles, VoiceOver reads title, help and state as one element. `SbMotionSetting` is built on it.
public struct SbSwitchRow: View {
    let title: String
    let help: String?
    @Binding var isOn: Bool
    private var context = SbContext()
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = SebaroSize.controlLg

    public init(_ title: String, help: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.help = help
        self._isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: SebaroSpace.s0_5) {
                Text(title).sbFont(.body).foregroundStyle(context.tone.text)
                if let help {
                    Text(help).sbFont(.caption).foregroundStyle(context.tone.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Color.sbAccent)
        .padding(.horizontal, SebaroSpacing.gutter)
        .padding(.vertical, SebaroSpace.s2)
        .frame(minHeight: rowHeight)
    }
}

/// Einstellungen › „Bewegung immer reduzieren“ (D46, spec/03 §13), stored as `sb-motion` = "reduce": the switch on
/// is `sbAccent` (never lime), the help sentence under it.
public struct SbMotionSetting: View {
    @AppStorage(SbSettingKeys.motion) private var raw = ""
    private var context = SbContext()
    public init() {}

    public var body: some View {
        SbSwitchRow(context.messages.motionReduce, help: context.messages.motionReduceHelp,
                    isOn: Binding(get: { raw == "reduce" }, set: { raw = $0 ? "reduce" : "" }))
    }
}

// MARK: - Field (spec/02 §2.1): label above, filled with surface-sunken, 1 pt baseline

/// A text field: the label above, the field filled with `surface-sunken`, a 1 pt border-strong baseline; with an
/// error the baseline is 2 pt `danger` and the message stands under it in text after the error glyph (never a red
/// sentence alone, D83 (2)). 48 pt high, growing with Dynamic Type. `optional` marks a voluntary field (D99 (3)):
/// „(optional)“ after the label in `text-muted` at the body weight; VoiceOver reads „Notiz, optional“. Required is
/// the norm and carries no mark, never an asterisk. `placeholder` in text-muted while empty (it may end in „…“
/// beside its label, D111 (4)); `help` in caption text-muted under the field with an optional end-aligned `counter`
/// („0 / 120“); `multiline` = the web's textarea (grows line by line, never cut). Focus for „<Beschriftung> fehlt.“
/// (D98 V2): `.sbFieldFocus($focus, equals: .name)` binds the field to the form's `@FocusState`
/// (`SbRequiredFields`).
public struct SbTextField: View {
    let label: String
    @Binding var text: String
    let error: String?
    let optional: Bool
    let placeholder: String?
    let help: String?
    let counter: String?
    let multiline: Bool
    var focusBinding: ((AnyView) -> AnyView)?
    var trailing: SbIconButton?
    private var context = SbContext()
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = SebaroSize.controlMd

    public init(_ label: String, text: Binding<String>, error: String? = nil, optional: Bool = false,
                placeholder: String? = nil, help: String? = nil, counter: String? = nil, multiline: Bool = false) {
        self.label = label
        self._text = text
        self.error = error
        self.optional = optional
        self.placeholder = placeholder
        self.help = help
        self.counter = counter
        self.multiline = multiline
    }

    /// Binds the field to a form's focus state (`@FocusState private var focus: Field?`), so the form can move focus
    /// to the first empty required field (D98 V2) and VoiceOver reads it with its error.
    public func sbFieldFocus<V: Hashable>(_ binding: FocusState<V>.Binding, equals value: V) -> SbTextField {
        var copy = self
        copy.focusBinding = { AnyView($0.focused(binding, equals: value)) }
        return copy
    }

    /// One icon button at the control's end (spec/08 §14.12, the Compose `trailing`): „Kalender“ opens a date sheet, „Leeren“
    /// clears. A 48 pt target inside the field; the value keeps the room before it.
    public func sbTrailing(_ icon: String, label: String, action: @escaping () -> Void) -> SbTextField {
        var copy = self
        copy.trailing = SbIconButton(icon, label: label, action: action)
        return copy
    }

    /// The label's words; with `optional` a space and „(optional)“ in text-muted, the label's size at the body weight.
    private var labelText: Text {
        guard optional else { return Text(label) }
        let labelFace = SebaroTextStyle.label.resolve(context.scheme)
        let bodyFace = SebaroTextStyle.body.resolve(context.scheme)
        let face = SebaroTextFace(family: labelFace.family, size: labelFace.size, lineHeight: labelFace.lineHeight,
                                  weight: bodyFace.weight, weightValue: bodyFace.weightValue, tracking: labelFace.tracking)
        var words = AttributedString(label + " ")
        var suffix = AttributedString("(\(context.messages.fieldOptional))")
        suffix.font = SebaroFonts.font(face, relativeTo: SebaroTextStyle.label.relativeTo, monospacedDigits: false)
        suffix.foregroundColor = context.tone.textMuted
        words.append(suffix)
        return Text(words)
    }

    /// What VoiceOver reads for the label: „Notiz“, or „Notiz, optional“.
    private var spokenLabel: String { optional ? "\(label), \(context.messages.fieldOptional)" : label }

    public var body: some View {
        // the prompt is drawn by the field: it takes the body cut itself, so it grows with Dynamic Type as the value
        let prompt = placeholder.map {
            Text($0).font(SebaroTextStyle.body.exactFont(for: context.scheme)).foregroundStyle(context.tone.textMuted)
        }
        let input = multiline
            ? AnyView(TextField("", text: $text, prompt: prompt, axis: .vertical).lineLimit(1...))
            : AnyView(TextField("", text: $text, prompt: prompt))
        let field = focusBinding?(input) ?? input
        VStack(alignment: .leading, spacing: SebaroSpace.s1) {
            labelText.sbFont(.label).foregroundStyle(context.tone.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(Text(spokenLabel))
            HStack(spacing: 0) {
                field
                    .sbFont(.body)
                    .foregroundStyle(context.tone.text)
                    .padding(.leading, SebaroSpace.s3)
                    .padding(.trailing, trailing == nil ? SebaroSpace.s3 : 0)
                    .padding(.vertical, multiline ? SebaroSpace.s3 : 0)
                    .accessibilityLabel(Text(spokenLabel))
                    .accessibilityHint(Text([error, help].compactMap { $0 }.joined(separator: ", ")))
                if let trailing { trailing }
            }
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
            if help != nil || counter != nil {
                HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s3) {
                    Text(help ?? "").sbFont(.caption).foregroundStyle(context.tone.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let counter {
                        Text(counter).sbFont(.caption).monospacedDigit().foregroundStyle(context.tone.textMuted)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
