import Foundation

// Numbers and dates go through the language's locale (TXT-04, TXT-12, TEC-10), never glued together by hand. Units and
// words come from Localizable.xcstrings; the space between number and unit is U+00A0.

extension Words {
    /// U+202F and U+2009 (narrow spaces some locales use) become U+00A0, as TXT-04 asks.
    private func spaces(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{202F}", with: "\u{00A0}").replacingOccurrences(of: "\u{2009}", with: "\u{00A0}")
    }

    /// Day and month joined by U+00A0 (TXT-04, CHECKS §27.2.4): „10.\u{00A0}Okt.“, „10\u{00A0}Oct“, „Oct\u{00A0}10“, in
    /// whatever order the locale writes them; a year stays apart (only one or two digits count as a day). The month
    /// before the day is tried only when no day stands before a word, so a weekday never joins the day.
    private func dayAndMonth(_ text: String) -> String {
        let text = spaces(text)
        let dayFirst = text.replacing(/(^|[^0-9])([0-9]{1,2}\.?) (\p{L})/) { "\($0.1)\($0.2)\u{00A0}\($0.3)" }
        guard dayFirst == text else { return dayFirst }
        return text.replacing(/(\p{L}\.?) ([0-9]{1,2})([^0-9]|$)/) { "\($0.1)\u{00A0}\($0.2)\($0.3)" }
    }

    func decimal(_ value: Double, digits: Int) -> String {
        spaces(value.formatted(.number.precision(.fractionLength(digits)).locale(locale)))
    }

    /// „60\u{00A0}%“ in every language: the number of the locale, then U+00A0 and the sign (TXT-04; English locales
    /// would write „60%“).
    func percent(_ fraction: Double, digits: Int = 0) -> String {
        decimal(fraction * 100, digits: digits) + "\u{00A0}%"
    }

    func money(_ euros: Double) -> String {
        spaces(euros.formatted(.currency(code: "EUR").locale(locale)))
    }

    /// „10.10.2026“ in German notes, „2026-10-10“ in English (TXT-04); the pattern is a word of the catalog.
    func noteDate(_ day: Day) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = self("date.pattern")
        return f.string(from: day.date)
    }

    /// „Samstag, 10.\u{00A0}Oktober 2026“ / „Saturday 10\u{00A0}October 2026“.
    func dayDate(_ day: Day) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = Calendar(identifier: .gregorian)
        f.setLocalizedDateFormatFromTemplate("EEEEdMMMMyyyy")
        return dayAndMonth(f.string(from: day.date))
    }

    /// „10.\u{00A0}Okt.“ / „10\u{00A0}Oct“.
    func shortDate(_ day: Day) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = Calendar(identifier: .gregorian)
        f.setLocalizedDateFormatFromTemplate("dMMM")
        return dayAndMonth(f.string(from: day.date))
    }

    /// The month's name, „Oktober“ / „October“.
    func month(_ day: Day) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = Calendar(identifier: .gregorian)
        f.setLocalizedDateFormatFromTemplate("LLLL")
        return f.string(from: day.date)
    }
}

/// A calendar day without a time of day („2026-10-20“ in the file).
struct Day: Hashable, Comparable, Codable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    init(_ year: Int, _ month: Int, _ day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    static func today(calendar: Calendar = .current) -> Day {
        let c = calendar.dateComponents([.year, .month, .day], from: Date())
        return Day(c.year ?? 2026, c.month ?? 1, c.day ?? 1)
    }

    var date: Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    func adding(days: Int) -> Day {
        let calendar = Calendar(identifier: .gregorian)
        let moved = calendar.date(byAdding: .day, value: days, to: date) ?? date
        let c = calendar.dateComponents([.year, .month, .day], from: moved)
        return Day(c.year ?? year, c.month ?? month, c.day ?? day)
    }

    static func < (a: Day, b: Day) -> Bool { (a.year, a.month, a.day) < (b.year, b.month, b.day) }

    init(from decoder: Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "no day: \(text)"))
        }
        self.init(parts[0], parts[1], parts[2])
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(format: "%04d-%02d-%02d", year, month, day))
    }
}
