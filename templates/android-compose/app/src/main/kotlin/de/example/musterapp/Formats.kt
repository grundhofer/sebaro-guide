package de.example.musterapp

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import java.text.NumberFormat
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Currency
import java.util.Locale

// Numbers and dates go through the screen's locale (TXT-04, TXT-12, TEC-10), never glued together by hand.
// Units and words come from res/values; the space between number and unit is U+00A0.

@Composable
@ReadOnlyComposable
fun appLocale(): Locale = LocalConfiguration.current.locales[0]

/** U+202F and U+2009 (narrow spaces some locales use) become U+00A0, as TXT-04 asks. */
private fun String.sbSpaces(): String = replace(' ', ' ').replace(' ', ' ')

fun formatDecimal(value: Double, digits: Int, locale: Locale): String =
    NumberFormat.getNumberInstance(locale).apply {
        minimumFractionDigits = digits
        maximumFractionDigits = digits
    }.format(value).sbSpaces()

fun formatPercent(fraction: Double, locale: Locale, digits: Int = 0): String =
    NumberFormat.getPercentInstance(locale).apply {
        minimumFractionDigits = digits
        maximumFractionDigits = digits
    }.format(fraction).sbSpaces()

fun formatMoney(euros: Double, locale: Locale): String =
    NumberFormat.getCurrencyInstance(locale).apply { currency = Currency.getInstance("EUR") }
        .format(euros).sbSpaces()

/** „10.10.2026“ in German notes, „2026-10-10“ in English (TXT-04); the pattern is a string resource. */
@Composable
@ReadOnlyComposable
fun formatNoteDate(date: LocalDate): String =
    DateTimeFormatter.ofPattern(stringResource(R.string.date_pattern), appLocale()).format(date)
