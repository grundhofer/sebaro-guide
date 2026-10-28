package de.example.musterapp

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import de.sebaro_ventures.design.SebaroTheme
import de.sebaro_ventures.design.designsystem.SbBackButton
import de.sebaro_ventures.design.designsystem.SbConfirmDialog
import de.sebaro_ventures.design.designsystem.SbDangerAction
import de.sebaro_ventures.design.designsystem.SbDemoMarker
import de.sebaro_ventures.design.designsystem.SbMetaItem
import de.sebaro_ventures.design.designsystem.SbMetaList
import de.sebaro_ventures.design.designsystem.SbPrimaryActionModel
import de.sebaro_ventures.design.designsystem.SbScreen
import de.sebaro_ventures.design.designsystem.SbStatus
import de.sebaro_ventures.design.designsystem.SbStatusGlyph
import de.sebaro_ventures.design.designsystem.SbStatusTone
import de.sebaro_ventures.design.designsystem.SbTopBar
import de.sebaro_ventures.design.designsystem.SbWrapText
import de.sebaro_ventures.design.designsystem.sbMessages
import de.sebaro_ventures.design.icons.SebaroIcons

private enum class Ask { Delete, Finish }

/**
 * Sub-screen: back button and title (NAV-05), „Beispieldaten“ on an invented sample (BEL-09), state as glyph and word (STA-01), facts flat (DAT-03), the one primary
 * action at the bottom (AKT-01, AKT-02); at the end of the content the final step without trash and the deletion with
 * trash, both with the 45° cut (AKT-07, FOR-04), both asking first (AKT-08, EBE-03).
 */
@Composable
fun DetailScreen(
    entry: Entry,
    onBack: () -> Unit,
    onEdit: () -> Unit,
    onFinish: () -> Unit,
    onDelete: () -> Unit,
) {
    val c = SebaroTheme.colors
    val t = SebaroTheme.tokens
    val m = sbMessages()
    var ask by rememberSaveable { mutableStateOf<Ask?>(null) }
    val open = entry.state == EntryState.Open
    val title = entry.title()
    val note = entry.note()
    SbScreen(
        topBar = { SbTopBar(title = title, topLevel = false, leading = { SbBackButton(onBack) }) },
        // a done entry can no longer change, so its screen has no next step and no primary action
        primaryAction = if (open) SbPrimaryActionModel(text = stringResource(R.string.detail_edit), onClick = onEdit) else null,
    ) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(padding)
                .padding(horizontal = t.spacing.gutter, vertical = t.space.s4),
            verticalArrangement = Arrangement.spacedBy(t.space.s6),
        ) {
            // BEL-09: an invented sample says so under its title; the user's own entries never carry the marker
            if (entry.isSample) SbDemoMarker(stringResource(R.string.demo_marker))
            if (open) {
                SbStatus(SbStatusTone.Neutral, word = stringResource(R.string.state_open), glyph = SbStatusGlyph.Pending)
            } else {
                SbStatus(SbStatusTone.Success, word = stringResource(R.string.state_done))
            }
            // ZUG-09, TXT-15: the user's own note wraps at spaces and hyphenates only a word wider than the line
            SbWrapText(
                note.ifBlank { stringResource(R.string.detail_no_note) },
                SebaroTheme.typography.body,
                if (note.isBlank()) c.textMuted else c.text,
            )
            SbMetaList(
                labels = true,
                items = listOf(
                    SbMetaItem(stringResource(R.string.detail_created), m.dayDateWithYear(entry.created)),
                    SbMetaItem(stringResource(R.string.detail_priority), stringResource(entry.priority.label)),
                ),
            )
            Column(verticalArrangement = Arrangement.spacedBy(t.space.s4)) {
                if (open) {
                    SbDangerAction(stringResource(R.string.detail_finish), onClick = { ask = Ask.Finish })
                }
                SbDangerAction(
                    stringResource(R.string.detail_delete),
                    onClick = { ask = Ask.Delete },
                    icon = SebaroIcons.Outline.Trash,
                )
            }
        }
    }
    when (ask) {
        Ask.Delete -> SbConfirmDialog(
            title = stringResource(R.string.dialog_delete_title),
            text = stringResource(R.string.dialog_delete_text, title),
            confirmText = stringResource(R.string.dialog_delete_confirm),
            onConfirm = {
                ask = null
                onDelete()
            },
            onDismiss = { ask = null },
        )
        Ask.Finish -> SbConfirmDialog(
            title = stringResource(R.string.dialog_finish_title),
            text = stringResource(R.string.dialog_finish_text, title),
            confirmText = stringResource(R.string.dialog_finish_confirm),
            onConfirm = {
                ask = null
                onFinish()
            },
            onDismiss = { ask = null },
        )
        null -> Unit
    }
}
