package de.example.musterapp

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * The cut-text check itself: fixtures it must fail and one it must pass, so a check that sees nothing cannot pass.
 * Native graphics as in ScreenshotTest: without them Robolectric measures every text as empty and nothing is cut.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36], qualifiers = "de-rDE-w360dp-h800dp-notnight-xhdpi")
class TextCheckTest {
    @get:Rule
    val rule = createComposeRule()

    private fun faults(waivers: List<TextWaiver> = emptyList(), content: @Composable () -> Unit): List<String> {
        rule.setContent(content)
        rule.waitForIdle()
        val check = TextCheck("fixture", waivers)
        rule.checkTexts(check)
        return check.faults()
    }

    /** The text lays out whole (its own layout is fine), but a smaller frame around it clips it. */
    @Composable
    private fun ClippedByFrame() {
        Box(Modifier.size(80.dp, 24.dp).clipToBounds()) {
            Text(
                "Dieser Satz ist zu lang für seinen Rahmen",
                softWrap = false,
                modifier = Modifier.wrapContentSize(align = Alignment.TopStart, unbounded = true),
            )
        }
    }

    @Test
    fun a_text_clipped_by_a_frame_fails() {
        val found = faults { ClippedByFrame() }
        assertEquals(listOf("fixture: Dieser Satz ist zu lang für seinen Rahmen (clipped by its surroundings)"), found)
    }

    @Test
    fun a_text_clipped_inside_scrolled_content_fails_also_after_scrolling() {
        val found = faults {
            Column(Modifier.height(120.dp).verticalScroll(rememberScrollState())) {
                repeat(12) { Text("Zeile ${it + 1}") }
                ClippedByFrame()
            }
        }
        assertEquals(listOf("fixture: Dieser Satz ist zu lang für seinen Rahmen (clipped by its surroundings)"), found)
    }

    @Test
    fun scrolled_content_passes_once_every_line_was_whole_in_view() {
        val check = TextCheck("fixture")
        rule.setContent {
            Column(Modifier.height(120.dp).verticalScroll(rememberScrollState())) {
                repeat(30) { Text("Zeile ${it + 1}") }
            }
        }
        rule.checkTexts(check)
        assertEquals(emptyList<String>(), check.faults())
        // every line was measured at least once, most of them only after scrolling
        assertTrue("checked ${check.checked}", check.checked >= 30)
    }

    @Test
    fun a_text_taller_than_its_scroll_viewport_is_never_whole_and_fails() {
        val found = faults {
            Column(Modifier.height(24.dp).width(120.dp).verticalScroll(rememberScrollState())) {
                Text("Eins zwei drei vier fünf sechs sieben acht neun zehn")
            }
        }
        assertEquals(1, found.size)
        assertTrue(found.single(), found.single().endsWith("(never whole in view, also after scrolling)"))
    }

    @Test
    fun an_ellipsis_fails() {
        val found = faults {
            Text("Dieser Satz ist zu lang für seinen Rahmen", maxLines = 1, softWrap = false,
                overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis, modifier = Modifier.width(80.dp))
        }
        assertEquals(listOf("fixture: Dieser Satz ist zu lang für seinen Rahmen (ellipsis)"), found)
    }

    @Test
    fun a_case_without_any_text_fails() {
        val found = faults { Box(Modifier.size(40.dp)) }
        assertEquals(listOf("fixture: no text checked"), found)
    }

    @Test
    fun a_waiver_that_matches_more_or_less_than_expected_fails() {
        val waiver = TextWaiver("fixture frame", expected = 2) { text, condition, _ ->
            text.startsWith("Dieser Satz") && condition == "clipped by its surroundings"
        }
        val found = faults(listOf(waiver)) { ClippedByFrame() }
        assertEquals(listOf("fixture: waiver „fixture frame“ matched 1 times, expected 2"), found)
    }
}
