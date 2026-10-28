package de.example.musterapp

import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsNode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.isRoot
import androidx.compose.ui.test.junit4.ComposeContentTestRule
import androidx.compose.ui.text.TextLayoutResult
import kotlin.math.roundToInt

// The cut-text check of the screenshot tests (ZUG-09): every text node of every window, in the unmerged semantics
// tree, is measured twice. Its own layout: no line wider than its box, no text taller than its box, no ellipsis. Its
// place: the part of it that is drawn (bounds clipped by every ancestor) must be the whole of it. A text cut only by
// the viewport of a scroll container is not a fault where it stands; scrolling every container through its range
// must then show it whole at least once. A case that checks no text at all fails.

/**
 * A known, narrow exception: [where] names it, [applies] picks text, condition and (where there is one) the text's
 * layout, [expected] is the exact number of distinct texts it must match, so it can neither grow nor go stale unseen.
 */
class TextWaiver(
    val where: String,
    val expected: Int,
    val applies: (text: String, condition: String, layout: TextLayoutResult?) -> Boolean,
)

class TextCheck(private val case: String, private val waivers: List<TextWaiver> = emptyList()) {
    var checked = 0
        private set
    private val cut = linkedSetOf<String>()
    private val clipped = mutableSetOf<String>()
    private val wholeSeen = mutableSetOf<String>()
    private val scrolledAway = mutableSetOf<String>()
    private val waived = mutableMapOf<TextWaiver, MutableSet<String>>()

    fun scan(roots: List<SemanticsNode>) = roots.forEach { visit(it, emptyList()) }

    private fun visit(n: SemanticsNode, ancestors: List<SemanticsNode>) {
        val text = n.config.getOrNull(SemanticsProperties.Text)?.joinToString(" ") { it.text }
            ?: n.config.getOrNull(SemanticsProperties.EditableText)?.text
        val layout = n.config.getOrNull(SemanticsActions.GetTextLayoutResult)?.action
        if (text != null || layout != null) measure(n, text ?: "?", layout, ancestors)
        n.children.forEach { visit(it, ancestors + n) }
    }

    private fun measure(
        n: SemanticsNode,
        text: String,
        layout: ((MutableList<TextLayoutResult>) -> Boolean)?,
        ancestors: List<SemanticsNode>,
    ) {
        // an empty field or a text without a layout to read is named, never passed silently
        if (layout == null) return report(text, "no text layout", null)
        val results = mutableListOf<TextLayoutResult>()
        if (!layout(results) || results.isEmpty()) return report(text, "no text layout", null)
        checked++
        results.forEach { r ->
            val lines = 0 until r.lineCount
            // didOverflowWidth alone also fires for a text narrower than its constraint, so the lines are measured
            if (lines.any { r.getLineRight(it) - r.getLineLeft(it) > r.size.width + 1f }) report(text, "wider", r)
            if (r.multiParagraph.height > r.size.height + 1f) report(text, "taller", r)
            if (lines.any { r.isLineEllipsized(it) }) report(text, "ellipsis", r)
        }
        val whole = Rect(n.positionInRoot, n.size.toSize())
        val key = "$text [${whole.width.roundToInt()}×${whole.height.roundToInt()}]"
        val drawn = n.boundsInRoot
        when {
            covers(drawn, whole) -> wholeSeen += key
            cutByScrolling(drawn, whole, ancestors.filter(::isScroller)) -> scrolledAway += key
            else -> {
                clipped += key
                report(text, "clipped by its surroundings", results.first())
            }
        }
    }

    /**
     * Cut only where the viewport of a scroll container ends: every cut edge lies on the matching edge of a
     * container that scrolls on that axis. A text wholly outside every viewport counts as scrolled away, too; it
     * still has to be seen whole later.
     */
    private fun cutByScrolling(drawn: Rect, whole: Rect, scrollers: List<SemanticsNode>): Boolean {
        if (scrollers.isEmpty()) return false
        if (drawn.width <= 0f || drawn.height <= 0f) return true
        val vertical = scrollers.filter { it.config.getOrNull(SemanticsProperties.VerticalScrollAxisRange) != null }
            .map { it.boundsInRoot }
        val horizontal = scrollers.filter { it.config.getOrNull(SemanticsProperties.HorizontalScrollAxisRange) != null }
            .map { it.boundsInRoot }
        fun near(a: Float, b: Float) = kotlin.math.abs(a - b) <= 1f
        val top = drawn.top <= whole.top + 1f || vertical.any { near(it.top, drawn.top) }
        val bottom = drawn.bottom >= whole.bottom - 1f || vertical.any { near(it.bottom, drawn.bottom) }
        val left = drawn.left <= whole.left + 1f || horizontal.any { near(it.left, drawn.left) }
        val right = drawn.right >= whole.right - 1f || horizontal.any { near(it.right, drawn.right) }
        return top && bottom && left && right
    }

    private fun report(text: String, condition: String, layout: TextLayoutResult?) {
        val waiver = waivers.firstOrNull { it.applies(text, condition, layout) }
        if (waiver != null) waived.getOrPut(waiver) { mutableSetOf() } += "$text ($condition)"
        else cut += "$case: $text ($condition)"
    }

    /** One line for the test output: how much was measured and waived. */
    fun summary(): String =
        "$case: $checked text layouts measured, ${wholeSeen.size} texts seen whole, " +
            "${waived.values.sumOf { it.size }} waived"

    /** Everything wrong in this case, as „case: text (condition)“; empty when it passes. */
    fun faults(): List<String> {
        val all = cut.toMutableList()
        if (checked == 0) all += "$case: no text checked"
        // a text found clipped once is reported as such, not again as never whole
        (scrolledAway - wholeSeen - clipped).forEach { all += "$case: $it (never whole in view, also after scrolling)" }
        waivers.forEach { w ->
            val hits = waived[w]?.size ?: 0
            if (hits != w.expected) all += "$case: waiver „${w.where}“ matched $hits times, expected ${w.expected}"
        }
        return all
    }
}

private fun androidx.compose.ui.unit.IntSize.toSize() =
    androidx.compose.ui.geometry.Size(width.toFloat(), height.toFloat())

private fun covers(drawn: Rect, whole: Rect) =
    drawn.left <= whole.left + 1f && drawn.top <= whole.top + 1f &&
        drawn.right >= whole.right - 1f && drawn.bottom >= whole.bottom - 1f

private fun isScroller(n: SemanticsNode) =
    n.config.getOrNull(SemanticsActions.ScrollBy) != null &&
        (n.config.getOrNull(SemanticsProperties.VerticalScrollAxisRange) != null ||
            n.config.getOrNull(SemanticsProperties.HorizontalScrollAxisRange) != null)

/** Every window's root in the unmerged tree; at least one must exist. */
fun ComposeContentTestRule.unmergedRoots(): List<SemanticsNode> =
    onAllNodes(isRoot(), useUnmergedTree = true).fetchSemanticsNodes(atLeastOneRootRequired = true)

private fun ComposeContentTestRule.scrollers(): List<SemanticsNode> {
    val found = mutableListOf<SemanticsNode>()
    fun walk(n: SemanticsNode) {
        if (isScroller(n)) found += n
        n.children.forEach(::walk)
    }
    unmergedRoots().forEach(::walk)
    return found
}

private fun ComposeContentTestRule.find(id: Int): SemanticsNode? {
    fun walk(n: SemanticsNode): SemanticsNode? = if (n.id == id) n else n.children.firstNotNullOfOrNull(::walk)
    return unmergedRoots().firstNotNullOfOrNull(::walk)
}

/**
 * Scans the windows as they stand, then scrolls every scroll container through its whole range in steps of most of
 * its viewport, scanning at each step, and scrolls it back to its start. At every step of an outer container each
 * inner one (a table that scrolls sideways inside a scrolling screen) is scrolled through again, so it is also seen
 * where it stands wholly in view.
 */
fun ComposeContentTestRule.checkTexts(check: TextCheck) {
    check.scan(unmergedRoots())
    val done = mutableSetOf<Int>()
    fun exercise(id: Int, depth: Int) {
        if (depth == 0 && !done.add(id)) return
        var moved = 0f
        for (step in 0 until 200) {
            val node = find(id) ?: break
            val vertical = node.config.getOrNull(SemanticsProperties.VerticalScrollAxisRange)
            val horizontal = node.config.getOrNull(SemanticsProperties.HorizontalScrollAxisRange)
            val range = vertical ?: horizontal ?: break
            if (range.value() >= range.maxValue()) break
            val by = 0.8f * if (vertical != null) node.boundsInRoot.height else node.boundsInRoot.width
            if (by < 1f) break
            runOnUiThread {
                val scroll = node.config[SemanticsActions.ScrollBy].action!!
                if (vertical != null) scroll(0f, by) else scroll(by, 0f)
            }
            waitForIdle()
            moved += by
            check.scan(unmergedRoots())
            if (depth == 0) scrollers().filter { it.id != id }.forEach { exercise(it.id, depth + 1) }
        }
        val node = find(id) ?: return
        val vertical = node.config.getOrNull(SemanticsProperties.VerticalScrollAxisRange) != null
        runOnUiThread {
            val scroll = node.config[SemanticsActions.ScrollBy].action!!
            if (vertical) scroll(0f, -moved) else scroll(-moved, 0f)
        }
        waitForIdle()
    }
    scrollers().forEach { exercise(it.id, 0) }
}
