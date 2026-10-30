import CoreText
import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The bundled fonts (D18, D38, D43, D68, D70): the seven static, hinted desktop instances of fonts/desktop/
/// (sebaro Sans 400 430 570 600 670 700, sebaro Mono 500), registered with Core Text for this process.
///
/// Every static carries the typographic family name „sebaro Sans“ or „sebaro Mono“ (name ID 16), but only its own
/// weight. `Font.custom(family:).weight(_:)` of the generated tokens picks one of nine generic buckets (CHECKS DK1),
/// so 430, 570 and 670 would never be drawn. The registry therefore reads each file's OS/2 weight class and
/// addresses the exact cut by its PostScript name (`face(_:)`, `.sbFont(_:)`).
public enum SebaroFonts {
    /// One registered static instance.
    public struct Face: Hashable, Sendable {
        /// Typographic family, e.g. „sebaro Sans“.
        public let family: String
        /// OS/2 usWeightClass of the file, e.g. 570.
        public let weight: Int
        /// The PostScript name Core Text knows the file by, e.g. „sebaroSans-Medium570“.
        public let postScriptName: String
        public let fileName: String
    }

    /// Registers every TTF of the package's Resources/Fonts once (process scope) and returns the faces. Safe to call
    /// repeatedly; `SebaroAppRoot` calls it before the first view. A font that fails to register is reported in
    /// `problems`, never silently replaced by the system font.
    @discardableResult
    public static func register() -> [Face] {
        lock.lock(); defer { lock.unlock() }
        if let done = registered { return done }
        var faces: [Face] = []
        for url in fontURLs() {
            guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
                  let descriptor = descriptors.first else {
                registrationProblems.append("\(url.lastPathComponent): not a font file Core Text can read")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                let cfError = error?.takeRetainedValue()
                // 105 = kCTFontManagerErrorAlreadyRegistered: another part of the app registered the same file.
                if let cfError, CFErrorGetCode(cfError) != 105 {
                    registrationProblems.append("\(url.lastPathComponent): \(cfError)")
                    continue
                }
            }
            let font = CTFontCreateWithFontDescriptor(descriptor, 12, nil)
            let ps = CTFontCopyPostScriptName(font) as String
            let family = (CTFontCopyName(font, kCTFontFamilyNameKey) as String?) ?? ps
            faces.append(Face(family: family, weight: weightClass(font) ?? 400, postScriptName: ps,
                              fileName: url.lastPathComponent))
        }
        registered = faces
        return faces
    }

    /// Problems of the last registration (empty when every file registered).
    public static var problems: [String] {
        lock.lock(); defer { lock.unlock() }
        return registrationProblems
    }

    /// The registered face of a family whose weight is nearest to `weight` (exact for every weight the tokens use).
    public static func face(family: String, weight: Double) -> Face? {
        let faces = register().filter { $0.family == family }
        return faces.min { abs(Double($0.weight) - weight) < abs(Double($1.weight) - weight) }
    }

    /// The exact cut of a text face (family + numeric weight of the token), scaled with Dynamic Type relative to
    /// `relativeTo` without an upper limit (D91 I7a). Falls back to the generated generic-weight font only when the
    /// family is not bundled.
    public static func font(_ face: SebaroTextFace, relativeTo: Font.TextStyle, monospacedDigits: Bool) -> Font {
        let f: Font
        if let exact = Self.face(family: face.family, weight: face.weightValue) {
            f = Font.custom(exact.postScriptName, size: face.size, relativeTo: relativeTo)
        } else {
            f = Font.custom(face.family, size: face.size, relativeTo: relativeTo).weight(face.weight)
        }
        return monospacedDigits ? f.monospacedDigit() : f
    }

    #if canImport(UIKit)
    /// The same exact cut as a UIFont for UIKit appearances (navigation bar titles), scaled by UIFontMetrics.
    public static func uiFont(_ face: SebaroTextFace, textStyle: UIFont.TextStyle) -> UIFont {
        let base = Self.face(family: face.family, weight: face.weightValue)
            .flatMap { UIFont(name: $0.postScriptName, size: face.size) }
            ?? UIFont.systemFont(ofSize: face.size, weight: .regular)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
    }
    #endif

    // MARK: private

    private static let lock = NSLock()
    nonisolated(unsafe) private static var registered: [Face]?
    nonisolated(unsafe) private static var registrationProblems: [String] = []

    private static func fontURLs() -> [URL] {
        guard let dir = Bundle.module.url(forResource: "Fonts", withExtension: nil),
              let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        else {
            registrationProblems.append("Resources/Fonts is missing from the SebaroDesign bundle")
            return []
        }
        return files.filter { $0.pathExtension.lowercased() == "ttf" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// usWeightClass from the OS/2 table (bytes 4–5, big endian).
    private static func weightClass(_ font: CTFont) -> Int? {
        guard let table = CTFontCopyTable(font, CTFontTableTag(kCTFontTableOS2), []) as Data?, table.count >= 6
        else { return nil }
        return Int(table[table.startIndex + 4]) << 8 | Int(table[table.startIndex + 5])
    }
}

public extension SebaroTextStyle {
    /// The exact cut of this role in a colour scheme (see `SebaroFonts`).
    func exactFont(for scheme: ColorScheme) -> Font {
        SebaroFonts.font(resolve(scheme), relativeTo: relativeTo, monospacedDigits: monospacedDigits)
    }
}

public extension View {
    /// The type role with its exact weight (400/430, 570/600, 670/700 by colour scheme, D44), its tracking and its
    /// line height, growing with Dynamic Type without an upper limit (D91 I7a). Prefer it over the generated
    /// `.sbTextStyle(_:)`, which can only apply the nine generic weights.
    func sbFont(_ style: SebaroTextStyle) -> some View {
        modifier(SbFontModifier(style: style))
    }
}

struct SbFontModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric private var scale: CGFloat = 1
    let style: SebaroTextStyle

    func body(content: Content) -> some View {
        let face = style.resolve(colorScheme)
        return content
            .font(style.exactFont(for: colorScheme))
            .tracking(face.tracking * scale)
            .lineSpacing(max(0, face.lineHeight - face.size) * scale)
    }
}
