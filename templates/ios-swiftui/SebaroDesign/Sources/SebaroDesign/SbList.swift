import SwiftUI

// MARK: - Status (spec/01 §1.5, spec/02 §3.1): glyph + word, never colour alone

/// The five tones, named as the CSS modifiers of `sb-status` and `SbStatusTone` in Compose.
public enum SbStatusTone: Sendable {
    case info, neutral, success, danger, warning
}

/// The glyph of a status when it is not the tone's own (spec/02 §3.1, §3.1a; `SbStatusGlyph` in Compose): `.warning`
/// for „Konflikt“ (D92), `.pending` for a counted rest „2 offen“ also in the neutral tone (D91 Z1a), `.globe` for
/// „nur online“ (16 pt: `info`, the set has no 16 px globe).
public enum SbStatusGlyph: Sendable {
    case progress, clock, success, error, pending, warning, globe

    /// The sprite name; SbIcon picks the 16 px master where one exists.
    func icon(small: Bool) -> String {
        switch self {
        case .progress: "progress"
        case .clock: "clock"
        case .success: "success--filled"
        case .error: "error--filled"
        case .pending: "pending"
        case .warning: "warning"
        case .globe: small ? "info" : "globe"
        }
    }
}

/// Status: the glyph in its status colour and the word in text, caption; a word that does not fit its place wraps. `word` nil = the tone's word
/// from the words table (läuft, geplant, erledigt, Fehler, offen). `small` = the 16 pt glyph of notes and claim rows,
/// else 20 pt (lists). `glyph` = another glyph than the tone's (nil = the tone's: progress, clock, success, error,
/// pending); the colour stays the tone's. VoiceOver reads the word.
public struct SbStatus: View {
    let tone: SbStatusTone
    let word: String?
    let small: Bool
    let glyph: SbStatusGlyph?
    private var context = SbContext()

    public init(_ tone: SbStatusTone, word: String? = nil, small: Bool = false, glyph: SbStatusGlyph? = nil) {
        self.tone = tone
        self.word = word
        self.small = small
        self.glyph = glyph
    }

    public var body: some View {
        let m = context.messages
        let (own, tint, fallback): (SbStatusGlyph, Color, String) = switch tone {
        case .info: (.progress, .sbInfo, m.statusRunning)
        case .neutral: (.clock, context.tone.textMuted, m.statusPlanned)
        case .success: (.success, .sbSuccess, m.statusDone)
        case .danger: (.error, .sbDanger, m.statusFailed)
        case .warning: (.pending, .sbWarning, m.statusOpen)
        }
        HStack(spacing: SebaroSpace.s1) {
            SbIcon((glyph ?? own).icon(small: small), size: small ? SebaroSize.iconSm : SebaroSize.iconMd, color: tint)
            // the word wraps in its place and is never cut (spec/08 §14.3, D99 (1), D102 lane narrow); before 2026-10-25 one line
            Text(word ?? fallback).sbFont(.caption).foregroundStyle(context.tone.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - List rows (spec/02 §3.3, spec/08 §14.4; D91 I7a)

/// A flat list row: title (body), meta (second line, caption text-muted, tabular), text (third line, caption);
/// 56 / 64 / 88 pt by content, growing with Dynamic Type without an upper limit (D91 I7a). At the accessibility
/// sizes the trail (the status) moves under the title, glyph and word stay. `hairline` = the 1 pt border line above,
/// inset 16 pt: false for the first row of a group. `done` = the finished row (D83 (1)): 40 pt, caption text-muted,
/// the success glyph, no hairline, „erledigt:“ only for VoiceOver. No swipe actions (D91 I3a): attach
/// `.sbContextMenu(_:)` for edit and delete.
public struct SbListRow<Trail: View>: View {
    let title: String
    let meta: String?
    let text: String?
    let hairline: Bool
    let done: Bool
    let trail: Trail
    private var context = SbContext()
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var oneLine: CGFloat = SebaroSize.controlLg
    @ScaledMetric(relativeTo: .body) private var twoLines: CGFloat = SebaroSpace.s16
    @ScaledMetric(relativeTo: .body) private var threeLines: CGFloat = 88   // spec/02 §3.3; no size token
    @ScaledMetric(relativeTo: .caption) private var doneHeight: CGFloat = SebaroSpace.s10

    public init(_ title: String, meta: String? = nil, text: String? = nil, hairline: Bool = true, done: Bool = false,
                @ViewBuilder trail: () -> Trail) {
        self.title = title
        self.meta = meta
        self.text = text
        self.hairline = hairline
        self.done = done
        self.trail = trail()
    }

    public var body: some View {
        let stacked = typeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: SebaroSpace.s1))
            : AnyLayout(HStackLayout(alignment: .center, spacing: SebaroSpace.s3))
        let minHeight = done ? doneHeight : (text != nil ? threeLines : (meta != nil ? twoLines : oneLine))
        layout {
            if done {
                HStack(spacing: SebaroSpace.s3) {
                    SbIcon("success--filled", size: SebaroSize.iconSm, color: .sbSuccess)
                    Text(title).sbFont(.caption).foregroundStyle(context.tone.textMuted)
                        .accessibilityLabel(Text(context.messages.donePrefix + title))
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title).sbFont(.body).foregroundStyle(context.tone.text)
                    if let meta { Text(meta).sbFont(.caption).monospacedDigit().foregroundStyle(context.tone.textMuted) }
                    if let text { Text(text).sbFont(.caption).monospacedDigit().foregroundStyle(context.tone.text) }
                }
            }
            if !stacked { Spacer(minLength: SebaroSpacing.inline) }
            trail.foregroundStyle(context.tone.textMuted).sbFont(.caption).monospacedDigit()
        }
        .padding(.horizontal, SebaroSpacing.gutter)
        .padding(.vertical, done ? 0 : SebaroSpace.s2)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
        .overlay(alignment: .top) {
            if hairline && !done {
                Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline)
                    .padding(.leading, SebaroSpacing.gutter)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

public extension SbListRow where Trail == EmptyView {
    init(_ title: String, meta: String? = nil, text: String? = nil, hairline: Bool = true, done: Bool = false) {
        self.init(title, meta: meta, text: text, hairline: hairline, done: done) { EmptyView() }
    }
}

/// Group header: the word in label, text-muted, and the count at 400, tabular: „Offen 2“, „Erledigt 3“.
public struct SbListHeader: View {
    let label: String
    let count: Int?
    private var context = SbContext()
    public init(_ label: String, count: Int? = nil) {
        self.label = label
        self.count = count
    }
    public var body: some View {
        HStack(spacing: SebaroSpace.s2) {
            Text(label).sbFont(.label)
            if let count {
                Text(SbMessages.formatCount(count, locale: context.currentLocale)).sbFont(.caption).monospacedDigit()
            }
        }
        .foregroundStyle(context.tone.textMuted)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SebaroSpacing.gutter)
        .padding(.top, SebaroSpace.s4)
        .padding(.bottom, SebaroSpace.s1)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The closing sentence of a list: „Mehr steht heute nicht an.“ Lists end.
public struct SbListEnd: View {
    let text: String
    private var context = SbContext()
    public init(_ text: String) { self.text = text }
    public var body: some View {
        Text(text).sbFont(.caption).foregroundStyle(context.tone.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SebaroSpacing.gutter)
            .padding(.top, SebaroSpace.s3)
    }
}

// MARK: - Context menu on long press instead of swipe (D91 I3a)

/// One entry of a row's menu. `destructive` entries go last, after a divider, as the red word „Löschen …“ that opens
/// the confirmation dialog (D39); they never delete directly.
public struct SbMenuItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let icon: String?
    public let destructive: Bool
    public let action: () -> Void
    /// `SbOverflowMenu` only: not nil = a row of a single choice with the system check mark; `enabled` false = shown
    /// but not choosable; `group` = the head of the section the row belongs to (spec/02 §4.18).
    public let checked: Bool?
    public let enabled: Bool
    public let group: String?

    public init(_ title: String, icon: String? = nil, destructive: Bool = false, checked: Bool? = nil,
                enabled: Bool = true, group: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.destructive = destructive
        self.checked = checked
        self.enabled = enabled
        self.group = group
        self.action = action
    }

    /// The action, unless the item is disabled: a row shown but not choosable never acts, also where the system menu
    /// would still deliver the press.
    public func run() {
        if enabled { action() }
    }
}

public extension View {
    /// D91 I3a: no swipe actions in rows (the swipe button would be a red area behind white text, which sebaro
    /// does not have). A long press opens the system context menu with the row's actions, the destructive one last
    /// after a divider; VoiceOver gets the same entries as custom actions of the row.
    func sbContextMenu(_ items: [SbMenuItem]) -> some View {
        let normal = items.filter { !$0.destructive }
        let destructive = items.filter(\.destructive)
        return self
            .contextMenu {
                ForEach(normal) { item in
                    Button(action: item.action) { SbMenuLabel(item: item) }
                }
                if !destructive.isEmpty && !normal.isEmpty { Divider() }
                ForEach(destructive) { item in
                    Button(role: .destructive, action: item.action) { SbMenuLabel(item: item) }
                }
            }
            .accessibilityActions {
                ForEach(normal + destructive) { item in
                    Button(item.title, action: item.action)
                }
            }
    }
}

/// The icon of a menu entry as an image of the sprite (menus are drawn by UIKit and take images, not views).
struct SbMenuLabel: View {
    let item: SbMenuItem
    var body: some View {
        if let icon = item.icon, let image = SbIconImage.template(icon) {
            Label { Text(item.title) } icon: { image }
        } else {
            Text(item.title)
        }
    }
}

enum SbIconImage {
    @MainActor static func template(_ name: String) -> Image? {
        let renderer = ImageRenderer(content: SbIcon(name, size: SebaroSize.iconLg, color: .black))
        #if canImport(UIKit) && !os(macOS)
        renderer.scale = 3
        return renderer.uiImage.map { Image(uiImage: $0.withRenderingMode(.alwaysTemplate)) }
        #else
        return renderer.nsImage.map { Image(nsImage: $0) }
        #endif
    }
}
