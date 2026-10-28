package de.example.musterapp

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import de.sebaro_ventures.design.SebaroTheme
import de.sebaro_ventures.design.SebaroTone
import de.sebaro_ventures.design.designsystem.SbMotionSetting
import de.sebaro_ventures.design.designsystem.SbRadioChoice
import de.sebaro_ventures.design.designsystem.SbScreen
import de.sebaro_ventures.design.designsystem.SbThemeChoice
import de.sebaro_ventures.design.designsystem.SbThemeMode
import de.sebaro_ventures.design.designsystem.SbToneChoice
import de.sebaro_ventures.design.designsystem.SbTopBar

/**
 * Settings, top-level: „Hell oder Dunkel“ as three radio rows (MOB-04, AKT-09), „Farbton“ beside it (FAR-15),
 * „Bewegung immer reduzieren“ (BEW-04), „Sprache“ (TEC-10). Every choice applies at once: no primary action (AKT-01).
 */
@Composable
fun SettingsScreen(
    mode: SbThemeMode,
    onMode: (SbThemeMode) -> Unit,
    tone: SebaroTone,
    onTone: (SebaroTone) -> Unit,
    reduceMotion: Boolean,
    onReduceMotion: (Boolean) -> Unit,
    language: AppLanguage,
    onLanguage: (AppLanguage) -> Unit,
    navigation: @Composable () -> Unit,
) {
    val t = SebaroTheme.tokens
    SbScreen(
        topBar = { SbTopBar(title = stringResource(R.string.settings_title)) },
        navigation = navigation,
    ) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(padding)
                .padding(vertical = t.space.s4),
            verticalArrangement = Arrangement.spacedBy(t.space.s6),
        ) {
            SbThemeChoice(mode = mode, onChange = onMode)
            SbToneChoice(tone = tone, onChange = onTone)
            SbMotionSetting(reduce = reduceMotion, onChange = onReduceMotion)
            SbRadioChoice(
                title = stringResource(R.string.settings_language),
                options = listOf(
                    AppLanguage.System to stringResource(R.string.language_system),
                    AppLanguage.German to stringResource(R.string.language_de),
                    AppLanguage.English to stringResource(R.string.language_en),
                ),
                selected = language,
                onChange = onLanguage,
            )
        }
    }
}
