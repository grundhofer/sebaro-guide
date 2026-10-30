import SwiftUI

// MARK: - Field details (spec/02 §2.9, §2.4; spec/08 §14.9, §14.12)

/// A field's notes under a group (the Compose `SbFieldNotes`): the error after the 16 pt danger glyph (caption, text),
/// then the help (caption, text-muted). With `announce` VoiceOver says the error once when it appears (polite).
struct SbGroupNotes: View {
    let help: String?
    let error: String?
    var announce = false
    private var context = SbContext()

    init(help: String?, error: String?, announce: Bool = false) {
        self.help = help
        self.error = error
        self.announce = announce
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SebaroSpace.s1) {
            if let error {
                HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s1) {
                    SbIcon("error--filled", size: SebaroSize.iconSm, color: .sbDanger)
                    SbWrapText(error, style: .caption).foregroundStyle(context.tone.text)
                }
                .accessibilityElement(children: .combine)
                .onAppear { if announce { SbAnnounce.polite(error) } }
                .onChange(of: error) { if announce { SbAnnounce.polite(error) } }
            }
            if let help {
                SbWrapText(help, style: .caption).foregroundStyle(context.tone.textMuted)
            }
        }
    }
}

/// The rows of one question (spec/02 §2.4, the Compose `SbChoiceGroup`): `label` above as a field's (a heading; `optional`
/// adds „(optional)“, D99 (3)), the `content` rows, then `help` and `error` as a field's notes, the gutter at the
/// sides. VoiceOver reads the error after the rows and says it once when it appears (polite).
public struct SbChoiceGroup<Content: View>: View {
    let label: String
    let optional: Bool
    let help: String?
    let error: String?
    let content: Content
    private var context = SbContext()

    public init(_ label: String, optional: Bool = false, help: String? = nil, error: String? = nil,
                @ViewBuilder content: () -> Content) {
        self.label = label
        self.optional = optional
        self.help = help
        self.error = error
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SbFieldLabel(label: label, optional: optional)
                .padding(.horizontal, SebaroSpacing.gutter)
                .padding(.vertical, SebaroSpace.s1)
                .accessibilityAddTraits(.isHeader)
            content
            if help != nil || error != nil {
                SbGroupNotes(help: help, error: error, announce: true)
                    .padding(.horizontal, SebaroSpacing.gutter)
                    .padding(.vertical, SebaroSpace.s1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

/// A field's label (label role, text): with `optional` a space and „(optional)“ in text-muted at the body weight,
/// read „Notiz, optional“ (D99 (3)).
struct SbFieldLabel: View {
    let label: String
    let optional: Bool
    private var context = SbContext()

    init(label: String, optional: Bool) {
        self.label = label
        self.optional = optional
    }

    var body: some View {
        let m = context.messages
        if optional {
            let labelFace = SebaroTextStyle.label.resolve(context.scheme)
            let bodyFace = SebaroTextStyle.body.resolve(context.scheme)
            let face = SebaroTextFace(family: labelFace.family, size: labelFace.size, lineHeight: labelFace.lineHeight,
                                      weight: bodyFace.weight, weightValue: bodyFace.weightValue, tracking: labelFace.tracking)
            (Text(label + " ") + Text("(\(m.fieldOptional))")
                .font(SebaroFonts.font(face, relativeTo: SebaroTextStyle.label.relativeTo, monospacedDigits: false))
                .foregroundColor(context.tone.textMuted))
                .sbFont(.label).foregroundStyle(context.tone.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(Text("\(label), \(m.fieldOptional)"))
        } else {
            SbWrapText(label, style: .label).foregroundStyle(context.tone.text)
        }
    }
}

/// Input chips (spec/02 §2.9): one chip per value, the word (label size at the caption weight, text) in a drawn 36 pt
/// frame (1 pt border-strong, radius 8) and a 48 pt remove button (close 16 pt, „<Wert> entfernen“) that calls
/// `onRemove` with the index. Chips wrap 8 pt apart; `groupLabel` names the group for VoiceOver. Never filled. The word
/// wraps at large text (Compose keeps it on one line; here nothing is cut, I7a).
public struct SbInputChips: View {
    let values: [String]
    let groupLabel: String
    let onRemove: (Int) -> Void
    private var context = SbContext()

    public init(_ values: [String], groupLabel: String, onRemove: @escaping (Int) -> Void) {
        self.values = values
        self.groupLabel = groupLabel
        self.onRemove = onRemove
    }

    public var body: some View {
        SbWrapRow(spacing: SebaroSpace.s2) {
            ForEach(Array(values.enumerated()), id: \.offset) { i, value in
                SbInputChip(value: value) { onRemove(i) }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(groupLabel))
    }
}

struct SbInputChip: View {
    let value: String
    let onRemove: () -> Void
    private var context = SbContext()

    init(value: String, onRemove: @escaping () -> Void) {
        self.value = value
        self.onRemove = onRemove
    }

    var body: some View {
        let inset = SebaroSpace.s3 / 2   // 6 pt: the 36 pt frame in a 48 pt row (spec/02 §2.9)
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.control, style: .continuous)
        HStack(spacing: 0) {
            SbWrapText(value).font(font).foregroundStyle(context.tone.text)
                .padding(.vertical, inset + SebaroSpace.s1)
                .padding(.leading, SebaroSpace.s3)
            Button(action: onRemove) { EmptyView() }
                .buttonStyle(SbRemoveIconStyle())
            .accessibilityLabel(Text(context.messages.removeValue(value)))
        }
        .frame(minHeight: SebaroSize.targetTouch)
        .background {
            shape.strokeBorder(context.tone.borderStrong, lineWidth: SebaroBorderWidth.control)
                .padding(.vertical, inset)
        }
    }

    private var font: Font {
        let label = SebaroTextStyle.label.resolve(context.scheme)
        let caption = SebaroTextStyle.caption.resolve(context.scheme)
        return SebaroFonts.font(SebaroTextFace(family: label.family, size: label.size, lineHeight: label.lineHeight,
                                               weight: caption.weight, weightValue: caption.weightValue,
                                               tracking: label.tracking),
                                relativeTo: .subheadline, monospacedDigits: false)
    }
}

/// The remove button of an input chip: close 16 pt in a 48 pt target, text-muted, text while pressed; no fill.
struct SbRemoveIconStyle: ButtonStyle {
    @Environment(\.sebaroTone) private var tone
    @Environment(\.isFocused) private var focused
    func makeBody(configuration: Configuration) -> some View {
        SbIcon("close--16", size: SebaroSize.iconSm, color: configuration.isPressed ? tone.text : tone.textMuted)
            .frame(width: SebaroSize.targetTouch, height: SebaroSize.targetTouch)
            .contentShape(Rectangle())
            .modifier(SbFocusRing(shape: RoundedRectangle(cornerRadius: SebaroRadius.control), focused: focused))
    }
}
