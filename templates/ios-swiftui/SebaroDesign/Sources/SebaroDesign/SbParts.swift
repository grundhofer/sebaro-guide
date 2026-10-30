import SwiftUI

// MARK: - Empty state (spec/02 §3.14; spec/08 §14.5)

/// Empty state: an optional spot illustration (a `--spot` sprite id, drawn in text-muted, its size fixed at 96 pt),
/// `title` (title, a heading) and `text` (one sentence how the view fills, text-muted). Never an action inside: the
/// primary action stays in `SbScreen`'s bottom block.
public struct SbEmptyState: View {
    let title: String
    let text: String
    let spot: String?
    private var context = SbContext()

    public init(_ title: String, text: String, spot: String? = nil) {
        self.title = title
        self.text = text
        self.spot = spot
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SebaroSpace.s2) {
            if let spot { SbIcon(spot, size: SebaroSpace.s12 * 2, color: context.tone.textMuted).accessibilityHidden(true) }
            Text(title).sbFont(.title).foregroundStyle(context.tone.text).accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)
            Text(text).sbFont(.body).foregroundStyle(context.tone.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SebaroSpacing.gutter)
        .padding(.vertical, SebaroSpace.s6)
    }
}

// MARK: - Callout (spec/02 §3.11; spec/08 §14.18)

public enum SbCalloutKind: Sendable { case note, warning, error, success }

/// Callout: the 20 pt filled glyph of `kind` in its status colour, then `title` (nil = the kind's word: „Hinweis“,
/// „Achtung“, „Fehler“, „Erfolg“) in body-strong over `text` in body, both in text, inside a 1 pt border hairline
/// frame, radius container, 12 by 16 pt inside. No fill and no coloured edge (the 3 pt edge means place). One
/// VoiceOver element for glyph, title and text; `actions` (secondary or text actions, never the primary action) stand
/// under the text as their own elements.
public struct SbCallout<Actions: View>: View {
    let kind: SbCalloutKind
    let text: String
    let title: String?
    let actions: Actions
    private var context = SbContext()

    public init(_ kind: SbCalloutKind, text: String, title: String? = nil, @ViewBuilder actions: () -> Actions) {
        self.kind = kind
        self.text = text
        self.title = title
        self.actions = actions()
    }

    public var body: some View {
        let m = context.messages
        let (glyph, tint, word): (String, Color, String) = switch kind {
        case .note: ("info--filled", .sbInfo, m.calloutNote)
        case .warning: ("warning--filled", .sbWarning, m.calloutWarning)
        case .error: ("error--filled", .sbDanger, m.calloutError)
        case .success: ("success--filled", .sbSuccess, m.calloutSuccess)
        }
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.container, style: .continuous)
        HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s3) {
            SbIcon(glyph, size: SebaroSize.iconMd, color: tint).alignmentGuide(.firstTextBaseline) { $0[.bottom] - 4 }
            VStack(alignment: .leading, spacing: SebaroSpace.s1) {
                VStack(alignment: .leading, spacing: SebaroSpace.s1) {
                    Text(title ?? word).sbFont(.bodyStrong)
                    Text(text).sbFont(.body)
                }
                .foregroundStyle(context.tone.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
                actions
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, SebaroSpace.s4)
        .padding(.vertical, SebaroSpace.s3)
        .overlay(shape.strokeBorder(context.tone.border, lineWidth: SebaroBorderWidth.hairline))
    }
}

public extension SbCallout where Actions == EmptyView {
    init(_ kind: SbCalloutKind, text: String, title: String? = nil) {
        self.init(kind, text: text, title: title) { EmptyView() }
    }
}

// MARK: - Tag and category (spec/02 §3.2, §3.1b; D73, D91 C1b)

/// Tag: an outlined word („Verfügbar“, „Beta“) in caption at 400 in text, 1 pt border-strong frame, radius small,
/// 8 pt at the sides. Never a status colour, not interactive.
public struct SbTag: View {
    let text: String
    private var context = SbContext()
    public init(_ text: String) { self.text = text }
    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.small, style: .continuous)
        // a word wider than the line at large text breaks with a hyphen, not between letters (§39.8)
        SbWrapText(text, style: .caption).foregroundStyle(context.tone.text)
            .padding(.horizontal, SebaroSpace.s2)
            .padding(.vertical, SebaroBorderWidth.hairline)
            .overlay(shape.strokeBorder(context.tone.borderStrong, lineWidth: SebaroBorderWidth.hairline))
    }
}

/// „Beispieldaten“ (FACTS-CONTRACT §8.5 f): the word in caption text, in a 1 pt border-strong frame, radius small,
/// 1 pt × 8 pt padding, as `SbTag` (the Compose `SbDemoMarker`). The caller passes the fixed state word (D24).
public struct SbDemoMarker: View {
    let text: String
    public init(_ text: String) { self.text = text }
    public var body: some View { SbTag(text) }
}

/// Category: content the user files himself. `tone` 1…6 = `SebaroCategory.all`: a 10 pt dot (or `icon`, 20 pt) in
/// that tone, 8 pt, then `text` in text; nil = the word alone. Never a fill, never text colour, never a state the app
/// assigns. One VoiceOver element.
public struct SbCategory: View {
    let text: String
    let tone: Int?
    let icon: String?
    private var context = SbContext()

    public init(_ text: String, tone: Int? = nil, icon: String? = nil) {
        precondition(tone.map { (1...6).contains($0) } ?? true, "SbCategory: tone 1 to 6 (D91 C1b), or nil")
        self.text = text
        self.tone = tone
        self.icon = icon
    }

    public var body: some View {
        let color = tone.flatMap { n in SebaroCategory.all.first { $0.number == n }?.color }
        HStack(spacing: SebaroSpace.s2) {
            if let icon {
                SbIcon(icon, size: SebaroSize.iconMd, color: color ?? context.tone.text)
            } else if let color {
                Circle().fill(color).frame(width: 10, height: 10)   // the web's 10px dot, no size token
            }
            Text(text).sbFont(.body).foregroundStyle(context.tone.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Check row (spec/02 §2.4; spec/08 §12.3)

/// A check row: the 24 pt check box at the start (no fill, edge and check in accent when checked, border-strong edge
/// when not), `title` in body and `help` in caption text-muted; at least 48 pt (56 pt with help), the whole row
/// toggles, pressed `pressedFill`. VoiceOver: the title with „angekreuzt“ / „nicht angekreuzt“.
public struct SbCheckRow: View {
    let title: String
    let help: String?
    @Binding var isOn: Bool
    private var context = SbContext()
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SebaroSize.controlMd

    public init(_ title: String, help: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.help = help
        self._isOn = isOn
    }

    public var body: some View {
        let box = RoundedRectangle(cornerRadius: SebaroRadius.small, style: .continuous)
        Button { isOn.toggle() } label: {
            HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s3) {
                ZStack {
                    box.strokeBorder(isOn ? Color.sbAccent : context.tone.borderStrong, lineWidth: SebaroX.layerLineWidth)
                    if isOn { SbIcon("check", size: SebaroSize.iconSm, color: .sbAccent) }
                }
                .frame(width: SebaroSize.iconMd, height: SebaroSize.iconMd)
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 4 }
                VStack(alignment: .leading, spacing: 0) {
                    Text(title).sbFont(.body).foregroundStyle(context.tone.text)
                    if let help { Text(help).sbFont(.caption).foregroundStyle(context.tone.textMuted) }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, SebaroSpacing.gutter)
            .padding(.vertical, SebaroSpace.s3)
            .frame(maxWidth: .infinity, minHeight: help == nil ? minHeight : minHeight + SebaroSpace.s2)
            .contentShape(Rectangle())
        }
        .buttonStyle(SbRowButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(isOn ? context.messages.checkOn : context.messages.checkOff))
    }
}

// MARK: - Skeleton (spec/02 §3.12; D80; spec/08 §14.6)

/// One bar of a skeleton: a title bar (20 pt, 40 %), a long (12 pt, 90 %) or a short line (12 pt, 55 %).
public enum SbSkeletonLine: Sendable { case title, long, short }

/// Skeleton for remote content over 1 s: `label` („Wird geladen …“) above static bars in border grey; no shimmer and
/// no movement (D80). VoiceOver reads the label only. Remove it when the content arrives.
public struct SbSkeleton: View {
    let label: String
    let lines: [SbSkeletonLine]
    private var context = SbContext()

    public init(_ label: String, lines: [SbSkeletonLine] = [.title, .long, .long, .short]) {
        self.label = label
        self.lines = lines
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SebaroSpace.s2) {
            Text(label).sbFont(.caption).foregroundStyle(context.tone.textMuted)
            GeometryReader { geo in
                VStack(alignment: .leading, spacing: SebaroSpace.s2) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        let (h, share): (CGFloat, CGFloat) = switch line {
                        case .title: (SebaroSpace.s5, 0.4)
                        case .long: (SebaroSpace.s3, 0.9)
                        case .short: (SebaroSpace.s3, 0.55)
                        }
                        RoundedRectangle(cornerRadius: SebaroRadius.small).fill(context.tone.border)
                            .frame(width: geo.size.width * share, height: h)
                    }
                }
            }
            .frame(height: lines.reduce(0) { $0 + ($1 == .title ? SebaroSpace.s5 : SebaroSpace.s3) }
                   + SebaroSpace.s2 * CGFloat(max(lines.count - 1, 0)))
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}
