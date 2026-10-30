import SwiftUI

// MARK: - Focus ring (D5, D85)

/// The one focus ring for keyboard focus (iPad keyboard, Full Keyboard Access): 2 pt in `Color.sbFocus`, 2 pt outside
/// the element, never animated. The system focus halo is switched off where this ring is drawn.
struct SbFocusRing<S: Shape>: ViewModifier {
    let shape: S
    let focused: Bool
    func body(content: Content) -> some View {
        content
            .overlay {
                if focused {
                    shape
                        .stroke(Color.sbFocus, lineWidth: SebaroFocus.width)
                        .padding(-(SebaroFocus.offset + SebaroFocus.width / 2))
                        .allowsHitTesting(false)
                }
            }
            .focusEffectDisabled()
    }
}

// MARK: - The primary action (D39, D48)

/// What the work behind the primary action is doing (D48, spec/03 §16). The app owns the state and its timing.
public enum SbActionState: Equatable, Sendable {
    /// Nothing runs: the normal label.
    case idle
    /// Work runs: `label` says what („Wird angelegt …“); `fraction` 0…1 when the share is known.
    case busy(label: String, fraction: Double? = nil)
    /// Finished: the check icon and `label` for `SebaroX.primaryActionDoneDwell` s, then the app sets `.idle`.
    case done(label: String)
    /// Failed: `reason` as a sentence above the action, the action reads `retryLabel` (nil = „Noch mal versuchen“);
    /// `details` the technical text under „Details“ (D102 (23), spec/07 §4.1), nil = none.
    case failed(reason: String, retryLabel: String? = nil, details: String? = nil)
}

/// The one primary action of a view: its label, action, optional icon (a sprite id) and state.
public struct SbPrimaryActionModel {
    public var title: String
    public var icon: String?
    public var enabled: Bool
    public var hint: String?
    public var state: SbActionState
    /// The app's own „Vibration“ switch (D105 (24)): false keeps the success impulse silent.
    public var haptics: Bool
    public var action: () -> Void

    public init(_ title: String, icon: String? = nil, enabled: Bool = true, hint: String? = nil,
                state: SbActionState = .idle, haptics: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.enabled = enabled
        self.hint = hint
        self.state = state
        self.haptics = haptics
        self.action = action
    }
}

/// The primary action (Hauptaktion): lime fill `sbPrimaryAction`, label `onPrimaryAction` in body-strong, 2 pt outline
/// (ink by day, the fill by night), radius 8, 56 pt high. Never filled in any other colour; at most one per view, at
/// the bottom of the area it acts on: place it through `SbScreen` or `SbPrimaryActionBar`, never alone in a list.
public struct SbPrimaryAction: View {
    let model: SbPrimaryActionModel
    @StateObject private var haptics = SbHaptics()

    public init(_ model: SbPrimaryActionModel) { self.model = model }

    public var body: some View {
        Button(action: { if model.haptics { haptics.prepare() }; model.action() }) {
            SbPrimaryActionLabel(model: model)
        }
        .buttonStyle(SbPrimaryActionStyle(state: model.state))
        .disabled(!model.enabled || isBusy)
        .accessibilityValue(accessibilityValue)
        .onChange(of: model.state) { _, new in
            if case .done = new, model.haptics { haptics.success() }
        }
    }

    private var isBusy: Bool { if case .busy = model.state { return true } else { return false } }
    private var accessibilityValue: String {
        if case .busy(_, let f?) = model.state { return "\(Int((f * 100).rounded()))\u{00A0}%" }
        return ""
    }
}

struct SbPrimaryActionLabel: View {
    let model: SbPrimaryActionModel
    private var context = SbContext()
    init(model: SbPrimaryActionModel) { self.model = model }

    var body: some View {
        let shown: (text: String, icon: String?) = switch model.state {
        case .idle: (model.title, model.icon)
        case .busy(let label, _): (label, nil)
        case .done(let label): (label, "check")
        case .failed(_, let retry, _): (retry ?? context.messages.retry, nil)
        }
        HStack(spacing: SebaroSpacing.inline) {
            if let icon = shown.icon { SbIcon(icon, size: SebaroSize.iconLg) }
            SbWrapText(shown.text, style: .bodyStrong, center: true)
        }
        .padding(.horizontal, SebaroSpace.s6)
        .frame(maxWidth: .infinity, minHeight: SebaroSize.controlLg)
        .overlay(alignment: .bottomLeading) {
            if case .busy(_, let fraction) = model.state {
                SbActionProgressBar(fraction: fraction, reduceMotion: context.reduceMotion)
            }
        }
    }
}

struct SbPrimaryActionStyle: ButtonStyle {
    let state: SbActionState
    @Environment(\.isEnabled) private var enabled
    @Environment(\.isFocused) private var focused
    @Environment(\.sebaroTone) private var tone

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.control, style: .continuous)
        let busy: Bool = { if case .busy = state { return true } else { return false } }()
        let live = enabled || busy
        let fill: Color = !live ? tone.surfaceSunken
            : (configuration.isPressed ? Color.sbPrimaryActionPressed : Color.sbPrimaryAction)
        configuration.label
            .foregroundStyle(live ? tone.onPrimaryAction : tone.textMuted)
            .background(fill, in: shape)
            .clipShape(shape)
            .overlay(shape.strokeBorder(live ? tone.primaryActionOutline : tone.borderStrong,
                                        lineWidth: SebaroX.primaryActionOutlineWidth))
            .contentShape(shape)
            .modifier(SbFocusRing(shape: RoundedRectangle(cornerRadius: SebaroRadius.control + SebaroFocus.offset,
                                                          style: .continuous), focused: focused))
    }
}

/// The 6 pt ink bar along the bottom edge of the busy primary action (D48): grows to `fraction`, or sweeps every
/// `SebaroX.primaryActionProgressPeriod` s; with reduced motion it stands still at full width, 40 % opaque.
struct SbActionProgressBar: View {
    let fraction: Double?
    let reduceMotion: Bool
    @State private var sweep = false

    var body: some View {
        GeometryReader { geo in
            let h = SebaroX.primaryActionProgressHeight
            Group {
                if let fraction {
                    Rectangle().frame(width: geo.size.width * min(max(fraction, 0), 1), height: h)
                        .animation(.linear(duration: SebaroMotion.durationMedium), value: fraction)
                } else if reduceMotion {
                    Rectangle().frame(width: geo.size.width, height: h).opacity(0.4)
                } else {
                    Rectangle().frame(width: geo.size.width * 0.34, height: h)
                        .offset(x: sweep ? geo.size.width * 3 : -geo.size.width)
                        .onAppear {
                            withAnimation(SebaroMotion.easingStandard.animation(duration: SebaroX.primaryActionProgressPeriod)
                                .repeatForever(autoreverses: false)) { sweep = true }
                        }
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottomLeading)
        }
        .clipShape(RoundedRectangle(cornerRadius: SebaroRadius.control, style: .continuous))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The fixed bottom place of the primary action: full width, 56 pt, 16 pt side and 12 pt vertical padding, the
/// optional per-action hint under it, and the reason of a failure above it (D48 as refined by D83 (2): the error
/// glyph in danger, the sentence in text, announced).
public struct SbPrimaryActionBar: View {
    let model: SbPrimaryActionModel
    private var context = SbContext()

    public init(_ model: SbPrimaryActionModel) { self.model = model }

    public var body: some View {
        VStack(spacing: SebaroSpace.s2) {
            if case .failed(let reason, _, let details) = model.state {
                HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s1) {
                    SbIcon("error--filled", size: SebaroSize.iconSm, color: .sbDanger)
                    Text(reason).sbFont(.body).foregroundStyle(context.tone.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .onAppear { SbAnnounce.polite(reason) }
                if let details {
                    SbErrorDetails(details)
                        .padding(.leading, SebaroSize.iconSm + SebaroSpace.s1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            SbPrimaryAction(model)
            if let hint = model.hint {
                Text(hint).sbFont(.caption).foregroundStyle(context.tone.textMuted).multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, SebaroSpacing.gutter)
        .padding(.vertical, SebaroSpace.s3)
    }
}

/// The technical details of an error under its sentence (D102 (23), spec/02 §3.28, spec/07 §4.1): the word
/// „Details“ after the 16 pt chevron in a 48 pt target, closed at first; open, `details` (the system's own message,
/// never a second sentence) in sebaro Mono. VoiceOver hears „Details, eingeklappt“ / „ausgeklappt“.
public struct SbErrorDetails: View {
    let details: String
    @State private var open: Bool
    private var context = SbContext()

    public init(_ details: String, initiallyExpanded: Bool = false) {
        self.details = details
        _open = State(initialValue: initiallyExpanded)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { open.toggle() } label: {
                HStack(spacing: SebaroSpace.s1) {
                    SbIcon("chevron-down--16", size: SebaroSize.iconSm, color: context.tone.textMuted)
                        .rotationEffect(.degrees(open ? 180 : 0))
                    Text(context.messages.errorDetails).sbFont(.label).foregroundStyle(context.tone.text)
                }
                .frame(minHeight: SebaroSize.targetTouch)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(open ? context.messages.errorDetailsOpen : context.messages.errorDetailsClosed)
            if open {
                Text(details).sbFont(.code).foregroundStyle(context.tone.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, SebaroSpace.s2)
            }
        }
    }
}

/// Polite announcements for VoiceOver (the live region of Compose / the web's role="status").
@MainActor enum SbAnnounce {
    /// Tests only: hears every announcement (VoiceOver cannot run in the test).
    static var heard: ((String) -> Void)?

    static func polite(_ text: String) {
        heard?(text)
        #if canImport(UIKit)
        var s = AttributedString(text)
        s.accessibilitySpeechAnnouncementPriority = .low
        AccessibilityNotification.Announcement(s).post()
        #endif
    }
}

// MARK: - Other actions: never filled (spec/08 §6)

/// Secondary action: 48 pt, 1 pt border-strong outline, radius 8, label body-strong in text; pressed `pressedFill`.
/// „Bearbeiten“, „Abbrechen“ in the dialog.
public struct SbSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.isFocused) private var focused
    @Environment(\.sebaroTone) private var tone
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.control, style: .continuous)
        configuration.label
            .sbFont(.bodyStrong)
            .foregroundStyle(enabled ? tone.text : tone.textMuted)
            .padding(.horizontal, SebaroSpacing.insetControl)
            .frame(minHeight: SebaroSize.controlMd)
            .background(configuration.isPressed ? tone.pressedFill : tone.bg, in: shape)
            .overlay(shape.strokeBorder(tone.borderStrong, lineWidth: SebaroBorderWidth.control))
            .contentShape(shape)
            .modifier(SbFocusRing(shape: RoundedRectangle(cornerRadius: SebaroRadius.control + SebaroFocus.offset,
                                                          style: .continuous), focused: focused))
    }
}

/// Text action (D52): the word in text colour with the 2 pt link underline, a 48 pt target; pressed turns the word
/// `sbLink`. „Wie geprüft?“, „Rückgängig“.
public struct SbTextActionStyle: ButtonStyle {
    @Environment(\.isFocused) private var focused
    @Environment(\.sebaroTone) private var tone
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .sbFont(.bodyStrong)
            .foregroundStyle(configuration.isPressed ? Color.sbLink : tone.text)
            .padding(.bottom, SebaroSpace.s0_5)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.sbLink).frame(height: SebaroX.linkUnderlineWidth)
            }
            .frame(minWidth: SebaroSize.targetTouch, minHeight: SebaroSize.targetTouch, alignment: .leading)
            .contentShape(Rectangle())
            .modifier(SbFocusRing(shape: RoundedRectangle(cornerRadius: SebaroRadius.control), focused: focused))
    }
}

/// A rounded rectangle whose top trailing corner is cut at 45° (D46: the cut means final). Only destructive actions
/// and a final step that deletes nothing (D102 (43)) use it; `cut` is the length of each leg
/// (`SebaroX.dangerBevelSize`, 12 pt). Mirrors in right-to-left layouts.
public struct SbBevelShape: InsettableShape {
    public var radius: CGFloat
    public var cut: CGFloat
    var inset: CGFloat = 0
    public var layoutDirection: LayoutDirection

    public init(radius: CGFloat = SebaroRadius.control, cut: CGFloat = SebaroX.dangerBevelSize,
                layoutDirection: LayoutDirection = .leftToRight) {
        self.radius = radius
        self.cut = cut
        self.layoutDirection = layoutDirection
    }

    public func path(in rect: CGRect) -> Path {
        let r0 = rect.insetBy(dx: inset, dy: inset)
        let r = min(radius, min(r0.width, r0.height) / 2)
        let k = min(max(cut - inset * 0.4142, 0), min(r0.width, r0.height) / 2)   // keep 45° under an inset stroke
        var p = Path()
        p.move(to: CGPoint(x: r0.minX + r, y: r0.minY))
        p.addLine(to: CGPoint(x: r0.maxX - k, y: r0.minY))
        p.addLine(to: CGPoint(x: r0.maxX, y: r0.minY + k))
        p.addArc(tangent1End: CGPoint(x: r0.maxX, y: r0.maxY), tangent2End: CGPoint(x: r0.minX, y: r0.maxY), radius: r)
        p.addArc(tangent1End: CGPoint(x: r0.minX, y: r0.maxY), tangent2End: CGPoint(x: r0.minX, y: r0.minY), radius: r)
        p.addArc(tangent1End: CGPoint(x: r0.minX, y: r0.minY), tangent2End: CGPoint(x: r0.maxX, y: r0.minY), radius: r)
        p.closeSubpath()
        guard layoutDirection == .rightToLeft else { return p }
        return p.applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: rect.minX + rect.maxX, ty: 0))
    }

    public func inset(by amount: CGFloat) -> SbBevelShape {
        var s = self
        s.inset += amount
        return s
    }
}

/// Destructive action: the word (and optional icon) in danger inside a 1 pt danger outline with the 45° cut (D46),
/// never filled, 48 pt. „Gewohnheit löschen“, „Löschen“ in the dialog.
public struct SbDangerButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var focused
    @Environment(\.layoutDirection) private var direction
    @Environment(\.sebaroTone) private var tone
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        let shape = SbBevelShape(layoutDirection: direction)
        configuration.label
            .sbFont(.bodyStrong)
            .foregroundStyle(Color.sbDanger)
            .padding(.horizontal, SebaroSpacing.insetControl)
            .frame(minHeight: SebaroSize.controlMd)
            .background(configuration.isPressed ? tone.pressedFill : Color.clear, in: shape)
            .overlay(shape.strokeBorder(Color.sbDanger, lineWidth: SebaroBorderWidth.control))
            .contentShape(shape)
            .modifier(SbFocusRing(shape: SbBevelShape(radius: SebaroRadius.control + SebaroFocus.offset,
                                                      cut: SebaroX.dangerBevelSize + SebaroFocus.offset,
                                                      layoutDirection: direction), focused: focused))
    }
}

/// The destructive action with its icon: `SbDangerAction("Gewohnheit löschen", icon: "trash") { … }`.
public struct SbDangerAction: View {
    let title: String
    let icon: String?
    let action: () -> Void
    public init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    public var body: some View {
        Button(action: action) {
            HStack(spacing: SebaroSpacing.inline) {
                if let icon { SbIcon(icon, size: SebaroSize.iconLg) }
                SbWrapText(title)
            }
        }
        .buttonStyle(SbDangerButtonStyle())
    }
}
