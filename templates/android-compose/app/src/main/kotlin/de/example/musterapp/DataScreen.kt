package de.example.musterapp

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringArrayResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import de.sebaro_ventures.design.SebaroTheme
import de.sebaro_ventures.design.designsystem.SbAxisLabel
import de.sebaro_ventures.design.designsystem.SbBar
import de.sebaro_ventures.design.designsystem.SbBarChart
import de.sebaro_ventures.design.designsystem.SbBigNumber
import de.sebaro_ventures.design.designsystem.SbCategory
import de.sebaro_ventures.design.designsystem.SbChartValue
import de.sebaro_ventures.design.designsystem.SbCodeBlock
import de.sebaro_ventures.design.designsystem.SbColumnKind
import de.sebaro_ventures.design.designsystem.SbDemoMarker
import de.sebaro_ventures.design.designsystem.SbFileNameText
import de.sebaro_ventures.design.designsystem.SbGoalRing
import de.sebaro_ventures.design.designsystem.SbLineChart
import de.sebaro_ventures.design.designsystem.SbLinePoint
import de.sebaro_ventures.design.designsystem.SbMarkedText
import de.sebaro_ventures.design.designsystem.SbMetaItem
import de.sebaro_ventures.design.designsystem.SbMetaList
import de.sebaro_ventures.design.designsystem.SbProgressBar
import de.sebaro_ventures.design.designsystem.SbProgressRing
import de.sebaro_ventures.design.designsystem.SbRating
import de.sebaro_ventures.design.designsystem.SbScreen
import de.sebaro_ventures.design.designsystem.SbShareRow
import de.sebaro_ventures.design.designsystem.SbShareRows
import de.sebaro_ventures.design.designsystem.SbSign
import de.sebaro_ventures.design.designsystem.SbSignedNumber
import de.sebaro_ventures.design.designsystem.SbSortableTable
import de.sebaro_ventures.design.designsystem.SbStatItem
import de.sebaro_ventures.design.designsystem.SbStats
import de.sebaro_ventures.design.designsystem.SbStatus
import de.sebaro_ventures.design.designsystem.SbStatusGlyph
import de.sebaro_ventures.design.designsystem.SbStatusTone
import de.sebaro_ventures.design.designsystem.SbSteps
import de.sebaro_ventures.design.designsystem.SbTableCell
import de.sebaro_ventures.design.designsystem.SbTableColumn
import de.sebaro_ventures.design.designsystem.SbTableSum
import de.sebaro_ventures.design.designsystem.SbTag
import de.sebaro_ventures.design.designsystem.SbTags
import de.sebaro_ventures.design.designsystem.SbTopBar
import de.sebaro_ventures.design.designsystem.sbFormatCount
import de.sebaro_ventures.design.designsystem.sbMessages
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter

// Every value on this screen is invented (BEL-09: „Beispieldaten“ under the title).
private val TODAY = LocalDate.of(2026, 10, 10)
private val EXPENSES = listOf(42.90, 1249.00, 12.50, 89.99)
private val EXPENSE_DAYS = listOf(3, 7, 8, 9)
private val STEPS = listOf(6200f, 8400f, 7100f, 9800f, 5400f, 10200f, 7600f)
private val WEEKS = listOf(5.2f, 5.8f, null, 6.1f, 6.6f, 6.4f)

/**
 * Top-level „Daten“: the kinds of data of the guide's page daten.html, each through its sebaro wrapper: numbers,
 * money and units (TXT-04, TXT-12, TXT-13, FAR-14), time (TXT-04), state (STA-01, STA-02, STA-09), progress (STA-06),
 * categories and marks (STA-04, FAR-12), technical values (SCH-01, TXT-08, ZUG-09), a sortable table with a sum
 * (DAT-14), charts (DAT-04, DAT-10, DAT-12, DAT-03) and a rating (DAT-09). No primary action: nothing to do here.
 */
@Composable
fun DataScreen(navigation: @Composable () -> Unit) {
    val t = SebaroTheme.tokens
    SbScreen(
        topBar = { SbTopBar(title = stringResource(R.string.data_title)) },
        navigation = navigation,
    ) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(padding)
                .padding(bottom = t.space.s8),
        ) {
            SbDemoMarker(
                stringResource(R.string.demo_marker),
                Modifier.padding(horizontal = t.spacing.gutter).padding(top = t.space.s4),
            )
            NumbersSection()
            TimeSection()
            StateSection()
            CategorySection()
            TechnicalSection()
            TableSection()
            ChartSection()
        }
    }
}

/** A section head of this screen (title, a heading for TalkBack) over its content in the gutter. */
@Composable
private fun Section(title: String, content: @Composable ColumnScope.() -> Unit) {
    val t = SebaroTheme.tokens
    Column(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = t.spacing.gutter)
            .padding(top = t.spacing.section),
        verticalArrangement = Arrangement.spacedBy(t.space.s4),
    ) {
        Text(
            title,
            style = SebaroTheme.typography.title,
            color = SebaroTheme.colors.text,
            modifier = Modifier.semantics { heading() },
        )
        content()
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun NumbersSection() {
    val locale = appLocale()
    Section(stringResource(R.string.data_numbers)) {
        SbBigNumber(value = formatMoney(EXPENSES.sum(), locale), label = stringResource(R.string.data_expenses_month))
        SbMetaList(
            labels = true,
            items = listOf(
                SbMetaItem(stringResource(R.string.data_integer), sbFormatCount(12)),
                SbMetaItem(stringResource(R.string.data_fraction), stringResource(R.string.fraction, sbFormatCount(5), sbFormatCount(8))),
                SbMetaItem(stringResource(R.string.data_decimal), formatDecimal(3.75, 2, locale)),
                SbMetaItem(stringResource(R.string.data_large), sbFormatCount(10_000)),
                SbMetaItem(stringResource(R.string.data_percent), formatPercent(0.6, locale)),
                SbMetaItem(stringResource(R.string.data_money), formatMoney(1249.0, locale)),
                SbMetaItem(stringResource(R.string.data_per_month), stringResource(R.string.per_month, formatMoney(0.99, locale))),
                SbMetaItem(stringResource(R.string.data_unit), stringResource(R.string.unit_km, formatDecimal(2.5, 1, locale))),
                SbMetaItem(stringResource(R.string.data_approx), stringResource(R.string.approx, sbFormatCount(40))),
                SbMetaItem(stringResource(R.string.data_rank), stringResource(R.string.rank, sbFormatCount(3), sbFormatCount(12))),
            ),
        )
        FlowRow(horizontalArrangement = Arrangement.spacedBy(SebaroTheme.tokens.space.s6)) {
            SbSignedNumber(stringResource(R.string.signed_plus, formatPercent(0.125, locale, 1)), SbSign.Plus)
            SbSignedNumber(stringResource(R.string.signed_minus, formatPercent(0.03, locale, 1)), SbSign.Minus)
            SbSignedNumber(stringResource(R.string.signed_zero, formatPercent(0.0, locale, 1)), SbSign.Zero)
        }
    }
}

@Composable
private fun TimeSection() {
    val m = sbMessages()
    Section(stringResource(R.string.data_time)) {
        SbMetaList(
            labels = true,
            items = listOf(
                SbMetaItem(stringResource(R.string.data_day), m.dayDateWithYear(TODAY)),
                SbMetaItem(stringResource(R.string.data_date_note), formatNoteDate(TODAY)),
                SbMetaItem(stringResource(R.string.data_date_short), m.shortDate(TODAY)),
                SbMetaItem(stringResource(R.string.data_clock), m.timeOfDay(LocalTime.of(8, 12))),
                SbMetaItem(
                    stringResource(R.string.data_range),
                    stringResource(R.string.range, m.timeOfDay(LocalTime.of(8, 0)), m.timeOfDay(LocalTime.of(22, 0))),
                ),
                SbMetaItem(
                    stringResource(R.string.data_span),
                    stringResource(R.string.range, m.shortDate(TODAY), m.shortDate(TODAY.plusDays(4))),
                ),
                SbMetaItem(stringResource(R.string.data_duration), stringResource(R.string.duration, 1, 20)),
                SbMetaItem(stringResource(R.string.data_remaining), stringResource(R.string.remaining_minutes, 3)),
            ),
        )
    }
}

@Composable
private fun StateSection() {
    val t = SebaroTheme.tokens
    Section(stringResource(R.string.data_state)) {
        Column(verticalArrangement = Arrangement.spacedBy(t.space.s3)) {
            SbStatus(SbStatusTone.Info)
            SbStatus(SbStatusTone.Neutral)
            SbStatus(SbStatusTone.Success)
            SbStatus(SbStatusTone.Danger)
            SbStatus(SbStatusTone.Warning, word = stringResource(R.string.state_conflict), glyph = SbStatusGlyph.Warning)
            SbStatus(
                SbStatusTone.Neutral,
                word = stringResource(R.string.state_count_open, sbFormatCount(2)),
                glyph = SbStatusGlyph.Pending,
            )
        }
        val locale = appLocale()
        SbProgressBar(0.6f, label = stringResource(R.string.data_import), valueText = formatPercent(0.6, locale))
        SbProgressRing(0.6f, label = stringResource(R.string.data_goal_day), valueText = formatPercent(0.6, locale))
        SbSteps(steps = stringArrayResource(R.array.data_steps).toList(), current = 1)
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun CategorySection() {
    val t = SebaroTheme.tokens
    Section(stringResource(R.string.data_categories)) {
        SbTags {
            stringArrayResource(R.array.data_tags).forEach { SbTag(it) }
        }
        FlowRow(horizontalArrangement = Arrangement.spacedBy(t.space.s6), verticalArrangement = Arrangement.spacedBy(t.space.s2)) {
            stringArrayResource(R.array.data_category_words).forEachIndexed { i, word -> SbCategory(word, tone = i + 1) }
        }
        val sentence = stringResource(R.string.data_mark_sentence)
        val word = stringResource(R.string.data_mark_word)
        val at = sentence.indexOf(word, ignoreCase = true)
        SbMarkedText(sentence, marks = if (at >= 0) listOf(at until at + word.length) else emptyList())
    }
}

@Composable
private fun TechnicalSection() {
    val t = SebaroTheme.tokens
    val c = SebaroTheme.colors
    val code = SebaroTheme.typography.code
    Section(stringResource(R.string.data_technical)) {
        Column(verticalArrangement = Arrangement.spacedBy(t.space.s1)) {
            Text(stringResource(R.string.data_id), style = SebaroTheme.typography.label, color = c.textMuted)
            Text(stringResource(R.string.sample_id), style = code, color = c.text)
        }
        Column(verticalArrangement = Arrangement.spacedBy(t.space.s1)) {
            Text(stringResource(R.string.data_version), style = SebaroTheme.typography.label, color = c.textMuted)
            Text(stringResource(R.string.sample_version), style = code, color = c.text)
        }
        Column(verticalArrangement = Arrangement.spacedBy(t.space.s1)) {
            Text(stringResource(R.string.data_file), style = SebaroTheme.typography.label, color = c.textMuted)
            SbFileNameText(stringResource(R.string.sample_file_name))
        }
        SbCodeBlock(code = stringResource(R.string.sample_json), language = stringResource(R.string.code_language_json))
    }
}

@Composable
private fun TableSection() {
    val locale = appLocale()
    val names = stringArrayResource(R.array.data_expense_names)
    var sortIndex by rememberSaveable { mutableIntStateOf(2) }
    var descending by rememberSaveable { mutableStateOf(true) }
    Section(stringResource(R.string.data_table)) {
        SbSortableTable(
            caption = stringResource(R.string.data_table_caption),
            columns = listOf(
                SbTableColumn(stringResource(R.string.data_col_item)),
                SbTableColumn(stringResource(R.string.data_col_date), SbColumnKind.Date),
                SbTableColumn(stringResource(R.string.data_col_amount), SbColumnKind.Number),
            ),
            rows = names.indices.map { i ->
                val day = TODAY.withDayOfMonth(EXPENSE_DAYS[i])
                listOf(
                    SbTableCell(names[i]),
                    SbTableCell(formatNoteDate(day), date = day),
                    SbTableCell(formatMoney(EXPENSES[i], locale), number = EXPENSES[i]),
                )
            },
            sortIndex = sortIndex,
            sortDescending = descending,
            onSort = { index, desc ->
                sortIndex = index
                descending = desc
            },
            rowHeads = true,
            sum = SbTableSum(stringResource(R.string.data_sum), mapOf(2 to formatMoney(EXPENSES.sum(), locale))),
        )
    }
}

@Composable
private fun ChartSection() {
    val m = sbMessages()
    val locale = appLocale()
    Section(stringResource(R.string.data_charts)) {
        SbStats(
            listOf(
                SbStatItem(stringResource(R.string.data_stat_steps), sbFormatCount(7_814), spark = STEPS),
                SbStatItem(stringResource(R.string.data_stat_streak), pluralStringResource(R.plurals.days, 12, 12)),
            ),
        )
        SbBarChart(
            bars = STEPS.mapIndexed { i, v ->
                SbBar(m.weekdays[i], v, sbFormatCount(v.toInt()), current = i == STEPS.lastIndex)
            },
            caption = stringResource(R.string.data_bar_caption, sbFormatCount(8_000)),
            target = SbChartValue(8_000f, sbFormatCount(8_000)),
        )
        val weekStarts = WEEKS.indices.map { TODAY.minusWeeks((WEEKS.size - 1 - it).toLong()) }
        val month = DateTimeFormatter.ofPattern("LLLL", locale)
        SbLineChart(
            points = WEEKS.mapIndexed { i, v ->
                SbLinePoint(m.weekFrom(m.shortDate(weekStarts[i])), v, v?.let { formatDecimal(it.toDouble(), 1, locale) } ?: m.noValue)
            },
            caption = stringResource(R.string.data_line_caption),
            // one month name over its weeks
            axis = weekStarts.groupBy { it.month }.values.map { SbAxisLabel(month.format(it.first()), span = it.size) },
        )
        SbShareRows(
            rows = stringArrayResource(R.array.data_share_names).zip(listOf(46f, 31f, 23f)).mapIndexed { i, (name, v) ->
                SbShareRow(name, v, formatPercent(v / 100.0, locale), current = i == 0)
            },
            caption = stringResource(R.string.data_share_caption),
        )
        SbGoalRing(done = 5, total = 8, caption = stringResource(R.string.data_goal_caption))
        SbRating(value = 4.2f, count = 38)
    }
}
