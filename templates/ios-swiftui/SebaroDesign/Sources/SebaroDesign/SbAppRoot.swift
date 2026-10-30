import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Settings stored by the app (the same keys as the web's localStorage, spec/03 §13, spec/09 §6)

/// Einstellungen › „Hell oder Dunkel“ (D75, D91 I8a): follow the system, or always light, or always dark.
/// Stored as `@AppStorage("sb-theme")`: "system" (or nothing), "light", "dark".
public enum SbThemeMode: String, CaseIterable, Sendable {
    case system, light, dark

    public static let storageKey = "sb-theme"

    /// nil = follow the system.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// The storage keys of the other two app settings: „Bewegung immer reduzieren“ (`"reduce"`, D46) and the colour
/// tone „Farbton“ (`"warm"`, D90, D91 C4c).
public enum SbSettingKeys {
    public static let motion = "sb-motion"
    public static let tone = "sb-tone"
}

// MARK: - Words the parts write (D87)

/// The words the SebaroDesign parts write themselves, one table per language (D87, the same words as SbMessages in
/// Compose and the web scripts). German is the default; `de-AT` falls back to `de`, an unknown language to German.
/// An app replaces the table with `.environment(\.sbMessages, myTable)`. Words the caller passes (titles, labels,
/// the status word of a row) stay the caller's and come from its String Catalog.
public struct SbMessages: Sendable {
    public var themeGroup: String
    public var themeSystem: String
    public var themeLight: String
    public var themeDark: String
    public var toneGroup: String
    public var toneCool: String
    public var toneWarm: String
    public var motionReduce: String
    public var motionReduceHelp: String
    public var statusRunning: String
    public var statusPlanned: String
    public var statusDone: String
    public var statusFailed: String
    public var statusOpen: String
    public var donePrefix: String
    public var cancel: String
    public var retry: String
    public var howChecked: String
    public var evidenceOpen: String
    public var evidenceClosed: String
    public var back: String
    /// The word after the label of a voluntary field, drawn in parentheses and read „Notiz, optional“ (D99 (3)).
    public var fieldOptional: String
    /// The word of an error's expandable details and its two VoiceOver states (D102 (23), `SbErrorDetails`).
    public var errorDetails: String
    public var errorDetailsOpen: String
    public var errorDetailsClosed: String
    /// The two other ways of `SbUnsavedDialog` (D105 (36), AKT-11): „Sichern“ (last) and „Verwerfen“.
    public var save: String
    public var discard: String
    /// The data-path line of an action whose data stays on the device, „Bleibt auf diesem Gerät.“ (D98 V4, BEL-10;
    /// FACTS-CONTRACT §6.5, spec/10 §3.4): under „Sichern“ of `SbUnsavedDialog(…, saveHint: .onDevice)`.
    public var staysOnDevice: String
    /// The error at an empty required field, „Name fehlt.“ (D98 V2, spec/07 §4.1; `SbRequiredFields`).
    public var fieldMissing: @Sendable (_ label: String) -> String
    /// The names of the stepper's buttons, „Wiederholungen weniger“ / „… mehr“ (D105 (12)).
    public var stepperLess: @Sendable (_ label: String) -> String
    public var stepperMore: @Sendable (_ label: String) -> String
    /// The time sheet's head (D105 (13)).
    public var timeChoose: String
    /// The own recording (D105 (8)–(11), `SbRecorderRow`).
    public var recordNone: String
    public var record: String
    public var recordStop: String
    public var recordRunning: String
    public var recordAgain: String
    public var recordDelete: String
    public var recordDenied: String
    public var recordSettings: String
    /// The audio row (`SbAudioRow`): the play / pause names of a medium, the seek bar, „0:12 von 0:42“, the failure.
    public var mediaPlay: @Sendable (_ name: String) -> String
    public var mediaPause: @Sendable (_ name: String) -> String
    public var mediaPosition: @Sendable (_ now: String, _ total: String) -> String
    public var mediaSeek: String
    public var audioFailed: String
    /// Chart words (spec/08 §14.10): „Ziel 8“, the current bar's state, „von 8“, „erreicht“, „erwartet“.
    public var chartTarget: @Sendable (_ value: String) -> String
    public var chartCurrent: String
    public var goalOf: @Sendable (_ total: String) -> String
    public var goalReached: String
    public var chartExpected: String
    /// The rating (spec/02 §3.20): the hidden „Bewertung: “, „4,2 von 5“, „38 Bewertungen“.
    public var ratingLabel: String
    public var ratingOf: @Sendable (_ value: String, _ max: String) -> String
    public var ratingCount: @Sendable (_ count: Int, _ formatted: String) -> String
    /// The sorted head of `SbSortableTable`: „Sortiert nach Betrag, absteigend“.
    public var tableSorted: @Sendable (_ column: String, _ descending: Bool) -> String
    /// The titles of `SbCallout` (spec/02 §3.11): „Hinweis“, „Achtung“, „Erfolg“, „Fehler“.
    public var calloutNote: String
    public var calloutWarning: String
    public var calloutSuccess: String
    public var calloutError: String
    /// The VoiceOver state of `SbCheckRow` („angekreuzt“ / „nicht angekreuzt“).
    public var checkOn: String
    public var checkOff: String
    /// The search field's clear button, the chips' limit sentence, a select without a choice (spec/08 §14.9, §14.12).
    public var clearSearch: String
    public var chipsMax: @Sendable (_ max: Int) -> String
    public var selectPlaceholder: String
    /// The states of `SbValueTile` (D105 (33), D106 (12)).
    public var valueKept: String
    public var valueStruck: String
    /// Chart words of part 2 (spec/08 §14.22–§14.24): a gap's „keine Angabe“, a point's sentence, the legend's name, the deviation's sides.
    public var noValue: String
    public var chartPoint: @Sendable (_ label: String, _ value: String) -> String
    public var chartLegend: String
    public var chartLess: String
    public var chartMore: String
    /// The heatmap (G6a, D93, D99 (7)): today's legend word, a day's sentence, „ab 28.09.“, the weekday heads, the hint.
    public var todayKey: String
    public var chartDay: @Sendable (_ day: String, _ value: String, _ today: Bool) -> String
    public var weekFrom: @Sendable (_ date: String) -> String
    public var weekdays: [String]
    public var heatmapHint: String
    /// The video (B12b): the failure, the play word and its name, a length in words, the captions chip.
    public var videoFailed: String
    public var videoPlay: String
    public var videoPlayName: @Sendable (_ title: String, _ length: String) -> String
    public var mediaLength: @Sendable (_ h: Int, _ m: Int, _ s: Int) -> String
    public var videoCaptions: String
    /// The remove button of an input chip, „Wasser entfernen“ (spec/02 §2.9).
    public var removeValue: @Sendable (_ value: String) -> String
    /// Steps (spec/08 §14.13): „erledigt“, „aktueller Schritt“, „Schritt 2 von 4“; the intro's skip word.
    public var stepDone: String
    public var stepCurrent: String
    public var stepOf: @Sendable (_ current: Int, _ total: Int) -> String
    public var introSkip: String
    /// Menus (spec/08 §14.16): the overflow button's name, a row's „Mehr zu …“.
    public var openMenu: String
    public var rowMore: @Sendable (_ name: String) -> String
    /// Cards and facts: a current card, „3 nicht belegt“, the version line, a check's reason.
    public var itemCurrent: String
    public var factsHidden: @Sendable (_ count: String) -> String
    public var aboutVersion: @Sendable (_ version: String, _ date: String) -> String
    public var aboutVersionOnly: @Sendable (_ version: String) -> String
    public var checkReason: @Sendable (_ reason: String) -> String
    /// The calendar (spec/08 §14.14).
    public var calendarToday: String
    public var calendarWithEntry: String
    public var calendarPrevious: String
    public var calendarNext: String
    public var calendarNone: String
    /// Code and diff (spec/08 §14.27, §14.28).
    public var codeCopy: String
    public var codeCopied: String
    public var diffAdded: String
    public var diffRemoved: String
    public var diffRegion: @Sendable (_ file: String) -> String
    public var diffSum: @Sendable (_ added: Int, _ removed: Int, _ a: String, _ r: String) -> String
    /// The place (spec/08 §14.31).
    public var placeOpenMap: String
    /// The board (spec/08 §14.32).
    public var boardCards: @Sendable (_ count: Int, _ formatted: String) -> String
    public var boardVotes: @Sendable (_ count: Int, _ formatted: String) -> String
    public var boardEmpty: String
    public var boardMore: @Sendable (_ name: String) -> String
    public var boardPrevious: String
    public var boardNext: String
    public var boardPosition: @Sendable (_ n: Int, _ total: Int, _ name: String) -> String
    public var boardMoveTo: String
    public var boardNewCardIn: @Sendable (_ name: String) -> String
    /// Document tabs and sheets: „geändert“, „Schließen“.
    public var docChanged: String
    public var sheetClose: String
    /// The camera and photo parts (D106 (16)–(24), D107 (5)–(7)).
    public var cameraClose: String
    public var flash: String
    public var flashOn: String
    public var flashOff: String
    public var cameraLooking: String
    public var cameraFound: String
    public var capturePage: String
    public var capturedSoFar: @Sendable (_ count: Int, _ formatted: String) -> String
    public var cornerNames: [String]
    public var cornerPosition: @Sendable (_ corner: String, _ x: String, _ y: String) -> String
    public var cornerChoose: String
    public var moveLeft: String
    public var moveRight: String
    public var moveUp: String
    public var moveDown: String
    public var filterGroup: String
    public var filterOriginal: String
    public var filterGrayscale: String
    public var filterBlackWhite: String
    public var pageName: @Sendable (_ n: Int) -> String
    public var pageWord: String
    public var pageOfTotal: @Sendable (_ total: String) -> String
    public var pageFieldName: @Sendable (_ total: String) -> String
    public var pagePrevious: String
    public var pageNext: String
    public var zoomOut: String
    public var zoomIn: String
    public var zoomFit: String
    public var zoomFitted: String
    public var zoomValue: @Sendable (_ value: String) -> String

    public static let de = SbMessages(
        themeGroup: "Hell oder Dunkel", themeSystem: "Wie das System", themeLight: "Hell", themeDark: "Dunkel",
        toneGroup: "Farbton", toneCool: "Kühl", toneWarm: "Warm",
        motionReduce: "Bewegung immer reduzieren",
        motionReduceHelp: "Neues erscheint dann ohne Bewegung, es wird nur eingeblendet. Gilt auch, wenn das Telefon Bewegung zulässt.",
        statusRunning: "läuft", statusPlanned: "geplant", statusDone: "erledigt", statusFailed: "Fehler",
        statusOpen: "offen", donePrefix: "erledigt: ", cancel: "Abbrechen", retry: "Noch mal versuchen",
        howChecked: "Wie geprüft?", evidenceOpen: "Beleg ausgeklappt", evidenceClosed: "Beleg eingeklappt",
        back: "Zurück", fieldOptional: "optional",
        errorDetails: "Details", errorDetailsOpen: "ausgeklappt", errorDetailsClosed: "eingeklappt",
        save: "Sichern", discard: "Verwerfen", staysOnDevice: "Bleibt auf diesem Gerät.", fieldMissing: { "\($0) fehlt." },
        stepperLess: { "\($0) weniger" }, stepperMore: { "\($0) mehr" }, timeChoose: "Uhrzeit wählen",
        recordNone: "Noch keine Aufnahme.", record: "Aufnehmen", recordStop: "Stopp", recordRunning: "Aufnahme läuft.",
        recordAgain: "Neu aufnehmen", recordDelete: "Löschen …",
        recordDenied: "Ohne Mikrofon kann die App nicht aufnehmen.", recordSettings: "Einstellungen öffnen",
        mediaPlay: { "\($0) abspielen" }, mediaPause: { "\($0) anhalten" }, mediaPosition: { "\($0) von \($1)" },
        mediaSeek: "Wiedergabestelle", audioFailed: "Die Aufnahme lässt sich nicht abspielen.",
        chartTarget: { "Ziel \($0)" }, chartCurrent: "aktueller Zeitraum", goalOf: { "von \($0)" },
        goalReached: "erreicht", chartExpected: "erwartet",
        ratingLabel: "Bewertung: ", ratingOf: { "\($0) von \($1)" },
        ratingCount: { $0 == 1 ? "\($1) Bewertung" : "\($1) Bewertungen" },
        tableSorted: { "Sortiert nach \($0), " + ($1 ? "absteigend" : "aufsteigend") },
        calloutNote: "Hinweis", calloutWarning: "Achtung", calloutSuccess: "Erfolg", calloutError: "Fehler",
        checkOn: "angekreuzt", checkOff: "nicht angekreuzt", clearSearch: "Suche leeren",
        chipsMax: { "Höchstens \($0) auswählbar." }, selectPlaceholder: "Bitte wählen", valueKept: "behalten",
        valueStruck: "gestrichen",
        noValue: "keine Angabe",
        chartPoint: { "\($0): \($1)" },
        chartLegend: "Legende",
        chartLess: "weniger",
        chartMore: "mehr",
        todayKey: "Rahmen: heute",
        chartDay: { $2 ? "\($0), heute: \($1)" : "\($0): \($1)" },
        weekFrom: { "ab \($0)" },
        weekdays: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"],
        heatmapHint: "Tipp auf einen Tag, um seinen Wert zu sehen.",
        videoFailed: "Das Video lässt sich nicht abspielen.",
        videoPlay: "Abspielen",
        videoPlayName: { "Abspielen: \($0), Video, \($1)" },
        mediaLength: { h, m, s in [h > 0 ? (h == 1 ? "1 Stunde" : "\(h) Stunden") : nil, m > 0 ? (m == 1 ? "1 Minute" : "\(m) Minuten") : nil, (s > 0 || (h == 0 && m == 0)) ? (s == 1 ? "1 Sekunde" : "\(s) Sekunden") : nil].compactMap { $0 }.joined(separator: " ") },
        videoCaptions: "Untertitel",
        removeValue: { "\($0) entfernen" },
        stepDone: "erledigt",
        stepCurrent: "aktueller Schritt",
        stepOf: { "Schritt \($0) von \($1)" },
        introSkip: "Einführung überspringen",
        openMenu: "Menü öffnen",
        rowMore: { "Mehr zu \($0)" },
        itemCurrent: "aktuell",
        factsHidden: { "\($0) nicht belegt" },
        aboutVersion: { "Version \($0) vom \($1)" },
        aboutVersionOnly: { "Version \($0)" },
        checkReason: { "Grund: \($0)" },
        calendarToday: "heute",
        calendarWithEntry: "mit Eintrag",
        calendarPrevious: "Voriger Monat",
        calendarNext: "Nächster Monat",
        calendarNone: "Nichts eingetragen.",
        codeCopy: "Kopieren",
        codeCopied: "Kopiert",
        diffAdded: "hinzugefügt: ",
        diffRemoved: "entfernt: ",
        diffRegion: { "Änderungen in \($0)" },
        diffSum: { added, removed, a, r in let lines = { (n: Int) in n == 1 ? "Zeile" : "Zeilen" }; return added > 0 && removed > 0 ? "\(a) \(lines(added)) hinzugefügt, \(r) entfernt" : added > 0 ? "\(a) \(lines(added)) hinzugefügt" : removed > 0 ? "\(r) \(lines(removed)) entfernt" : "Keine Zeile geändert" },
        placeOpenMap: "In Karten öffnen",
        boardCards: { $0 == 1 ? "\($1) Karte" : "\($1) Karten" },
        boardVotes: { $0 == 1 ? "\($1) Stimme" : "\($1) Stimmen" },
        boardEmpty: "Noch keine Karte.",
        boardMore: { "Mehr zu \($0)" },
        boardPrevious: "Vorige Spalte",
        boardNext: "Nächste Spalte",
        boardPosition: { "Spalte \($0) von \($1): \($2)" },
        boardMoveTo: "Verschieben nach …",
        boardNewCardIn: { "Neue Karte in „\($0)“" },
        docChanged: "geändert",
        sheetClose: "Schließen",
        cameraClose: "Kamera schließen",
        flash: "Blitz",
        flashOn: "Blitz an",
        flashOff: "Blitz aus",
        cameraLooking: "sucht Blatt",
        cameraFound: "Blatt erkannt",
        capturePage: "Seite aufnehmen",
        capturedSoFar: { $0 == 0 ? "Noch keine Seite" : $0 == 1 ? "1 Seite bisher" : "\($1) Seiten bisher" },
        cornerNames: ["Ecke oben links", "Ecke oben rechts", "Ecke unten rechts", "Ecke unten links"],
        cornerPosition: { "\($0), \($1)\u{00A0}% von links, \($2)\u{00A0}% von oben" },
        cornerChoose: "Wähle eine Ecke.",
        moveLeft: "Nach links schieben",
        moveRight: "Nach rechts schieben",
        moveUp: "Nach oben schieben",
        moveDown: "Nach unten schieben",
        filterGroup: "Filter",
        filterOriginal: "Original",
        filterGrayscale: "Graustufen",
        filterBlackWhite: "Schwarzweiß",
        pageName: { "Seite \($0)" },
        pageWord: "Seite",
        pageOfTotal: { "von \($0)" },
        pageFieldName: { "Seite von \($0)" },
        pagePrevious: "Vorige Seite",
        pageNext: "Nächste Seite",
        zoomOut: "Verkleinern",
        zoomIn: "Vergrößern",
        zoomFit: "Einpassen",
        zoomFitted: "eingepasst",
        zoomValue: { "Zoom \($0)" })

    public static let en = SbMessages(
        themeGroup: "Light or dark", themeSystem: "Like the system", themeLight: "Light", themeDark: "Dark",
        toneGroup: "Tone", toneCool: "Cool", toneWarm: "Warm",
        motionReduce: "Always reduce motion",
        motionReduceHelp: "New things then appear without movement, they only fade in. Also when the phone allows motion.",
        statusRunning: "running", statusPlanned: "planned", statusDone: "done", statusFailed: "error",
        statusOpen: "open", donePrefix: "done: ", cancel: "Cancel", retry: "Try again",
        howChecked: "How was this checked?", evidenceOpen: "Evidence expanded", evidenceClosed: "Evidence collapsed",
        back: "Back", fieldOptional: "optional",
        errorDetails: "Details", errorDetailsOpen: "expanded", errorDetailsClosed: "collapsed",
        save: "Save", discard: "Discard", staysOnDevice: "Stays on this device.", fieldMissing: { "\($0) is missing." },
        stepperLess: { "Fewer: \($0)" }, stepperMore: { "More: \($0)" }, timeChoose: "Choose a time",
        recordNone: "No recording yet.", record: "Record", recordStop: "Stop", recordRunning: "Recording.",
        recordAgain: "Record again", recordDelete: "Delete …",
        recordDenied: "Without the microphone the app can’t record.", recordSettings: "Open settings",
        mediaPlay: { "Play \($0)" }, mediaPause: { "Pause \($0)" }, mediaPosition: { "\($0) of \($1)" },
        mediaSeek: "Playback position", audioFailed: "This recording can’t be played.",
        chartTarget: { "Target \($0)" }, chartCurrent: "current period", goalOf: { "of \($0)" },
        goalReached: "reached", chartExpected: "expected",
        ratingLabel: "Rating: ", ratingOf: { "\($0) of \($1)" },
        ratingCount: { $0 == 1 ? "\($1) rating" : "\($1) ratings" },
        tableSorted: { "Sorted by \($0), " + ($1 ? "descending" : "ascending") },
        calloutNote: "Note", calloutWarning: "Warning", calloutSuccess: "Success", calloutError: "Error",
        checkOn: "checked", checkOff: "not checked", clearSearch: "Clear search",
        chipsMax: { "Up to \($0) can be chosen." }, selectPlaceholder: "Please choose", valueKept: "kept",
        valueStruck: "struck",
        noValue: "not given",
        chartPoint: { "\($0): \($1)" },
        chartLegend: "Legend",
        chartLess: "less",
        chartMore: "more",
        todayKey: "Frame: today",
        chartDay: { $2 ? "\($0), today: \($1)" : "\($0): \($1)" },
        weekFrom: { "from \($0)" },
        weekdays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"],
        heatmapHint: "Tap a day to see its value.",
        videoFailed: "This video can’t be played.",
        videoPlay: "Play",
        videoPlayName: { "Play: \($0), video, \($1)" },
        mediaLength: { h, m, s in [h > 0 ? (h == 1 ? "1 hour" : "\(h) hours") : nil, m > 0 ? (m == 1 ? "1 minute" : "\(m) minutes") : nil, (s > 0 || (h == 0 && m == 0)) ? (s == 1 ? "1 second" : "\(s) seconds") : nil].compactMap { $0 }.joined(separator: " ") },
        videoCaptions: "Captions",
        removeValue: { "Remove \($0)" },
        stepDone: "done",
        stepCurrent: "current step",
        stepOf: { "Step \($0) of \($1)" },
        introSkip: "Skip introduction",
        openMenu: "Open menu",
        rowMore: { "More about \($0)" },
        itemCurrent: "current",
        factsHidden: { "\($0) not verified" },
        aboutVersion: { "Version \($0) from \($1)" },
        aboutVersionOnly: { "Version \($0)" },
        checkReason: { "Reason: \($0)" },
        calendarToday: "today",
        calendarWithEntry: "has entries",
        calendarPrevious: "Previous month",
        calendarNext: "Next month",
        calendarNone: "Nothing entered.",
        codeCopy: "Copy",
        codeCopied: "Copied",
        diffAdded: "added: ",
        diffRemoved: "removed: ",
        diffRegion: { "Changes in \($0)" },
        diffSum: { added, removed, a, r in let lines = { (n: Int) in n == 1 ? "line" : "lines" }; return added > 0 && removed > 0 ? "\(a) \(lines(added)) added, \(r) removed" : added > 0 ? "\(a) \(lines(added)) added" : removed > 0 ? "\(r) \(lines(removed)) removed" : "No line changed" },
        placeOpenMap: "Open in maps",
        boardCards: { $0 == 1 ? "\($1) card" : "\($1) cards" },
        boardVotes: { $0 == 1 ? "\($1) vote" : "\($1) votes" },
        boardEmpty: "No card yet.",
        boardMore: { "More about \($0)" },
        boardPrevious: "Previous column",
        boardNext: "Next column",
        boardPosition: { "Column \($0) of \($1): \($2)" },
        boardMoveTo: "Move to …",
        boardNewCardIn: { "New card in “\($0)”" },
        docChanged: "changed",
        sheetClose: "Close",
        cameraClose: "Close camera",
        flash: "Flash",
        flashOn: "Flash on",
        flashOff: "Flash off",
        cameraLooking: "looking for a page",
        cameraFound: "page found",
        capturePage: "Capture page",
        capturedSoFar: { $0 == 0 ? "No page yet" : $0 == 1 ? "1 page so far" : "\($1) pages so far" },
        cornerNames: ["Top left corner", "Top right corner", "Bottom right corner", "Bottom left corner"],
        cornerPosition: { "\($0), \($1)\u{00A0}% from the left, \($2)\u{00A0}% from the top" },
        cornerChoose: "Choose a corner.",
        moveLeft: "Move left",
        moveRight: "Move right",
        moveUp: "Move up",
        moveDown: "Move down",
        filterGroup: "Filter",
        filterOriginal: "Original",
        filterGrayscale: "Greyscale",
        filterBlackWhite: "Black and white",
        pageName: { "Page \($0)" },
        pageWord: "Page",
        pageOfTotal: { "of \($0)" },
        pageFieldName: { "Page of \($0)" },
        pagePrevious: "Previous page",
        pageNext: "Next page",
        zoomOut: "Zoom out",
        zoomIn: "Zoom in",
        zoomFit: "Fit",
        zoomFitted: "fitted",
        zoomValue: { "Zoom \($0)" })

    /// The table of a language („de“, „de-AT“, „en-GB“); an unknown language gets German.
    public static func forLanguage(_ identifier: String) -> SbMessages {
        identifier.lowercased().hasPrefix("en") ? .en : .de
    }

    /// A count in a language: „10.000“ (de), „10,000“ (en); never U+202F or U+2009 (D22).
    public static func formatCount(_ value: Int, locale: Locale) -> String {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        return (f.string(from: NSNumber(value: value)) ?? String(value))
            .replacingOccurrences(of: "\u{202F}", with: "\u{00A0}")
            .replacingOccurrences(of: "\u{2009}", with: "\u{00A0}")
    }
}

private struct SbMessagesKey: EnvironmentKey { static let defaultValue: SbMessages? = nil }
private struct SbReduceMotionSettingKey: EnvironmentKey { static let defaultValue = false }

public extension EnvironmentValues {
    /// The app's own words table; nil = the built-in table of the environment's locale.
    var sbMessages: SbMessages? {
        get { self[SbMessagesKey.self] }
        set { self[SbMessagesKey.self] = newValue }
    }

    /// The app setting „Bewegung immer reduzieren“ (D46); SebaroAppRoot provides it from `sb-motion`.
    var sbReduceMotionSetting: Bool {
        get { self[SbReduceMotionSettingKey.self] }
        set { self[SbReduceMotionSettingKey.self] = newValue }
    }
}

/// Reads the words and the motion wish of the environment; used by every part.
struct SbContext: DynamicProperty {
    @Environment(\.sbMessages) private var custom
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.sbReduceMotionSetting) private var appReduce
    @Environment(\.sebaroTone) var tone
    @Environment(\.colorScheme) var scheme

    var messages: SbMessages { custom ?? SbMessages.forLanguage(locale.identifier) }
    /// The system's „Bewegung reduzieren“ or the app setting (spec/03 §13).
    var reduceMotion: Bool { systemReduce || appReduce }
    var currentLocale: Locale { locale }
}

// MARK: - Tone-aware roles the generated file does not derive

public extension SebaroTone {
    /// The 2 pt layer line (D46): ink by day, border-strong by night, of this tone (TOKEN-CONTRACT: the CSS line
    /// colour is var(--sb-color-text) / var(--sb-color-border-strong), which the warm tone replaces). For the cool
    /// tone this is exactly `SebaroX.layerLineColor`.
    var layerLine: Color {
        switch self {
        case .cool:
            return SebaroX.layerLineColor
        case .warm:
            #if canImport(UIKit)
            let day = UIColor(text), night = UIColor(borderStrong)
            return Color(uiColor: UIColor { traits in
                (traits.userInterfaceStyle == .dark ? night : day).resolvedColor(with: traits)
            })
            #else
            return SebaroX.layerLineColor
            #endif
        }
    }
}

// MARK: - Motion (D46 (4), D80)

public extension AnyTransition {
    /// How new content enters (spec/03 §13): from below over `SebaroX.enterDistance` with opacity; with reduced
    /// motion only the fade. Pair it with `SebaroMotion.easingEmphasized.animation(duration: durationLong)`.
    static func sbEnter(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .offset(y: SebaroX.enterDistance).combined(with: .opacity)
    }
}

public extension SebaroMotion {
    /// The animation of an entry (emphasized, 200 ms); with reduced motion the standard fade over
    /// `SebaroX.enterFadeDuration` (200 ms, D102 (52), spec/03 §13.1).
    static func enter(reduceMotion: Bool) -> Animation {
        reduceMotion ? easingStandard.animation(duration: SebaroX.enterFadeDuration)
                     : easingEmphasized.animation(duration: durationLong)
    }
}

// MARK: - Root

/// The root of every sebaro iOS app (the counterpart of `SebaroAppTheme` in Compose, spec/08 §2.2): registers the
/// bundled fonts, applies the stored Hell/Dunkel choice to the windows of the scene (overrideUserInterfaceStyle,
/// so „Wie das System“ really returns to the system), provides the colour tone and the motion setting, sets the
/// ground and the default text, and installs the navigation bar appearance (D91 I2a).
public struct SebaroAppRoot<Content: View>: View {
    @AppStorage(SbThemeMode.storageKey) private var themeRaw = SbThemeMode.system.rawValue
    @AppStorage(SbSettingKeys.motion) private var motionRaw = ""
    @AppStorage(SbSettingKeys.tone) private var toneRaw = ""
    @Environment(\.colorScheme) private var scheme
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        SebaroFonts.register()
        self.content = content()
    }

    private var mode: SbThemeMode { SbThemeMode(rawValue: themeRaw) ?? .system }
    private var tone: SebaroTone { toneRaw == "warm" ? .warm : .cool }

    public var body: some View {
        content
            .environment(\.sebaroTone, tone)
            .environment(\.sbReduceMotionSetting, motionRaw == "reduce")
            .foregroundStyle(tone.text)
            .tint(Color.sbAccent)
            .background(tone.bg.ignoresSafeArea())
            .onAppear { applyTheme(); SbNavigationBarAppearance.install(scheme: scheme, tone: tone) }
            .onChange(of: themeRaw) { applyTheme() }
            .onChange(of: scheme) { SbNavigationBarAppearance.install(scheme: scheme, tone: tone) }
            .onChange(of: toneRaw) { SbNavigationBarAppearance.install(scheme: scheme, tone: tone) }
    }

    private func applyTheme() {
        #if canImport(UIKit)
        let style: UIUserInterfaceStyle = switch mode {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
        for scene in UIApplication.shared.connectedScenes {
            (scene as? UIWindowScene)?.windows.forEach { $0.overrideUserInterfaceStyle = style }
        }
        #endif
    }
}
