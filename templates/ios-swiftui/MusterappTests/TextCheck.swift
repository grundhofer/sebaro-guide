import SebaroDesign
import SwiftUI
import UIKit

/// The text check of every screenshot case (ZUG-09: nothing cut, at the default size and at AX5).
///
/// SwiftUI has no layout tree a test can read, so the check works on the accessibility tree, which SwiftUI builds
/// from what it laid out. For every text element (trait „static text“ or „header“, not a button):
///
/// - **too high**: the element's words, set at the smallest size any text role of sebaro has at the case's type size
///   and wrapped at its width, need more height than the element has. A text in a larger role needs
///   even more, so this never accuses a text that fits; it finds a text cut to fewer lines than it has, a fixed height
///   that is too small, and a one-line limit on a sentence. It does not find a text cut by a few letters.
/// - **outside**: the element reaches past the window's left or right edge and no sideways scroll view holds it, or
///   past the bottom edge and no vertical scroll view holds it (a dialog at AX5 that cannot scroll).
///
/// What it does not see: a single line that a parent cuts (SwiftUI keeps a text at least one line high, so its own
/// frame stays whole and only the parent's clip cuts it), buttons and rows (VoiceOver reads their words as one label, so their parts have no frames of
/// their own), text that another part covers instead of cutting, text a part takes out of the tree, a value scrolling
/// in a one-line field (EIN-01 wants that), and an ellipsis drawn into a text (the label is always whole).
enum TextCheck {
    /// A known, explained exception: an element it matches is not reported, and the number of elements with a
    /// finding that match it must lie in `count`, so a stale exception fails too.
    struct Exception {
        let reason: String
        let count: ClosedRange<Int>
        let matches: (AxNode) -> Bool

        init(reason: String, count: Int, matches: @escaping (AxNode) -> Bool) {
            self.init(reason: reason, count: count...count, matches: matches)
        }

        init(reason: String, count: ClosedRange<Int>, matches: @escaping (AxNode) -> Bool) {
            self.reason = reason
            self.count = count
            self.matches = matches
        }
    }

    /// The title of a system navigation bar (MOB-05: the bar is the system's). It keeps its size at every text size
    /// and cuts a long title with „…“ at AX5; VoiceOver reads it whole. The app cannot reach it. Applied only at AX5
    /// (a bar title cut at the default size still fails); 0 to 3 bars per window (a sheet over a screen has two), and
    /// a short title that fits is not counted, so the lower end is 0.
    @MainActor
    static func navigationBarTitle(in window: UIWindow) -> Exception {
        func bars(_ view: UIView) -> [UIView] {
            ((view is UINavigationBar && !view.isHidden) ? [view] : []) + view.subviews.flatMap(bars)
        }
        let frames = bars(window).map { $0.convert($0.bounds, to: nil) }
        return Exception(reason: "the system navigation bar's title keeps its size at AX5", count: 0...3) { node in
            node.traits.contains(.header) && frames.contains { $0.insetBy(dx: -1, dy: -1).contains(node.frame) }
        }
    }

    /// The findings of one window, measured in its topmost sheet or dialog if one is open (what VoiceOver can
    /// reach); an empty tree is a finding too (a case that measures nothing proves nothing).
    @MainActor
    static func run(_ hosted: Hosted, category: UIContentSizeCategory, exceptions: [Exception] = []) -> [String] {
        let nodes = hosted.topNodes
        let texts = nodes.filter {
            ($0.traits.contains(.staticText) || $0.traits.contains(.header)) && !$0.traits.contains(.button) && !$0.label.isEmpty
        }
        guard !texts.isEmpty else { return ["no text element measured"] }
        let font = measureFont(category)
        let scrollers = scrollFrames(hosted.window)
        var findings: [(node: AxNode, problems: [String])] = []
        let bounds = hosted.window.bounds
        for node in texts {
            let f = node.frame
            var problems: [String] = []
            let needed = (node.label as NSString).boundingRect(
                with: CGSize(width: max(f.width, 1), height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil).height
            if needed > f.height + 1 {
                problems.append("too high: needs \(Int(needed.rounded(.up))) pt, has \(Int(f.height))")
            }
            let sideways = scrollers.first { $0.horizontal && $0.holds(f) }
            if (f.minX < bounds.minX - 1 || f.maxX > bounds.maxX + 1) && sideways == nil {
                problems.append("outside the window sideways")
            }
            // an element in a sideways scroll view stands where that view stands once it is scrolled to
            let probe = sideways.map { CGRect(x: $0.frame.midX, y: f.minY, width: 0, height: f.height) } ?? f
            if (f.maxY > bounds.maxY + 1 || f.minY < bounds.minY - 1)
                && !scrollers.contains(where: { !$0.horizontal && $0.holds(probe) }) {
                problems.append("outside the window and in no scroll view (scroll views: "
                                + scrollers.map { "\($0.frame.integral) content \($0.content.integral)" }.joined(separator: ", ") + ")")
            }
            if !problems.isEmpty { findings.append((node, problems)) }
        }
        var report: [String] = []
        for exception in exceptions {
            let hit = findings.filter { exception.matches($0.node) }
            if !exception.count.contains(hit.count) {
                report.append("exception „\(exception.reason)“ matched \(hit.count) elements, expected \(exception.count): "
                              + hit.map { describe($0) }.joined(separator: "; "))
            }
            findings.removeAll { exception.matches($0.node) }
        }
        return report + findings.map(describe)
    }

    private static func describe(_ finding: (node: AxNode, problems: [String])) -> String {
        "„\(finding.node.label)“ at \(finding.node.frame.integral): " + finding.problems.joined(separator: "; ")
    }

    /// sebaro's roles with their size and the text style Dynamic Type scales them by (SebaroTokens.swift).
    static let roles: [(size: CGFloat, style: UIFont.TextStyle)] = [
        (32, .largeTitle), (24, .title1), (20, .title3), (16, .body), (14, .subheadline), (14, .caption1),
        (14, .callout), (12, .caption1),
    ]

    /// sebaro Sans 400 at the smallest size any role has at the case's type size: each role scales by its own text
    /// style, so at AX5 the smallest is not always label-small.
    static func measureFont(_ category: UIContentSizeCategory) -> UIFont {
        let traits = UITraitCollection(preferredContentSizeCategory: category)
        let size = roles.map { UIFontMetrics(forTextStyle: $0.style).scaledValue(for: $0.size, compatibleWith: traits) }.min() ?? 12
        let face = SebaroTextStyle.labelSmall.resolve(.light)
        return SebaroFonts.face(family: face.family, weight: 400).flatMap { UIFont(name: $0.postScriptName, size: size) }
            ?? UIFont.systemFont(ofSize: size)
    }

    struct ScrollFrame {
        let frame: CGRect
        let content: CGRect
        let horizontal: Bool

        /// The element lies in the scroll view's band and inside its content, so scrolling brings it into view.
        func holds(_ f: CGRect) -> Bool {
            horizontal
                ? f.midY >= frame.minY && f.midY <= frame.maxY && f.minX >= content.minX - 1 && f.maxX <= content.maxX + 1
                : f.midX >= frame.minX && f.midX <= frame.maxX && f.minY >= content.minY - 1 && f.maxY <= content.maxY + 1
        }
    }

    @MainActor
    static func scrollFrames(_ window: UIWindow) -> [ScrollFrame] {
        func all(_ view: UIView) -> [UIScrollView] {
            ((view as? UIScrollView).map { [$0] } ?? []) + view.subviews.flatMap(all)
        }
        return all(window).flatMap { s -> [ScrollFrame] in
            let frame = s.convert(s.bounds, to: nil)
            let origin = CGPoint(x: frame.minX - s.contentOffset.x - s.adjustedContentInset.left,
                                 y: frame.minY - s.contentOffset.y - s.adjustedContentInset.top)
            let content = CGRect(origin: origin,
                                 size: CGSize(width: s.contentSize.width + s.adjustedContentInset.left + s.adjustedContentInset.right,
                                              height: s.contentSize.height + s.adjustedContentInset.top + s.adjustedContentInset.bottom))
            var result: [ScrollFrame] = []
            // a scroll view under the bars scrolls through its insets too
            if content.width > s.bounds.width + 1 { result.append(ScrollFrame(frame: frame, content: content, horizontal: true)) }
            if content.height > s.bounds.height + 1 { result.append(ScrollFrame(frame: frame, content: content, horizontal: false)) }
            return result
        }
    }
}
