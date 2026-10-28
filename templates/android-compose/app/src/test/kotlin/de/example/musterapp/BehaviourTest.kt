package de.example.musterapp

import android.content.res.Configuration
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.test.onAllNodesWithText
import org.robolectric.RuntimeEnvironment
import java.io.File
import java.time.LocalDate
import java.util.Locale
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextInput
import de.sebaro_ventures.design.designsystem.SbThemeMode
import de.sebaro_ventures.design.designsystem.SebaroAppTheme
import de.sebaro_ventures.design.designsystem.rememberSbToastState
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * What the screens do, not how they look: validation, the unsaved dialog, search, the final step, entries kept across
 * a new process, samples in the screen's language and their „Beispieldaten“ marker.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36], qualifiers = "de-rDE-w360dp-h800dp-notnight-xhdpi")
class BehaviourTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun empty_title_says_what_is_missing_and_takes_the_focus() {
        var saved: String? = null
        rule.setContent {
            SebaroAppTheme(mode = SbThemeMode.Light) {
                FormScreen(initial = null, onSave = { title, _, _ -> saved = title }, onClose = {})
            }
        }
        // STA-03: the primary action stays enabled, its press names the field and moves the focus there
        rule.onNodeWithText("Eintrag anlegen").performClick()
        rule.onNodeWithText("Titel fehlt.", substring = true, useUnmergedTree = true).assertIsDisplayed()
        rule.onNode(hasSetTextAction() and hasText("Titel", substring = true)).assertIsFocused()
        assertNull(saved)
        rule.onNode(hasSetTextAction() and hasText("Titel", substring = true)).performTextInput("Keller aufräumen")
        rule.onNodeWithText("Eintrag anlegen").performClick()
        assertEquals("Keller aufräumen", saved)
    }

    @Test
    fun closing_with_changes_asks_with_three_actions() {
        var closed = false
        rule.setContent {
            SebaroAppTheme(mode = SbThemeMode.Light) {
                FormScreen(initial = null, onSave = { _, _, _ -> }, onClose = { closed = true })
            }
        }
        rule.onNode(hasSetTextAction() and hasText("Titel", substring = true)).performTextInput("Neu")
        rule.onNodeWithContentDescription("Schließen").performClick()
        rule.onNodeWithText("Neuen Eintrag sichern?").assertIsDisplayed()
        rule.onNodeWithText("Abbrechen").assertIsDisplayed()
        rule.onNodeWithText("Sichern").assertIsDisplayed()
        rule.onNodeWithText("Verwerfen").performClick()
        assertEquals(true, closed)
    }

    @Test
    fun closing_without_changes_does_not_ask() {
        var closed = false
        rule.setContent {
            SebaroAppTheme(mode = SbThemeMode.Light) {
                FormScreen(initial = null, onSave = { _, _, _ -> }, onClose = { closed = true })
            }
        }
        rule.onNodeWithContentDescription("Schließen").performClick()
        assertEquals(true, closed)
    }

    @Test
    fun search_filters_and_names_a_miss() {
        rule.setContent {
            val store = remember { EntryStore.sample() }
            var query by remember { mutableStateOf("") }
            SebaroAppTheme(mode = SbThemeMode.Light) {
                ListScreen(
                    entries = store.entries.toList(), query = query, onQuery = { query = it }, onOpen = {},
                    onCreate = {}, onHide = {}, toasts = rememberSbToastState(), navigation = {},
                )
            }
        }
        rule.onNodeWithText("Balkon bepflanzen").assertIsDisplayed()
        rule.onNode(hasSetTextAction()).performTextInput("Regal")
        rule.onNodeWithText("Regal im Flur aufbauen").assertIsDisplayed()
        rule.onNodeWithText("Balkon bepflanzen").assertDoesNotExist()
        rule.onNode(hasSetTextAction()).performTextInput("xyz")
        rule.onNodeWithText("Kein Eintrag mit „Regalxyz“").assertIsDisplayed()
    }

    @Test
    fun finishing_asks_first_and_then_takes_the_primary_action_away() {
        rule.setContent {
            val store = remember { EntryStore.sample() }
            val entry = store.entries[0]
            SebaroAppTheme(mode = SbThemeMode.Light) {
                DetailScreen(entry = entry, onBack = {}, onEdit = {}, onFinish = { store.finish(entry.id) }, onDelete = {})
            }
        }
        rule.onNodeWithText("Eintrag bearbeiten").assertIsDisplayed()
        rule.onNodeWithText("Eintrag abschließen").performScrollTo().performClick()
        rule.onNodeWithText("Eintrag abschließen?").assertIsDisplayed()
        rule.onNodeWithText("Abschließen").performClick()
        rule.onNodeWithText("Eintrag abschließen?").assertDoesNotExist()
        rule.onNodeWithText("Eintrag bearbeiten").assertDoesNotExist()
        rule.onNodeWithText("erledigt", substring = true, useUnmergedTree = true).assertIsDisplayed()
    }

    @Test
    fun entries_survive_a_new_process() {
        val context = RuntimeEnvironment.getApplication()
        val dir = File(context.filesDir, "process-test").apply { deleteRecursively(); mkdirs() }
        val resources = context.resources
        val first = EntryStore.open(dir)
        assertEquals(5, first.entries.size)
        val added = first.add("Keller aufräumen", "Alte Farbe zum Wertstoffhof.", Priority.High, LocalDate.of(2026, 10, 27))
        first.update(2, "Balkon bepflanzen, diesmal mit Tomaten", "Erde reicht.", Priority.Low, resources)
        first.update(3, first.entries.first { it.id == 3 }.title(resources), "", Priority.High, resources)
        first.finish(1)
        first.setHidden(4, true)
        first.delete(5)
        first.flush()
        val before = first.entries.toList()

        // a new process: nothing of the first store is left but the file
        val second = EntryStore.open(dir)
        assertEquals(before, second.entries.toList())
        assertEquals("Keller aufräumen", second.get(added)!!.typedTitle)
        assertNull("an edited sample is the user's", second.get(2)!!.sample)
        assertEquals("only the priority changed: still a sample", 2, second.get(3)!!.sample)
        assertEquals(EntryState.Done, second.get(1)!!.state)
        assertEquals(true, second.get(4)!!.hidden)
        assertNull(second.get(5))
    }

    @Test
    fun samples_follow_the_language_and_typed_text_stays() {
        val app = RuntimeEnvironment.getApplication()
        // one store for the whole test, as MusterApplication keeps it across the activity's language recreation
        val store = EntryStore.sample().apply { add("Mütze abholen", "Bis Freitag.", Priority.Normal, LocalDate.of(2026, 10, 27)) }
        var language by mutableStateOf("de")
        rule.setContent {
            val config = Configuration(app.resources.configuration).apply { setLocale(Locale.forLanguageTag(language)) }
            val context = remember(language) { app.createConfigurationContext(config) }
            CompositionLocalProvider(LocalContext provides context, LocalConfiguration provides config) {
                SebaroAppTheme(mode = SbThemeMode.Light) {
                    ListScreen(
                        entries = store.entries.toList(), query = "", onQuery = {}, onOpen = {}, onCreate = {},
                        onHide = {}, toasts = rememberSbToastState(), navigation = {},
                    )
                }
            }
        }
        val german = app.createConfigurationContext(
            Configuration(app.resources.configuration).apply { setLocale(Locale.GERMAN) },
        ).resources.getStringArray(R.array.sample_titles)[1]
        val english = app.createConfigurationContext(
            Configuration(app.resources.configuration).apply { setLocale(Locale.ENGLISH) },
        ).resources.getStringArray(R.array.sample_titles)[1]
        assertNotEquals(german, english)
        for ((tag, shown, gone) in listOf(Triple("de", german, english), Triple("en", english, german), Triple("de", german, english))) {
            language = tag
            rule.waitForIdle()
            rule.onNodeWithText(shown, useUnmergedTree = true).assertExists("$tag: $shown")
            rule.onNodeWithText(gone, useUnmergedTree = true).assertDoesNotExist()
            rule.onNodeWithText("Mütze abholen", useUnmergedTree = true).assertExists("$tag: typed title as typed")
        }
    }

    @Test
    fun only_samples_carry_the_marker_in_list_detail_and_form() {
        val store = EntryStore.sample().apply { add("Mütze abholen", "", Priority.Normal, LocalDate.of(2026, 10, 27)) }
        val user = store.entries.first { !it.isSample }
        val sample = store.entries.first { it.isSample }
        var screen by mutableStateOf("list")
        rule.setContent {
            SebaroAppTheme(mode = SbThemeMode.Light) {
                when (screen) {
                    "list" -> ListScreen(
                        entries = store.entries.toList(), query = "", onQuery = {}, onOpen = {}, onCreate = {},
                        onHide = {}, toasts = rememberSbToastState(), navigation = {},
                    )
                    "detail-sample" -> DetailScreen(sample, onBack = {}, onEdit = {}, onFinish = {}, onDelete = {})
                    "detail-user" -> DetailScreen(user, onBack = {}, onEdit = {}, onFinish = {}, onDelete = {})
                    "form-sample" -> FormScreen(initial = sample, onSave = { _, _, _ -> }, onClose = {})
                    "form-user" -> FormScreen(initial = user, onSave = { _, _, _ -> }, onClose = {})
                    "form-new" -> FormScreen(initial = null, onSave = { _, _, _ -> }, onClose = {})
                }
            }
        }
        fun markers() = rule.onAllNodesWithText("Beispieldaten", useUnmergedTree = true).fetchSemanticsNodes().size
        // the list composes the rows in view: the user's entry first, then the samples, each with its own marker
        val titles = RuntimeEnvironment.getApplication().resources.getStringArray(R.array.sample_titles)
        val sampleRows = titles.count { rule.onAllNodesWithText(it, useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty() }
        rule.onNodeWithText("Mütze abholen", useUnmergedTree = true).assertExists()
        assertTrue("sample rows in view: $sampleRows", sampleRows >= 2)
        assertEquals(sampleRows, markers())
        screen = "detail-sample"; rule.waitForIdle(); assertEquals(1, markers())
        screen = "detail-user"; rule.waitForIdle(); assertEquals(0, markers())
        screen = "form-sample"; rule.waitForIdle(); assertEquals(1, markers())
        // once the sample's words change it becomes the user's entry, and the marker goes
        rule.onNode(hasSetTextAction() and hasText("Titel", substring = true)).performTextInput(" neu")
        assertEquals(0, markers())
        screen = "form-user"; rule.waitForIdle(); assertEquals(0, markers())
        screen = "form-new"; rule.waitForIdle(); assertEquals(0, markers())
    }
}
