package de.example.musterapp

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.Snapshot
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasScrollAction
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.ComposeContentTestRule
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.performTextReplacement
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.style.TextOverflow
import com.github.takahirom.roborazzi.ExperimentalRoborazziApi
import com.github.takahirom.roborazzi.captureScreenRoboImage
import de.sebaro_ventures.design.SebaroTone
import de.sebaro_ventures.design.designsystem.SbThemeMode
import de.sebaro_ventures.design.designsystem.SbToastData
import de.sebaro_ventures.design.designsystem.SebaroAppTheme
import de.sebaro_ventures.design.designsystem.rememberSbToastState
import java.io.File
import org.junit.Assert.assertTrue
import org.junit.FixMethodOrder
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.MethodSorters
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

// Every screen in light and dark at font scale 1.0 and 2.0 on a 360 × 800 dp phone (German, xhdpi), drawn on the
// JVM with Robolectric's native graphics and captured with Roborazzi, every window included (dialogs). The PNGs go to
// the folder the build passes in (app/build.gradle.kts). Each case first finds the text that shows its screen is up,
// then the cut-text check of TextCheck.kt runs on it, scrolling every scroll container through (ZUG-09).

private const val SCREEN = "de-rDE-w360dp-h800dp"
private const val TALL = "de-rDE-w360dp-h8000dp"
private const val SETTLE_MS = 3_000L

/**
 * [expect]: a text in the unmerged tree that shows the case's screen or dialog is up. [waivers]: the case's known
 * exceptions to the cut-text check for a run („light-fs2.0“), each with its exact number of hits.
 */
private class Case(
    val name: String,
    val expect: String,
    val act: (ComposeContentTestRule) -> Unit = {},
    val waivers: (tag: String) -> List<TextWaiver> = { emptyList() },
    val content: @Composable () -> Unit,
)

/** SbSearchField names the field for TalkBack with its label, which it does not draw (a 0 × 0 node, no layout). */
private val SEARCH_LABEL: (String) -> List<TextWaiver> = {
    listOf(TextWaiver("SbSearchField: label only as the field's name", 1) { text, condition, _ ->
        text == "Einträge durchsuchen" && condition == "no text layout"
    })
}

/**
 * SbTextField gives TalkBack its label and „(optional)“ as one text and leaves the drawn words out of the semantics
 * tree, so this check cannot measure them; the screenshots show them whole.
 */
private val NOTE_LABEL: (String) -> List<TextWaiver> = {
    listOf(TextWaiver("SbTextField: label „Notiz (optional)“ only as one TalkBack text", 1) { text, condition, _ ->
        text == "Notiz, optional" && condition == "no text layout"
    })
}

/**
 * SbBarChart draws each slot's weekday and number on one line (softWrap = false, overflow Visible) and leaves out,
 * at large text, those that do not fit (spec/08 §16). For such a text Compose's semantics layout wraps it anyway, so
 * it reports a text taller than its box, though the drawing shows one line (looked at in both scales). Waived: only
 * „taller“, only for a non-wrapping, overflow-visible text without a line break, only on the data screen, with the
 * number of such slot texts per run (at 1.0 the seven numbers, at 2.0 also the weekdays that no longer fit their slot).
 */
private val BAR_SLOTS: (String) -> List<TextWaiver> = { tag ->
    val expected = mapOf("light-fs1.0" to 7, "dark-fs1.0" to 7, "light-fs2.0" to 11, "dark-fs2.0" to 12).getValue(tag)
    listOf(TextWaiver("SbBarChart slot text on one line", expected) { _, condition, r ->
        condition == "taller" && r != null && !r.layoutInput.softWrap &&
            r.layoutInput.overflow == TextOverflow.Visible && '\n' !in r.layoutInput.text.text
    })
}

/** Scrolls the screen's content to its end, so a part under the action zone comes into view, then taps [text]. */
private fun ComposeContentTestRule.scrollDownAndTap(text: String) {
    onNode(hasScrollAction()).performSemanticsAction(SemanticsActions.ScrollBy) { it(0f, 100_000f) }
    waitForIdle()
    onNodeWithText(text).assertIsDisplayed().performClick()
}

@Composable
private fun sampleStore(): EntryStore = remember { EntryStore.sample() }

/**
 * A user's entry whose note holds one word wider than the phone's line at font scale 2.0 (ZUG-09, TXT-15): the
 * package's SbWrapText breaks it inside the word and cuts nothing. The hyphen comes from the system's hyphenation
 * patterns, which Robolectric lacks, so the test images show the break without one.
 */
const val LONG_WORD = "Donaudampfschifffahrtsgesellschaftskapitänsmützenabzeichen"
private val LONG_WORD_ENTRY = Entry(
    id = 99,
    typedTitle = "Mütze abholen",
    typedNote = "Abholen: $LONG_WORD, bis Freitag.",
    priority = Priority.Normal,
    created = java.time.LocalDate.of(2026, 10, 12),
)

@Composable
private fun Nav(selected: Int) = MusterNavigation(selected = selected, onSelect = {})

@Composable
private fun Entries(query: String = "", empty: Boolean = false, toast: Boolean = false) {
    val store = sampleStore()
    val toasts = rememberSbToastState()
    val entries = if (empty) emptyList() else store.entries.toList()
    if (toast) {
        val message = stringResource(R.string.list_hidden_toast, entries[1].title())
        val undo = stringResource(R.string.toast_undo)
        LaunchedEffect(Unit) { toasts.show(SbToastData(message, undo)) }
    }
    ListScreen(
        entries = entries,
        query = query,
        onQuery = {},
        onOpen = {},
        onCreate = {},
        onHide = {},
        toasts = toasts,
        navigation = { Nav(0) },
    )
}

@Composable
private fun Detail(index: Int) {
    val store = sampleStore()
    DetailScreen(entry = store.entries[index], onBack = {}, onEdit = {}, onFinish = {}, onDelete = {})
}

@Composable
private fun Form(edit: Boolean) {
    val store = sampleStore()
    FormScreen(initial = if (edit) store.entries[0] else null, onSave = { _, _, _ -> }, onClose = {})
}

@Composable
private fun Settings() = SettingsScreen(
    mode = SbThemeMode.System,
    onMode = {},
    tone = SebaroTone.Cool,
    onTone = {},
    reduceMotion = false,
    onReduceMotion = {},
    language = AppLanguage.System,
    onLanguage = {},
    navigation = { Nav(2) },
)

private val SCREENS = listOf(
    Case("01-list", "Balkon bepflanzen", waivers = SEARCH_LABEL) { Entries() },
    Case("02-list-no-hit", "Kein Eintrag mit „Zebra“", waivers = SEARCH_LABEL) { Entries(query = "Zebra") },
    Case("03-list-empty", "Noch keine Einträge") { Entries(empty = true) },
    Case("04-list-toast", "„Balkon bepflanzen“ ausgeblendet", waivers = SEARCH_LABEL) { Entries(toast = true) },
    Case("05-detail", "Bremsen und Licht prüfen lassen, vorher einen Termin ausmachen.") { Detail(0) },
    Case("06-detail-done", "erledigt") { Detail(3) },
    Case("07-dialog-delete", "Eintrag löschen?", act = { it.scrollDownAndTap("Eintrag löschen") }) { Detail(0) },
    Case("08-dialog-finish", "Eintrag abschließen?", act = { it.scrollDownAndTap("Eintrag abschließen") }) { Detail(0) },
    Case("09-form-new", "Neuer Eintrag", waivers = NOTE_LABEL) { Form(edit = false) },
    Case("10-form-missing", "Titel fehlt.", waivers = NOTE_LABEL, act = {
        it.onNodeWithText("Eintrag anlegen").performClick()
    }) { Form(edit = false) },
    Case("11-dialog-unsaved", "Änderungen an „Fahrrad zur Inspektion bringen“ sichern?", waivers = NOTE_LABEL, act = {
        it.onNode(hasSetTextAction() and hasText("Titel", substring = true)).performTextReplacement("Fahrrad zur Werkstatt bringen")
        it.onNodeWithContentDescription("Schließen").performClick()
    }) { Form(edit = true) },
    Case("12-settings", "Sprache") { Settings() },
    Case("13-data", "Zahlen", waivers = BAR_SLOTS) { DataScreen(navigation = { Nav(1) }) },
    Case("14-detail-long-word", "Abholen: $LONG_WORD, bis Freitag.") {
        DetailScreen(entry = LONG_WORD_ENTRY, onBack = {}, onEdit = {}, onFinish = {}, onDelete = {})
    },
    Case("15-form-edit-sample", "Beispieldaten", waivers = NOTE_LABEL) { Form(edit = true) },
)

/** The data screen at full length, in an 8000 dp window, so every part of it can be looked at. */
private val TALL_SCREENS = listOf(
    Case("13-data-full", "Zahlen", waivers = BAR_SLOTS) { DataScreen(navigation = { Nav(1) }) },
)

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36])
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
class ScreenshotTest {
    @get:Rule
    val rule = createComposeRule()

    private val dir = File(System.getProperty("musterapp.shots.dir") ?: "build/screenshots")

    @Test @Config(qualifiers = "$SCREEN-notnight-xhdpi", fontScale = 1f)
    fun a1_light_fs1() = render(SCREENS, dark = false, tag = "light-fs1.0")

    @Test @Config(qualifiers = "$SCREEN-notnight-xhdpi", fontScale = 2f)
    fun a2_light_fs2() = render(SCREENS, dark = false, tag = "light-fs2.0")

    @Test @Config(qualifiers = "$SCREEN-night-xhdpi", fontScale = 1f)
    fun a3_dark_fs1() = render(SCREENS, dark = true, tag = "dark-fs1.0")

    @Test @Config(qualifiers = "$SCREEN-night-xhdpi", fontScale = 2f)
    fun a4_dark_fs2() = render(SCREENS, dark = true, tag = "dark-fs2.0")

    @Test @Config(qualifiers = "$TALL-notnight-xhdpi", fontScale = 1f)
    fun b1_tall_light_fs1() = render(TALL_SCREENS, dark = false, tag = "light-fs1.0")

    @Test @Config(qualifiers = "$TALL-notnight-xhdpi", fontScale = 2f)
    fun b2_tall_light_fs2() = render(TALL_SCREENS, dark = false, tag = "light-fs2.0")

    @Test @Config(qualifiers = "$TALL-night-xhdpi", fontScale = 1f)
    fun b3_tall_dark_fs1() = render(TALL_SCREENS, dark = true, tag = "dark-fs1.0")

    @Test @Config(qualifiers = "$TALL-night-xhdpi", fontScale = 2f)
    fun b4_tall_dark_fs2() = render(TALL_SCREENS, dark = true, tag = "dark-fs2.0")

    @OptIn(ExperimentalRoborazziApi::class)
    private fun render(cases: List<Case>, dark: Boolean, tag: String) {
        dir.mkdirs()
        var shown by mutableStateOf<Case?>(null)
        rule.setContent {
            val case = shown ?: return@setContent
            key(case.name) {
                SebaroAppTheme(mode = if (dark) SbThemeMode.Dark else SbThemeMode.Light) { case.content() }
            }
        }
        val cut = mutableListOf<String>()
        for (case in cases) {
            shown = case
            Snapshot.sendApplyNotifications()
            rule.waitForIdle()
            case.act(rule)
            // the toast stands 6 s; the clock moves only as far as every enter animation needs
            rule.mainClock.autoAdvance = false
            rule.mainClock.advanceTimeBy(SETTLE_MS)
            rule.mainClock.autoAdvance = true
            rule.onNodeWithText(case.expect, useUnmergedTree = true).assertExists("${case.name}: „${case.expect}“")
            captureScreenRoboImage(File(dir, "${case.name}-$tag.png").path)
            val check = TextCheck(case.name, case.waivers(tag))
            rule.checkTexts(check)
            println("$tag ${check.summary()}")
            cut += check.faults()
            if (case.name == "14-detail-long-word") cut += longWordFaults(case.name)
        }
        shown = null
        Snapshot.sendApplyNotifications()
        rule.waitForIdle()
        assertTrue("cut text at $tag:\n" + cut.joinToString("\n"), cut.isEmpty())
    }

    /** The long word breaks only inside itself: every line break of the note falls within the word or at a space. */
    private fun longWordFaults(case: String): List<String> {
        val node = rule.onNodeWithText(LONG_WORD, substring = true, useUnmergedTree = true).fetchSemanticsNode()
        val results = mutableListOf<TextLayoutResult>()
        node.config[SemanticsActions.GetTextLayoutResult].action!!(results)
        val r = results.single()
        val text = r.layoutInput.text.text
        val wordStart = text.indexOf(LONG_WORD)
        val wordEnd = wordStart + LONG_WORD.length
        val faults = mutableListOf<String>()
        if (r.lineCount < 2) faults += "$case: the long word did not break"
        for (line in 0 until r.lineCount - 1) {
            val end = r.getLineEnd(line)
            val atSpace = text[end - 1] == ' '
            if (!atSpace && end !in (wordStart + 1) until wordEnd) faults += "$case: break after „${text.take(end)}“"
        }
        return faults
    }
}
