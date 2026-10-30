import SebaroDesign
import SwiftUI
import XCTest
@testable import Musterapp

/// Checks the text check itself: deliberately cut fixtures must fail, a long scrolling list must pass.
@MainActor
final class TextCheckTests: XCTestCase {
    private let sentence = "Ein Satz, der in seinem Rahmen keinen Platz hat und darum abgeschnitten wird."

    private func findings(_ view: some View, look: Look = Look(), exceptions: [TextCheck.Exception] = []) -> [String] {
        let hosted = Hosted(view, look: look)
        defer { hosted.close() }
        return TextCheck.run(hosted, category: look.category, exceptions: exceptions)
    }

    func testTextCutByAFixedFrameFails() {
        let result = findings(Text(sentence).sbFont(.body).frame(width: 160, height: 24, alignment: .topLeading).clipped())
        XCTAssertEqual(result.count, 1, "\(result)")
        XCTAssertTrue(result.first?.contains("too high") ?? false, "\(result)")
    }

    func testOneLineLimitOnASentenceFails() {
        let result = findings(Text(sentence).sbFont(.body).lineLimit(1).frame(width: 200))
        XCTAssertEqual(result.count, 1, "\(result)")
    }

    func testTextCutAtAX5Fails() {
        // fits at the default size, cut at AX5: the frame keeps the default height of two lines
        let view = Text("Ein Satz mit sieben kurzen Wörtern darin.").sbFont(.body).frame(width: 300, height: 48).clipped()
        XCTAssertEqual(findings(view), [])
        XCTAssertEqual(findings(view, look: Look(typeSize: .accessibility5)).count, 1)
    }

    func testTextPushedOutOfTheWindowFails() {
        let result = findings(Text("Weit draußen").sbFont(.body).fixedSize().offset(x: 420))
        XCTAssertTrue(result.contains { $0.contains("outside the window sideways") }, "\(result)")
    }

    func testTextBelowTheWindowWithoutScrollingFails() {
        let view = VStack(spacing: 0) {
            Color.clear.frame(height: 900)
            Text("Unten").sbFont(.body)
        }
        let result = findings(view)
        XCTAssertTrue(result.contains { $0.contains("in no scroll view") }, "\(result)")
    }

    func testNoTextFails() {
        XCTAssertEqual(findings(Color.clear), ["no text element measured"])
    }

    func testAnExceptionWithTheWrongCountFails() {
        let cut = Text(sentence).sbFont(.body).frame(width: 160, height: 24).clipped()
        let right = TextCheck.Exception(reason: "test", count: 1) { $0.label == self.sentence }
        XCTAssertEqual(findings(cut, exceptions: [right]), [])
        let wrong = TextCheck.Exception(reason: "test", count: 2) { $0.label == self.sentence }
        XCTAssertEqual(findings(cut, exceptions: [wrong]).count, 1)
    }

    func testThirtyRowsInAScrollViewPass() {
        let view = ScrollView {
            VStack(alignment: .leading, spacing: SebaroSpace.s4) {
                ForEach(1...30, id: \.self) { i in Text("Zeile \(i): \(self.sentence)").sbFont(.body) }
            }
            .padding(SebaroSpacing.gutter)
        }
        XCTAssertEqual(findings(view), [])
        XCTAssertEqual(findings(view, look: Look(typeSize: .accessibility5, size: Look.small)), [])
    }
}
