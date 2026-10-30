import Foundation
import SebaroDesign
import SwiftUI

/// The language choice of „Einstellungen“ (TEC-10): „Wie das System“, Deutsch or English.
enum AppLanguage: String, CaseIterable, Sendable {
    case system, de, en

    static let storageKey = "app-language"

    /// The languages the app has (CFBundleLocalizations in Info.plist).
    static let available = ["de", "en"]

    /// The language the app shows: the chosen one; for „Wie das System“ the first of the device's languages that the
    /// app has, else German, the app's fallback language (CFBundleDevelopmentRegion = de, D111).
    func resolved(preferred: [String] = Locale.preferredLanguages) -> String {
        switch self {
        case .de: return "de"
        case .en: return "en"
        case .system:
            for identifier in preferred {
                if let code = Locale(identifier: identifier).language.languageCode?.identifier,
                   Self.available.contains(code) {
                    return code
                }
            }
            return "de"
        }
    }
}

/// Every word of the app in one language, from Localizable.xcstrings (de, en). The app looks words up in the bundle
/// of the chosen language, so the in-app choice applies at once, without a restart; the sebaro parts take their own
/// words from `messages` (SbMessages) and their formats from `locale`.
struct Words: @unchecked Sendable {
    let language: String
    private let bundle: Bundle

    init(language: String, bundle: Bundle = .main) {
        self.language = language
        self.bundle = bundle.path(forResource: language, ofType: "lproj").flatMap(Bundle.init(path:)) ?? bundle
    }

    /// The locale for numbers and dates: German as in Germany, English with the 24-hour clock and the euro.
    var locale: Locale { Locale(identifier: language == "en" ? "en_GB" : "de_DE") }

    /// The words the sebaro parts write themselves (spec/12 §13).
    var messages: SbMessages { SbMessages.forLanguage(language) }

    /// The word for `key`; with arguments it is a format (`%@`, `%lld`; plurals come from the catalog's variations).
    /// A key the catalog lacks stops a debug build.
    func callAsFunction(_ key: String, _ arguments: CVarArg...) -> String {
        let missing = "\u{0}"
        let format = bundle.localizedString(forKey: key, value: missing, table: nil)
        assert(format != missing, "Localizable.xcstrings has no „\(key)“")
        guard format != missing else { return key }
        return arguments.isEmpty ? format : String(format: format, locale: locale, arguments: arguments)
    }

    /// „10.000“ / „10,000“ (TXT-04), as the sebaro parts count.
    func count(_ value: Int) -> String { SbMessages.formatCount(value, locale: locale) }
}

private struct WordsKey: EnvironmentKey {
    static let defaultValue = Words(language: "de")
}

extension EnvironmentValues {
    var words: Words {
        get { self[WordsKey.self] }
        set { self[WordsKey.self] = newValue }
    }
}

extension View {
    /// The app's words, the sebaro parts' words and the locale of one language, in one step.
    func language(_ words: Words) -> some View {
        environment(\.words, words)
            .environment(\.sbMessages, words.messages)
            .environment(\.locale, words.locale)
    }
}
