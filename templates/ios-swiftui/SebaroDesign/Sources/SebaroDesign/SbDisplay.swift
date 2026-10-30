import SwiftUI

// MARK: - Display set (spec/02 §3.2, §3.4, §3.8, §3.13, §3.22; D52, D80, D83 (3), D91 B8b, D101 (6))

/// Tags in a row that wraps, 8 pt apart (`sb-tags`): `SbTag` and `SbDemoMarker`.
public struct SbTags<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        SbWrapRow(spacing: SebaroSpace.s2) { content }
    }
}

/// One row of a meta list: `label` („Erinnerung“) and its `value` („alle 2 Stunden“). `fileName` = the value is a file
/// name: it breaks only after - . _ / without a hyphen (D101 (6)); an identifier („1.4.0“) stays plain (D80).
public struct SbMetaItem: Sendable {
    public let label: String
    public let value: String
    public let fileName: Bool
    public init(_ label: String, value: String, fileName: Bool = false) {
        self.label = label
        self.value = value
        self.fileName = fileName
    }
}

/// Meta list (spec/02 §3.8): rows of at least 48 pt, the label in caption text-muted and the value in body with tabular
/// figures, columns 2 : 3, a 1 pt border hairline between rows. `labels` = `sb-meta-list--labels` (D80): a label column
/// of 160 pt growing with the text, the value in the rest, 12 pt above and below; once the value would keep less than
/// half the label column the label stands above the value. The plain list does the same once a word of either no
/// longer fits its column (D99 (1)). One arrangement per list (spec/08 §14.18); `stacked` sets it, nil measures it. One
/// VoiceOver element per row.
public struct SbMetaList: View {
    let items: [SbMetaItem]
    let labels: Bool
    let stacked: Bool?
    private var context = SbContext()
    @ScaledMetric(relativeTo: .body) private var column: CGFloat = SebaroSpace.s16 * 2 + SebaroSpace.s8

    public init(_ items: [SbMetaItem], labels: Bool = false, stacked: Bool? = nil) {
        self.items = items
        self.labels = labels
        self.stacked = stacked
    }

    public var body: some View {
        // stacked when the side-by-side rows would break a word: ViewThatFits measures the rows at their ideal widths
        Group {
            if let stacked {
                rows(onTop: stacked)
            } else {
                ViewThatFits(in: .horizontal) {
                    rows(onTop: false)
                    rows(onTop: true)
                }
            }
        }
    }

    private func value(_ item: SbMetaItem) -> some View {
        Group {
            if item.fileName {
                SbWrapText.fileName(item.value)
            } else {
                Text(item.value).fixedSize(horizontal: false, vertical: true)
            }
        }
        .font(SebaroTextStyle.body.exactFont(for: context.scheme).monospacedDigit())
        .foregroundStyle(context.tone.text)
    }

    private func label(_ item: SbMetaItem) -> some View {
        SbWrapText(item.label, style: .caption).foregroundStyle(context.tone.textMuted)
    }

    private func rows(onTop: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                Group {
                    if onTop {
                        VStack(alignment: .leading, spacing: 0) {
                            label(item)
                            value(item)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else if labels {
                        HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s3) {
                            label(item).frame(width: column, alignment: .leading)
                            // the value keeps at least half the label column, else the label goes above it (D80)
                            value(item).frame(minWidth: column / 2, maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        SbRatioRow(gap: SebaroSpace.s3) {
                            label(item)
                            value(item)
                            // plain probes: a Text offered no width reports its widest word
                            Text(item.label).sbFont(.caption).hidden()
                            Text(item.fileName ? sbFileNameBreaks(item.value) : item.value)
                                .font(SebaroTextStyle.body.exactFont(for: context.scheme).monospacedDigit()).hidden()
                        }
                    }
                }
                .padding(.vertical, labels || onTop ? SebaroSpace.s3 : 0)
                .frame(minHeight: SebaroSize.targetTouch)
                .overlay(alignment: .top) {
                    if i > 0 { Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline) }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// Two subviews side by side in the columns 2 : 3, centred; subviews 2 and 3 are hidden plain-text probes of the two
/// (a `Text` offered no width reports its widest word). Its ideal width is what both need so that no word breaks, so
/// `ViewThatFits` stacks the rows once a word no longer fits its column (D99 (1)).
struct SbRatioRow: Layout {
    let gap: CGFloat

    static func least(labelWord: CGFloat, valueWord: CGFloat, gap: CGFloat) -> CGFloat {
        max(labelWord * 5 / 2, valueWord * 5 / 3) + gap
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 4 else { return .zero }
        let words = [2, 3].map { subviews[$0].sizeThatFits(ProposedViewSize(width: 0, height: nil)).width }
        let least = Self.least(labelWord: words[0], valueWord: words[1], gap: gap)
        let w = proposal.width.map { max($0, least) } ?? least
        let a = (w - gap) * 2 / 5, b = (w - gap) * 3 / 5
        let h = max(subviews[0].sizeThatFits(ProposedViewSize(width: a, height: nil)).height,
                    subviews[1].sizeThatFits(ProposedViewSize(width: b, height: nil)).height)
        return CGSize(width: w, height: h)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let a = (bounds.width - gap) * 2 / 5, b = (bounds.width - gap) * 3 / 5
        subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading,
                          proposal: ProposedViewSize(width: a, height: nil))
        subviews[1].place(at: CGPoint(x: bounds.minX + a + gap, y: bounds.midY), anchor: .leading,
                          proposal: ProposedViewSize(width: b, height: nil))
        for i in 2..<subviews.count { subviews[i].place(at: CGPoint(x: -100_000, y: bounds.minY), proposal: .unspecified) }
    }
}

/// Card (spec/02 §3.4) for settings or figures: level 1 (D46), `bg` with the 2 pt layer line, radius container, 16 pt
/// inside, parts 8 pt apart: `title` (title), `text` (body text-muted), `content`, then `actions` (8 pt more, wrapping).
/// `onTap` = the whole card is the target: the title gets the link underline, the pressed fill, the focus ring. Never
/// tinted, never a shadow, never for list items.
public struct SbCard<Content: View, Actions: View>: View {
    let title: String?
    let text: String?
    let onTap: (() -> Void)?
    let content: Content
    let actions: Actions
    private var context = SbContext()

    public init(title: String? = nil, text: String? = nil, onTap: (() -> Void)? = nil,
                @ViewBuilder content: () -> Content, @ViewBuilder actions: () -> Actions) {
        self.title = title
        self.text = text
        self.onTap = onTap
        self.content = content()
        self.actions = actions()
    }

    public var body: some View {
        let inner = VStack(alignment: .leading, spacing: SebaroSpace.s2) {
            if let title {
                if onTap != nil {
                    Text(title).sbFont(.title).foregroundStyle(context.tone.text)
                        .underline(true, pattern: .solid, color: .sbLink)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    SbWrapText(title, style: .title).foregroundStyle(context.tone.text)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            if let text { SbWrapText(text, style: .body).foregroundStyle(context.tone.textMuted) }
            content
            SbWrapRow(spacing: SebaroSpace.s2) { actions }.padding(.top, SebaroSpace.s2)
        }
        SbCardFrame(edge: SebaroX.layerLineWidth, color: context.tone.layerLine, onTap: onTap) { inner }
    }
}

public extension SbCard where Actions == EmptyView {
    init(title: String? = nil, text: String? = nil, onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, text: text, onTap: onTap, content: content, actions: { EmptyView() })
    }
}

public extension SbCard where Actions == EmptyView, Content == EmptyView {
    init(title: String? = nil, text: String? = nil, onTap: (() -> Void)? = nil) {
        self.init(title: title, text: text, onTap: onTap, content: { EmptyView() }, actions: { EmptyView() })
    }
}

/// Item card (spec/02 §3.4, D83 (3)): one of many cards of one kind (board, collection): a 1 pt border-strong edge,
/// radius container, 16 pt inside, `title` in title, `text` in body text-muted. `current` = the 3 pt accent place line
/// at its start (only one card is current; VoiceOver „aktuell“). `onTap` as `SbCard`, without the underline.
public struct SbItemCard: View {
    let title: String
    let text: String?
    let current: Bool
    let onTap: (() -> Void)?
    private var context = SbContext()

    public init(_ title: String, text: String? = nil, current: Bool = false, onTap: (() -> Void)? = nil) {
        self.title = title
        self.text = text
        self.current = current
        self.onTap = onTap
    }

    public var body: some View {
        SbCardFrame(edge: SebaroBorderWidth.control, color: context.tone.borderStrong, onTap: onTap, place: current) {
            VStack(alignment: .leading, spacing: SebaroSpace.s2) {
                SbWrapText(title, style: .title).foregroundStyle(context.tone.text)
                if let text { SbWrapText(text, style: .body).foregroundStyle(context.tone.textMuted) }
            }
        }
        .accessibilityValue(Text(current ? context.messages.itemCurrent : ""))
    }
}

/// The frame of both cards: edge, radius 12, 16 pt inside; the whole card as target and the place line.
struct SbCardFrame<Content: View>: View {
    let edge: CGFloat
    let color: Color
    let onTap: (() -> Void)?
    var place = false
    let content: Content

    init(edge: CGFloat, color: Color, onTap: (() -> Void)?, place: Bool = false, @ViewBuilder content: () -> Content) {
        self.edge = edge
        self.color = color
        self.onTap = onTap
        self.place = place
        self.content = content()
    }

    var body: some View {
        if let onTap {
            Button(action: onTap) { content }
                .buttonStyle(SbCardButtonStyle(edge: edge, color: color, place: place))
        } else {
            SbCardBox(edge: edge, color: color, place: place, pressed: false) { content }
                .accessibilityElement(children: .combine)
        }
    }

}

struct SbCardButtonStyle: ButtonStyle {
    let edge: CGFloat
    let color: Color
    let place: Bool
    @Environment(\.isFocused) private var focused
    func makeBody(configuration: Configuration) -> some View {
        SbCardBox(edge: edge, color: color, place: place, pressed: configuration.isPressed) { configuration.label }
            .modifier(SbFocusRing(shape: RoundedRectangle(cornerRadius: SebaroRadius.container + SebaroFocus.offset,
                                                          style: .continuous), focused: focused))
    }
}

struct SbCardBox<Content: View>: View {
    let edge: CGFloat
    let color: Color
    let place: Bool
    let pressed: Bool
    let content: Content
    @Environment(\.sebaroTone) private var tone

    init(edge: CGFloat, color: Color, place: Bool, pressed: Bool, @ViewBuilder content: () -> Content) {
        self.edge = edge
        self.color = color
        self.place = place
        self.pressed = pressed
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.container, style: .continuous)
        content
            .padding(SebaroSpace.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(pressed ? tone.pressedFill : tone.bg, in: shape)
            .overlay(alignment: .leading) {
                if place { Rectangle().fill(Color.sbAccent).frame(width: SebaroBorderWidth.strong) }
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(color, lineWidth: edge))
            .contentShape(shape)
    }
}

/// The initials of a name: the first letters of its first and last word („Anna Keller“ → „AK“).
public func sbInitials(_ name: String) -> String {
    let words = name.split(separator: " ").filter { !$0.isEmpty }
    return [words.first, words.dropFirst().last].compactMap { $0?.prefix(1).uppercased() }.joined()
}

/// Avatar (spec/02 §3.13): `initials` in label (small: the label weight at the small label size) in text, in a circle of
/// 40 pt (small: 32 pt) with a 1 pt border-strong ring, no fill; the circle tells people from app signs. The circle
/// grows with the text. VoiceOver reads `name`, never the initials.
public struct SbAvatar: View {
    let name: String
    let initials: String
    let small: Bool
    private var context = SbContext()
    @ScaledMetric(relativeTo: .subheadline) private var scale: CGFloat = 1

    public init(_ name: String, initials: String? = nil, small: Bool = false) {
        self.name = name
        self.initials = initials ?? sbInitials(name)
        self.small = small
    }

    public var body: some View {
        let edge = (small ? SebaroSpace.s8 : SebaroSpace.s10) * scale
        Text(initials).sbFont(small ? .labelSmall : .label).foregroundStyle(context.tone.text)
            .lineLimit(1).fixedSize()
            .frame(width: edge, height: edge)
            .overlay(Circle().strokeBorder(context.tone.borderStrong, lineWidth: SebaroBorderWidth.control))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(name))
    }
}

/// Avatars in a row, 4 pt apart (`sb-avatars`), the group named by `label` („Auf der Tafel“); they wrap at large text.
public struct SbAvatars<Content: View>: View {
    let label: String
    let content: Content
    public init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    public var body: some View {
        SbWrapRow(spacing: SebaroSpace.s1) { content }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(label))
    }
}

/// Quote (spec/02 §3.22, D91 B8b): `paragraphs` in body, text, with the quote line on their start edge (2 pt, the layer
/// line's width and colour, as tall as the words, 16 pt to the text; no ground, never italic, never cobalt), 12 pt
/// between paragraphs; `source` under it in caption text-muted, aligned with the words, outside the line, then
/// `demoMarker`. Quotation marks belong to the caller's text.
public struct SbQuote: View {
    let paragraphs: [String]
    let source: String?
    let demoMarker: String?
    private var context = SbContext()

    public init(_ paragraphs: [String], source: String? = nil, demoMarker: String? = nil) {
        self.paragraphs = paragraphs
        self.source = source
        self.demoMarker = demoMarker
    }

    public init(_ text: String, source: String? = nil, demoMarker: String? = nil) {
        self.init([text], source: source, demoMarker: demoMarker)
    }

    public var body: some View {
        let indent = SebaroX.layerLineWidth + SebaroSpace.s4
        VStack(alignment: .leading, spacing: SebaroSpace.s2) {
            VStack(alignment: .leading, spacing: SebaroSpace.s3) {
                ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, p in
                    SbWrapText(p, style: .body).foregroundStyle(context.tone.text)
                }
            }
            .padding(.leading, indent)
            .overlay(alignment: .leading) {
                Rectangle().fill(context.tone.layerLine).frame(width: SebaroX.layerLineWidth)
            }
            if source != nil || demoMarker != nil {
                SbWrapRow(spacing: SebaroSpace.s2) {
                    if let source { SbWrapText(source, style: .caption).foregroundStyle(context.tone.textMuted) }
                    if let demoMarker { SbDemoMarker(demoMarker) }
                }
                .padding(.leading, indent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Running text whose links (`AttributedString` runs with `.link`) get the link look of D52 (`sbLinkStyles` in
/// Compose): the word in text with the underline in link colour (the font's underline; SwiftUI cannot draw the 2 pt
/// line 0.2 em under the baseline, *provisional, agent*); everything else plain text. A tap opens the link through the
/// environment's `openURL`.
public struct SbLinkText: View {
    let text: AttributedString
    let style: SebaroTextStyle
    private var context = SbContext()

    public init(_ text: AttributedString, style: SebaroTextStyle = .body) {
        self.text = text
        self.style = style
    }

    /// The links of `text` in the D52 look: text colour, link-coloured underline.
    public static func styled(_ text: AttributedString, ink: Color) -> AttributedString {
        var out = text
        for run in out.runs where run.link != nil {
            out[run.range].foregroundColor = ink
            out[run.range].underlineStyle = Text.LineStyle(pattern: .solid, color: .sbLink)
        }
        return out
    }

    public var body: some View {
        Text(Self.styled(text, ink: context.tone.text))
            .sbFont(style).foregroundStyle(context.tone.text)
            .tint(context.tone.text)
            .fixedSize(horizontal: false, vertical: true)
    }
}
