import SwiftUI

/// A form as a full-height sheet with „Sichern“ at the bottom (D91 I5b): a form is a task with an end, not a
/// sub-page. The sheet has its own inline title, „Abbrechen“ as the cancellation action at the top leading place,
/// and the primary action at the bottom of the area it acts on (D39, D74), not „Sichern“ at the top trailing place
/// as iOS usually does: that is the visible difference from iOS. Ground `bg`, the 2 pt ink layer line along the top
/// edge and its 16 pt corners (D46, D77), no grabber. While the draft is changed (`isDirty`) a swipe down cannot
/// close the sheet, so changes are never lost silently; „Abbrechen“ always closes it.
///
/// From 640 pt width (iPad, D91 Z2b) the system shows the sheet as a form sheet, at most 560 pt wide
/// (`presentationSizing(.form)` from iOS 18; on iOS 17 the system's own form width).
public extension View {
    func sbFormSheet<Form: View>(isPresented: Binding<Bool>, title: String, isDirty: Bool,
                                 primaryAction: SbPrimaryActionModel,
                                 @ViewBuilder form: @escaping () -> Form) -> some View {
        sheet(isPresented: isPresented) {
            SbFormSheet(title: title, isDirty: isDirty, primaryAction: primaryAction,
                        onCancel: { isPresented.wrappedValue = false }, form: form)
        }
    }
}

/// The content of the form sheet; `sbFormSheet(…)` presents it. Usable alone for specimens and tests.
public struct SbFormSheet<Form: View>: View {
    let title: String
    let isDirty: Bool
    let primaryAction: SbPrimaryActionModel
    let onCancel: () -> Void
    let form: () -> Form
    private var context = SbContext()

    public init(title: String, isDirty: Bool, primaryAction: SbPrimaryActionModel, onCancel: @escaping () -> Void,
                @ViewBuilder form: @escaping () -> Form) {
        self.title = title
        self.isDirty = isDirty
        self.primaryAction = primaryAction
        self.onCancel = onCancel
        self.form = form
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                form()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, SebaroSpacing.gutter)
                    .padding(.vertical, SebaroSpace.s4)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(context.tone.bg)
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                SbToolbarItem(placement: .cancellationAction) {
                    Button(action: onCancel) {
                        Text(context.messages.cancel).sbFont(.body).foregroundStyle(context.tone.text)
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                SbPrimaryActionBar(primaryAction)
                    .background(context.tone.bg.ignoresSafeArea(edges: .bottom))
                    .overlay(alignment: .top) { SbLayerLine() }
            }
        }
        .modifier(SbHardScrollEdge())
        .overlay(alignment: .top) { SbSheetTopEdge() }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(context.tone.bg)
        .presentationCornerRadius(SebaroRadius.sheet)
        .interactiveDismissDisabled(isDirty)
        .modifier(SbFormSizing())
    }
}

/// The ink line along the sheet's top edge and its two 16 pt corners (the Android `SbBottomSheet` draws the same).
struct SbSheetTopEdge: View {
    @Environment(\.sebaroTone) private var tone
    var body: some View {
        let w = SebaroX.layerLineWidth
        UnevenRoundedRectangle(topLeadingRadius: SebaroRadius.sheet, topTrailingRadius: SebaroRadius.sheet,
                               style: .continuous)
            .strokeBorder(tone.layerLine, lineWidth: w)
            .frame(height: SebaroRadius.sheet * 2)
            .mask(alignment: .top) { Rectangle().frame(height: SebaroRadius.sheet) }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct SbFormSizing: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            content.presentationSizing(.form)
        } else {
            content
        }
    }
}
