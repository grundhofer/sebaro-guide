import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - App-sign tile (D36, D40, D50, D57, D62)

/// The app sign in its group-coloured tile: the only place a product colour appears on screen (D40). Drawn from the
/// generated inline tiles (brand/inline/tile-<id>.svg from 48 pt with the three-letter code, tile-<id>-small.svg the
/// symbol alone below 48 pt and on the start tile, D57, D62); tile and sign colours come from `SebaroSignTile`, the
/// corner radius from `SebaroX.signTileRadiusRatio`. Below 32 pt show the symbol without a tile (spec/03 §4.3).
public struct SbSignTile: View {
    let product: SebaroProduct
    let size: CGFloat
    let withCode: Bool
    let accessibilityName: String?

    /// `accessibilityName` = the product name, or nil when the name stands next to the tile.
    public init(_ product: SebaroProduct, size: CGFloat = SebaroX.signTileSize, withCode: Bool? = nil,
                accessibilityName: String? = nil) {
        self.product = product
        self.size = size
        self.withCode = withCode ?? (size >= 48)
        self.accessibilityName = accessibilityName
    }

    public var body: some View {
        let tile = product.tile
        ZStack {
            RoundedRectangle(cornerRadius: size * SebaroX.signTileRadiusRatio, style: .circular).fill(tile.tile)
            if let doc = SbSignTiles.document(product.rawValue, small: !withCode) {
                SbSvgCanvas(document: doc, ink: tile.glyph, skipClasses: ["sb-app-sign__tile"])
            } else {
                Color.clear.onAppear {
                    assertionFailure("SbSignTile: brand/inline/tile-\(product.rawValue)\(withCode ? "" : "-small").svg is not in the package (export with --product)")
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(accessibilityName.map { Text($0) } ?? Text(""))
        .accessibilityHidden(accessibilityName == nil)
        .accessibilityAddTraits(.isImage)
    }
}

enum SbSignTiles {
    nonisolated(unsafe) private static var cache: [String: SbSvgDocument] = [:]
    private static let lock = NSLock()

    static func document(_ id: String, small: Bool) -> SbSvgDocument? {
        let name = "tile-\(id)\(small ? "-small" : "")"
        lock.lock(); defer { lock.unlock() }
        if let d = cache[name] { return d }
        guard let url = Bundle.module.url(forResource: name, withExtension: "svg", subdirectory: "Signs"),
              let data = try? Data(contentsOf: url), let doc = SbSvgParser.parseDocument(data).root else { return nil }
        cache[name] = doc
        return doc
    }
}

// MARK: - Bottom navigation (D36, D48 (2), D91 I1a)

/// One destination of the bottom navigation: the word (localised by the caller), the outline icon and the filled
/// icon of the current item (sprite ids, e.g. "home" / "home--filled").
public struct SbTabItem: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let icon: String
    public let selectedIcon: String

    public init(_ label: String, icon: String, selectedIcon: String? = nil) {
        self.id = icon
        self.label = label
        self.icon = icon
        self.selectedIcon = selectedIcon ?? (SbIcons.symbol(icon + "--filled") != nil ? icon + "--filled" : icon)
    }
}

/// Our own bottom bar, the same as `SbNavigationBar` on Android and the web (D91 I1a): 3–5 destinations, icon and
/// word each (D36), 64 pt, equal widths; the current item carries the 3 pt accent line along its top, the filled
/// icon, icon and word in `sbLink`, the word at the title weight. No glass, no pill, no tint area.
///
/// What the system tab bar would give for free is built here: VoiceOver reads each item as a selected or unselected
/// tab of a tab bar; the bar does not grow with Dynamic Type (I7a), instead a long press shows the large content
/// viewer at accessibility sizes; a second tap on the current item calls `onReselect` (scroll to top, pop to root).
public struct SbTabBar: View {
    let items: [SbTabItem]
    @Binding var selection: Int
    let onReselect: (Int) -> Void
    private var context = SbContext()

    public init(items: [SbTabItem], selection: Binding<Int>, onReselect: @escaping (Int) -> Void = { _ in }) {
        precondition((3...5).contains(items.count), "SbTabBar: 3 to 5 destinations, got \(items.count)")
        self.items = items
        self._selection = selection
        self.onReselect = onReselect
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let current = index == selection
                Button {
                    if current { onReselect(index) } else { selection = index }
                } label: {
                    VStack(spacing: SebaroSpace.s0_5) {
                        SbIcon(current ? item.selectedIcon : item.icon, size: SebaroSize.iconLg)
                        Text(item.label)
                            .font(tabFont(current: current))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(current ? Color.sbLink : context.tone.textMuted)
                    .frame(maxWidth: .infinity, minHeight: SebaroSpace.s16)
                    .overlay(alignment: .top) {
                        if current { Rectangle().fill(Color.sbAccent).frame(height: SebaroBorderWidth.strong) }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(SbPlainFocusStyle())
                .accessibilityLabel(Text(item.label))
                .accessibilityAddTraits(current ? [.isSelected, .isButton] : [.isButton])
                .accessibilityShowsLargeContentViewer {
                    SbIcon(current ? item.selectedIcon : item.icon, size: SebaroSize.iconLg)
                    Text(item.label)
                }
            }
        }
        // I7a: the bar keeps its size; the large content viewer above replaces growth.
        .dynamicTypeSize(.large)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isTabBar)
    }

    private func tabFont(current: Bool) -> Font {
        // label-small 12/16; the current item at the title weight (670 by day, 700 by night).
        let small = SebaroTextStyle.labelSmall.resolve(context.scheme)
        guard current else { return SebaroFonts.font(small, relativeTo: .caption, monospacedDigits: false) }
        let title = SebaroTextStyle.title.resolve(context.scheme)
        let face = SebaroTextFace(family: small.family, size: small.size, lineHeight: small.lineHeight,
                                  weight: title.weight, weightValue: title.weightValue, tracking: small.tracking)
        return SebaroFonts.font(face, relativeTo: .caption, monospacedDigits: false)
    }
}

/// A plain button style with the system focus ring replaced by ours.
struct SbPlainFocusStyle: ButtonStyle {
    @Environment(\.isFocused) private var focused
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
            .modifier(SbFocusRing(shape: RoundedRectangle(cornerRadius: SebaroRadius.control), focused: focused))
    }
}

// MARK: - Screen frame (D39, D46, D74)

/// Screen frame (spec/08 §4 in SwiftUI): the content, and at the bottom one block of at most one primary action and
/// the bottom navigation, with the 2 pt ink layer line on top (D46). The block rides above the keyboard only on a
/// screen without navigation (forms); with navigation it stays under the keyboard as on Android.
public struct SbScreen<Content: View>: View {
    let primaryAction: SbPrimaryActionModel?
    let tabs: SbTabBar?
    let content: Content
    private var context = SbContext()

    public init(primaryAction: SbPrimaryActionModel? = nil, tabs: SbTabBar? = nil, @ViewBuilder content: () -> Content) {
        self.primaryAction = primaryAction
        self.tabs = tabs
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(context.tone.bg.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if primaryAction != nil || tabs != nil {
                    VStack(spacing: 0) {
                        if let primaryAction { SbPrimaryActionBar(primaryAction) }
                        if let tabs { tabs }
                    }
                    .background(context.tone.bg.ignoresSafeArea(edges: .bottom))
                    .overlay(alignment: .top) { SbLayerLine() }
                    // a toast host on the whole screen stands above this block (CHECKS.md §41)
                    .background(GeometryReader { g in
                        Color.clear.preference(key: SbBottomBlockKey.self, value: g.size.height)
                    })
                }
            }
            .ignoresSafeArea(tabs != nil ? .keyboard : [], edges: .bottom)
            .modifier(SbHardScrollEdge())
    }
}

/// The height of `SbScreen`'s bottom block (primary action and navigation, without the home indicator's area): a
/// toast host attached to the whole screen lifts its toast by it; a host on the content already ends above the block.
struct SbBottomBlockKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// iOS 26 and later fade scrolled content under the bars with a blur (the soft scroll edge effect) or, in the hard
/// style, on a system ground that is not the tone's `bg` (measured on the iOS 27.0 simulator: #FBFEFF by day).
/// sebaro has neither blur nor a second ground (D46): the navigation bar is opaque in `bg` (see
/// `SbNavigationBarAppearance`), so the top edge effect is switched off; scrolled content is cut off under the bar.
///
/// `#if compiler(>=6.2)` around every symbol of the iOS 26 / macOS 26 SDK (here, in `SbToolbarItem` and in
/// `SbTopLevelNavigation`): `#available` only decides at run time, the symbol must still exist when compiling.
/// Swift 6.2 is Xcode 26, the first with that SDK; Xcode 16 (Swift 6.0, the package's minimum, spec/12 §1) compiles
/// the iOS 17/18 branch, which is also what such an app shows on iOS 26 (it links an older SDK).
struct SbHardScrollEdge: ViewModifier {
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *) {
            content.scrollEdgeEffectHidden(true, for: .top)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

/// A toolbar item without the glass capsule iOS 26 draws behind bar items (D46: no tinted, blurred ground):
/// `SbToolbarItem(placement: .topBarTrailing) { Button { … } label: { SbIcon("calendar") }.accessibilityLabel("Kalender") }`.
public struct SbToolbarItem<Content: View>: ToolbarContent {
    let placement: ToolbarItemPlacement
    let content: Content
    public init(placement: ToolbarItemPlacement, @ViewBuilder content: () -> Content) {
        self.placement = placement
        self.content = content()
    }
    public var body: some ToolbarContent {
        #if compiler(>=6.2)   // the iOS 26 SDK (see SbHardScrollEdge)
        if #available(iOS 26.0, macOS 26.0, *) {
            ToolbarItem(placement: placement) { content }.sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: placement) { content }
        }
        #else
        ToolbarItem(placement: placement) { content }
        #endif
    }
}

/// The 2 pt layer line in ink (D46) of the current tone.
public struct SbLayerLine: View {
    @Environment(\.sebaroTone) private var tone
    public init() {}
    public var body: some View {
        Rectangle().fill(tone.layerLine).frame(height: SebaroX.layerLineWidth).accessibilityHidden(true)
    }
}

// MARK: - Navigation bar of the system with our parts (D91 I2a)

/// The system navigation bar keeps VoiceOver, the back swipe, the large title and Dynamic Type. sebaro sets only
/// ground, type and colours: ground `bg` of the tone, no shadow line (D46), the large title in headline 24/32 and the
/// inline title in title 20/28 with their exact cuts (670 by day, 700 by night, D44), the back item in text colour
/// with the sprite's `chevron-left`. `SebaroAppRoot` installs it and re-installs it when the scheme or tone changes;
/// bars already on screen get the new appearance too.
@MainActor
public enum SbNavigationBarAppearance {
    public static func install(scheme: ColorScheme, tone: SebaroTone) {
        #if canImport(UIKit) && !os(macOS)
        let bar = UINavigationBarAppearance()
        bar.configureWithOpaqueBackground()
        bar.backgroundColor = UIColor(tone.bg)
        bar.shadowColor = .clear
        let text = UIColor(tone.text)
        bar.largeTitleTextAttributes = [
            .font: SebaroFonts.uiFont(SebaroTextStyle.headline.resolve(scheme), textStyle: .largeTitle),
            .foregroundColor: text,
        ]
        bar.titleTextAttributes = [
            .font: SebaroFonts.uiFont(SebaroTextStyle.title.resolve(scheme), textStyle: .title3),
            .foregroundColor: text,
        ]
        let back = UIBarButtonItemAppearance()
        back.normal.titleTextAttributes = [
            .font: SebaroFonts.uiFont(SebaroTextStyle.body.resolve(scheme), textStyle: .body),
            .foregroundColor: text,
        ]
        bar.backButtonAppearance = back
        let plain = UIBarButtonItemAppearance()
        plain.normal.titleTextAttributes = back.normal.titleTextAttributes
        bar.buttonAppearance = plain
        if let chevron = chevronImage() { bar.setBackIndicatorImage(chevron, transitionMaskImage: chevron) }

        let proxy = UINavigationBar.appearance()
        proxy.standardAppearance = bar
        proxy.scrollEdgeAppearance = bar
        proxy.compactAppearance = bar
        proxy.tintColor = text
        for scene in UIApplication.shared.connectedScenes {
            for window in (scene as? UIWindowScene)?.windows ?? [] {
                apply(bar, tint: text, in: window.rootViewController)
            }
        }
        #endif
    }

    #if canImport(UIKit) && !os(macOS)
    private static func apply(_ bar: UINavigationBarAppearance, tint: UIColor, in vc: UIViewController?) {
        guard let vc else { return }
        if let nav = vc as? UINavigationController {
            nav.navigationBar.standardAppearance = bar
            nav.navigationBar.scrollEdgeAppearance = bar
            nav.navigationBar.compactAppearance = bar
            nav.navigationBar.tintColor = tint
        }
        vc.children.forEach { apply(bar, tint: tint, in: $0) }
        apply(bar, tint: tint, in: vc.presentedViewController)
    }

    private static func chevronImage() -> UIImage? {
        let renderer = ImageRenderer(content: SbIcon("chevron-left", size: SebaroSize.iconLg, color: .black))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage?.withRenderingMode(.alwaysTemplate)
    }
    #endif
}

public extension View {
    /// The parts sebaro puts into the system navigation bar of a top-level screen (D91 I2a): the large title, the
    /// 32 pt sign tile as the first item (the start tile lands there, spec/03 §14) and the subtitle (iOS 26
    /// `navigationSubtitle`; before iOS 26 a caption line in text-muted directly under the bar).
    func sbTopLevelNavigation(title: String, subtitle: String? = nil, product: SebaroProduct) -> some View {
        modifier(SbTopLevelNavigation(title: title, subtitle: subtitle, product: product))
    }
}

struct SbTopLevelNavigation: ViewModifier {
    let title: String
    let subtitle: String?
    let product: SebaroProduct
    @Environment(\.sebaroTone) private var tone
    @Environment(\.dynamicTypeSize) private var typeSize

    // explicit, because private stored properties make the memberwise initializer private (Swift 6.0/6.1, Xcode 26)
    init(title: String, subtitle: String?, product: SebaroProduct) {
        self.title = title
        self.subtitle = subtitle
        self.product = product
    }

    func body(content: Content) -> some View {
        #if os(iOS)
        #if compiler(>=6.2)   // the iOS 26 SDK (see SbHardScrollEdge)
        if #available(iOS 26.0, *) {
            // iOS 26 and later draw the system large title under an opaque bar's ground, so it disappears (seen on
            // the iOS 27.0 simulator), and `inlineLarge` moves the leading tile to the trailing side. So the bar
            // keeps the tile (leading) and the tools, the system title is removed from the bar (it still names the
            // screen for VoiceOver and the back button of sub-screens), and title and subtitle stand as our own
            // row directly under the bar: the same picture as the large title of iOS 17/18 and Android's SbTopBar.
            content
                .navigationTitle(title)
                .toolbar(removing: .title)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { tile }.sharedBackgroundVisibility(.hidden)
                }
                .safeAreaInset(edge: .top, spacing: 0) { titleRow }
        } else {
            largeTitle(content)
        }
        #else
        largeTitle(content)
        #endif
        #else
        content.navigationTitle(title)
        #endif
    }

    #if os(iOS)
    /// iOS 17 and 18 (and every iOS of an app built with an SDK before iOS 26): the system large title with our type
    /// (SbNavigationBarAppearance), the tile as the first bar item, the subtitle as a line under the bar.
    private func largeTitle(_ content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { ToolbarItem(placement: .topBarLeading) { tile } }
            .modifier(SbSubtitleLine(subtitle: subtitle))
    }
    #endif

    private var tile: some View { SbSignTile(product, size: 32).sbStartTarget() }

    /// Title (headline, a heading for VoiceOver) and subtitle (caption, text-muted) under the bar, wrapping at
    /// every type size (D91 I7a).
    private var titleRow: some View {
        VStack(alignment: .leading, spacing: SebaroSpace.s0_5) {
            Text(title).sbFont(.headline).foregroundStyle(tone.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle).sbFont(.caption).foregroundStyle(tone.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SebaroSpacing.gutter)
        .padding(.bottom, SebaroSpace.s2)
        .background(tone.bg)
    }
}

public extension View {
    /// The title of a sub-screen (Einstellungen, Über, a detail): inline in the bar in the title role 20/28, as
    /// on Android (spec/08 §4: `title` on sub-screens). iOS 26 and later would hide a large title under the opaque
    /// bar, so sub-screens never use one.
    func sbNavigationTitle(_ title: String) -> some View {
        #if os(iOS)
        navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        #else
        navigationTitle(title)
        #endif
    }
}

/// The subtitle as a wrapping line directly under the bar (caption, text-muted, on bg).
struct SbSubtitleLine: ViewModifier {
    let subtitle: String?
    @Environment(\.sebaroTone) private var tone
    func body(content: Content) -> some View {
        if let subtitle {
            content.safeAreaInset(edge: .top, spacing: 0) {
                Text(subtitle).sbFont(.caption).foregroundStyle(tone.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, SebaroSpacing.gutter)
                    .padding(.bottom, SebaroSpace.s2)
                    .background(tone.bg)
            }
        } else {
            content
        }
    }
}
