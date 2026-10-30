import SebaroDesign
import SwiftUI
import XCTest
@testable import Musterapp

/// Every screen and dialog of the app, hosted as the app composes it, in light and dark, at the default type size and
/// at AX5 (`accessibilityExtraExtraExtraLarge`), in a 393 × 852 and a 320 × 568 pt window. Each case first finds a
/// word that proves its screen or dialog is there, then runs the text check (TextCheck). With `SB_SHOTS` (pass
/// `TEST_RUNNER_SB_SHOTS=<folder>` to xcodebuild) it writes `<case>-<look>.png`, and for long screens the further
/// pages `<case>-<look>-p2.png` … as they scroll.
@MainActor
final class ScreenshotTests: XCTestCase {
    struct Case {
        let name: String
        /// A word of the case's language that must be on screen once it is set up.
        let proof: (Words) -> String
        let view: (Words) -> AnyView
        /// The label (its start) of the element to activate after the view stands, as VoiceOver's double tap.
        var activate: ((Words) -> String)?
        var pages = false
        /// The case shows a title in the system navigation bar; at AX5 it is an exception (TextCheck.navigationBarTitle).
        var barTitle = true
        /// Known, explained findings of the text check for a look (each with its exact count).
        var exceptions: (Look, Words) -> [TextCheck.Exception] = { _, _ in [] }
    }

    private var shots: URL? {
        ProcessInfo.processInfo.environment["SB_SHOTS"].map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    /// Light and dark × default and AX5 × 393 and 320 pt.
    private var looks: [Look] {
        [UIUserInterfaceStyle.light, .dark].flatMap { style in
            [DynamicTypeSize.large, .accessibility5].flatMap { type in
                [Look.phone, Look.small].map { Look(style: style, typeSize: type, size: $0) }
            }
        }
    }

    private func app(place: Place = .entries, path: [Int] = [], query: String = "", form: FormRequest? = nil,
                     store: EntryStore = .inMemory(), toasts: SbToastState = SbToastState()) -> AnyView {
        AnyView(AppView(store: store, place: place, path: path, query: query, form: form, toasts: toasts))
    }

    private func run(_ c: Case, looks: [Look]? = nil) throws {
        var problems: [String] = []
        for look in looks ?? self.looks {
            let words = Words(language: look.language)
            let hosted = Hosted(c.view(words), look: look)
            if let activate = c.activate { hosted.activate(activate(words)) }
            let proof = c.proof(words)
            let labels = hosted.nodes.map(\.label)
            if !labels.contains(where: { $0.contains(proof) }) {
                problems.append("\(c.name) \(look): „\(proof)“ is not on screen: \(labels)")
            }
            let barTitle = look.typeSize == .accessibility5 && c.barTitle ? [TextCheck.navigationBarTitle(in: hosted.window)] : []
            problems += TextCheck.run(hosted, category: look.category, exceptions: barTitle + c.exceptions(look, words)).map { "\(c.name) \(look): \($0)" }
            if let shots {
                try FileManager.default.createDirectory(at: shots, withIntermediateDirectories: true)
                try XCTUnwrap(hosted.image().pngData()).write(to: shots.appendingPathComponent("\(c.name)-\(look).png"))
                if c.pages, let scroller = hosted.scrollViews.last {
                    var page = 2
                    // the scroll view reaches under the bars; what is visible between them is its height less the insets
                    let inset = scroller.adjustedContentInset
                    let end = scroller.contentSize.height + inset.bottom - scroller.bounds.height
                    let step = (scroller.bounds.height - inset.top - inset.bottom) * 0.85
                    while scroller.contentOffset.y < end - 1 && page <= 40 {
                        let y = min(scroller.contentOffset.y + step, end)
                        scroller.setContentOffset(CGPoint(x: 0, y: y), animated: false)
                        hosted.settle(0.3)
                        try XCTUnwrap(hosted.image(scale: 1).pngData())
                            .write(to: shots.appendingPathComponent("\(c.name)-\(look)-p\(page).png"))
                        page += 1
                    }
                }
            }
            hosted.close()
        }
        XCTAssertEqual(problems, [], problems.joined(separator: "\n"))
    }

    func testList() throws {
        try run(Case(name: "list", proof: { $0("sample.1.title") }, view: { _ in self.app() }, pages: true))
    }

    func testListWarmToneAndEnglish() throws {
        let extra = [Look(style: .light, tone: .warm), Look(style: .dark, tone: .warm),
                     Look(language: "en"), Look(style: .dark, typeSize: .accessibility5, size: Look.small, language: "en")]
        try run(Case(name: "list", proof: { $0("sample.1.title") }, view: { _ in self.app() }), looks: extra)
    }

    func testListEmpty() throws {
        try run(Case(name: "list-empty", proof: { $0("list.empty.title") }, view: { _ in self.app(store: .inMemory([])) }))
    }

    func testListNoHit() throws {
        try run(Case(name: "list-nohit", proof: { $0("list.nohit.text") }, view: { _ in self.app(query: "Zebra") }))
    }

    func testListToast() throws {
        try run(Case(name: "list-toast", proof: { $0("toast.undo") }, view: { words in
            let store = EntryStore.inMemory()
            let toasts = SbToastState()
            let entry = try! XCTUnwrap(store.entry(2))
            store.setHidden(2, true)
            toasts.show(SbToastData(words("list.hidden.toast", entry.title(words)), actionLabel: words("toast.undo")) {
                store.setHidden(2, false)
            })
            return self.app(store: store, toasts: toasts)
        }))
    }

    func testDetail() throws {
        try run(Case(name: "detail", proof: { $0("detail.delete") }, view: { _ in self.app(path: [1]) }, pages: true))
    }

    func testDetailDone() throws {
        try run(Case(name: "detail-done", proof: { $0("state.done") }, view: { _ in self.app(path: [4]) }))
    }

    func testDeleteDialog() throws {
        try run(Case(name: "dialog-delete", proof: { $0("dialog.delete.confirm") }, view: { _ in self.app(path: [1]) },
                     activate: { $0("detail.delete") }, pages: true))
    }

    func testFinishDialog() throws {
        try run(Case(name: "dialog-finish", proof: { $0("dialog.finish.confirm") }, view: { _ in self.app(path: [1]) },
                     activate: { $0("detail.finish") }, pages: true))
    }

    func testFormNew() throws {
        try run(Case(name: "form-new", proof: { $0("form.note.label") }, view: { _ in self.app(form: .new) }, pages: true))
    }

    func testFormTitleMissing() throws {
        try run(Case(name: "form-missing", proof: { $0.messages.fieldMissing($0("form.title.label")) },
                     view: { _ in self.app(form: .new) }, activate: { $0("form.create") }))
    }

    func testFormEditSample() throws {
        try run(Case(name: "form-edit", proof: { $0("demo.marker") }, view: { _ in self.app(form: .edit(1)) }))
    }

    func testTimeSheet() throws {
        try run(Case(name: "time-sheet", proof: { $0.messages.timeChoose }, view: { _ in self.app(form: .new) },
                     activate: { $0("form.remind.label") }))
    }

    func testUnsavedDialog() throws {
        try run(Case(name: "dialog-unsaved", proof: { $0.messages.discard }, view: { words in
            var draft = FormDraft()
            draft.title = words("sample.2.title")
            return AnyView(FormScreen(request: .new, store: .inMemory(), words: words, onClose: {}, draft: draft,
                                      askUnsaved: true))
        }, pages: true))
    }

    /// At AX5 `SbHeatmap` leaves out the weekday heads that would touch (D104 (21)) and keeps them in the
    /// accessibility tree at x = −100000, drawn nowhere: every second one at 393 pt (Di, Do, Sa), four at 320 pt.
    private func leftOutHeatmapHeads(_ look: Look, _ words: Words) -> [TextCheck.Exception] {
        guard look.typeSize == .accessibility5 else { return [] }
        return [TextCheck.Exception(reason: "SbHeatmap: weekday heads left out at AX5",
                                    count: look.size == Look.small ? 4 : 3) {
            words.messages.weekdays.contains($0.label) && $0.frame.minX < -10_000
        }]
    }

    private var dataCase: Case {
        Case(name: "data", proof: { $0("data.numbers") }, view: { _ in self.app(place: .data) }, pages: true,
             exceptions: leftOutHeatmapHeads)
    }

    func testData() throws {
        try run(dataCase)
    }

    func testDataEnglish() throws {
        try run(dataCase, looks: [Look(language: "en"), Look(style: .dark, typeSize: .accessibility5, size: Look.small, language: "en")])
    }

    func testStartError() throws {
        try run(Case(name: "start-error", proof: { $0("start.error.newer") },
                     view: { words in AnyView(StartErrorScreen(error: .newerVersion(3)).language(words)) }, barTitle: false))
    }

    func testSettings() throws {
        try run(Case(name: "settings", proof: { $0("language.system") }, view: { _ in self.app(place: .settings) },
                     pages: true))
    }
}
