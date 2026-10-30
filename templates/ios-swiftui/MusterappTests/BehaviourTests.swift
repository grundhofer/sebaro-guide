import SebaroDesign
import SwiftUI
import XCTest
@testable import Musterapp

/// Persistence, the language switch, the unsaved guard and the steps that ask first.
@MainActor
final class BehaviourTests: XCTestCase {
    private let de = Words(language: "de")
    private let en = Words(language: "en")

    private func temporaryFolder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("musterapp-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    // MARK: persistence

    func testEntriesSurviveASecondStoreOnTheSameFile() throws {
        let folder = try temporaryFolder()
        let first = try EntryStore.open(directory: folder)
        let file = folder.appendingPathComponent("entries.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path), "the samples are written at the first start")
        XCTAssertEqual(first.entries.count, 5)

        let id = first.add(EntryInput(title: "Keller aufräumen", note: "Kisten beschriften", priority: .high, effort: 3,
                                      remind: SbTimeOfDay(19, 30)), today: Day(2026, 10, 30))
        first.update(2, EntryInput(title: "Balkon und Fensterbank bepflanzen", note: first.entry(2)!.note(de),
                                   priority: .low, effort: 4, remind: SbTimeOfDay(7)), words: de)
        first.finish(1)
        first.setHidden(3, true)
        first.delete(5)

        let second = try EntryStore.open(directory: folder)
        XCTAssertEqual(second.entries, first.entries, "a second store reads exactly what the first one wrote")
        XCTAssertEqual(second.entry(id)?.typedTitle, "Keller aufräumen")
        XCTAssertEqual(second.entry(id)?.remind, SbTimeOfDay(19, 30))
        XCTAssertEqual(second.entry(2)?.isSample, false, "a changed sample is the user's")
        XCTAssertEqual(second.entry(1)?.state, .done)
        XCTAssertEqual(second.entry(3)?.hidden, true)
        XCTAssertNil(second.entry(5), "a deleted sample stays deleted")

        let values = try file.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true, "„Bleibt auf diesem Gerät.“: no device backup (BEL-10)")
        let support = try EntryStore.defaultDirectory()
        XCTAssertTrue(support.path.hasSuffix("Library/Application Support"), support.path)
    }

    func testAnUnreadableFileIsNeverReplacedBySamples() throws {
        let folder = try temporaryFolder()
        let file = folder.appendingPathComponent("entries.json")
        // not JSON, no version, version 0 (never written), the current version with entries of another shape
        for bytes in ["{", #"{"entries":[]}"#, #"{"version":0,"entries":[]}"#, #"{"version":2,"entries":[{"id":1}]}"#] {
            try Data(bytes.utf8).write(to: file)
            XCTAssertThrowsError(try EntryStore.open(directory: folder), bytes) { error in
                XCTAssertEqual(error as? StoreError, .unreadable, bytes)
            }
            XCTAssertEqual(try Data(contentsOf: file), Data(bytes.utf8), "the file stays as it was: \(bytes)")
        }
    }

    /// Version 1 (entries without estimate and reminder) is migrated to the current version and written back.
    func testAnOlderFileIsMigrated() throws {
        let folder = try temporaryFolder()
        let file = folder.appendingPathComponent("entries.json")
        let old = #"""
        {"version": 1, "entries": [
          {"id": 7, "typedTitle": "Keller aufräumen", "typedNote": "Kisten", "priority": "high", "created": "2026-09-01",
           "state": "open", "hidden": false},
          {"id": 2, "typedTitle": "", "typedNote": "", "priority": "normal", "created": "2026-10-18", "state": "done",
           "hidden": true, "sample": 2}
        ]}
        """#
        try Data(old.utf8).write(to: file)
        let store = try EntryStore.open(directory: folder)
        XCTAssertEqual(store.entries.map(\.id), [7, 2])
        XCTAssertEqual(store.entry(7)?.typedTitle, "Keller aufräumen")
        XCTAssertEqual(store.entry(7)?.created, Day(2026, 9, 1))
        XCTAssertEqual(store.entry(7)?.effort, 1, "the form's start value")
        XCTAssertEqual(store.entry(7)?.remind, SbTimeOfDay(18))
        XCTAssertEqual(store.entry(2)?.sample, 2)
        XCTAssertEqual(store.entry(2)?.state, .done)
        XCTAssertEqual(store.entry(2)?.hidden, true)

        let written = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any]
        XCTAssertEqual(written?["version"] as? Int, EntryStore.version, "written back in the current version")
        XCTAssertEqual(try EntryStore.open(directory: folder).entries, store.entries)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), ["entries.json"])
    }

    /// A file of a newer version is refused, and neither the file nor its folder changes.
    func testANewerFileIsRefusedAndLeftAsItIs() throws {
        let folder = try temporaryFolder()
        let file = folder.appendingPathComponent("entries.json")
        let newer = Data(#"{"version": 3, "entries": [{"id": 1, "title": "aus der Zukunft"}], "tags": []}"#.utf8)
        try newer.write(to: file)
        let before = try FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date
        XCTAssertThrowsError(try EntryStore.open(directory: folder)) { error in
            XCTAssertEqual(error as? StoreError, .newerVersion(3))
        }
        XCTAssertEqual(try Data(contentsOf: file), newer, "byte for byte as it was")
        XCTAssertEqual(try FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date, before)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), ["entries.json"])
    }

    /// The calm start error instead of the app: what happened, that the entries stay, what helps; no primary action.
    func testTheStartErrorSaysTheEntriesStay() {
        let hosted = Hosted(StartErrorScreen(error: .newerVersion(3)).language(de), look: Look())
        defer { hosted.close() }
        let labels = hosted.nodes.map(\.label)
        XCTAssertTrue(labels.contains { $0.contains("Einträge nicht geöffnet") }, "\(labels)")
        XCTAssertTrue(labels.contains { $0.contains("Sie bleiben unverändert auf diesem Gerät.") }, "\(labels)")
        XCTAssertFalse(labels.contains { $0.contains("Eintrag anlegen") })
    }

    // MARK: language

    func testSamplesFollowTheLanguageAndTheUsersWordsStay() {
        let store = EntryStore.inMemory()
        let own = store.add(EntryInput(title: "Eigener Titel", note: "", priority: .normal, effort: 1, remind: SbTimeOfDay(18)),
                            today: Day(2026, 10, 30))
        let sample = store.entry(1)!
        XCTAssertEqual(sample.title(de), "Fahrrad zur Inspektion bringen")
        XCTAssertEqual(sample.title(en), "Take the bike in for a service")
        XCTAssertEqual(sample.title(de), "Fahrrad zur Inspektion bringen", "back to German")
        XCTAssertEqual(store.entry(own)?.title(en), "Eigener Titel")
        // a sample saved with its shown words unchanged stays a sample, in the other language too
        store.update(1, EntryInput(title: sample.title(en), note: sample.note(en), priority: .low, effort: 2,
                                   remind: SbTimeOfDay(8)), words: en)
        XCTAssertEqual(store.entry(1)?.isSample, true)
        XCTAssertEqual(store.entry(1)?.title(de), "Fahrrad zur Inspektion bringen")
    }

    func testTheLanguageSwitchesInOneProcess() {
        let hosted = Hosted(AppView(store: .inMemory()), look: Look())
        defer { hosted.close() }
        func labels() -> [String] { hosted.nodes.map(\.label) }
        XCTAssertTrue(labels().contains { $0.contains("Fahrrad zur Inspektion bringen") }, "\(labels())")
        XCTAssertTrue(labels().contains { $0.contains("Beispieldaten") })

        hosted.defaults.set(AppLanguage.en.rawValue, forKey: AppLanguage.storageKey)
        hosted.settle(1.0)
        XCTAssertTrue(labels().contains { $0.contains("Take the bike in for a service") }, "\(labels())")
        XCTAssertTrue(labels().contains { $0.contains("Sample data") })
        XCTAssertTrue(labels().contains { $0.contains("Add entry") }, "the primary action in English")
        XCTAssertFalse(labels().contains { $0.contains("Fahrrad") }, "no German sample left")

        hosted.defaults.set(AppLanguage.de.rawValue, forKey: AppLanguage.storageKey)
        hosted.settle(1.0)
        XCTAssertTrue(labels().contains { $0.contains("Fahrrad zur Inspektion bringen") }, "\(labels())")
    }

    func testSystemLanguageFallsBackToGerman() {
        XCTAssertEqual(AppLanguage.system.resolved(preferred: ["en-US", "de-DE"]), "en")
        XCTAssertEqual(AppLanguage.system.resolved(preferred: ["fr-FR", "en-GB"]), "en")
        XCTAssertEqual(AppLanguage.system.resolved(preferred: ["de-AT"]), "de")
        XCTAssertEqual(AppLanguage.system.resolved(preferred: ["fr-FR", "it-IT"]), "de", "D111: the development region")
        XCTAssertEqual(Bundle.main.infoDictionary?["CFBundleDevelopmentRegion"] as? String, "de")
        XCTAssertEqual(Bundle.main.infoDictionary?["CFBundleLocalizations"] as? [String], ["de", "en"])
    }

    func testEveryWordExistsInBothLanguages() throws {
        func keys(_ language: String) throws -> [String: String] {
            let folder = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
            let strings = (NSDictionary(contentsOfFile: folder + "/Localizable.strings") as? [String: String]) ?? [:]
            let plurals = (NSDictionary(contentsOfFile: folder + "/Localizable.stringsdict") as? [String: Any]) ?? [:]
            return strings.merging(plurals.mapValues { _ in "plural" }) { a, _ in a }
        }
        let german = try keys("de")
        let english = try keys("en")
        XCTAssertGreaterThan(german.count, 100)
        XCTAssertEqual(Set(german.keys), Set(english.keys))
        let empty = german.filter { $0.value.isEmpty }.map(\.key).sorted()
        XCTAssertEqual(empty, ["sample.3.note"], "only the sample without a note is empty")
        XCTAssertEqual(de("hours", 1), "1\u{00A0}Stunde")
        XCTAssertEqual(de("hours", 3), "3\u{00A0}Stunden")
        XCTAssertEqual(en("hours", 1), "1\u{00A0}hour")
        XCTAssertEqual(de.count(10_000), "10.000")
        XCTAssertEqual(en.count(10_000), "10,000")
    }

    // MARK: numbers and units (TXT-04)

    /// Keys whose number placeholder is followed by an ordinary space on purpose: no unit follows.
    private static let numberWithoutUnit: [String: String] = [
        "state.count.open": "a count and a state word, „2 offen“ (STA-09)",
        "per.month": "a sum of money, its currency sign comes with the number",
        "data.heatmap.top": "„%@ or more“, a number and words",
        "rank": "„Platz %@ von %@“, a number and a word",
    ]

    /// Every number in the catalog is joined to its unit by U+00A0, in German and English, in every plural form; no
    /// U+202F or U+2009 anywhere. The catalog is read from the source folder, as it is written.
    func testTheCatalogJoinsEveryNumberToItsUnit() throws {
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Musterapp/Localizable.xcstrings")
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: source)) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        func values(_ node: Any, _ path: String) -> [(String, String)] {
            guard let dict = node as? [String: Any] else { return [] }
            if let unit = dict["stringUnit"] as? [String: Any], let value = unit["value"] as? String { return [(path, value)] }
            return dict.sorted { $0.key < $1.key }.flatMap { values($0.value, "\(path)/\($0.key)") }
        }
        var findings: [String] = []
        var checked = 0
        for (key, entry) in strings {
            let localizations = (entry as? [String: Any])?["localizations"] ?? [:]
            for (path, value) in values(localizations, key) {
                checked += 1
                if value.contains("\u{202F}") || value.contains("\u{2009}") { findings.append("\(path): U+202F/U+2009") }
                if Self.numberWithoutUnit[key] == nil, value.contains(/(%(lld|d|@)|[0-9]) [\p{L}%€]/) {
                    findings.append("\(path): „\(value)“ has an ordinary space after a number")
                }
            }
        }
        XCTAssertGreaterThan(checked, 200)
        XCTAssertEqual(findings, [], findings.joined(separator: "\n"))
        XCTAssertEqual(de("glasses", 2), "2\u{00A0}Gläser")
        XCTAssertEqual(en("glasses", 1), "1\u{00A0}glass")
        XCTAssertEqual(de("people", 1), "1\u{00A0}Person")
        XCTAssertEqual(en("people", 12), "12\u{00A0}people")
    }

    /// The formatted output: numbers, percent, money, dates and every unit word, in both languages.
    func testFormattedOutputJoinsNumbersToUnitsAndDaysToMonths() {
        let day = Day(2026, 10, 10)
        XCTAssertEqual(de.percent(0.6), "60\u{00A0}%")
        XCTAssertEqual(en.percent(0.6), "60\u{00A0}%")
        XCTAssertEqual(de.percent(0.125, digits: 1), "12,5\u{00A0}%")
        XCTAssertEqual(en.percent(0.125, digits: 1), "12.5\u{00A0}%")
        XCTAssertEqual(de.shortDate(day), "10.\u{00A0}Okt.")
        XCTAssertEqual(en.shortDate(day), "10\u{00A0}Oct")
        XCTAssertEqual(de.dayDate(day), "Samstag, 10.\u{00A0}Oktober 2026")
        XCTAssertTrue(en.dayDate(day).contains("10\u{00A0}October 2026"), en.dayDate(day))
        XCTAssertEqual(de.noteDate(day), "10.10.2026")
        XCTAssertEqual(en.noteDate(day), "2026-10-10")
        for words in [de, en] {
            let output = [words.decimal(1234.5, digits: 1), words.percent(0.6), words.percent(0.03, digits: 1),
                          words.money(1234.5), words.money(12), words.dayDate(day), words.shortDate(day),
                          words.shortDate(Day(2026, 1, 2)), words.noteDate(day), words.month(day), words.count(10_000),
                          words("glasses", 1), words("glasses", 8), words("people", 1), words("people", 3),
                          words("hours", 2), words("days", 4), words("duration", 1, 30), words("remaining.minutes", 5),
                          words("approx", "20"), words("unit.km", words.decimal(2.5, digits: 1))]
            for text in output {
                XCTAssertFalse(text.contains(/[\u{202F}\u{2009}]/), "\(words.language): „\(text)“ has a narrow space")
                XCTAssertFalse(text.contains(/[0-9] [\p{L}%€]/), "\(words.language): „\(text)“ has an ordinary space after a number")
            }
        }
    }

    // MARK: form

    func testTitleMissingKeepsTheFormOpen() {
        let store = EntryStore.inMemory()
        var closed = 0
        let hosted = Hosted(FormScreen(request: .new, store: store, words: de, onClose: { closed += 1 }), look: Look())
        defer { hosted.close() }
        hosted.activate("Eintrag anlegen")
        XCTAssertTrue(hosted.nodes.contains { $0.label.contains("Titel fehlt.") }, "\(hosted.nodes.map(\.label))")
        XCTAssertEqual(closed, 0)
        XCTAssertEqual(store.entries.count, 5, "nothing saved")
    }

    func testUnsavedChangesAskWithThreeKeys() {
        var draft = FormDraft()
        draft.title = "Keller aufräumen"
        var closed = 0
        let store = EntryStore.inMemory()
        let hosted = Hosted(FormScreen(request: .new, store: store, words: de, onClose: { closed += 1 }, draft: draft),
                            look: Look())
        defer { hosted.close() }
        hosted.activate("Abbrechen")
        let labels = hosted.nodes.map(\.label)
        XCTAssertEqual(closed, 0, "changes are never closed away silently")
        XCTAssertTrue(labels.contains("Neuen Eintrag sichern?"), "\(labels)")
        for key in ["Abbrechen", "Verwerfen", "Sichern"] {
            XCTAssertTrue(labels.contains(key), "„\(key)“ in \(labels)")
        }
        // the dialog's keys come after its title; „Verwerfen“ closes without saving
        hosted.activate("Verwerfen")
        XCTAssertEqual(closed, 1)
        XCTAssertEqual(store.entries.count, 5)
    }

    func testUnsavedDialogSavesWithSichern() {
        var draft = FormDraft()
        draft.title = "Keller aufräumen"
        var closed = 0
        let store = EntryStore.inMemory()
        let hosted = Hosted(FormScreen(request: .new, store: store, words: de, onClose: { closed += 1 }, draft: draft,
                                       askUnsaved: true), look: Look())
        defer { hosted.close() }
        hosted.activate("Sichern")
        XCTAssertEqual(closed, 1)
        XCTAssertEqual(store.entries.first?.typedTitle, "Keller aufräumen")
    }

    func testNoChangesCloseAtOnce() {
        var closed = 0
        let hosted = Hosted(FormScreen(request: .edit(1), store: .inMemory(), words: de, onClose: { closed += 1 }),
                            look: Look())
        defer { hosted.close() }
        hosted.activate("Abbrechen")
        XCTAssertEqual(closed, 1)
        XCTAssertFalse(hosted.nodes.contains { $0.label == "Verwerfen" })
    }

    // MARK: list and detail

    func testHideOffersUndo() {
        let store = EntryStore.inMemory()
        let toasts = SbToastState()
        let screen = ListScreen(store: store, query: .constant(""), toasts: toasts,
                                tabs: SbTabBar(items: [SbTabItem("1", icon: "file-text"), SbTabItem("2", icon: "chart-bar"),
                                                       SbTabItem("3", icon: "settings")], selection: .constant(0)),
                                onCreate: {})
        screen.hide(store.entry(2)!)
        XCTAssertEqual(store.entry(2)?.hidden, true)
        XCTAssertEqual(toasts.current?.message, "„Balkon bepflanzen“ ausgeblendet")
        XCTAssertEqual(toasts.current?.actionLabel, "Rückgängig")
        toasts.current?.onAction()
        XCTAssertEqual(store.entry(2)?.hidden, false)
    }

    func testFinishAsksFirstAndTakesThePrimaryActionAway() {
        let store = EntryStore.inMemory()
        let hosted = Hosted(AppView(store: store, path: [1]), look: Look())
        defer { hosted.close() }
        XCTAssertTrue(hosted.nodes.contains { $0.label.hasPrefix("Eintrag bearbeiten") })
        hosted.activate("Eintrag abschließen")
        XCTAssertEqual(store.entry(1)?.state, .open, "the dialog asks first")
        XCTAssertTrue(hosted.nodes.contains { $0.label == "Eintrag abschließen?" }, "\(hosted.nodes.map(\.label))")
        hosted.activate("Abschließen")
        XCTAssertEqual(store.entry(1)?.state, .done)
        XCTAssertFalse(hosted.nodes.contains { $0.label.hasPrefix("Eintrag bearbeiten") }, "a done entry has no next step")
    }

    func testDeleteAsksFirstAndReturnsToTheList() {
        let store = EntryStore.inMemory()
        let hosted = Hosted(AppView(store: store, path: [1]), look: Look())
        defer { hosted.close() }
        hosted.activate("Eintrag löschen")
        XCTAssertNotNil(store.entry(1), "the dialog asks first")
        hosted.activate("Löschen")
        XCTAssertNil(store.entry(1))
        XCTAssertTrue(hosted.nodes.contains { $0.label.hasPrefix("Balkon bepflanzen") }, "\(hosted.nodes.map(\.label))")
    }

    func testSearchWithoutHitSaysSo() {
        let hosted = Hosted(AppView(store: .inMemory(), query: "Zebra"), look: Look())
        defer { hosted.close() }
        XCTAssertTrue(hosted.nodes.contains { $0.label == "Kein Eintrag mit „Zebra“" }, "\(hosted.nodes.map(\.label))")
    }
}
