import SebaroDesign
import SwiftUI

@main
struct MusterappApp: App {
    /// Under the test runner the app shows nothing of its own and opens no file: the tests host their screens
    /// themselves, each with its own store.
    private let underTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    var body: some Scene {
        WindowGroup {
            if underTest {
                Color.clear
            } else {
                SebaroAppRoot {
                    StoreLoader()
                }
            }
        }
    }
}

/// Opens the entries file once; the app is ready when it is read. A file it cannot open is left as it is and the app
/// says so calmly (`StartErrorScreen`), never replacing the entries by samples.
private struct StoreLoader: View {
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue
    @State private var store: EntryStore?
    @State private var failure: StoreError?

    var body: some View {
        Group {
            if let store {
                AppView(store: store)
            } else if let failure {
                let words = Words(language: (AppLanguage(rawValue: languageRaw) ?? .system).resolved())
                StartErrorScreen(error: failure).language(words)
            }
        }
        .task {
            if store == nil && failure == nil {
                do {
                    store = try EntryStore.open(directory: EntryStore.defaultDirectory())
                } catch let error as StoreError {
                    failure = error
                } catch {
                    failure = .unreadable
                }
            }
        }
    }
}
