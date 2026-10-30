import SwiftUI

// MARK: - Board, document tabs, editor surface (spec/02 §3.16, §4.21; B1b, B2b, D102 (36), (40), D105 (41)–(45), D106 (15))

/// One card of an `SbBoard` column (spec/02 §3.16): `id` names it, `title` in label, `text` the description under it
/// (caption in text, all of it, wrapping; D102 (40)), `meta` the grey line under that, `votes` the thumbs-up count after
/// it (VoiceOver „3 Stimmen“). `writing` = someone else is writing this card: `title` is then the sentence („Lea
/// schreibt …“) after the pending glyph, grey, the edge in border, no „Mehr“.
public struct SbBoardCard: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let text: String?
    public let meta: String?
    public let votes: Int?
    public let writing: Bool
    public init(id: String, title: String, text: String? = nil, meta: String? = nil, votes: Int? = nil, writing: Bool = false) {
        self.id = id
        self.title = title
        self.text = text
        self.meta = meta
        self.votes = votes
        self.writing = writing
    }
}

/// One column of an `SbBoard`: `id`, `name` (its heading), `cards` in order; `category` 1…6 = the dot of a column the
/// user files himself (D73, D91 C1b), never a fill.
public struct SbBoardColumn: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let cards: [SbBoardCard]
    public let category: Int?
    public init(id: String, name: String, cards: [SbBoardCard], category: Int? = nil) {
        self.id = id
        self.name = name
        self.cards = cards
        self.category = category
    }
}

/// Where an `SbBoard` stands (B2b): `column` = the column in place; `swiping` = the board is narrower than 640 pt and
/// swipes, so the screen's primary action names that column („Neue Karte in „Lassen““, spec/02 §3.16).
@MainActor @Observable
public final class SbBoardState {
    public internal(set) var column = 0
    public internal(set) var swiping = false
    public init() {}

    /// The board arrives at column `i`, after a step of the position bar or a swipe that ended there: the one place for
    /// both, so each arrival is announced exactly once. Returns the column to announce: nil when `i` is already in
    /// place (the scroll position reporting a step the bar made) or when the board does not swipe.
    func arrive(at i: Int) -> Int? {
        guard i != column else { return nil }
        column = i
        return swiping ? i : nil
    }

    /// The column after a step of `by` (±1), kept inside the board; nil at either end (the step does nothing there).
    public static func step(_ column: Int, by: Int, count: Int) -> Int? {
        let to = column + by
        return (0..<count).contains(to) ? to : nil
    }
}

/// Board (B1b, B2b; spec/02 §3.16): columns divided by a 1 pt border hairline, no frame and no ground; the cards are the
/// only boxes (1 pt border-strong, radius container, `current` = the card with the 3 pt accent place line, VoiceOver
/// „aktuell“). Each column is a group with its heading (the name, the category dot and the count, „2 Karten“) and „Mehr
/// zu <Spalte>“ (`columnItems`, `columnDanger` last; none = no button); an empty column says „Noch keine Karte.“. A
/// card's „Mehr zu <Karte>“ holds `cardItems`, then „Verschieben nach …“ when `onMove` is set (the columns as check
/// rows; the card's own column is checked and does nothing), then `cardDanger`: moving never needs dragging. Narrower
/// than 640 pt the columns stay side by side and swipe: one column is the board minus the gutters and 48 pt, so the next
/// column's start stays in view, a swipe stops at the next column, and above them the position bar „Vorige Spalte“ ·
/// „Spalte 2 von 3: Lassen“ (announced) · „Nächste Spalte“ (greyed at either end). From 640 pt the columns share the
/// width, at least `SebaroX.boardColumn` (240 pt) each, and scroll when they do not fit. `onNewCard` (D102 (36)): an
/// app whose screen keeps its own primary action puts „Neue Karte in „<Spalte>““ as a secondary action at the foot of
/// every column.
public struct SbBoard: View {
    let columns: [SbBoardColumn]
    let state: SbBoardState
    let current: String?
    let onMove: ((SbBoardCard, SbBoardColumn) -> Void)?
    let cardItems: (SbBoardCard) -> [SbMenuItem]
    let cardDanger: (SbBoardCard) -> SbMenuItem?
    let columnItems: (SbBoardColumn) -> [SbMenuItem]
    let columnDanger: (SbBoardColumn) -> SbMenuItem?
    let onNewCard: ((SbBoardColumn) -> Void)?
    private var context = SbContext()
    @State private var position: String?
    @State private var width: CGFloat = 360
    @ScaledMetric(relativeTo: .body) private var wideColumn: CGFloat = SebaroX.boardColumn

    public init(_ columns: [SbBoardColumn], state: SbBoardState, current: String? = nil,
                onMove: ((SbBoardCard, SbBoardColumn) -> Void)? = nil,
                cardItems: @escaping (SbBoardCard) -> [SbMenuItem] = { _ in [] },
                cardDanger: @escaping (SbBoardCard) -> SbMenuItem? = { _ in nil },
                columnItems: @escaping (SbBoardColumn) -> [SbMenuItem] = { _ in [] },
                columnDanger: @escaping (SbBoardColumn) -> SbMenuItem? = { _ in nil },
                onNewCard: ((SbBoardColumn) -> Void)? = nil) {
        self.columns = columns
        self.state = state
        self.current = current
        self.onMove = onMove
        self.cardItems = cardItems
        self.cardDanger = cardDanger
        self.columnItems = columnItems
        self.columnDanger = columnDanger
        self.onNewCard = onNewCard
    }

    public var body: some View {
        // the board's width is read in the background, so the board itself is as tall as its longest column
        let narrow = width < 640
        let step = max(width - 2 * SebaroSpacing.gutter - SebaroSize.targetTouch, SebaroSize.targetTouch)
        VStack(alignment: .leading, spacing: SebaroSpace.s2) {
            if narrow { nav }
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 0) {
                    ForEach(Array(columns.enumerated()), id: \.element.id) { i, column in
                        columnView(column, first: i == 0)
                            .frame(width: narrow ? step : max(wideColumn, width / CGFloat(max(columns.count, 1))))
                            .id(column.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: $position, anchor: .leading)
            .contentMargins(.horizontal, narrow ? SebaroSpacing.gutter : 0, for: .scrollContent)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GeometryReader { g in Color.clear.preference(key: SbLineWidthKey.self, value: g.size.width) })
        .onPreferenceChange(SbLineWidthKey.self) { [$width] w in if w > 0, $width.wrappedValue != w { $width.wrappedValue = w } }
        .onAppear { state.swiping = narrow }
        .onChange(of: narrow) { state.swiping = narrow }
        .onChange(of: position) {
            guard let position, let i = columns.firstIndex(where: { $0.id == position }) else { return }
            arrive(i)
        }
    }

    private func show(_ i: Int) {
        withAnimation(context.reduceMotion ? nil : SebaroMotion.enter(reduceMotion: false)) { position = columns[i].id }
        arrive(i)
    }

    private func arrive(_ i: Int) {
        if let a = state.arrive(at: i) { SbAnnounce.polite(context.messages.boardPosition(a + 1, columns.count, columns[a].name)) }
    }

    private var nav: some View {
        let m = context.messages
        let i = min(state.column, max(columns.count - 1, 0))
        return HStack(spacing: 0) {
            step("chevron-left", m.boardPrevious, to: SbBoardState.step(i, by: -1, count: columns.count))
            SbWrapText(columns.isEmpty ? "" : m.boardPosition(i + 1, columns.count, columns[i].name), style: .caption, center: true)
                .foregroundStyle(context.tone.text)
                .frame(maxWidth: .infinity)
            step("chevron-right", m.boardNext, to: SbBoardState.step(i, by: 1, count: columns.count))
        }
        .padding(.horizontal, SebaroSpacing.gutter - SebaroSpace.s3)
    }

    private func step(_ icon: String, _ label: String, to: Int?) -> some View {
        Button { if let to { show(to) } } label: {
            SbIcon(icon, size: SebaroSize.iconLg, color: to == nil ? context.tone.textSubtle : context.tone.text)
                .frame(width: SebaroSize.targetTouch, height: SebaroSize.targetTouch)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // at either end greyed and dimmed for VoiceOver, still focusable (a disabled button keeps its element)
        .disabled(to == nil)
        .accessibilityLabel(Text(label))
    }

    private func columnView(_ column: SbBoardColumn, first: Bool) -> some View {
        let m = context.messages
        let count = column.cards.count
        let color = column.category.flatMap { n in SebaroCategory.all.first { $0.number == n }?.color }
        return VStack(alignment: .leading, spacing: SebaroSpace.s2) {
            HStack(alignment: .top, spacing: SebaroSpace.s1) {
                // name and count wrap between them at large text; „Mehr“ keeps its place at the end
                SbWrapRow(spacing: SebaroSpace.s2) {
                    HStack(spacing: SebaroSpace.s2) {
                        if let color { Circle().fill(color).frame(width: 10, height: 10) }   // the web's 10px dot
                        SbWrapText(column.name, style: .label).foregroundStyle(context.tone.text)
                    }
                    SbWrapText(m.boardCards(count, SbMessages.formatCount(count, locale: context.currentLocale)), style: .caption)
                        .foregroundStyle(context.tone.textMuted)
                }
                .frame(maxWidth: .infinity, minHeight: SebaroSize.targetTouch, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                more(m.boardMore(column.name), items: columnItems(column), danger: columnDanger(column), moveTo: nil)
            }
            if column.cards.isEmpty {
                SbWrapText(m.boardEmpty, style: .body).foregroundStyle(context.tone.textMuted)
            }
            ForEach(column.cards) { card in
                cardView(card, in: column)
            }
            if let onNewCard {
                Button { onNewCard(column) } label: {
                    HStack(spacing: SebaroSpace.s1) {
                        SbIcon("plus--16", size: SebaroSize.iconSm)
                        SbWrapText(m.boardNewCardIn(column.name))
                    }
                }
                .buttonStyle(SbSecondaryButtonStyle())
            }
        }
        .padding(.horizontal, SebaroSpace.s2)
        .padding(.top, SebaroSpace.s3)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .overlay(alignment: .leading) {
            if !first { Rectangle().fill(context.tone.border).frame(width: SebaroBorderWidth.hairline) }
        }
        .accessibilityElement(children: .contain)
    }

    private func cardView(_ card: SbBoardCard, in column: SbBoardColumn) -> some View {
        let m = context.messages
        let isCurrent = card.id == current
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.container, style: .continuous)
        let moveTo: [SbMenuItem]? = onMove.map { move in
            columns.map { c in SbMenuItem(c.name, checked: c.id == column.id) { if c.id != column.id { move(card, c) } } }
        }
        return HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: SebaroSpace.s2) {
                HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s1) {
                    if card.writing { SbIcon("pending--16", size: SebaroSize.iconSm, color: context.tone.textMuted) }
                    SbWrapText(card.title, style: .label).foregroundStyle(card.writing ? context.tone.textMuted : context.tone.text)
                }
                .padding(.top, SebaroSpace.s1)
                if let text = card.text { SbWrapText(text, style: .caption).foregroundStyle(context.tone.text) }
                if card.meta != nil || card.votes != nil {
                    HStack(spacing: SebaroSpace.s2) {
                        if let meta = card.meta { SbWrapText.name(meta, style: .caption).foregroundStyle(context.tone.textMuted) }
                        if let votes = card.votes {
                            HStack(spacing: SebaroSpace.s0_5) {
                                SbIcon("thumbs-up", size: SebaroSize.iconSm, color: context.tone.textMuted)
                                Text(SbMessages.formatCount(votes, locale: context.currentLocale)).sbFont(.caption).monospacedDigit()
                                    .foregroundStyle(context.tone.textMuted)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(Text(m.boardVotes(votes, SbMessages.formatCount(votes, locale: context.currentLocale))))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, SebaroSpace.s2)
            .accessibilityElement(children: .combine)
            .accessibilityValue(Text(isCurrent ? m.itemCurrent : ""))
            if !card.writing {
                more(m.boardMore(card.title), items: cardItems(card), danger: cardDanger(card), moveTo: moveTo)
            }
        }
        .padding(.leading, SebaroSpace.s3)
        .padding(.trailing, SebaroSpace.s1)
        .overlay(alignment: .leading) {
            if isCurrent { Rectangle().fill(Color.sbAccent).frame(width: SebaroBorderWidth.strong) }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(card.writing ? context.tone.border : context.tone.borderStrong, lineWidth: SebaroBorderWidth.control))
    }

    /// „Mehr zu <name>“ (more-horizontal, text-muted, 48 pt) with its menu: `items`, then „Verschieben nach …“ (the
    /// columns as check rows), then `danger` last. Nothing to offer = no button.
    @ViewBuilder private func more(_ name: String, items: [SbMenuItem], danger: SbMenuItem?, moveTo: [SbMenuItem]?) -> some View {
        if !items.isEmpty || danger != nil || moveTo != nil {
            Menu {
                ForEach(items) { item in Button(action: item.run) { SbMenuLabel(item: item) }.disabled(!item.enabled) }
                if let moveTo {
                    Menu(context.messages.boardMoveTo) {
                        ForEach(moveTo) { item in
                            Toggle(isOn: Binding(get: { item.checked ?? false }, set: { _ in item.run() })) { Text(item.title) }
                        }
                    }
                }
                if let danger {
                    Divider()
                    Button(role: .destructive, action: danger.run) { SbMenuLabel(item: danger) }.disabled(!danger.enabled)
                }
            } label: {
                SbIcon("more-horizontal", size: SebaroSize.iconLg, color: context.tone.textMuted)
                    .frame(width: SebaroSize.targetTouch, height: SebaroSize.targetTouch)
                    .contentShape(Rectangle())
            }
            .menuIndicator(.hidden)
            .accessibilityLabel(Text(name))
        }
    }
}

/// Document tabs (spec/02 §4.21) under an editor's top bar: `names` of the open documents, `selected` the current
/// one, `changed` the documents with unsaved changes (the changed--16 dot before the name and the hidden „geändert“). A
/// tab ≥ 48 pt; its name is cut at the end after 240 pt, growing with the text (spec/02 §4.21; VoiceOver reads it whole); the
/// row scrolls. `label` names the row for VoiceOver.
public struct SbDocTabs: View {
    let names: [String]
    @Binding var selected: Int
    let label: String
    let changed: Set<Int>
    private var context = SbContext()
    @ScaledMetric(relativeTo: .subheadline) private var cap: CGFloat = 240

    public init(_ names: [String], selected: Binding<Int>, label: String, changed: Set<Int> = []) {
        self.names = names
        self._selected = selected
        self.label = label
        self.changed = changed
    }

    public var body: some View {
        let m = context.messages
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(names.enumerated()), id: \.offset) { i, name in
                    let chosen = i == selected
                    Button { selected = i } label: {
                        HStack(spacing: SebaroSpace.s1) {
                            if changed.contains(i) { SbIcon("changed--16", size: SebaroSize.iconSm, color: context.tone.text) }
                            Text(name).sbFont(.label).lineLimit(1).truncationMode(.tail)
                                .foregroundStyle(chosen ? Color.sbLink : context.tone.textMuted)
                                .frame(maxWidth: cap, alignment: .leading)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.horizontal, SebaroSpace.s4)
                        .frame(minWidth: SebaroSize.targetTouch, minHeight: SebaroSize.targetTouch)
                        .overlay(alignment: .bottom) {
                            if chosen { Rectangle().fill(Color.sbAccent).frame(height: SebaroBorderWidth.strong) }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(changed.contains(i) ? "\(name), \(m.docChanged)" : name))
                    .accessibilityAddTraits(chosen ? [.isSelected] : [])
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .background(alignment: .bottom) { Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(label))
    }
}

public extension View {
    /// sebaro's phone editor on a `TextEditor` (D105 (44), spec/01 §1.8; the counterpart of `sbEditorSurface` on
    /// Android): ground `bg` (the system background hidden), text `text`, the caret and selection in accent (the tint),
    /// every file in sebaro Mono at `SebaroX.editorSize` growing with Dynamic Type (D105 (43)), its line height
    /// `SebaroX.editorLineHeight` 1.6, the gutter at the sides and 12 pt above and below. Selection, handles, keyboard,
    /// spell checking and copy are the system's; SwiftUI does not hyphenate while writing (spec/07 §3.1). The caret's width
    /// is the system's (UIKit has no caret width; Android draws 2 pt, *provisional, agent*). Line numbers, where an
    /// app shows them, have no thousands separator (D105 (45)).
    func sbEditorSurface() -> some View { modifier(SbEditorSurface()) }
}

struct SbEditorSurface: ViewModifier {
    @Environment(\.sebaroTone) private var tone
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = SebaroX.editorSize

    func body(content: Content) -> some View {
        let code = SebaroTextStyle.code.resolve(scheme)
        let face = SebaroTextFace(family: code.family, size: SebaroX.editorSize, lineHeight: SebaroX.editorSize * SebaroX.editorLineHeight,
                                  weight: code.weight, weightValue: code.weightValue, tracking: 0)
        content
            .font(SebaroFonts.font(face, relativeTo: .body, monospacedDigits: false))
            .lineSpacing(size * (SebaroX.editorLineHeight - 1))
            .foregroundStyle(tone.text)
            .tint(Color.sbAccent)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, SebaroSpacing.gutter)
            .padding(.vertical, SebaroSpace.s3)
            .background(tone.bg)
    }
}
