import SwiftUI

// MARK: - Facts parts (spec/10 §4; FACTS-CONTRACT §8.3, §8.5; D21, D24, D101 (11), (12); spec/02 §3.24)

/// The head of an about screen (B10a, spec/02 §3.24): the 64 pt sign tile of `product` (hidden from VoiceOver), then
/// `name` in title (a heading), the one-liner `line` in body and „Version 1.4.0 vom 20.10.2026“ (the version in sebaro
/// Mono, `date` the caller's text) in caption text-muted. The text keeps 192 pt (growing with the text) beside the
/// tile, else it moves under it; never centred. 16 pt above and below, the gutter at the sides. `product` nil = an app
/// without a sign yet (spec/08 §14.17): no tile; `date` nil = „Version 1.4.0“ alone. `SbFactsLine` follows directly under it.
public struct SbAboutHead: View {
    let product: SebaroProduct?
    let name: String
    let line: String
    let version: String
    let date: String?
    private var context = SbContext()
    @ScaledMetric(relativeTo: .body) private var textRoom: CGFloat = SebaroSpace.s16 * 3

    public init(product: SebaroProduct?, name: String, line: String, version: String, date: String?) {
        self.product = product
        self.name = name
        self.line = line
        self.version = version
        self.date = date
    }

    public var body: some View {
        Group {
            if let product {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: SebaroSpace.s4) {
                        tile(product)
                        text.frame(minWidth: textRoom, maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: SebaroSpace.s4) {
                        tile(product)
                        text
                    }
                }
            } else {
                text
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SebaroSpacing.gutter)
        .padding(.vertical, SebaroSpace.s4)
    }

    private func tile(_ product: SebaroProduct) -> some View {
        SbSignTile(product, size: SebaroSpace.s16).accessibilityHidden(true)
    }

    /// The product name: a name, never hyphenated; when it alone is wider than the line it breaks between letters.
    static func nameText(_ name: String) -> SbWrapText { .name(name, style: .title) }

    private var text: some View {
        let m = context.messages
        let meta = date.map { m.aboutVersion(version, $0) } ?? m.aboutVersionOnly(version)
        var words = AttributedString(meta)
        if let r = words.range(of: version) {
            words[r].font = SebaroTextStyle.code.exactFont(for: context.scheme)
        }
        return VStack(alignment: .leading, spacing: SebaroSpace.s0_5) {
            Self.nameText(name).foregroundStyle(context.tone.text).accessibilityAddTraits(.isHeader)
            SbWrapText(line, style: .body).foregroundStyle(context.tone.text)
            Text(words).sbFont(.caption).foregroundStyle(context.tone.textMuted).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// One cell of the compact facts line (spec/10 §4.1): `text` the caller's claim word („Keine Tracker“), `refs` the
/// fact refs whose notes back it; `place` = a remote place „Helsinki (FI)“ with the pin before it.
public struct SbFactCell: Sendable {
    public let text: String
    public let refs: [String]
    public let place: Bool
    public init(_ text: String, refs: [String] = [], place: Bool = false) {
        self.text = text
        self.refs = refs
        self.place = place
    }
}

/// The compact form (a) of the facts (spec/10 §4.1): the product name, then each cell after a „·“, caption text-muted,
/// wrapping between cells. A cell shows only when every ref has a note that may state it (D21); the others are counted
/// into „n nicht belegt“, a link-style button when `onHidden` leads to the full form. Stale: the name, the stale notice,
/// the demo marker. The demo marker last. Once a cell with its „·“ no longer fits one line (large text, D101 (11),
/// (12)), the line becomes a list: the name on its own line, each cell on its own line, no „·“. The gutter at the
/// sides; one VoiceOver element, the button its own.
public struct SbFactsLine: View {
    let notes: SbNotes
    let cells: [SbFactCell]
    let todayIso: String
    let onHidden: (() -> Void)?
    private var context = SbContext()

    public init(notes: SbNotes, cells: [SbFactCell], todayIso: String, onHidden: (() -> Void)? = nil) {
        self.notes = notes
        self.cells = cells
        self.todayIso = todayIso
        self.onHidden = onHidden
    }

    /// The cells the line shows and the count of the others (D21): none while stale.
    public static func split(_ notes: SbNotes, cells: [SbFactCell], todayIso: String) -> (shown: [SbFactCell], hidden: Int) {
        guard !notes.isStale(todayIso: todayIso) else { return ([], 0) }
        let shown = cells.filter { c in c.refs.allSatisfy { r in notes.claims.first { $0.refs == [r] }?.showsClaim ?? false } }
        return (shown, cells.count - shown.count)
    }

    public var body: some View {
        let m = context.messages
        let stale = notes.isStale(todayIso: todayIso)
        let parts = Self.split(notes, cells: cells, todayIso: todayIso)
        let hiddenWord = parts.hidden > 0
            ? m.factsHidden(SbMessages.formatCount(parts.hidden, locale: context.currentLocale)) : nil
        // VoiceOver: the name, the stale notice, the cells, the count without a button and the demo marker as one
        // element on the name; the „nicht belegt“ button its own. The flow or the list (D101 (11), (12)): only the
        // one drawn is in the view, so the elements are the ones on screen
        let summary = ([notes.productName] + (stale ? [notes.staleNotice ?? ""] : []) + parts.shown.map(\.text)
                       + (onHidden == nil ? [hiddenWord].compactMap { $0 } : []) + [notes.demo].compactMap { $0 })
            .filter { !$0.isEmpty }.joined(separator: ", ")
        ViewThatFits(in: .horizontal) {
            SbFactsFlow(gap: SebaroSpace.s1) {
                name.accessibilityLabel(Text(summary))
                if stale { dotted { staleCell.fixedSize() } }
                ForEach(Array(parts.shown.enumerated()), id: \.offset) { _, c in dotted { factCell(c).fixedSize() } }
                if let hiddenWord { dotted { hiddenCell(hiddenWord).fixedSize() } }
                if let demo = notes.demo { dotted { SbDemoMarker(demo).fixedSize().accessibilityHidden(true) } }
            }
            VStack(alignment: .leading, spacing: SebaroSpace.s3) {
                name.accessibilityLabel(Text(summary))
                if stale { staleCell }
                ForEach(Array(parts.shown.enumerated()), id: \.offset) { _, c in factCell(c) }
                if let hiddenWord { hiddenCell(hiddenWord) }
                if let demo = notes.demo { SbDemoMarker(demo).accessibilityHidden(true) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SebaroSpacing.gutter)
        .accessibilityElement(children: .contain)
    }

    private var name: some View {
        let caption = SebaroTextStyle.caption.resolve(context.scheme), label = SebaroTextStyle.label.resolve(context.scheme)
        return Self.nameText(notes.productName)
            .font(SebaroFonts.font(SebaroTextFace(family: caption.family, size: caption.size, lineHeight: caption.lineHeight,
                                                  weight: label.weight, weightValue: label.weightValue, tracking: caption.tracking),
                                   relativeTo: .caption, monospacedDigits: false))
            .foregroundStyle(context.tone.text)
    }

    /// The product name: a name, never hyphenated (the font is set by the caller).
    static func nameText(_ name: String) -> SbWrapText { .name(name) }

    private func dotted(@ViewBuilder _ cell: () -> some View) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s1) {
            Text("·").sbFont(.caption).foregroundStyle(context.tone.textMuted).accessibilityHidden(true)
            cell()
        }
    }

    private var staleCell: some View {
        HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s1) {
            SbIcon("warning--filled-16", size: SebaroSize.iconSm, color: .sbWarning)
            SbWrapText(notes.staleNotice ?? "", style: .caption).foregroundStyle(context.tone.text)
        }
        .accessibilityHidden(true)
    }

    private func factCell(_ c: SbFactCell) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s0_5) {
            if c.place { SbIcon("pin", size: SebaroSize.iconSm, color: context.tone.textMuted) }
            SbWrapText(c.text, style: .caption).foregroundStyle(context.tone.textMuted)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder private func hiddenCell(_ word: String) -> some View {
        if let onHidden {
            Button(action: onHidden) { SbWrapText(word, style: .caption) }.buttonStyle(SbTextActionStyle())
        } else {
            SbWrapText(word, style: .caption).foregroundStyle(context.tone.textMuted).accessibilityHidden(true)
        }
    }
}

/// The facts line's flow: subview 0 the name, then the dotted one-line cells, flowing and wrapping between whole cells,
/// `gap` apart. Its ideal width is its widest cell (`least`), so the `ViewThatFits` of `SbFactsLine` takes the list
/// instead once a cell with its „·“ no longer fits one line (D101 (11), (12)).
struct SbFactsFlow: Layout {
    let gap: CGFloat

    /// The narrowest width the flow can take: the widest cell on its line.
    static func least(cellWidths: [CGFloat]) -> CGFloat { cellWidths.max() ?? 0 }

    private func arrange(_ width: CGFloat, _ s: Subviews) -> (size: CGSize, places: [Int: CGPoint], proposals: [Int: ProposedViewSize]) {
        var places: [Int: CGPoint] = [:], proposals: [Int: ProposedViewSize] = [:]
        let whole = ProposedViewSize(width: width, height: nil)
        // lines of whole cells, each cell centred on its line (a 48 pt button cell beside a caption cell)
        var lines: [[(Int, CGSize)]] = [[]]
        var x: CGFloat = 0
        for i in s.indices {
            let size = i == 0 ? s[0].sizeThatFits(whole) : s[i].sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                lines.append([])
                x = 0
            }
            lines[lines.count - 1].append((i, size))
            proposals[i] = i == 0 ? whole : .unspecified
            x += size.width + gap
        }
        var y: CGFloat = 0
        for (n, line) in lines.enumerated() {
            if n > 0 { y += gap }
            let h = line.map(\.1.height).max() ?? 0
            var lx: CGFloat = 0
            for (i, size) in line {
                places[i] = CGPoint(x: lx, y: y + (h - size.height) / 2)
                lx += size.width + gap
            }
            y += h
        }
        return (CGSize(width: width, height: y), places, proposals)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let w = proposal.width, w.isFinite else {
            // the ideal size (`ViewThatFits`): as narrow as the widest cell
            let least = Self.least(cellWidths: subviews.dropFirst().map { $0.sizeThatFits(.unspecified).width })
            return arrange(least, subviews).size
        }
        return arrange(w, subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let a = arrange(bounds.width, subviews)
        for (i, s) in subviews.enumerated() {
            s.place(at: CGPoint(x: bounds.minX + (a.places[i]?.x ?? 0), y: bounds.minY + (a.places[i]?.y ?? 0)),
                    proposal: a.proposals[i] ?? .unspecified)
        }
    }
}

/// The stale notice (FACTS-CONTRACT §8.3): the warning glyph + the notice in body text; it replaces every claim.
public struct SbStaleNotice: View {
    let text: String
    private var context = SbContext()
    public init(_ text: String) { self.text = text }
    public var body: some View {
        HStack(alignment: .top, spacing: SebaroSpace.s2) {
            SbIcon("warning--filled-16", size: SebaroSize.iconSm, color: .sbWarning)
                .padding(.top, SebaroSpace.s0_5)
            SbWrapText(text, style: .body).foregroundStyle(context.tone.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SebaroSpacing.gutter)
        .padding(.vertical, SebaroSpace.s3)
        .accessibilityElement(children: .combine)
    }
}

/// Per-action hint (FACTS-CONTRACT §8.5 d) under an action that is not the primary action: caption text-muted.
public struct SbActionHint: View {
    let text: String
    private var context = SbContext()
    public init(_ text: String) { self.text = text }
    public var body: some View {
        SbWrapText(text, style: .caption).foregroundStyle(context.tone.textMuted)
    }
}

/// The check list „Wie geprüft?“ (c): every check in execution order, one below the other: the state glyph and word
/// (label), the title (body), date · by (caption text-muted), the reason („Grund: …“) and the limit (caption), the
/// evidence refs (code, text-muted); 1 pt hairlines between checks.
public struct SbCheckList: View {
    let notes: SbNotes
    private var context = SbContext()
    public init(_ notes: SbNotes) { self.notes = notes }
    public var body: some View {
        let m = context.messages
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(notes.checks.enumerated()), id: \.offset) { i, check in
                VStack(alignment: .leading, spacing: SebaroSpace.s0_5) {
                    HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s1) {
                        SbCheckStateGlyph(check.result)
                        SbWrapText(check.stateWord, style: .label).foregroundStyle(context.tone.text)
                    }
                    SbWrapText(check.title, style: .body).foregroundStyle(context.tone.text)
                    let meta = [check.date, check.by].compactMap { $0 }.joined(separator: " · ")
                    if !meta.isEmpty { SbWrapText(meta, style: .caption).foregroundStyle(context.tone.textMuted) }
                    if let reason = check.reason { SbWrapText(m.checkReason(reason), style: .caption).foregroundStyle(context.tone.text) }
                    if let limit = check.limit { SbWrapText(limit, style: .caption).foregroundStyle(context.tone.text) }
                    ForEach(check.evidence, id: \.self) { e in
                        SbWrapText.name(e, style: .code).foregroundStyle(context.tone.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SebaroSpacing.gutter)
                .padding(.vertical, SebaroSpace.s3)
                .overlay(alignment: .top) {
                    if i > 0 { Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline) }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
