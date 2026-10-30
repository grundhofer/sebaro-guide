import SwiftUI

/// The confirmation before a destructive action (D39), our own dialog as on Android (D91 I4a), not `.alert`:
/// ground `bg`, the 2 pt ink layer line, radius 16, 24 pt padding, at most 560 pt wide, the palette's scrim behind,
/// no shadow (D46). Title (title role, a question with the object), text (what is lost, then „Das lässt sich nicht
/// rückgängig machen.“), then „Abbrechen“ (secondary, first) and the verb (`SbDangerButtonStyle`, the 45° cut, last;
/// D83 (5)). Confirming plays the stronger double impulse (`SbHaptics.deleteConfirmed()`, touch only) before
/// `onConfirm`, unless the app's own „Vibration“ switch is off: it passes `haptics: false` (D105 (24)). The same dialog asks before a final step that deletes nothing (D102 (43), spec/02 §4.6: „Retro beenden?“);
/// its message then says what is no longer possible afterwards instead of „Das lässt sich nicht rückgängig machen.“.
///
/// Modal for real: it is presented as a full-screen cover without the cover's slide (the transaction disables that
/// animation) on a clear background, so VoiceOver and keyboard focus stay inside and the dialog covers navigation
/// and tab bar; the card itself enters 8 pt from below in 200 ms, with reduced motion it only fades (D46 (4)).
/// VoiceOver focus starts on „Abbrechen“; Escape (hardware keyboard), the VoiceOver escape gesture and a tap on the
/// scrim cancel.
public extension View {
    /// `neutral` (D105 (37), spec/02 §4.6): nothing is lost by the step („Als UTF-8 sichern?“), so the verb is a secondary
    /// action without the danger colour, the cut or the pulse.
    func sbConfirmDialog(isPresented: Binding<Bool>, title: String, message: String, confirm: String,
                         haptics: Bool = true, neutral: Bool = false, onConfirm: @escaping () -> Void) -> some View {
        modifier(SbDialogPresenter(isPresented: isPresented) { close in
            SbConfirmDialog(title: title, message: message, confirm: confirm, haptics: haptics, neutral: neutral,
                            onConfirm: { onConfirm(); close() }, onDismiss: close)
        })
    }

    /// Unsaved changes, three ways (D105 (36), D106 (11), AKT-11; spec/02 §4.6): „Abbrechen“ first, „Verwerfen“ (the
    /// danger outline with the cut, no trash: the changes go, the file stays) and „Sichern“ last as a secondary action
    /// (no lime in a dialog). „Sichern unter …“ is never offered here. The words „Sichern“ and „Verwerfen“ come from
    /// the words table unless `save` / `discard` are passed. `saveHint` is the data-path line directly under
    /// „Sichern“ (D98 V4, BEL-10; spec/10 §3.4): `.onDevice` = „Bleibt auf diesem Gerät.“ from the words table.
    func sbUnsavedDialog(isPresented: Binding<Bool>, title: String, message: String, save: String? = nil,
                         discard: String? = nil, saveHint: SbDataPathHint? = nil, haptics: Bool = true,
                         onSave: @escaping () -> Void, onDiscard: @escaping () -> Void) -> some View {
        modifier(SbDialogPresenter(isPresented: isPresented) { close in
            SbUnsavedDialog(title: title, message: message, save: save, discard: discard, saveHint: saveHint,
                            haptics: haptics, onSave: { onSave(); close() }, onDiscard: { onDiscard(); close() }, onDismiss: close)
        })
    }
}

/// Presents a dialog of this file as a full-screen cover without the cover's slide, on a clear background.
struct SbDialogPresenter<Dialog: View>: ViewModifier {
    @Binding var isPresented: Bool
    let dialog: (_ close: @escaping () -> Void) -> Dialog
    @State private var shown = false

    init(isPresented: Binding<Bool>, @ViewBuilder dialog: @escaping (_ close: @escaping () -> Void) -> Dialog) {
        self._isPresented = isPresented
        self.dialog = dialog
    }

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .fullScreenCover(isPresented: $shown) { host }
            #else
            .sheet(isPresented: $shown) { host }
            #endif
            .onChange(of: isPresented, initial: true) { _, new in set(new) }
            .onChange(of: shown) { _, new in if !new && isPresented { isPresented = false } }
    }

    private var host: some View {
        dialog { set(false) }
            .presentationBackground(.clear)
    }

    private func set(_ value: Bool) {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            shown = value
            if !value { isPresented = false }
        }
    }
}

/// The dialog itself with its scrim; `sbConfirmDialog(…)` presents it. Usable alone for specimens and tests.
public struct SbConfirmDialog: View {
    let title: String
    let message: String
    let confirm: String
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    var animateIn: Bool
    let hapticsOn: Bool
    let neutral: Bool
    @StateObject private var haptics = SbHaptics()

    public init(title: String, message: String, confirm: String, animateIn: Bool = true, haptics: Bool = true,
                neutral: Bool = false, onConfirm: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.confirm = confirm
        self.animateIn = animateIn
        self.hapticsOn = haptics && !neutral
        self.neutral = neutral
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
    }

    public var body: some View {
        SbDialogFrame(title: title, message: message, animateIn: animateIn, onDismiss: onDismiss,
                      onAppear: { if hapticsOn { haptics.prepare() } }) { fill in
            if neutral {
                SbDialogButton(confirm, fill: fill, action: onConfirm)
            } else {
                SbDialogButton(confirm, fill: fill, danger: true) {
                    if hapticsOn { haptics.deleteConfirmed() }
                    onConfirm()
                }
            }
        }
    }
}

/// The data-path line under an action that sends or stores (D98 V4, BEL-10; spec/10 §3.4): `.onDevice` =
/// „Bleibt auf diesem Gerät.“ / „Stays on this device.“ from `SbMessages.staysOnDevice`; `.text` = the app's own
/// line, e.g. „Nur auf deinen Befehl. Ziel: …“ (FACTS-CONTRACT §6.5).
public enum SbDataPathHint: Sendable, Equatable {
    case onDevice
    case text(String)

    func resolved(_ messages: SbMessages) -> String {
        switch self {
        case .onDevice: messages.staysOnDevice
        case .text(let line): line
        }
    }
}

/// The unsaved-changes dialog itself (`sbUnsavedDialog(…)` presents it): „Abbrechen“ · „Verwerfen“ · „Sichern“.
/// Confirming „Verwerfen“ plays the stronger pulse as a deletion does (spec/03 §18), only with `haptics`. `saveHint`
/// stands directly under „Sichern“ in caption, text-muted: start-aligned with the key in one row, centred under the
/// full-width key when the keys are stacked (spec/10 §3.4); VoiceOver reads it right after „Sichern“.
public struct SbUnsavedDialog: View {
    let title: String
    let message: String
    let save: String?
    let discard: String?
    let saveHint: SbDataPathHint?
    let animateIn: Bool
    let hapticsOn: Bool
    let onSave: () -> Void
    let onDiscard: () -> Void
    let onDismiss: () -> Void
    private var context = SbContext()
    @StateObject private var haptics = SbHaptics()

    public init(title: String, message: String, save: String? = nil, discard: String? = nil,
                saveHint: SbDataPathHint? = nil, animateIn: Bool = true, haptics: Bool = true,
                onSave: @escaping () -> Void, onDiscard: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.save = save
        self.discard = discard
        self.saveHint = saveHint
        self.animateIn = animateIn
        self.hapticsOn = haptics
        self.onSave = onSave
        self.onDiscard = onDiscard
        self.onDismiss = onDismiss
    }

    public var body: some View {
        SbDialogFrame(title: title, message: message, animateIn: animateIn, onDismiss: onDismiss,
                      onAppear: { if hapticsOn { haptics.prepare() } }) { fill in
            SbDialogButton(discard ?? context.messages.discard, fill: fill, danger: true) {
                if hapticsOn { haptics.deleteConfirmed() }
                onDiscard()
            }
            if let saveHint {
                VStack(alignment: fill ? .center : .leading, spacing: SebaroSpace.s2) {
                    SbDialogButton(save ?? context.messages.save, fill: fill, action: onSave)
                    Text(saveHint.resolved(context.messages)).sbFont(.caption).foregroundStyle(context.tone.textMuted)
                        .multilineTextAlignment(fill ? .center : .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: fill ? .infinity : nil)
            } else {
                SbDialogButton(save ?? context.messages.save, fill: fill, action: onSave)
            }
        }
    }
}

/// One action of a dialog: secondary, or `danger` with the 45° cut; `fill` = the full width of a stacked row.
struct SbDialogButton: View {
    let title: String
    let fill: Bool
    let danger: Bool
    let action: () -> Void

    init(_ title: String, fill: Bool, danger: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.fill = fill
        self.danger = danger
        self.action = action
    }

    var body: some View {
        let button = Button(action: action) {
            // a key wider than its row at AX5 („Abbrechen“ on 320 pt) breaks with a hyphen, not between letters
            SbWrapText(title, center: true)
                .frame(maxWidth: fill ? .infinity : nil)
        }
        if danger { button.buttonStyle(SbDangerButtonStyle()) } else { button.buttonStyle(SbSecondaryButtonStyle()) }
    }
}

/// The frame of every dialog of this file: the palette's scrim, the card (ground `bg`, the 2 pt ink layer line,
/// radius 16, 24 pt padding, at most 560 pt wide, no shadow), the title (title role, a heading), the message (body),
/// then „Abbrechen“ first and the caller's actions after it, end-aligned in one row; when they do not fit one row each
/// takes its own row at the full width, in their order, the verb last (spec/02 §4.6). When the card is taller
/// than the screen only the message scrolls; title and actions stay. When title and actions alone do not fit, the
/// whole card scrolls (the last fallback; the actions are then reached by scrolling). VoiceOver focus starts on „Abbrechen“; Escape,
/// the VoiceOver escape gesture and a tap on the scrim cancel.
struct SbDialogFrame<Actions: View>: View {
    let title: String
    let message: String
    let animateIn: Bool
    let onDismiss: () -> Void
    let onAppear: () -> Void
    let actions: (_ fill: Bool) -> Actions
    private var context = SbContext()
    @AccessibilityFocusState private var cancelFocused: Bool
    @State private var visible = false
    /// The least of the message that stays in view while it scrolls (about two body lines, growing with the text):
    /// `ViewThatFits` measures the scrolling card at this height, so it is chosen exactly when title and actions fit.
    @ScaledMetric(relativeTo: .body) private var messageMin: CGFloat = SebaroSpace.s12

    init(title: String, message: String, animateIn: Bool, onDismiss: @escaping () -> Void,
         onAppear: @escaping () -> Void, @ViewBuilder actions: @escaping (_ fill: Bool) -> Actions) {
        self.title = title
        self.message = message
        self.animateIn = animateIn
        self.onDismiss = onDismiss
        self.onAppear = onAppear
        self.actions = actions
    }

    var body: some View {
        let on = visible || !animateIn
        ZStack {
            context.tone.scrim
                .ignoresSafeArea()
                .opacity(on ? 1 : 0)
                .onTapGesture(perform: onDismiss)
                .accessibilityHidden(true)
            if on {
                // whole; else only the message scrolls; when title and actions alone are taller than the screen
                // (AX5, a 320 × 568 pt phone, a long name) the whole card scrolls, so every action stays reachable
                ViewThatFits(in: .vertical) {
                    card(scrolls: false)
                    card(scrolls: true)
                    ScrollView { card(scrolls: false) }.scrollBounceBehavior(.basedOnSize)
                }
                .padding(.horizontal, SebaroSpacing.gutter)
                .padding(.vertical, SebaroSpace.s6)
                .transition(.sbEnter(reduceMotion: context.reduceMotion))
            }
        }
        .accessibilityAction(.escape, onDismiss)
        .onAppear {
            onAppear()
            withAnimation(SebaroMotion.enter(reduceMotion: context.reduceMotion)) { visible = true }
            cancelFocused = true
        }
    }

    private func card(scrolls: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.sheet, style: .continuous)
        let text = Text(message).sbFont(.body).foregroundStyle(context.tone.text)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        return VStack(alignment: .leading, spacing: 0) {
            SbWrapText(title, style: .title).foregroundStyle(context.tone.text)
                .accessibilityAddTraits(.isHeader)
            Group {
                if scrolls {
                    ScrollView { text }.scrollBounceBehavior(.basedOnSize)
                        .frame(minHeight: messageMin, idealHeight: messageMin)
                } else {
                    text
                }
            }
            .padding(.top, SebaroSpace.s3)
            ViewThatFits(in: .horizontal) {
                // top: a data-path line under the last key leaves the keys on one line (spec/10 §3.4)
                HStack(alignment: .top, spacing: SebaroSpace.s3) {
                    Spacer(minLength: 0)
                    buttons(fill: false)
                }
                VStack(spacing: SebaroSpace.s3) { buttons(fill: true) }
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, SebaroSpace.s6)
        }
        .padding(SebaroSpace.s6)
        .frame(maxWidth: 560, alignment: .leading)   // spec/08 §8: max 560, as Compose (`560.dp`, no size token)
        .background(context.tone.bg, in: shape)
        .overlay(shape.strokeBorder(context.tone.layerLine, lineWidth: SebaroX.layerLineWidth))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder private func buttons(fill: Bool) -> some View {
        SbDialogButton(context.messages.cancel, fill: fill, action: onDismiss)
            .keyboardShortcut(.cancelAction)
            .accessibilityFocused($cancelFocused)
        actions(fill)
    }
}
