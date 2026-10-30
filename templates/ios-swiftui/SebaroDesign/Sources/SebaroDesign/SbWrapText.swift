import CoreFoundation
import Foundation
import SwiftUI

// MARK: - Text that wraps and hyphenates only an overlong word (D99 (1), D100 (6), D101 (6); spec/08 §16, spec/12 §17)

/// One run of a wrapping text: `words` (prose: breaks between words; a single word wider than its line breaks with a
/// hyphen), `name` (a person's or a product's name, an identifier or code: never a hyphen; when it alone is wider
/// than the line it breaks between letters), `fileName` (breaks only after - . _ / and without a hyphen, `sbFileNameBreaks`).
public enum SbTextPart: Hashable, Sendable {
    case words(String)
    case name(String)
    case fileName(String)

    var plain: String {
        switch self {
        case .words(let s), .name(let s), .fileName(let s): return s
        }
    }
}

/// The pure part of `SbWrapText`: which words may be hyphenated and where the soft hyphens go.
public enum SbHyphenation {
    /// The soft hyphen U+00AD: a break that draws „-“ only when the line breaks there.
    static let softHyphen: Character = "\u{00AD}"

    /// The words of prose as the line breaker sees them (the Compose `sbWidestWord`): a word ends at white space or after
    /// a hyphen before a letter („Werbe-ID“ may break after „Werbe-“, „2026-10“ not); U+00A0 joins („60 %“).
    public static func words(_ text: String) -> [String] {
        text.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }).flatMap { piece -> [String] in
            var out: [String] = []
            var current = ""
            let chars = Array(piece)
            for (i, ch) in chars.enumerated() {
                current.append(ch)
                if ch == "-", i + 1 < chars.count, chars[i + 1].isLetter {
                    out.append(current)
                    current = ""
                }
            }
            if !current.isEmpty { out.append(current) }
            return out
        }
    }

    /// `word` with a soft hyphen at every hyphenation point of the language (Core Foundation's dictionaries; „Abbrechen“ →
    /// „Ab·bre·chen“); a word the dictionary cannot divide („Blitz“) stays whole. Without a dictionary for the language
    /// (Japanese, Chinese, Korean), between any two letters with at least two letters on each side.
    public static func softHyphenated(_ word: String, locale: Locale) -> String {
        // the dictionary sees the letters only: quotes and punctuation around the word („…“) stay outside
        let lead = word.prefix { !$0.isLetter }
        let trail = word.reversed().prefix { !$0.isLetter }
        guard lead.count + trail.count < word.count else { return word }
        let core = String(word.dropFirst(lead.count).dropLast(trail.count))
        return String(lead) + hyphenatedCore(core, locale: locale) + String(trail.reversed())
    }

    private static func hyphenatedCore(_ word: String, locale: Locale) -> String {
        let ns = word as NSString
        let length = ns.length
        guard length >= 4 else { return word }
        var points: [Int] = []
        let cfLocale = locale as CFLocale
        let dictionary = CFStringIsHyphenationAvailableForLocale(cfLocale)
        if dictionary {
            var before = length
            while before > 0 {
                let at = CFStringGetHyphenationLocationBeforeIndex(ns as CFString, before, CFRange(location: 0, length: length),
                                                                   0, cfLocale, nil)
                if at == kCFNotFound || at <= 0 || at >= before { break }
                points.append(at)
                before = at
            }
        }
        points = points.filter { $0 >= 2 && $0 <= length - 2 }
        if points.isEmpty && dictionary { return word }
        if points.isEmpty {
            // between letters, by grapheme, never next to punctuation
            let chars = Array(word)
            var out = ""
            for (i, ch) in chars.enumerated() {
                if i >= 2, i <= chars.count - 2, ch.isLetter, chars[i - 1].isLetter { out.append(softHyphen) }
                out.append(ch)
            }
            return out
        }
        let result = NSMutableString(string: ns)
        for p in points.sorted(by: >) { result.insert(String(softHyphen), at: p) }
        return result as String
    }

    /// The text as drawn: prose with soft hyphens only in the words of `overlong`, names as written, file names with
    /// their breaks after - . _ /.
    public static func shown(_ parts: [SbTextPart], overlong: Set<String>, locale: Locale) -> String {
        parts.map { part -> String in
            switch part {
            case .name(let s): return s
            case .fileName(let s): return sbFileNameBreaks(s)
            case .words(let s):
                guard !overlong.isEmpty else { return s }
                // keep every space and line break as written; replace only the overlong words
                var out = ""
                var word = ""
                func flush() {
                    if !word.isEmpty {
                        out += words(word).map { overlong.contains($0) ? softHyphenated($0, locale: locale) : $0 }.joined()
                        word = ""
                    }
                }
                for ch in s {
                    if ch == " " || ch == "\n" || ch == "\t" { flush(); out.append(ch) } else { word.append(ch) }
                }
                flush()
                return out
            }
        }.joined()
    }

    /// The candidates for a hyphen: every distinct word of the prose runs.
    public static func candidates(_ parts: [SbTextPart]) -> [String] {
        var seen = Set<String>()
        return parts.flatMap { part -> [String] in
            if case .words(let s) = part { return words(s) }
            return []
        }.filter { seen.insert($0).inserted }
    }

    /// The texts `SbWrapText` offers its layout. `words` = the candidates that have a hyphenation point (a word without
    /// one, „Tag“, „Blitz“, looks the same either way); `sets[i]` = the words (indices into `words`) that carry soft
    /// hyphens in `texts[i]`. `sets[0]` is empty (the plain text); then the 1, 2, … words with the most characters (the
    /// set of overlong words is always the widest ones, and their order by width is that by characters but for close
    /// cases); then each word alone that is not yet a set of its own, so a single overlong word is always exact.
    static func variants(_ parts: [SbTextPart], locale: Locale) -> (words: [String], sets: [Set<Int>], texts: [String]) {
        let words = candidates(parts).filter { softHyphenated($0, locale: locale) != $0 }
        let order = words.indices.sorted { words[$0].count != words[$1].count ? words[$0].count > words[$1].count : $0 < $1 }
        var sets: [Set<Int>] = [[]]
        for k in order.indices { sets.append(Set(order.prefix(k + 1))) }
        for i in words.indices where !sets.contains([i]) { sets.append([i]) }
        let texts = sets.map { set in shown(parts, overlong: Set(set.map { words[$0] }), locale: locale) }
        return (words, sets, texts)
    }
}

/// Text that wraps between words onto as many lines as its place allows and is never clipped or cut with an ellipsis
/// (D99 (1)), the counterpart of the Compose `SbWrapText`. Only a word wider than the whole line is hyphenated, at the
/// hyphenation points of the language (D101); the other words keep whole (Compose switches the whole text to
/// `Hyphens.Auto` then);
/// names and code (`.name`) break between letters without a hyphen; file names (`.fileName`) break after - . _ /
/// without a hyphen (D100 (6), D101 (6)). VoiceOver reads the text as written.
///
/// `style` is the type role (`.sbFont`); nil = the font the parent sets (a button style). The choice is made in the
/// layout (`SbHyphenLayout`), at the width the text is offered, from hidden one-line probes of its words in the same
/// font: no state and no second pass, so a parent that measures several candidates (`ViewThatFits`) sees the same text
/// that is drawn. Not for a field's value (it scrolls, D110, D111 (4)) or a one-line placeholder (D111 (3)), and not
/// for identifiers that never break („DAT-02“, „1.4.0“, D80).
public struct SbWrapText: View {
    let parts: [SbTextPart]
    let style: SebaroTextStyle?
    let center: Bool
    private var context = SbContext()

    /// Prose (`.words`).
    public init(_ text: String, style: SebaroTextStyle? = nil, center: Bool = false) {
        self.init(parts: [.words(text)], style: style, center: center)
    }

    public init(parts: [SbTextPart], style: SebaroTextStyle? = nil, center: Bool = false) {
        self.parts = parts
        self.style = style
        self.center = center
    }

    /// A name, identifier or code: never hyphenated (`.name`).
    public static func name(_ text: String, style: SebaroTextStyle? = nil) -> SbWrapText {
        SbWrapText(parts: [.name(text)], style: style)
    }

    /// A file name or path: breaks after - . _ / only (`.fileName`).
    public static func fileName(_ text: String, style: SebaroTextStyle? = nil) -> SbWrapText {
        SbWrapText(parts: [.fileName(text)], style: style)
    }

    public var body: some View {
        let plain = parts.map(\.plain).joined()
        let v = SbHyphenation.variants(parts, locale: context.currentLocale)
        SbHyphenLayout(sets: v.sets) {
            ForEach(Array(v.texts.enumerated()), id: \.offset) { _, s in text(s) }
            // the words, measured on one line in the same font, never drawn
            ForEach(v.words, id: \.self) { word in Text(word).lineLimit(1).hidden() }
        }
        .modifier(SbOptionalFont(style: style))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(plain))
    }

    private func text(_ s: String) -> some View {
        Text(s)
            .multilineTextAlignment(center ? .center : .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// The layout of `SbWrapText`: one text per entry of `sets` (`SbHyphenation.variants`; 0 the plain text), then one
/// hidden probe per word that can be hyphenated. At the offered width the words whose probe is wider than that width
/// are the overlong ones, and the text with soft hyphens in exactly those words is laid out (`pick`); the others are
/// placed off screen. It never reports a width wider than the one offered (a `Text` with an overlong word reports the
/// word's width).
struct SbHyphenLayout: Layout {
    let sets: [Set<Int>]

    static func overlong(wordWidths: [CGFloat], width: CGFloat) -> Bool { wordWidths.contains { $0 > width + 0.5 } }

    /// The text for `width`: none overlong = the plain one; else the one whose set is exactly the overlong words, and
    /// when the order by characters missed it, the smallest set that holds them all.
    static func pick(wordWidths: [CGFloat], width: CGFloat, sets: [Set<Int>]) -> Int {
        let over = Set(wordWidths.indices.filter { overlong(wordWidths: [wordWidths[$0]], width: width) })
        guard !over.isEmpty else { return 0 }
        if let exact = sets.firstIndex(of: over) { return exact }
        return sets.indices.filter { sets[$0].isSuperset(of: over) }.min { sets[$0].count < sets[$1].count } ?? 0
    }

    private func chosen(_ width: CGFloat?, _ subviews: Subviews) -> Int {
        guard let width, width.isFinite, subviews.count > sets.count else { return 0 }
        let words = subviews.dropFirst(sets.count).map { $0.sizeThatFits(.unspecified).width }
        return Self.pick(wordWidths: words, width: width, sets: sets)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let size = subviews[chosen(proposal.width, subviews)].sizeThatFits(proposal)
        guard let w = proposal.width, w.isFinite else { return size }
        return CGSize(width: min(size.width, w), height: size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let pick = chosen(bounds.width, subviews)
        for (i, s) in subviews.enumerated() {
            if i == pick {
                s.place(at: bounds.origin, proposal: ProposedViewSize(width: bounds.width, height: bounds.height))
            } else {
                s.place(at: CGPoint(x: -100_000, y: bounds.minY), proposal: .zero)
            }
        }
    }
}

struct SbOptionalFont: ViewModifier {
    let style: SebaroTextStyle?
    func body(content: Content) -> some View {
        if let style { content.sbFont(style) } else { content }
    }
}

/// A width read by a background `GeometryReader` (the largest of several).
struct SbLineWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

