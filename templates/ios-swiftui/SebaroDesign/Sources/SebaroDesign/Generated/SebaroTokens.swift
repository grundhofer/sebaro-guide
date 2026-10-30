// generated — do not edit.
// sebaroDesign token contract 1.10 · draft "sebaro" · palette "sebaro"
// source: systems/sebaro/tokens/tokens.json (sha256 e7c07024111c4253)
//         palettes/sebaro.json (sha256 21cebe04ae051e3a)
// builder: tools/build_tokens.py 1.10.1 · spec: shared/TOKEN-CONTRACT.md
// SwiftUI export (secondary target, BRIEF). Colours are asset-free dynamic colours: they resolve
// per trait collection (iOS) / effective appearance (macOS). Requires iOS 15 / macOS 12;
// sbTextStyle(_:) needs iOS 16 / macOS 13 (View.tracking).

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum SebaroBuildInfo {
    public static let contract = "1.10"
    public static let draft = "sebaro"
    public static let palette = "sebaro"
}

// MARK: - Colour plumbing

enum SebaroColorUtil {
    static func components(_ rgba: UInt32) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        (CGFloat((rgba >> 24) & 0xFF) / 255, CGFloat((rgba >> 16) & 0xFF) / 255,
         CGFloat((rgba >> 8) & 0xFF) / 255, CGFloat(rgba & 0xFF) / 255)
    }
    #if canImport(UIKit)
    static func platformColor(_ rgba: UInt32) -> UIColor {
        let c = components(rgba)
        return UIColor(red: c.0, green: c.1, blue: c.2, alpha: c.3)
    }
    #elseif canImport(AppKit)
    static func platformColor(_ rgba: UInt32) -> NSColor {
        let c = components(rgba)
        return NSColor(srgbRed: c.0, green: c.1, blue: c.2, alpha: c.3)
    }
    #endif
}

public extension Color {
    /// Static sRGB colour from 0xRRGGBBAA.
    init(sbRGBA rgba: UInt32) {
        let c = SebaroColorUtil.components(rgba)
        self.init(.sRGB, red: Double(c.0), green: Double(c.1), blue: Double(c.2), opacity: Double(c.3))
    }

    /// Asset-free dynamic colour: `light` or `dark` (0xRRGGBBAA) by the current appearance.
    init(sbLight light: UInt32, dark: UInt32) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            SebaroColorUtil.platformColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return SebaroColorUtil.platformColor(isDark ? dark : light)
        })
        #else
        self.init(sbRGBA: light)
        #endif
    }

    // Palette roles (core accent; product accents: Environment \.sebaroAccent).
    /// `bg`: page / window background
    static let sbBg = Color(sbLight: 0xF4F5F8FF, dark: 0x13161CFF)
    /// `surface`: default container: cards, panels, sidebars
    static let sbSurface = Color(sbLight: 0xFBFCFEFF, dark: 0x1B1E24FF)
    /// `surface-raised`: elevated container: menus, popovers, dialogs, sheets
    static let sbSurfaceRaised = Color(sbLight: 0xFFFFFFFF, dark: 0x212429FF)
    /// `surface-sunken`: inset area: wells, code blocks, input fill, table stripes
    static let sbSurfaceSunken = Color(sbLight: 0xE9EBEEFF, dark: 0x090C11FF)
    /// `text`: primary text and icons
    static let sbText = Color(sbLight: 0x1C1E22FF, dark: 0xEBEDEFFF)
    /// `text-muted`: secondary text: labels, captions, metadata, placeholders
    static let sbTextMuted = Color(sbLight: 0x66696EFF, dark: 0x9D9EA1FF)
    /// `text-subtle`: RESTRICTED: large text (>= 24px, >= 18.66px bold) or disabled/decorative text only
    static let sbTextSubtle = Color(sbLight: 0x828589FF, dark: 0x797A7DFF)
    /// `border`: decorative hairline: dividers, outlines that carry no meaning
    static let sbBorder = Color(sbLight: 0xD7D9DDFF, dark: 0x32353CFF)
    /// `border-strong`: interactive boundary: inputs, checkboxes, toggles (>= 3:1)
    static let sbBorderStrong = Color(sbLight: 0x84868AFF, dark: 0x707379FF)
    /// `accent`: brand fill: primary button, selected indicator, active switch
    static let sbAccent = Color(sbLight: 0x3057B1FF, dark: 0x89B1FAFF)
    /// `accent-hover`: hover state of accent
    static let sbAccentHover = Color(sbLight: 0x2348A1FF, dark: 0x95BEFFFF)
    /// `accent-pressed`: pressed state of accent
    static let sbAccentPressed = Color(sbLight: 0x163991FF, dark: 0xA7CBFFFF)
    /// `on-accent`: content on accent, accent-hover, accent-pressed
    static let sbOnAccent = Color(sbLight: 0xFFFFFFFF, dark: 0x101114FF)
    /// `accent-subtle`: tinted fill: selected row, tonal button, chip (never the only state cue)
    static let sbAccentSubtle = Color(sbLight: 0xDAEAFFFF, dark: 0x202E47FF)
    /// `text-on-accent-subtle`: content on accent-subtle
    static let sbTextOnAccentSubtle = Color(sbLight: 0x304B83FF, dark: 0xAECBFFFF)
    /// `focus`: focus ring (2px + 2px offset)
    static let sbFocus = Color(sbLight: 0x3057B1FF, dark: 0x89B1FAFF)
    /// `success`: success fill / icon colour (always with icon + word)
    static let sbSuccess = Color(sbLight: 0x07662EFF, dark: 0x439C5BFF)
    /// `on-success`: content on the success fill
    static let sbOnSuccess = Color(sbLight: 0xFFFFFFFF, dark: 0x101114FF)
    /// `success-subtle`: tinted success background: alerts, banners
    static let sbSuccessSubtle = Color(sbLight: 0xDEF6E2FF, dark: 0x19301EFF)
    /// `text-on-success-subtle`: text on success-subtle
    static let sbTextOnSuccessSubtle = Color(sbLight: 0x005821FF, dark: 0xAADDB3FF)
    /// `warning`: warning fill / icon colour (always with icon + word)
    static let sbWarning = Color(sbLight: 0xBE5A0AFF, dark: 0xF59258FF)
    /// `on-warning`: content on the warning fill
    static let sbOnWarning = Color(sbLight: 0xFFFFFFFF, dark: 0x101114FF)
    /// `warning-subtle`: tinted warning background: alerts, banners
    static let sbWarningSubtle = Color(sbLight: 0xFFE7D7FF, dark: 0x3C2315FF)
    /// `text-on-warning-subtle`: text on warning-subtle
    static let sbTextOnWarningSubtle = Color(sbLight: 0x782E00FF, dark: 0xFCBE9DFF)
    /// `danger`: danger fill / icon colour (always with icon + word)
    static let sbDanger = Color(sbLight: 0xAF2A27FF, dark: 0xE66761FF)
    /// `on-danger`: content on the danger fill
    static let sbOnDanger = Color(sbLight: 0xFFFFFFFF, dark: 0x101114FF)
    /// `danger-subtle`: tinted danger background: alerts, banners
    static let sbDangerSubtle = Color(sbLight: 0xFFE5E0FF, dark: 0x3E211FFF)
    /// `text-on-danger-subtle`: text on danger-subtle
    static let sbTextOnDangerSubtle = Color(sbLight: 0x7C2621FF, dark: 0xFFB7B0FF)
    /// `info`: info fill / icon colour (always with icon + word)
    static let sbInfo = Color(sbLight: 0x33485DFF, dark: 0xC8DDF5FF)
    /// `on-info`: content on the info fill
    static let sbOnInfo = Color(sbLight: 0xFFFFFFFF, dark: 0x101114FF)
    /// `info-subtle`: tinted info background: alerts, banners
    static let sbInfoSubtle = Color(sbLight: 0xE8EFF7FF, dark: 0x252B31FF)
    /// `text-on-info-subtle`: text on info-subtle
    static let sbTextOnInfoSubtle = Color(sbLight: 0x354A5FFF, dark: 0xC3CFDDFF)
    /// `selection`: text selection highlight (alpha)
    static let sbSelection = Color(sbLight: 0x3057B140, dark: 0x89B1FA59)
    /// `scrim`: modal backdrop (alpha)
    static let sbScrim = Color(sbLight: 0x1C1E2252, dark: 0x00000099)
    /// `link`: inline link
    static let sbLink = Color(sbLight: 0x254BA4FF, dark: 0x8FB7FFFF)
    /// `link-visited`: visited inline link
    static let sbLinkVisited = Color(sbLight: 0x4A6076FF, dark: 0xA8C1DAFF)
    /// `primary-action`: fill of the one primary action per view ('Hauptaktion', lime; at most one per view, always at the bottom, D39)
    static let sbPrimaryAction = Color(sbLight: 0xA9E773FF, dark: 0xA9E277FF)
    /// `primary-action-hover`: hover fill of the primary action
    static let sbPrimaryActionHover = Color(sbLight: 0x9DD966FF, dark: 0xB6ED88FF)
    /// `primary-action-pressed`: pressed fill of the primary action
    static let sbPrimaryActionPressed = Color(sbLight: 0x90CC59FF, dark: 0x99D267FF)
    /// `on-primary-action`: label and icon on the primary action (neutral ink, never the brand colour)
    static let sbOnPrimaryAction = Color(sbLight: 0x1C1E22FF, dark: 0x101114FF)
    /// `primary-action-outline`: 2 px boundary of the primary action: light mode ink outline (the lime fill has only 1.34:1 against bg), dark mode the fill itself (D40)
    static let sbPrimaryActionOutline = Color(sbLight: 0x1C1E22FF, dark: 0xA9E277FF)
    /// `hover-fill`: hover fill of rows, list items and quiet controls (one step away from the ground; in dark mode lighter than bg, never darker, so a hover never reads as a hole)
    static let sbHoverFill = Color(sbLight: 0xE9EBEEFF, dark: 0x212429FF)
    /// `pressed-fill`: pressed fill of quiet controls, slightly beyond hover in the same direction; both regular and muted text pass 4.5:1 in both modes. Dark danger text also passes (4.55:1).
    static let sbPressedFill = Color(sbLight: 0xE7E9ECFF, dark: 0x25282FFF)
}

/// A value that differs between light and dark mode.
public struct SebaroModeValue<T> {
    public let light: T
    public let dark: T
    public init(light: T, dark: T) { self.light = light; self.dark = dark }
    public func resolve(_ scheme: ColorScheme) -> T { scheme == .dark ? dark : light }
}

extension SebaroModeValue: Sendable where T: Sendable {}

// MARK: - Product accents

public struct SebaroAccentSet: Sendable {
    public let accent: Color
    public let accentHover: Color
    public let accentPressed: Color
    public let onAccent: Color
    public let accentSubtle: Color
    public let textOnAccentSubtle: Color
    /// The umbrella (core) accent family.
    public static let brand = SebaroAccentSet(accent: Color.sbAccent, accentHover: Color.sbAccentHover, accentPressed: Color.sbAccentPressed, onAccent: Color.sbOnAccent, accentSubtle: Color.sbAccentSubtle, textOnAccentSubtle: Color.sbTextOnAccentSubtle)
}

/// The products (palette `signTiles.productMap`, D54): each names its sign tile; no product accents.
public enum SebaroProduct: String, CaseIterable, Sendable {
    case studio = "studio"
    case tagwerk = "tagwerk"
    case compass = "compass"
    case habittracker = "habittracker"
    case intervaltimer = "intervaltimer"
    case tally = "tally"
    case waterreminder = "waterreminder"
    case retrobeam = "retrobeam"
    case novalis = "novalis"
    case coden = "coden"

    public var tile: SebaroSignTile {
        switch self {
        case .studio: return .studio
        case .tagwerk: return .everyday
        case .compass: return .tools
        case .habittracker: return .everyday
        case .intervaltimer: return .everyday
        case .tally: return .tools
        case .waterreminder: return .everyday
        case .retrobeam: return .collaboration
        case .novalis: return .collaboration
        case .coden: return .learning
        }
    }
}

/// App-sign tiles (palette `signTiles`, PALETTE-CONTRACT 2.2 §8.2, D50, D51): tile and sign colour per
/// purpose group, the same in light and dark mode. Only for app signs (D40), never for UI.
public enum SebaroSignTile: String, CaseIterable, Sendable {
    case studio = "studio"
    case collaboration = "collaboration"
    case everyday = "everyday"
    case learning = "learning"
    case tools = "tools"
    case media = "media"
    case money = "money"
    case system = "system"

    public var displayName: String {
        switch self {
        case .studio: return "Kobalt"
        case .collaboration: return "Petrol"
        case .everyday: return "Magenta"
        case .learning: return "Violett"
        case .tools: return "Orange"
        case .media: return "Ziegel"
        case .money: return "Grün"
        case .system: return "Azur"
        }
    }

    public var label: String {
        switch self {
        case .studio: return "Studio"
        case .collaboration: return "Zusammenarbeit & Schreiben"
        case .everyday: return "Alltag & Gesundheit"
        case .learning: return "Lernen & Entwickeln"
        case .tools: return "Werkzeuge"
        case .media: return "Medien & Kreativ"
        case .money: return "Geld & Haushalt"
        case .system: return "System & Sicherheit"
        }
    }

    public var tile: Color {
        switch self {
        case .studio: return Color(sbLight: 0x3057B1FF, dark: 0x3057B1FF)
        case .collaboration: return Color(sbLight: 0x0F8186FF, dark: 0x0F8186FF)
        case .everyday: return Color(sbLight: 0xA80C5DFF, dark: 0xA80C5DFF)
        case .learning: return Color(sbLight: 0x7154CEFF, dark: 0x7154CEFF)
        case .tools: return Color(sbLight: 0xD55C13FF, dark: 0xD55C13FF)
        case .media: return Color(sbLight: 0xB62A12FF, dark: 0xB62A12FF)
        case .money: return Color(sbLight: 0x1E7942FF, dark: 0x1E7942FF)
        case .system: return Color(sbLight: 0x1A89C5FF, dark: 0x1A89C5FF)
        }
    }

    public var glyph: Color {
        switch self {
        case .studio: return Color(sbLight: 0xFFFFFFFF, dark: 0xFFFFFFFF)
        case .collaboration: return Color(sbLight: 0xFFFFFFFF, dark: 0xFFFFFFFF)
        case .everyday: return Color(sbLight: 0xFFFFFFFF, dark: 0xFFFFFFFF)
        case .learning: return Color(sbLight: 0xFFFFFFFF, dark: 0xFFFFFFFF)
        case .tools: return Color(sbLight: 0xFFFFFFFF, dark: 0xFFFFFFFF)
        case .media: return Color(sbLight: 0xFFFFFFFF, dark: 0xFFFFFFFF)
        case .money: return Color(sbLight: 0xFFFFFFFF, dark: 0xFFFFFFFF)
        case .system: return Color(sbLight: 0xFFFFFFFF, dark: 0xFFFFFFFF)
        }
    }

    /// The products whose sign sits on this tile, in signTiles.productMap order (empty for a spare group).
    public var products: [String] { Self.productMap.filter { $0.1 == self }.map { $0.0 } }

    /// The tile of a product key, or nil for a product without a tile.
    public static func forProduct(_ key: String) -> SebaroSignTile? {
        productMap.first { $0.0 == key }?.1
    }

    private static let productMap: [(String, SebaroSignTile)] = [
        ("studio", .studio),
        ("tagwerk", .everyday),
        ("compass", .tools),
        ("habittracker", .everyday),
        ("intervaltimer", .everyday),
        ("tally", .tools),
        ("waterreminder", .everyday),
        ("retrobeam", .collaboration),
        ("novalis", .collaboration),
        ("coden", .learning),
    ]
}

private struct SebaroAccentKey: EnvironmentKey {
    static let defaultValue: SebaroAccentSet = SebaroAccentSet.brand
}

public extension EnvironmentValues {
    /// Effective accent family (always the core accent: no product accents, D54).
    var sebaroAccent: SebaroAccentSet {
        get { self[SebaroAccentKey.self] }
        set { self[SebaroAccentKey.self] = newValue }
    }
}

// MARK: - Data visualisation

public enum SebaroDataviz {
    public static let categorical: [Color] = [Color(sbLight: 0x1F1F1FFF, dark: 0xF8F8F8FF), Color(sbLight: 0xAB8704FF, dark: 0xFCC959FF), Color(sbLight: 0x089772FF, dark: 0x5ADDC7FF), Color(sbLight: 0xD06482FF, dark: 0xAF7280FF), Color(sbLight: 0x2698C8FF, dark: 0x2591C4FF), Color(sbLight: 0x0B3C2BFF, dark: 0x1C7B5AFF)]
    public static let sequential: [Color] = [Color(sbLight: 0x5C8AB3FF, dark: 0x3C729EFF), Color(sbLight: 0x45658AFF, dark: 0x7295BCFF), Color(sbLight: 0x294374FF, dark: 0xAFBED4FF), Color(sbLight: 0x1C2130FF, dark: 0xEAEFFEFF)]
    public static let diverging: [Color] = [Color(sbLight: 0x965038FF, dark: 0xCA7F67FF), Color(sbLight: 0xBB7454FF, dark: 0xA05C3DFF), Color(sbLight: 0xD7D9DDFF, dark: 0x32353CFF), Color(sbLight: 0x4390A2FF, dark: 0x0A7989FF), Color(sbLight: 0x256B7FFF, dark: 0x599AB1FF)]
}

// MARK: - Code colours

/// Code colours (palette `syntax`, D67): code that no role names stays in `Color.sbText`, comments in
/// `Color.sbTextMuted` (spec/01 §1.8).
public enum SebaroSyntax {
    /// Schlüsselwörter, Annotationen, Tags und At-Regeln
    public static let keyword = Color(sbLight: 0x54258CFF, dark: 0xBC98F9FF)
    /// Zeichenketten, reguläre Ausdrücke und Attributwerte
    public static let string = Color(sbLight: 0x1B490FFF, dark: 0x7BB76EFF)
    /// Zahlen, Wahrheitswerte, null, Konstanten und Escape-Sequenzen
    public static let constant = Color(sbLight: 0x951D52FF, dark: 0xFAA6B2FF)
}

// MARK: - Categories

/// One category tone (palette `categories`, D73): only as a dot or glyph next to the word, never a fill,
/// never text colour, never for states the app assigns. `number` is the order an app offers the tones in;
/// `name` is the accessible name in a colour choice.
public struct SebaroCategory: Sendable {
    public let number: Int
    public let name: String
    public let color: Color

    public static let all: [SebaroCategory] = [
        SebaroCategory(number: 1, name: "Tanne", color: Color(sbLight: 0x486654FF, dark: 0x8DD3B1FF)),
        SebaroCategory(number: 2, name: "Jade", color: Color(sbLight: 0x4B916BFF, dark: 0x71AF88FF)),
        SebaroCategory(number: 3, name: "Taube", color: Color(sbLight: 0x767EA0FF, dark: 0x8192CFFF)),
        SebaroCategory(number: 4, name: "Veilchen", color: Color(sbLight: 0x67548EFF, dark: 0xBD9FDCFF)),
        SebaroCategory(number: 5, name: "Messing", color: Color(sbLight: 0x88763FFF, dark: 0xD2BD77FF)),
        SebaroCategory(number: 6, name: "Malve", color: Color(sbLight: 0x975C78FF, dark: 0xC07D9FFF)),
    ]
}

// MARK: - Mark

/// Text highlight and search hit (palette `mark`, D73): `fill` behind the text, a 2 pt `edge` at its bottom;
/// the current hit takes a 3 pt edge in `Color.sbText`.
public enum SebaroMark {
    public static let fill = Color(sbLight: 0xFFF198FF, dark: 0x3E3600FF)
    public static let edge = Color(sbLight: 0x8D894EFF, dark: 0xE3B831FF)
}

// MARK: - Colour tone

/// Colour tone (palette `variants`, D90): the choice „Farbton“ in the settings next to Hell/Dunkel. A tone
/// replaces only the grey roles below; every other role is the same in each tone (`Color.sb*`).
public enum SebaroTone: String, CaseIterable, Sendable {
    case cool
    case warm

    public var bg: Color {
        switch self {
        case .cool: return Color.sbBg
        case .warm: return Color(sbLight: 0xFBF4EAFF, dark: 0x1B140FFF)
        }
    }
    public var surface: Color {
        switch self {
        case .cool: return Color.sbSurface
        case .warm: return Color(sbLight: 0xFFFBF5FF, dark: 0x241C16FF)
        }
    }
    public var surfaceRaised: Color {
        switch self {
        case .cool: return Color.sbSurfaceRaised
        case .warm: return Color(sbLight: 0xFFFFFBFF, dark: 0x29221DFF)
        }
    }
    public var surfaceSunken: Color {
        switch self {
        case .cool: return Color.sbSurfaceSunken
        case .warm: return Color(sbLight: 0xF3EADCFF, dark: 0x100B07FF)
        }
    }
    public var text: Color {
        switch self {
        case .cool: return Color.sbText
        case .warm: return Color(sbLight: 0x231C18FF, dark: 0xF3EBE8FF)
        }
    }
    public var textMuted: Color {
        switch self {
        case .cool: return Color.sbTextMuted
        case .warm: return Color(sbLight: 0x6F675FFF, dark: 0xA69C96FF)
        }
    }
    public var textSubtle: Color {
        switch self {
        case .cool: return Color.sbTextSubtle
        case .warm: return Color(sbLight: 0x8B837BFF, dark: 0x817873FF)
        }
    }
    public var border: Color {
        switch self {
        case .cool: return Color.sbBorder
        case .warm: return Color(sbLight: 0xE0D8CCFF, dark: 0x3B332DFF)
        }
    }
    public var borderStrong: Color {
        switch self {
        case .cool: return Color.sbBorderStrong
        case .warm: return Color(sbLight: 0x8B857CFF, dark: 0x7A716AFF)
        }
    }
    public var scrim: Color {
        switch self {
        case .cool: return Color.sbScrim
        case .warm: return Color(sbLight: 0x231C1852, dark: 0x00000099)
        }
    }
    public var hoverFill: Color {
        switch self {
        case .cool: return Color.sbHoverFill
        case .warm: return Color(sbLight: 0xF3EADCFF, dark: 0x2A221CFF)
        }
    }
    public var pressedFill: Color {
        switch self {
        case .cool: return Color.sbPressedFill
        case .warm: return Color(sbLight: 0xF1E8DAFF, dark: 0x2E2620FF)
        }
    }
    public var onPrimaryAction: Color {
        switch self {
        case .cool: return Color.sbOnPrimaryAction
        case .warm: return Color(sbLight: 0x231C18FF, dark: 0x101114FF)
        }
    }
    public var primaryActionOutline: Color {
        switch self {
        case .cool: return Color.sbPrimaryActionOutline
        case .warm: return Color(sbLight: 0x231C18FF, dark: 0xA9E277FF)
        }
    }
}

private struct SebaroToneKey: EnvironmentKey {
    static let defaultValue: SebaroTone = .cool
}

public extension EnvironmentValues {
    /// The colour tone the user chose; read the grey roles through it (`tone.bg`).
    var sebaroTone: SebaroTone {
        get { self[SebaroToneKey.self] }
        set { self[SebaroToneKey.self] = newValue }
    }
}

// MARK: - Typography

public enum SebaroFontFamily {
    /// sebaro Sans, system-ui, -apple-system, Segoe UI, Roboto, sans-serif
    public static let ui = "sebaro Sans"
    /// sebaro Sans, system-ui, -apple-system, Segoe UI, Roboto, sans-serif
    public static let display = "sebaro Sans"
    /// sebaro Mono, ui-monospace, SFMono-Regular, Menlo, monospace
    public static let mono = "sebaro Mono"
}

/// One appearance (light or dark) of a text style (TOKEN-CONTRACT §9).
public struct SebaroTextFace: Sendable {
    public let family: String
    public let size: CGFloat
    public let lineHeight: CGFloat
    /// Nearest of the nine Font.Weight steps to `weightValue`.
    public let weight: Font.Weight
    /// Exact token weight (1...1000), e.g. 570; SwiftUI can only apply `weight`.
    public let weightValue: Double
    public let tracking: CGFloat
}

/// A typography role with its light and dark appearance. `.sbTextStyle(_:)` follows the colour scheme;
/// `font` and the 1.0 accessors (`family`, `size`, …) return the light appearance.
public struct SebaroTextStyle: Sendable {
    public let light: SebaroTextFace
    public let dark: SebaroTextFace
    public let relativeTo: Font.TextStyle
    public let monospacedDigits: Bool

    /// The appearance for a colour scheme; read it with @Environment(\.colorScheme).
    public func resolve(_ scheme: ColorScheme) -> SebaroTextFace { scheme == .dark ? dark : light }

    /// Scales with Dynamic Type relative to `relativeTo`; falls back to the system font if the family
    /// is not registered (UIAppFonts / ATSApplicationFontsPath).
    public func font(for scheme: ColorScheme) -> Font {
        let face = resolve(scheme)
        let f = Font.custom(face.family, size: face.size, relativeTo: relativeTo).weight(face.weight)
        return monospacedDigits ? f.monospacedDigit() : f
    }

    /// Light appearance (a Font cannot follow the colour scheme); prefer .sbTextStyle(_:) or font(for:).
    public var font: Font { font(for: .light) }
    public var family: String { light.family }
    public var size: CGFloat { light.size }
    public var lineHeight: CGFloat { light.lineHeight }
    public var weight: Font.Weight { light.weight }
    public var tracking: CGFloat { light.tracking }
}

public extension SebaroTextStyle {
    static let display = SebaroTextStyle(
        light: SebaroTextFace(family: SebaroFontFamily.display, size: 32, lineHeight: 40, weight: .bold, weightValue: 670, tracking: 0),
        dark: SebaroTextFace(family: SebaroFontFamily.display, size: 32, lineHeight: 40, weight: .bold, weightValue: 700, tracking: 0.32),
        relativeTo: .largeTitle, monospacedDigits: false)
    static let headline = SebaroTextStyle(
        light: SebaroTextFace(family: SebaroFontFamily.display, size: 24, lineHeight: 32, weight: .bold, weightValue: 670, tracking: 0),
        dark: SebaroTextFace(family: SebaroFontFamily.display, size: 24, lineHeight: 32, weight: .bold, weightValue: 700, tracking: 0.24),
        relativeTo: .title, monospacedDigits: false)
    static let title = SebaroTextStyle(
        light: SebaroTextFace(family: SebaroFontFamily.ui, size: 20, lineHeight: 28, weight: .bold, weightValue: 670, tracking: 0),
        dark: SebaroTextFace(family: SebaroFontFamily.ui, size: 20, lineHeight: 28, weight: .bold, weightValue: 700, tracking: 0.2),
        relativeTo: .title3, monospacedDigits: false)
    static let body = SebaroTextStyle(
        light: SebaroTextFace(family: SebaroFontFamily.ui, size: 16, lineHeight: 24, weight: .regular, weightValue: 400, tracking: 0),
        dark: SebaroTextFace(family: SebaroFontFamily.ui, size: 16, lineHeight: 24, weight: .regular, weightValue: 430, tracking: 0.16),
        relativeTo: .body, monospacedDigits: false)
    static let bodyStrong = SebaroTextStyle(
        light: SebaroTextFace(family: SebaroFontFamily.ui, size: 16, lineHeight: 24, weight: .semibold, weightValue: 570, tracking: 0),
        dark: SebaroTextFace(family: SebaroFontFamily.ui, size: 16, lineHeight: 24, weight: .semibold, weightValue: 600, tracking: 0.16),
        relativeTo: .body, monospacedDigits: false)
    static let label = SebaroTextStyle(
        light: SebaroTextFace(family: SebaroFontFamily.ui, size: 14, lineHeight: 20, weight: .semibold, weightValue: 570, tracking: 0),
        dark: SebaroTextFace(family: SebaroFontFamily.ui, size: 14, lineHeight: 20, weight: .semibold, weightValue: 600, tracking: 0.14),
        relativeTo: .subheadline, monospacedDigits: false)
    static let caption = SebaroTextStyle(
        light: SebaroTextFace(family: SebaroFontFamily.ui, size: 14, lineHeight: 20, weight: .regular, weightValue: 400, tracking: 0),
        dark: SebaroTextFace(family: SebaroFontFamily.ui, size: 14, lineHeight: 20, weight: .regular, weightValue: 430, tracking: 0.14),
        relativeTo: .caption, monospacedDigits: false)
    static let code = SebaroTextStyle(
        light: SebaroTextFace(family: SebaroFontFamily.mono, size: 14, lineHeight: 20, weight: .medium, weightValue: 500, tracking: 0),
        dark: SebaroTextFace(family: SebaroFontFamily.mono, size: 14, lineHeight: 20, weight: .medium, weightValue: 500, tracking: 0.14),
        relativeTo: .callout, monospacedDigits: false)
    static let numeric = SebaroTextStyle(
        light: SebaroTextFace(family: SebaroFontFamily.ui, size: 16, lineHeight: 24, weight: .regular, weightValue: 400, tracking: 0),
        dark: SebaroTextFace(family: SebaroFontFamily.ui, size: 16, lineHeight: 24, weight: .regular, weightValue: 430, tracking: 0.16),
        relativeTo: .body, monospacedDigits: true)
    static let labelSmall = SebaroTextStyle(
        light: SebaroTextFace(family: SebaroFontFamily.ui, size: 12, lineHeight: 16, weight: .regular, weightValue: 400, tracking: 0),
        dark: SebaroTextFace(family: SebaroFontFamily.ui, size: 12, lineHeight: 16, weight: .regular, weightValue: 430, tracking: 0.12),
        relativeTo: .caption, monospacedDigits: false)
}

/// Light appearance of each role (static Fonts cannot follow the colour scheme).
public extension Font {
    static let sbDisplay = SebaroTextStyle.display.font
    static let sbHeadline = SebaroTextStyle.headline.font
    static let sbTitle = SebaroTextStyle.title.font
    static let sbBody = SebaroTextStyle.body.font
    static let sbBodyStrong = SebaroTextStyle.bodyStrong.font
    static let sbLabel = SebaroTextStyle.label.font
    static let sbCaption = SebaroTextStyle.caption.font
    static let sbCode = SebaroTextStyle.code.font
    static let sbNumeric = SebaroTextStyle.numeric.font
    static let sbLabelSmall = SebaroTextStyle.labelSmall.font
}

@available(iOS 16.0, macOS 13.0, *)
public extension View {
    /// Font + tracking + approximate line height (SwiftUI has no exact line-height) of the light or
    /// dark appearance, following the colour scheme of the environment.
    func sbTextStyle(_ style: SebaroTextStyle) -> some View {
        modifier(SebaroTextStyleModifier(style: style))
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct SebaroTextStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let style: SebaroTextStyle

    func body(content: Content) -> some View {
        let face = style.resolve(colorScheme)
        return content.font(style.font(for: colorScheme)).tracking(face.tracking)
            .lineSpacing(max(0, face.lineHeight - face.size))
    }
}

// MARK: - Scalars

public struct SebaroEasing: Sendable {
    public let x1: Double, y1: Double, x2: Double, y2: Double
    public init(x1: Double, y1: Double, x2: Double, y2: Double) { self.x1 = x1; self.y1 = y1; self.x2 = x2; self.y2 = y2 }
    /// Use `reduceMotion` from @Environment(\.accessibilityReduceMotion): it removes the movement. Pass every
    /// duration marked "reduced motion: collapse" through here; "keep" durations are timers, not movement.
    public func animation(duration: Double, reduceMotion: Bool = false) -> Animation {
        reduceMotion ? .linear(duration: 0) : .timingCurve(x1, y1, x2, y2, duration: duration)
    }
}

public struct SebaroShadowLayer: Sendable {
    public let color: Color
    public let x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat
    public let inset: Bool
}

public struct SebaroBorder: Sendable {
    public let color: Color
    public let width: CGFloat
    public let style: String
}

public struct SebaroElevationLevel: Sendable {
    public let surface: Color
    public let borderColor: Color
    public let borderWidth: SebaroModeValue<CGFloat>
    /// CSS-equivalent layers; SwiftUI .shadow takes one layer (use the largest).
    public let shadow: SebaroModeValue<[SebaroShadowLayer]>
    public let elevation: SebaroModeValue<CGFloat>
}

public enum SebaroElevation {
    public static let level0 = SebaroElevationLevel(
        surface: Color.sbBg,
        borderColor: Color.sbBorder,
        borderWidth: SebaroModeValue(light: 0, dark: 0),
        shadow: SebaroModeValue(light: [], dark: []),
        elevation: SebaroModeValue(light: 0, dark: 0)
    )
    public static let level1 = SebaroElevationLevel(
        surface: Color.sbBg,
        borderColor: Color(sbLight: 0x1C1E22FF, dark: 0x707379FF),
        borderWidth: SebaroModeValue(light: 2, dark: 2),
        shadow: SebaroModeValue(light: [], dark: []),
        elevation: SebaroModeValue(light: 0, dark: 0)
    )
    public static let level2 = SebaroElevationLevel(
        surface: Color.sbBg,
        borderColor: Color(sbLight: 0x1C1E22FF, dark: 0x707379FF),
        borderWidth: SebaroModeValue(light: 2, dark: 2),
        shadow: SebaroModeValue(light: [], dark: []),
        elevation: SebaroModeValue(light: 0, dark: 0)
    )
    public static let level3 = SebaroElevationLevel(
        surface: Color.sbBg,
        borderColor: Color(sbLight: 0x1C1E22FF, dark: 0x707379FF),
        borderWidth: SebaroModeValue(light: 2, dark: 2),
        shadow: SebaroModeValue(light: [], dark: []),
        elevation: SebaroModeValue(light: 0, dark: 0)
    )
    public static let overlay = SebaroElevationLevel(
        surface: Color.sbBg,
        borderColor: Color(sbLight: 0x1C1E22FF, dark: 0x707379FF),
        borderWidth: SebaroModeValue(light: 2, dark: 2),
        shadow: SebaroModeValue(light: [], dark: []),
        elevation: SebaroModeValue(light: 0, dark: 0)
    )
}

public enum SebaroSpace {
    public static let s0: CGFloat = 0
    public static let s0_5: CGFloat = 2
    public static let s1: CGFloat = 4
    public static let s2: CGFloat = 8
    public static let s3: CGFloat = 12
    public static let s4: CGFloat = 16
    public static let s5: CGFloat = 20
    public static let s6: CGFloat = 24
    public static let s8: CGFloat = 32
    public static let s10: CGFloat = 40
    public static let s12: CGFloat = 48
    public static let s16: CGFloat = 64
}

public enum SebaroSpacing {
    public static let inline: CGFloat = 8
    public static let stack: CGFloat = 12
    public static let group: CGFloat = 24
    public static let insetControl: CGFloat = 16
    public static let insetContainer: CGFloat = 16
    public static let gutter: CGFloat = 16
    public static let gutterWide: CGFloat = 48
    public static let section: CGFloat = 48
    public static let sectionWide: CGFloat = 64
}

public enum SebaroRadius {
    /// tags, badges, checkboxes, inline code
    public static let small: CGFloat = 4
    /// buttons incl. the primary action, fields, segmented controls
    public static let control: CGFloat = 8
    /// cards, panels, menus, popovers
    public static let container: CGFloat = 12
    /// dialogs, bottom sheets
    public static let sheet: CGFloat = 16
    /// switch track and thumb, radio dot
    public static let pill: CGFloat = 9999
}

public enum SebaroBorderWidth {
    /// dividers and card outlines with color.border
    public static let hairline: CGFloat = 1
    /// field baselines and control outlines with color.border-strong
    public static let control: CGFloat = 1
    /// the current-place edge (selected tab, nav item, claim row) in color.accent
    public static let strong: CGFloat = 3
}

public enum SebaroFocus {
    public static let width: CGFloat = 2
    public static let offset: CGFloat = 2
}

public enum SebaroMotion {
    public static let durationShort: Double = 0.12 // seconds; reduced motion: collapse
    public static let durationMedium: Double = 0.16 // seconds; reduced motion: collapse
    public static let durationLong: Double = 0.2 // seconds; reduced motion: collapse
    public static let easingStandard: SebaroEasing = SebaroEasing(x1: 0.2, y1: 0, x2: 0, y2: 1)
    public static let easingEmphasized: SebaroEasing = SebaroEasing(x1: 0.05, y1: 0.7, x2: 0.1, y2: 1)
    public static let easingExit: SebaroEasing = SebaroEasing(x1: 0.3, y1: 0, x2: 1, y2: 1)
}

public enum SebaroSize {
    public static let targetTouch: CGFloat = 48
    public static let targetPointer: CGFloat = 24
    public static let iconSm: CGFloat = 16
    public static let iconMd: CGFloat = 20
    public static let iconLg: CGFloat = 24
    /// compact pointer controls (desktop tables, toolbars)
    public static let controlSm: CGFloat = 32
    /// buttons, fields, list rows on touch
    public static let controlMd: CGFloat = 48
    /// the primary action at the bottom of a view (D39), claim rows
    public static let controlLg: CGFloat = 56
    /// German running text: 60-70 characters per line
    public static let measureProse: Double = 70
    public static let containerMax: CGFloat = 1440
}

public enum SebaroLayer {
    public static let sticky: Double = 20
    public static let dropdown: Double = 30
    public static let overlay: Double = 40
    public static let modal: Double = 50
    public static let popover: Double = 60
    public static let toast: Double = 70
    public static let tooltip: Double = 80
}

public enum SebaroBreakpoint {
    public static let sm: CGFloat = 640
    public static let lg: CGFloat = 1024
}

public enum SebaroOpacity {
}

public enum SebaroComponent {
}

public enum SebaroX {
    /// Boundary of the primary action in color.primary-action-outline: 2 px ink by day (the lime fill has 1.34:1 against bg), the fill colour itself at night (D40).
    public static let primaryActionOutlineWidth: CGFloat = 2
    /// D48 (1): the bar inside the busy primary action, along its bottom edge, in color.on-primary-action (lime on bg is 1.34:1, so the bar is ink on lime).
    public static let primaryActionProgressHeight: CGFloat = 6
    /// One sweep of the indeterminate bar (unknown duration). Kept under reduced motion so the period never strobes; the CSS and Compose stop the sweep and show a still bar instead (D48).
    public static let primaryActionProgressPeriod: Double = 1.1 // seconds; reduced motion: keep
    /// How long the label „✓ <done>“ stays before the action returns to its normal label (D48); a dwell time, not movement.
    public static let primaryActionDoneDwell: Double = 1.5 // seconds; reduced motion: keep
    /// Corner radius of the app-sign tile as a share of its edge (8 px at 48 px). Rounded like the owner's bild-1 (sketch C); brand.config.json signs.tile.radius.
    public static let signTileRadiusRatio: Double = 0.1667
    /// Edge of the app-sign tile in lists, cards and headers (web and in-app).
    public static let signTileSize: CGFloat = 48
    /// Edge of the symbol box as a share of the tile edge on tiles of 48 px and more, where the three-letter code sits under the symbol (D57): 36 of 72, the same layout as the launcher (brand.config.json signs.code symbolDp 36 of the visible 72 dp; build_brand_src.py refuses a mismatch).
    public static let signTileGlyphRatio: Double = 0.5
    /// The share for tiles below 48 px, where the symbol stands alone without the code (D57; stroke master of the size, glyphSmall where the product has one): header lockup and 32 px tiles.
    public static let signTileGlyphRatioSmall: Double = 0.6
    /// Lines and series strokes in charts.
    public static let chartLineWidth: CGFloat = 2
    /// Grid lines (decorative, no meaning).
    public static let chartGrid: Color = Color.sbBorder
    /// Axis lines and tick marks.
    public static let chartAxis: Color = Color.sbBorderStrong
    /// Bars of a labelled bar chart (the label carries the value; colour carries nothing).
    public static let chartBar: Color = Color.sbBorderStrong
    /// The one current or selected bar (today, the chosen period): the accent job "current place", always with a bold label as the non-colour cue.
    public static let chartBarCurrent: Color = Color.sbAccent
    /// D46 (2): layers are separated by a 2 px line in ink, not by a ground tone or a shadow: cards and groups, overlays, the bottom block, the site header and footer, sticky bars, the side navigation edge. Rows inside a group keep the 1 px hairline in color.border.
    public static let layerLineWidth: CGFloat = 2
    /// Ink of the layer line: text by day (15.31:1 on bg), border-strong by night (3.81:1 on bg; text would glare as a frame). Proposal from the round-3 sketch (D46).
    public static let layerLineColor: Color = Color(sbLight: 0x1C1E22FF, dark: 0x707379FF)
    /// D46 (1): the 45° cut at the top end corner of a destructive action (outlined danger action, the confirm button of its dialog): legs of 12 px. Only destructive actions and a final step that deletes nothing but cannot be taken back (D102 (43)) carry it; everything else stays round.
    public static let dangerBevelSize: CGFloat = 12
    /// D46 (4): new content enters from below over this distance in motion.duration.long with motion.easing.emphasized (transform and opacity only); with reduced motion (system or the app setting „Bewegung immer reduzieren“) it only fades.
    public static let enterDistance: CGFloat = 8
    /// D46 (4), D102 (52), spec/03 §13.1: the fade that replaces the entry under reduced motion, under the system setting and under the app setting „Bewegung immer reduzieren“ alike, on every platform. Kept, because tokens.css collapses motion.duration.long under both settings (sections 7 and 7a, contract 1.10).
    public static let enterFadeDuration: Double = 0.2 // seconds; reduced motion: keep
    /// D49/D52: edge of the app-sign tile in the centre of the start screen; the tile then moves to its place in the top bar or title bar (motion.duration.long, motion.easing.emphasized).
    public static let startTileSize: CGFloat = 96
    /// D52: links are text-coloured words with a 2 px underline in color.link (visited: color.link-visited); hover/pressed turn the word color.link. External links add the external-link icon.
    public static let linkUnderlineWidth: CGFloat = 2
    /// D73, D91 C2a: the line at the bottom edge of a mark (palette mark.edge, >= 3:1 on every ground); it carries the shape, the fill only colours. The current search hit takes border-width.strong (3 px) in color.text instead.
    public static let markEdgeWidth: CGFloat = 2
    /// D81, D91 F3a, D100 (2): start width of a window's sidebar (.sb-side-nav, the divider's aria-valuenow); the content keeps 480 px beside it, so the sidebar docks from a window of 722 px (240 + 2 + 480; spec/02 §4.17, §4.23).
    public static let paneSidebar: CGFloat = 240
    /// D91 F3a: the smallest width a divider gives the sidebar (aria-valuemin); dragged 48 px below it the sidebar collapses.
    public static let paneSidebarMin: CGFloat = 200
    /// D91 F3a: the largest width a divider gives the sidebar (aria-valuemax).
    public static let paneSidebarMax: CGFloat = 360
    /// spec/02 §4.17, shared/ADOPTION.md §2.3: below this width of .sb-window (240 + 2 + 480) the sidebar leaves the grid and is an overlay; the CSS container queries use the same number (they cannot read a custom property). A counterpart without sb-window.js reads the window's width against this token, never the computed style of a hidden pane.
    public static let paneSidebarOverlayBelow: CGFloat = 722
    /// D81, D91 F3a: start width of a window's inspector (the divider's aria-valuenow); it docks from a window of 1004 px (722 + 2 + 280; spec/02 §4.17, §4.23) and is an overlay of this width below that.
    public static let paneInspector: CGFloat = 280
    /// D91 F3a: the smallest width a divider gives the inspector (aria-valuemin).
    public static let paneInspectorMin: CGFloat = 240
    /// D91 F3a: the largest width a divider gives the inspector (aria-valuemax).
    public static let paneInspectorMax: CGFloat = 400
    /// spec/02 §4.17, shared/ADOPTION.md §2.3: below this width of .sb-window (722 + 2 + 280) the inspector leaves the grid and is an overlay; the CSS container queries use the same number. Read like pane.sidebar-overlay-below.
    public static let paneInspectorOverlayBelow: CGFloat = 1004
    /// D102 (40): the least width of a board column in the side-by-side layout, the columns sharing the rest of the board (spec/02 §3.16): a product may set --sb-x-sebaro-board-column wider for its board, never below 240 px; at large text a column still grows to 15em (D102 lane narrow). A fixed pixel value like the panes, and a least width rather than a fixed one (provisional, agent).
    public static let boardColumn: CGFloat = 240
    /// D91 F1a (D102 lane desktop, 2026-10-25): where the macOS title bar starts its content beside the system's three window buttons (spec/02 §4.17, spec/09 §13.1): the buttons at x 16 with trafficLightPosition, their width and a gap. A fixed pixel value, not the space tokens in rem: the system buttons do not grow with the page's text size, so at 200 % the room stays 80 px (it was 160 px).
    public static let trafficLightRoom: CGFloat = 80
    /// D102 (27): the text size of an editor's writing area (Markdown source and code), the default of the product variable: the product sets --sb-x-sebaro-editor-size on its editor from its own setting (at least 16 px, so the 0.875em parts stay at 14 px; provisional, agent). Headings, inline code, line numbers and task boxes are em of it (spec/01 §1.8.2). In rem, so the page's text size scales it.
    public static let editorSize: CGFloat = 16
    /// D102 (27): the line height of an editor's writing area, relative to each line's own size; the owner chose 1.6 for the writing area instead of body's 1.5 (D102 (27), spec/01 §1.8.2). Only the writing area: rendered text keeps its roles' line heights.
    public static let editorLineHeight: Double = 1.6
}
