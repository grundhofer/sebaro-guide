package de.example.musterapp

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import de.sebaro_ventures.design.SebaroTheme
import de.sebaro_ventures.design.designsystem.SbDemoMarker
import de.sebaro_ventures.design.designsystem.SbEmptyState
import de.sebaro_ventures.design.designsystem.SbListEnd
import de.sebaro_ventures.design.designsystem.SbListHeader
import de.sebaro_ventures.design.designsystem.SbListRow
import de.sebaro_ventures.design.designsystem.SbMenuItem
import de.sebaro_ventures.design.designsystem.SbPrimaryActionModel
import de.sebaro_ventures.design.designsystem.SbScreen
import de.sebaro_ventures.design.designsystem.SbSearchField
import de.sebaro_ventures.design.designsystem.SbToastHost
import de.sebaro_ventures.design.designsystem.SbToastState
import de.sebaro_ventures.design.designsystem.SbTopBar
import de.sebaro_ventures.design.icons.SebaroIcons

/**
 * Top-level list: search, groups with their count in the head (HAL-05, DAT-01), done rows recede (DAT-02), the end
 * sentence, the empty state with the primary action below (DAT-07), „Beispieldaten“ in each sample row (BEL-09) and
 * „Ausblenden“ with an undo toast (EBE-05).
 */
@Composable
fun ListScreen(
    entries: List<Entry>,
    query: String,
    onQuery: (String) -> Unit,
    onOpen: (Int) -> Unit,
    onCreate: () -> Unit,
    onHide: (Entry) -> Unit,
    toasts: SbToastState,
    navigation: @Composable () -> Unit,
) {
    val t = SebaroTheme.tokens
    val needle = query.trim()
    val resources = LocalContext.current.resources
    val configuration = LocalConfiguration.current
    val shown = remember(entries, needle, configuration) {
        if (needle.isEmpty()) entries
        else entries.filter {
            it.title(resources).contains(needle, ignoreCase = true) || it.note(resources).contains(needle, ignoreCase = true)
        }
    }
    val hide = stringResource(R.string.list_hide)
    val demo = stringResource(R.string.demo_marker)
    SbScreen(
        topBar = { SbTopBar(title = stringResource(R.string.list_title)) },
        primaryAction = SbPrimaryActionModel(text = stringResource(R.string.list_create), onClick = onCreate),
        navigation = navigation,
        snackbarHost = { SbToastHost(toasts) },
    ) { padding ->
        LazyColumn(Modifier.fillMaxSize(), contentPadding = padding) {
            if (entries.isEmpty()) {
                item {
                    SbEmptyState(
                        title = stringResource(R.string.list_empty_title),
                        text = stringResource(R.string.list_empty_text),
                    )
                }
                return@LazyColumn
            }
            item {
                SbSearchField(
                    value = query,
                    onValueChange = onQuery,
                    label = stringResource(R.string.list_search_label),
                    placeholder = stringResource(R.string.list_search_placeholder),
                    modifier = Modifier.padding(horizontal = t.spacing.gutter, vertical = t.space.s4),
                )
            }
            if (shown.isEmpty()) {
                item {
                    SbEmptyState(
                        title = stringResource(R.string.list_nohit_title, needle),
                        text = stringResource(R.string.list_nohit_text),
                    )
                }
                return@LazyColumn
            }
            for (state in EntryState.entries) {
                val group = shown.filter { it.state == state }
                if (group.isEmpty()) continue
                item(key = "head-$state") {
                    SbListHeader(
                        label = stringResource(if (state == EntryState.Open) R.string.group_open else R.string.group_done),
                        count = group.size,
                    )
                }
                items(group, key = { it.id }) { entry ->
                    SbListRow(
                        title = entry.title(),
                        meta = stringResource(R.string.list_meta_created, formatNoteDate(entry.created)),
                        // BEL-09: each invented sample carries the marker in its row, the user's entries never
                        trail = if (entry.isSample) ({ SbDemoMarker(demo) }) else null,
                        done = entry.state == EntryState.Done,
                        onClick = { onOpen(entry.id) },
                        menu = listOf(SbMenuItem(hide, onClick = { onHide(entry) }, icon = SebaroIcons.Outline.EyeOff)),
                    )
                }
            }
            item { SbListEnd(stringResource(R.string.list_end)) }
        }
    }
}
