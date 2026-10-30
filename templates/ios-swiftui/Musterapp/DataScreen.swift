import SebaroDesign
import SwiftUI

// Every value on this screen is invented (BEL-09: „Beispieldaten“ under the title).
private let today = Day(2026, 10, 10)
private let expenses = [42.90, 1249.00, 12.50, 89.99]
private let expenseDays = [3, 7, 8, 9]
private let steps: [Double] = [6200, 8400, 7100, 9800, 5400, 10200, 7600]
private let weeks: [Double?] = [5.2, 5.8, nil, 6.1, 6.6, 6.4]
private let weeksOther: [Double?] = [6.8, 6.5, 6.9, 7.0, 6.2, 6.7]
private let bins: [Double] = [3, 9, 14, 7, 2]
private let deviations: [Double] = [12, -8, 3, -15]
private let glasses: [[Double?]] = [[4, 6, 8, 5, 7, 3, 2], [6, 8, 8, 7, 5, 4, 6], [7, 8, 5, 6, nil, nil, nil]]

/// Top-level „Daten“: the kinds of data of the guide's page daten.html, each through its sebaro part: numbers, money
/// and units (TXT-04, TXT-12, TXT-13, FAR-14), time (TXT-04), state (STA-01, STA-02, STA-09), progress (STA-06),
/// categories and marks (STA-04, FAR-12), technical values (SCH-01, TXT-08, ZUG-09), a sortable table with a sum
/// (DAT-14), charts (DAT-04, DAT-10, DAT-11, DAT-12, DAT-03) and a rating (DAT-09). No primary action: nothing to do
/// here.
struct DataScreen: View {
    let tabs: SbTabBar
    @Environment(\.words) private var words
    @Environment(\.sebaroTone) private var tone
    @State private var sortIndex: Int? = 2
    @State private var descending = true

    var body: some View {
        SbScreen(tabs: tabs) {
            ScrollView {
                VStack(alignment: .leading, spacing: SebaroSpacing.section) {
                    SbDemoMarker(words("demo.marker"))
                    numbers
                    time
                    state
                    categories
                    technical
                    table
                    charts
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SebaroSpacing.gutter)
                .padding(.top, SebaroSpace.s4)
                .padding(.bottom, SebaroSpace.s8)
            }
        }
        // without a product id the export has no sign tile, so the top-level title stands inline (see README,
        // „Lücken der Vorlage“); a product uses .sbTopLevelNavigation(title:product:) with its tile
        .sbNavigationTitle(words("data.title"))
    }

    /// A section of this screen: its title (a heading for VoiceOver) over its content.
    private func section(_ key: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: SebaroSpace.s4) {
            Text(words(key)).sbFont(.title).accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)
            content()
        }
    }

    private var numbers: some View {
        section("data.numbers") {
            SbBigNumber(words.money(expenses.reduce(0, +)), label: words("data.expenses.month"))
            SbMetaList([SbMetaItem(words("data.integer"), value: words.count(12)),
                        SbMetaItem(words("data.fraction"), value: words("fraction", words.count(5), words.count(8))),
                        SbMetaItem(words("data.decimal"), value: words.decimal(3.75, digits: 2)),
                        SbMetaItem(words("data.large"), value: words.count(10_000)),
                        SbMetaItem(words("data.percent"), value: words.percent(0.6)),
                        SbMetaItem(words("data.money"), value: words.money(1249)),
                        SbMetaItem(words("data.per.month"), value: words("per.month", words.money(0.99))),
                        SbMetaItem(words("data.unit"), value: words("unit.km", words.decimal(2.5, digits: 1))),
                        SbMetaItem(words("data.approx"), value: words("approx", words.count(40))),
                        SbMetaItem(words("data.rank"), value: words("rank", words.count(3), words.count(12)))],
                       labels: true)
            SbTags {
                SbSignedNumber(words("signed.plus", words.percent(0.125, digits: 1)), sign: .plus)
                SbSignedNumber(words("signed.minus", words.percent(0.03, digits: 1)), sign: .minus)
                SbSignedNumber(words("signed.zero", words.percent(0, digits: 1)), sign: .zero)
            }
        }
    }

    private var time: some View {
        section("data.time") {
            SbMetaList([SbMetaItem(words("data.day"), value: words.dayDate(today)),
                        SbMetaItem(words("data.date.note"), value: words.noteDate(today)),
                        SbMetaItem(words("data.date.short"), value: words.shortDate(today)),
                        SbMetaItem(words("data.clock"), value: SbTimeOfDay(8, 12).text),
                        SbMetaItem(words("data.range"), value: words("range", SbTimeOfDay(8).text, SbTimeOfDay(22).text)),
                        SbMetaItem(words("data.span"),
                                   value: words("range", words.shortDate(today), words.shortDate(today.adding(days: 4)))),
                        SbMetaItem(words("data.duration"), value: words("duration", 1, 20)),
                        SbMetaItem(words("data.remaining"), value: words("remaining.minutes", 3))],
                       labels: true)
        }
    }

    private var state: some View {
        section("data.state") {
            VStack(alignment: .leading, spacing: SebaroSpace.s3) {
                SbStatus(.info)
                SbStatus(.neutral)
                SbStatus(.success)
                SbStatus(.danger)
                SbStatus(.warning, word: words("state.conflict"), glyph: .warning)
                SbStatus(.neutral, word: words("state.count.open", words.count(2)), glyph: .pending)
            }
            SbProgressBar(0.6, label: words("data.import"), valueText: words.percent(0.6))
            SbProgressRing(0.6, label: words("data.goal.day"), valueText: words.percent(0.6))
            SbSteps([words("data.step.1"), words("data.step.2"), words("data.step.3")], current: 1)
        }
    }

    private var categories: some View {
        section("data.categories") {
            SbTags {
                SbTag(words("data.tag.1"))
                SbTag(words("data.tag.2"))
            }
            SbTags {
                ForEach(1...3, id: \.self) { i in SbCategory(words("data.category.\(i)"), tone: i) }
            }
            let sentence = words("data.mark.sentence")
            let word = words("data.mark.word")
            let marks: [Range<Int>] = sentence.range(of: word, options: .caseInsensitive).map {
                let start = sentence.distance(from: sentence.startIndex, to: $0.lowerBound)
                return [start..<(start + word.count)]
            } ?? []
            SbMarkedText(sentence, marks: marks)
        }
    }

    private var technical: some View {
        section("data.technical") {
            labelled("data.id") { Text(verbatim: "E-0042").sbFont(.code) }
            labelled("data.version") { Text(verbatim: "1.4.0").sbFont(.code) }
            labelled("data.file") { SbFileNameText(words("sample.file.name")) }
            SbCodeBlock("{\n  \"id\": \"E-0042\",\n  \"done\": true\n}", language: words("code.language.json"))
        }
    }

    private func labelled(_ key: String, @ViewBuilder value: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: SebaroSpace.s1) {
            SbWrapText(words(key), style: .label).foregroundStyle(tone.textMuted)
            value()
        }
    }

    private var table: some View {
        section("data.table") {
            let rows: [[SbTableCell]] = expenses.indices.map { i in
                let day = Day(2026, 10, expenseDays[i])
                return [SbTableCell(words("data.expense.\(i + 1)")),
                        SbTableCell(words.noteDate(day), date: day.date),
                        SbTableCell(words.money(expenses[i]), number: expenses[i])]
            }
            SbSortableTable(words("data.table.caption"),
                            columns: [SbTableColumn(words("data.col.item")),
                                      SbTableColumn(words("data.col.date"), kind: .date),
                                      SbTableColumn(words("data.col.amount"), kind: .number)],
                            rows: rows, sortIndex: sortIndex, sortDescending: descending, rowHeads: true,
                            sum: SbTableSum(words("data.sum"), values: [2: words.money(expenses.reduce(0, +))])) {
                sortIndex = $0
                descending = $1
            }
        }
    }

    private var charts: some View {
        let m = words.messages
        let weekStarts = weeks.indices.map { today.adding(days: -7 * (weeks.count - 1 - $0)) }
        // one month name over its weeks
        var axis: [SbAxisLabel] = []
        for start in weekStarts {
            let name = words.month(start)
            if let last = axis.last, last.text == name {
                axis[axis.count - 1] = SbAxisLabel(name, span: last.span + 1)
            } else {
                axis.append(SbAxisLabel(name))
            }
        }
        return section("data.charts") {
            SbStats([SbStatItem(words("data.stat.steps"), value: words.count(7_814), spark: steps),
                     SbStatItem(words("data.stat.streak"), value: words("days", 12))])
            SbBarChart(steps.indices.map { i in
                SbBar(m.weekdays[i], value: steps[i], valueText: words.count(Int(steps[i])), current: i == steps.count - 1)
            }, caption: words("data.bar.caption", words.count(8_000)), target: SbChartValue(8_000, text: words.count(8_000)))
            SbLineChart(weeks.indices.map { i in
                SbLinePoint(m.weekFrom(words.shortDate(weekStarts[i])), value: weeks[i],
                            valueText: weeks[i].map { words.decimal($0, digits: 1) } ?? m.noValue)
            }, caption: words("data.line.caption"), axis: axis)
            SbSeriesChart([SbSeries(words("data.series.1"), points: weeks.map { $0.map { SbChartValue($0, text: words.decimal($0, digits: 1)) } }),
                           SbSeries(words("data.series.2"), points: weeksOther.map { $0.map { SbChartValue($0, text: words.decimal($0, digits: 1)) } })],
                          labels: weekStarts.map { m.weekFrom(words.shortDate($0)) },
                          caption: words("data.series.caption"), axis: axis)
            SbShareRows(zip([1, 2, 3], [46.0, 31, 23]).map { i, v in
                SbShareRow(words("data.share.\(i)"), value: v, valueText: words.percent(v / 100), current: i == 1)
            }, caption: words("data.share.caption"))
            SbHistogram(bins.indices.map { i in
                SbBin(words("range", words.count(10 * i), words.count(10 * (i + 1))), count: bins[i],
                      countText: words("people", Int(bins[i])))
            }, edges: (0...bins.count).map { words.count(10 * $0) }, unit: words("data.histogram.unit"),
                        caption: words("data.histogram.caption"))
            SbDeviationChart(deviations.indices.map { i in
                let v = deviations[i]
                let text = v > 0 ? words("signed.plus", words.percent(v / 100)) : words("signed.minus", words.percent(-v / 100))
                return SbDeviation(words("data.deviation.\(i + 1)"), value: v, valueText: text)
            }, midpoint: words("data.deviation.mid"), caption: words("data.deviation.caption"),
                             less: words("data.deviation.less"), more: words("data.deviation.more"))
            SbHeatmap(glasses.indices.map { w in
                let start = Day(2026, 9, 28).adding(days: 7 * w)
                return SbHeatmapWeek(start: words.shortDate(start), days: glasses[w].indices.map { d in
                    let value = glasses[w][d]
                    let isToday = start.adding(days: d) == today
                    if value == nil && !isToday { return nil }
                    return SbHeatmapDay(words.dayDate(start.adding(days: d)), value: value,
                                        valueText: value.map { words("glasses", Int($0)) } ?? m.noValue, today: isToday)
                })
            }, classes: [SbScaleClass(from: 0, label: words("range", words.count(0), words.count(3))),
                         SbScaleClass(from: 4, label: words("range", words.count(4), words.count(5))),
                         SbScaleClass(from: 6, label: words("range", words.count(6), words.count(7))),
                         SbScaleClass(from: 8, label: words("data.heatmap.top", words.count(8)))],
                      caption: words("data.heatmap.caption"), weekdays: m.weekdays)
            SbGoalRing(done: 5, total: 8, caption: words("data.goal.caption"))
            SbRating(4.2, count: 38)
        }
    }
}
