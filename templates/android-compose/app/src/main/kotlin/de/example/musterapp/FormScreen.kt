package de.example.musterapp

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import de.sebaro_ventures.design.SebaroTheme
import de.sebaro_ventures.design.designsystem.SbDemoMarker
import de.sebaro_ventures.design.designsystem.SbIconButton
import de.sebaro_ventures.design.designsystem.SbPrimaryActionModel
import de.sebaro_ventures.design.designsystem.SbScreen
import de.sebaro_ventures.design.designsystem.SbSegmented
import de.sebaro_ventures.design.designsystem.SbTextField
import de.sebaro_ventures.design.designsystem.SbTopBar
import de.sebaro_ventures.design.designsystem.SbUnsavedDialog
import de.sebaro_ventures.design.designsystem.sbFormatCount
import de.sebaro_ventures.design.icons.SebaroIcons

const val NOTE_MAX = 500

/**
 * Form: „Beispieldaten“ while an invented sample is edited unchanged (BEL-09), labels above the fields (EIN-01), „(optional)“ on the voluntary note, nothing on required fields; the primary
 * action stays enabled and says „Titel fehlt.“ at the empty field, focus on it (STA-03); segments that turn into a
 * select at large text (EIN-04, ZUG-09); the data-path line under the action (BEL-10); closing with changes asks
 * „Abbrechen“ · „Verwerfen“ · „Sichern“ (AKT-11). No „Sichern“ in the top bar (NAV-05).
 */
@Composable
fun FormScreen(
    initial: Entry?,
    onSave: (title: String, note: String, priority: Priority) -> Unit,
    onClose: () -> Unit,
) {
    val t = SebaroTheme.tokens
    val initialTitle = initial?.title().orEmpty()
    val initialNote = initial?.note().orEmpty()
    var title by rememberSaveable { mutableStateOf(initialTitle) }
    var note by rememberSaveable { mutableStateOf(initialNote) }
    var priority by rememberSaveable { mutableStateOf(initial?.priority ?: Priority.Normal) }
    var titleMissing by rememberSaveable { mutableStateOf(false) }
    var askUnsaved by rememberSaveable { mutableStateOf(false) }
    val titleFocus = remember { FocusRequester() }
    val noteFocus = remember { FocusRequester() }
    val noteTooLong = note.length > NOTE_MAX
    val dirty = title != initialTitle || note != initialNote ||
        priority != (initial?.priority ?: Priority.Normal)

    fun submit() {
        when {
            title.isBlank() -> {
                titleMissing = true
                titleFocus.requestFocus()
            }
            noteTooLong -> noteFocus.requestFocus()
            else -> onSave(title.trim(), note.trim(), priority)
        }
    }

    fun requestClose() {
        if (dirty) askUnsaved = true else onClose()
    }

    BackHandler { requestClose() }

    SbScreen(
        topBar = {
            SbTopBar(
                title = stringResource(if (initial == null) R.string.form_new_title else R.string.form_edit_title),
                topLevel = false,
                leading = { SbIconButton(SebaroIcons.Outline.Close, stringResource(R.string.form_close), ::requestClose) },
            )
        },
        primaryAction = SbPrimaryActionModel(
            text = stringResource(if (initial == null) R.string.form_create else R.string.form_save),
            onClick = ::submit,
            hint = stringResource(R.string.hint_local),
        ),
    ) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(padding)
                .padding(horizontal = t.spacing.gutter, vertical = t.space.s4),
            verticalArrangement = Arrangement.spacedBy(t.space.s6),
        ) {
            // BEL-09: editing an invented sample says so while its words are still the sample's (EntryStore.update)
            if (initial?.isSample == true && title == initialTitle && note == initialNote) {
                SbDemoMarker(stringResource(R.string.demo_marker))
            }
            SbTextField(
                value = title,
                onValueChange = {
                    title = it
                    titleMissing = false
                },
                label = stringResource(R.string.form_title_label),
                modifier = Modifier.focusRequester(titleFocus),
                error = if (titleMissing) stringResource(R.string.form_title_missing) else null,
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences, imeAction = ImeAction.Next),
            )
            SbSegmented(
                label = stringResource(R.string.form_priority_label),
                options = Priority.entries.map { it to stringResource(it.label) },
                selected = priority,
                onChange = { priority = it },
            )
            SbTextField(
                value = note,
                onValueChange = { note = it },
                label = stringResource(R.string.form_note_label),
                modifier = Modifier.focusRequester(noteFocus),
                optional = true,
                singleLine = false,
                minLines = 3,
                counter = stringResource(R.string.form_note_counter, sbFormatCount(note.length), sbFormatCount(NOTE_MAX)),
                error = if (noteTooLong) {
                    stringResource(R.string.form_note_too_long, sbFormatCount(note.length), sbFormatCount(NOTE_MAX))
                } else {
                    null
                },
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
            )
        }
    }
    if (askUnsaved) {
        SbUnsavedDialog(
            title = if (initial == null) {
                stringResource(R.string.unsaved_new_title)
            } else {
                stringResource(R.string.unsaved_edit_title, initialTitle)
            },
            text = stringResource(if (initial == null) R.string.unsaved_new_text else R.string.unsaved_edit_text),
            onSave = {
                askUnsaved = false
                submit()
            },
            onDiscard = {
                askUnsaved = false
                onClose()
            },
            onDismiss = { askUnsaved = false },
        )
    }
}
