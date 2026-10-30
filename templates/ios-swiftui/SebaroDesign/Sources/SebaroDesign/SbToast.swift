import SwiftUI

// MARK: - Toast (D46, D78; spec/02 §4.3, spec/08 §14.1)

/// Toast: the result of a reversible action outside the primary action, „Glas eingetragen · 6 / 8“ with „Rückgängig“
/// (a text action, D52). Ground `bg`, the 2 pt ink layer line, radius `container`, no shadow (D46). Never for errors,
/// never instead of the delete dialog (D39); the copy toast „In die Zwischenablage kopiert“ has no action (D102 (18)).
/// D99 (1): the action stands after the message while the message's widest word fits beside it; else it goes under
/// the message at the end and the message takes the whole width; an action wider than the toast wraps there at the
/// toast's width; the toast grows, no word is cut.
public struct SbToast: View {
    let message: String
    let actionLabel: String?
    let onAction: () -> Void
    /// VoiceOver focus of the message and the action, each on its own element (set by `sbToastHost`)
    var focus: AccessibilityFocusState<SbToastPart?>.Binding?
    /// only the message scrolls and the action stays under it at the end (set by `sbToastHost` when the toast is
    /// taller than its room, CHECKS.md §41)
    var scrollsMessage = false
    private var context = SbContext()

    public init(_ message: String, actionLabel: String? = nil, onAction: @escaping () -> Void = {}) {
        self.message = message
        self.actionLabel = actionLabel
        self.onAction = onAction
    }

    /// The same toast reporting VoiceOver focus on its message and its action into `focus`.
    func focus(_ focus: AccessibilityFocusState<SbToastPart?>.Binding) -> SbToast {
        var copy = self
        copy.focus = focus
        return copy
    }

    /// The same toast with only its message scrolling, the action fixed under it at the end.
    func scrollingMessage() -> SbToast {
        var copy = self
        copy.scrollsMessage = true
        return copy
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.container, style: .continuous)
        Group {
            if scrollsMessage { scrolling } else { layout }
        }
        .padding(.leading, SebaroSpace.s4)
        .padding([.top, .bottom, .trailing], SebaroSpace.s1)
        .frame(maxWidth: .infinity, minHeight: SebaroSize.controlMd, alignment: .leading)
        .background(context.tone.bg, in: shape)
        .overlay(shape.strokeBorder(context.tone.layerLine, lineWidth: SebaroX.layerLineWidth))
        .accessibilityElement(children: .contain)
    }

    /// The fallback when the toast is taller than its room: the message scrolls in what is left, the action stands
    /// under it at the end, always in view; an action wider than the toast wraps.
    private var scrolling: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ScrollView {
                SbWrapText(message, style: .numeric).foregroundStyle(context.tone.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .modifier(SbToastFocus(focus: focus, part: .message))
                    .padding(.vertical, SebaroSpace.s3 - SebaroSpace.s1)
            }
            .scrollBounceBehavior(.basedOnSize)
            if let actionLabel {
                Button(action: onAction) { SbWrapText(actionLabel) }.buttonStyle(SbTextActionStyle())
                    .padding(.horizontal, SebaroSpace.s2)
                    .modifier(SbToastFocus(focus: focus, part: .action))
            }
        }
    }

    private var layout: some View {
        let words = Array(Set(message.split(whereSeparator: \.isWhitespace).map(String.init)))
        return SbToastLayout(gap: SebaroSpace.s3 - SebaroSpace.s1) {
            SbWrapText(message, style: .numeric).foregroundStyle(context.tone.text)
                .modifier(SbToastFocus(focus: focus, part: .message))
            if let actionLabel {
                Button(action: onAction) { SbWrapText(actionLabel) }.buttonStyle(SbTextActionStyle())
                    .padding(.horizontal, SebaroSpace.s2)
                    .modifier(SbToastFocus(focus: focus, part: .action))
            }
            // the words, measured but never drawn: the widest decides where the action goes
            ForEach(words, id: \.self) { Text($0).sbFont(.numeric).fixedSize().hidden().accessibilityHidden(true)
                .layoutValue(key: SbToastProbeKey.self, value: true) }
        }
    }
}

/// The parts of a toast VoiceOver can focus: the message and the action are separate elements (the toast is a
/// container), so the focus is observed on each of them, not on the container.
enum SbToastPart: Hashable, Sendable { case message, action }

/// What keeps a toast on screen past its time: VoiceOver focus on its message or its action, or a finger on it.
struct SbToastHold: Equatable, Sendable {
    var focus: SbToastPart?
    var touched = false
    var held: Bool { focus != nil || touched }
}

struct SbToastFocus: ViewModifier {
    let focus: AccessibilityFocusState<SbToastPart?>.Binding?
    let part: SbToastPart

    func body(content: Content) -> some View {
        if let focus { content.accessibilityFocused(focus, equals: part) } else { content }
    }
}

/// Message (subview 0), the optional action, then the hidden word probes (marked with `SbToastProbeKey`). The action stands beside
/// the message while the widest probe fits the room left; else under it, at the end.
struct SbToastLayout: Layout {
    let gap: CGFloat

    private func parts(_ subviews: Subviews) -> (message: LayoutSubview, action: LayoutSubview?, widest: CGFloat) {
        let rest = subviews.dropFirst()
        let widest = rest.filter { $0[SbToastProbeKey.self] }.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        return (subviews[0], rest.first { !$0[SbToastProbeKey.self] }, widest)
    }

    private func arrange(_ proposal: ProposedViewSize, _ subviews: Subviews)
        -> (size: CGSize, message: CGRect, action: CGRect?) {
        let (message, action, widest) = parts(subviews)
        return Self.arrange(width: proposal.width ?? message.sizeThatFits(.unspecified).width, widest: widest, gap: gap,
                            message: { message.sizeThatFits(ProposedViewSize(width: $0, height: nil)) },
                            action: action.map { a in { a.sizeThatFits(ProposedViewSize(width: $0, height: nil)) } })
    }

    /// The arithmetic of the toast, apart from SwiftUI so a test can run it: `width` = the room, `widest` = the
    /// message's widest word, `message(w)` / `action(w)` = their sizes at a width (nil = their ideal size).
    static func arrange(width w: CGFloat, widest: CGFloat, gap: CGFloat, message: (CGFloat) -> CGSize,
                        action: ((CGFloat?) -> CGSize)?) -> (size: CGSize, message: CGRect, action: CGRect?) {
        guard let action else {
            let m = message(w)
            return (CGSize(width: w, height: m.height), CGRect(origin: .zero, size: m), nil)
        }
        let a = action(nil)
        let room = w - a.width
        if widest <= room {
            let m = message(room)
            let oneLine = m.height <= a.height
            let pad: CGFloat = oneLine ? 0 : gap
            let h = max(m.height + 2 * pad, a.height)
            return (CGSize(width: w, height: h),
                    CGRect(x: 0, y: (h - m.height) / 2, width: room, height: m.height),
                    CGRect(x: w - a.width, y: (h - a.height) / 2, width: a.width, height: a.height))
        }
        // under the message: an action wider than the toast is measured at the toast's width and wraps (D99 (1))
        let m = message(w)
        let under = a.width > w ? action(w) : a
        let h = gap + m.height + under.height
        return (CGSize(width: w, height: h),
                CGRect(x: 0, y: gap, width: w, height: m.height),
                CGRect(x: w - under.width, y: gap + m.height, width: under.width, height: under.height))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal, subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let (_, messageFrame, actionFrame) = arrange(ProposedViewSize(width: bounds.width, height: nil), subviews)
        let (message, action, _) = parts(subviews)
        message.place(at: CGPoint(x: bounds.minX + messageFrame.minX, y: bounds.minY + messageFrame.minY),
                      proposal: ProposedViewSize(messageFrame.size))
        if let action, let actionFrame {
            action.place(at: CGPoint(x: bounds.minX + actionFrame.minX, y: bounds.minY + actionFrame.minY),
                         proposal: ProposedViewSize(actionFrame.size))
        }
        // the probes stay out of sight at the origin, zero-sized
        for probe in subviews where probe[SbToastProbeKey.self] {
            probe.place(at: bounds.origin, proposal: .zero)
        }
    }
}

struct SbToastProbeKey: LayoutValueKey { static let defaultValue = false }

/// One toast for `sbToastHost`: the message, an optional action word („Rückgängig“) and what it does.
public struct SbToastData: Identifiable {
    public let id = UUID()
    public let message: String
    public let actionLabel: String?
    public let onAction: () -> Void

    public init(_ message: String, actionLabel: String? = nil, onAction: @escaping () -> Void = {}) {
        self.message = message
        self.actionLabel = actionLabel
        self.onAction = onAction
    }
}

/// The toast of a screen (spec/08 §14.1): `show` replaces the current one, `dismiss` closes it.
@MainActor @Observable
public final class SbToastState {
    public private(set) var current: SbToastData?
    public init() {}
    public func show(_ data: SbToastData) { current = data }
    public func dismiss() { current = nil }

    /// The toast's timer: unless `hold` holds it, toast `id` closes after `duration`. Cancelled (the host restarts
    /// it with every change of the hold), nothing closes; a newer toast is never closed by an older timer.
    func expire(_ id: UUID, hold: SbToastHold, after duration: Duration) async {
        if hold.held { return }
        try? await Task.sleep(for: duration)
        if !Task.isCancelled, current?.id == id { dismiss() }
    }
}

public extension View {
    /// Shows `state`'s toast at the bottom of this view, in the gutter, 8 pt above its edge, and always above the
    /// primary action and the bottom bar of `SbScreen`: attached to the content of `SbScreen` it ends above that
    /// block, attached to the whole `SbScreen` it is lifted by the block's height (CHECKS.md §41). A toast taller than
    /// the room left above the block fills it and only its message scrolls; the action stays in view under it. It enters from below (only fades
    /// with reduced motion), is announced politely, and closes after `duration` (6 s); it stays while VoiceOver focus
    /// is on its message or its action or a finger is on it, and the full time starts again when they leave. Its action closes it; Escape and the VoiceOver escape gesture close it.
    func sbToastHost(_ state: SbToastState, duration: Duration = .seconds(6)) -> some View {
        modifier(SbToastHost(state: state, duration: duration))
    }
}

struct SbToastHost: ViewModifier {
    let state: SbToastState
    let duration: Duration
    private var context = SbContext()
    @AccessibilityFocusState private var focus: SbToastPart?
    @State private var touched = false
    /// the height of an `SbScreen` bottom block inside this view (0 when the host is on the screen's content)
    @State private var block: CGFloat = 0

    init(state: SbToastState, duration: Duration) {
        self.state = state
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            ZStack {
                if let data = state.current {
                    // a toast taller than the room above the block (AX5 on a 320 × 568 pt phone) fills that room and
                    // only its message scrolls; the action stays in view (CHECKS.md §41; provisional, agent)
                    ViewThatFits(in: .vertical) {
                        toast(data, scrolls: false)
                        toast(data, scrolls: true)
                    }
                    .transition(.sbEnter(reduceMotion: context.reduceMotion))
                    .id(data.id)
                    .task(id: TimerKey(id: data.id, hold: SbToastHold(focus: focus, touched: touched))) {
                        await state.expire(data.id, hold: SbToastHold(focus: focus, touched: touched), after: duration)
                    }
                    .onAppear { SbAnnounce.polite(data.message) }
                }
            }
            .animation(SebaroMotion.enter(reduceMotion: context.reduceMotion), value: state.current?.id)
            .padding(.bottom, block)
        }
        .onPreferenceChange(SbBottomBlockKey.self) { [$block] h in if $block.wrappedValue != h { $block.wrappedValue = h } }
    }

    private func toast(_ data: SbToastData, scrolls: Bool) -> some View {
        let toast = SbToast(data.message, actionLabel: data.actionLabel) {
            data.onAction()
            state.dismiss()
        }
        .focus($focus)
        return (scrolls ? toast.scrollingMessage() : toast)
        .accessibilityAction(.escape) { state.dismiss() }
        .onKeyPress(.escape) { state.dismiss(); return .handled }
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in touched = true }
            .onEnded { _ in touched = false })
        .padding(.horizontal, SebaroSpacing.gutter)
        .padding(.vertical, SebaroSpace.s2)
    }

    private struct TimerKey: Equatable {
        let id: UUID
        let hold: SbToastHold
    }
}
