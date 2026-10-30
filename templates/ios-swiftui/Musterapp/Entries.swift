import Foundation
import Observation
import SebaroDesign

enum EntryState: String, Codable, Sendable {
    case open, done
}

enum Priority: String, Codable, CaseIterable, Sendable {
    case low, normal, high

    var key: String { "priority.\(rawValue)" }
}

/// One entry of the list. `done` entries are finished for good and can no longer be edited.
///
/// `sample` is the number of an invented sample entry (BEL-09): its title and note are looked up only when shown, so
/// they follow a language change, and the screens mark it „Beispieldaten“. A user's entry has `sample` nil and keeps
/// `typedTitle` and `typedNote` exactly as typed.
struct Entry: Codable, Identifiable, Equatable, Sendable {
    var id: Int
    var typedTitle: String
    var typedNote: String
    var priority: Priority
    var created: Day
    /// The estimate in hours (the stepper of the form).
    var effort: Int
    /// The reminder time in minutes after midnight (the time row of the form).
    var remindAt: Int
    var state: EntryState = .open
    var hidden = false
    var sample: Int?

    var isSample: Bool { sample != nil }

    func title(_ words: Words) -> String { sample.map { words("sample.\($0).title") } ?? typedTitle }

    func note(_ words: Words) -> String { sample.map { words("sample.\($0).note") } ?? typedNote }

    var remind: SbTimeOfDay { SbTimeOfDay(remindAt / 60, remindAt % 60) }
}

/// Why the entries file was not opened. The file is left untouched in both cases.
enum StoreError: Error, Equatable {
    /// The file comes from a newer version of the app (its format version is higher than `EntryStore.version`).
    case newerVersion(Int)
    /// The file is not JSON of a known format, has no version or an unknown older one, or cannot be read at all.
    case unreadable
}

/// What the form gives back.
struct EntryInput: Equatable, Sendable {
    var title: String
    var note: String
    var priority: Priority
    var effort: Int
    var remind: SbTimeOfDay
}

/// The app's entries, kept on this device in one small JSON file in Application Support (Foundation's JSONEncoder,
/// no extra library). Every change writes the whole file atomically; the file is excluded from the device backup,
/// so „Bleibt auf diesem Gerät.“ holds (BEL-10). A product with many entries or queries takes SwiftData instead.
@MainActor @Observable
final class EntryStore {
    private(set) var entries: [Entry]
    @ObservationIgnored private let file: URL?

    private init(file: URL?, entries: [Entry]) {
        self.file = file
        self.entries = entries
    }

    func entry(_ id: Int) -> Entry? { entries.first { $0.id == id } }

    @discardableResult
    func add(_ input: EntryInput, today: Day) -> Int {
        let id = (entries.map(\.id).max() ?? 0) + 1
        entries.insert(Entry(id: id, typedTitle: input.title, typedNote: input.note, priority: input.priority,
                             created: today, effort: input.effort, remindAt: input.remind.hour * 60 + input.remind.minute),
                       at: 0)
        save()
        return id
    }

    /// A sample whose title and note the user leaves as shown stays a sample; once either is changed, the entry is the
    /// user's, with both texts as they stand.
    func update(_ id: Int, _ input: EntryInput, words: Words) {
        change(id) { e in
            if !(e.isSample && input.title == e.title(words) && input.note == e.note(words)) {
                e.typedTitle = input.title
                e.typedNote = input.note
                e.sample = nil
            }
            e.priority = input.priority
            e.effort = input.effort
            e.remindAt = input.remind.hour * 60 + input.remind.minute
        }
    }

    func finish(_ id: Int) { change(id) { $0.state = .done } }

    func setHidden(_ id: Int, _ hidden: Bool) { change(id) { $0.hidden = hidden } }

    func delete(_ id: Int) {
        entries.removeAll { $0.id == id }
        save()
    }

    private func change(_ id: Int, _ edit: (inout Entry) -> Void) {
        guard let i = entries.firstIndex(where: { $0.id == id }) else { return }
        edit(&entries[i])
        save()
    }

    private struct FileContent: Codable {
        var version: Int
        var entries: [Entry]
    }

    /// The format this build writes. A file of an older version is migrated when it is opened; a file of a newer
    /// version is refused and never written to (`StoreError.newerVersion`).
    static let version = 2

    /// Only the version, read first, so a file of another version is never decoded as this one.
    private struct FileVersion: Decodable {
        var version: Int
    }

    /// Version 1, the example of an older format: entries without the estimate and the reminder time. Its migration
    /// gives them the form's start values (1 hour, 18:00). A product adds a struct and a step like this for every
    /// format it leaves behind and never edits an old one.
    private struct EntryV1: Decodable {
        var id: Int
        var typedTitle: String
        var typedNote: String
        var priority: Priority
        var created: Day
        var state: EntryState
        var hidden: Bool
        var sample: Int?

        var migrated: Entry {
            Entry(id: id, typedTitle: typedTitle, typedNote: typedNote, priority: priority, created: created, effort: 1,
                  remindAt: 18 * 60, state: state, hidden: hidden, sample: sample)
        }
    }

    private struct FileContentV1: Decodable {
        var entries: [EntryV1]
    }

    /// The entries of a file's bytes, migrated to `version`; `migrated` says the file is of an older version.
    static func read(_ data: Data) throws(StoreError) -> (entries: [Entry], migrated: Bool) {
        let decoder = JSONDecoder()
        guard let found = try? decoder.decode(FileVersion.self, from: data).version else { throw .unreadable }
        do {
            switch found {
            case version:
                return (try decoder.decode(FileContent.self, from: data).entries, false)
            case 1:
                return (try decoder.decode(FileContentV1.self, from: data).entries.map(\.migrated), true)
            case let newer where newer > version:
                throw StoreError.newerVersion(newer)
            default:
                throw StoreError.unreadable
            }
        } catch let error as StoreError {
            throw error
        } catch {
            throw .unreadable
        }
    }

    private func save() {
        guard let file else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(FileContent(version: Self.version, entries: entries)).write(to: file, options: .atomic)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var url = file
            try url.setResourceValues(values)
        } catch {
            // the old file stays; the error ends the app loudly rather than losing entries unseen
            fatalError("entries.json could not be written: \(error)")
        }
    }

    /// The folder of the file: Application Support of the app.
    static func defaultDirectory() throws -> URL {
        try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
                                    create: true)
    }

    /// The entries in `directory`/entries.json; on the first start the invented samples (BEL-09), written there at
    /// once, so a deleted sample stays deleted. A file of an older version is migrated and written back in this
    /// version (atomically, so the old file stays until the new one is complete). A file the app cannot read or of a
    /// newer version throws `StoreError` and stays byte for byte as it was: the app shows the calm start error and
    /// never replaces the entries by samples.
    static func open(directory: URL) throws(StoreError) -> EntryStore {
        let file = directory.appendingPathComponent("entries.json")
        if FileManager.default.fileExists(atPath: file.path) {
            guard let data = try? Data(contentsOf: file) else { throw .unreadable }
            let (entries, migrated) = try read(data)
            let store = EntryStore(file: file, entries: entries)
            if migrated { store.save() }
            return store
        }
        let store = EntryStore(file: file, entries: samples())
        store.save()
        return store
    }

    /// The invented samples in memory only, for tests and previews.
    static func inMemory(_ entries: [Entry]? = nil) -> EntryStore {
        EntryStore(file: nil, entries: entries ?? samples())
    }

    static func samples() -> [Entry] {
        let priorities: [Priority] = [.high, .normal, .low, .normal, .normal]
        let states: [EntryState] = [.open, .open, .open, .done, .done]
        let efforts = [2, 3, 1, 2, 1]
        let reminders = [18 * 60, 10 * 60, 19 * 60 + 30, 9 * 60, 8 * 60]
        return priorities.indices.map { i in
            Entry(id: i + 1, typedTitle: "", typedNote: "", priority: priorities[i], created: Day(2026, 10, 20 - 2 * i),
                  effort: efforts[i], remindAt: reminders[i], state: states[i], sample: i + 1)
        }
    }
}
