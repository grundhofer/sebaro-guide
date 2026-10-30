import SebaroDesign
import SwiftUI

/// Top-level „Einstellungen“: „Hell oder Dunkel“ (Wie das System, Hell, Dunkel), „Farbton“ (Kühl, Warm), „Bewegung
/// immer reduzieren“ and „Sprache“ (Wie das System, Deutsch, English); every choice applies at once, so there is no
/// primary action (MOB-04, AKT-09, FAR-15, BEW-04, TEC-10, AKT-01). The first three are sebaro's parts with their own
/// words and storage keys; the language is the app's.
struct SettingsScreen: View {
    let tabs: SbTabBar
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue
    @Environment(\.words) private var words

    var body: some View {
        SbScreen(tabs: tabs) {
            ScrollView {
                VStack(alignment: .leading, spacing: SebaroSpacing.group) {
                    SbThemeChoice()
                    SbToneChoice()
                    SbMotionSetting()
                    SbCheckChoice(words("settings.language"),
                                  options: [(AppLanguage.system, words("language.system")),
                                            (AppLanguage.de, words("language.de")),
                                            (AppLanguage.en, words("language.en"))],
                                  selection: Binding(get: { AppLanguage(rawValue: languageRaw) ?? .system },
                                                     set: { languageRaw = $0.rawValue }))
                }
                .padding(.vertical, SebaroSpace.s4)
            }
        }
        // without a product id the export has no sign tile, so the top-level title stands inline (see README,
        // „Lücken der Vorlage“); a product uses .sbTopLevelNavigation(title:product:) with its tile
        .sbNavigationTitle(words("settings.title"))
    }
}
