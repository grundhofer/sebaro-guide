import SebaroDesign
import SwiftUI

/// The three top-level places of the bottom bar (NAV-02, NAV-03).
enum Place: Int, CaseIterable, Sendable {
    case entries, data, settings
}

/// What the form sheet edits.
enum FormRequest: Identifiable, Hashable, Sendable {
    case new
    case edit(Int)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let id): "edit-\(id)"
        }
    }
}

/// The app below `SebaroAppRoot`: the language, one navigation stack with the three top-level screens and the detail,
/// and the form as a sheet (MOB-07). The bottom bar is sebaro's own `SbTabBar` on the top-level screens only; a
/// sub-screen has the system back button (NAV-05).
struct AppView: View {
    let store: EntryStore
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue
    @State private var place: Place
    @State private var path: [Int]
    @State private var query: String
    @State private var form: FormRequest?
    @State private var toasts: SbToastState

    /// The other parameters start the app in a given state (tests and screenshots).
    init(store: EntryStore, place: Place = .entries, path: [Int] = [], query: String = "", form: FormRequest? = nil,
         toasts: SbToastState = SbToastState()) {
        self.store = store
        _place = State(initialValue: place)
        _path = State(initialValue: path)
        _query = State(initialValue: query)
        _form = State(initialValue: form)
        _toasts = State(initialValue: toasts)
    }

    var body: some View {
        let words = Words(language: (AppLanguage(rawValue: languageRaw) ?? .system).resolved())
        NavigationStack(path: $path) {
            top(words)
                .navigationDestination(for: Int.self) { id in
                    if let entry = store.entry(id) {
                        DetailScreen(entry: entry,
                                     onEdit: { form = .edit(id) },
                                     onFinish: { store.finish(id) },
                                     onDelete: {
                                         path.removeAll()
                                         store.delete(id)
                                     })
                    }
                }
        }
        .sheet(item: $form) { request in
            FormScreen(request: request, store: store, words: words, onClose: { form = nil })
                .language(words)
        }
        .language(words)
    }

    @ViewBuilder
    private func top(_ words: Words) -> some View {
        let tabs = SbTabBar(items: [SbTabItem(words("nav.entries"), icon: "file-text"),
                                    SbTabItem(words("nav.data"), icon: "chart-bar"),
                                    SbTabItem(words("nav.settings"), icon: "settings")],
                            selection: Binding(get: { place.rawValue }, set: { place = Place(rawValue: $0) ?? .entries }),
                            onReselect: { _ in path.removeAll() })
        switch place {
        case .entries:
            ListScreen(store: store, query: $query, toasts: toasts, tabs: tabs, onCreate: { form = .new })
        case .data:
            DataScreen(tabs: tabs)
        case .settings:
            SettingsScreen(tabs: tabs)
        }
    }
}
