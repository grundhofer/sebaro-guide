package de.example.musterapp

import android.app.Activity
import android.app.LocaleManager
import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.LocaleList
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.edit
import de.sebaro_ventures.design.SebaroTone
import de.sebaro_ventures.design.designsystem.SbThemeMode
import java.util.Locale

private const val PREFS = "settings"
private const val KEY_MODE = "mode"
private const val KEY_TONE = "tone"
private const val KEY_MOTION = "reduce-motion"
private const val KEY_LANGUAGE = "language"

/**
 * The three appearance settings of MOB-01 / MOB-04 / FAR-15 / BEW-04, stored on the device and handed to
 * SebaroAppTheme(mode, reduceMotion, tone). Every choice applies at once, without „Sichern“.
 */
class SettingsStore(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    var mode by mutableStateOf(SbThemeMode.entries.firstOrNull { it.name == prefs.getString(KEY_MODE, null) } ?: SbThemeMode.System)
        private set
    var tone by mutableStateOf(SebaroTone.fromId(prefs.getString(KEY_TONE, null)))
        private set
    var reduceMotion by mutableStateOf(prefs.getBoolean(KEY_MOTION, false))
        private set

    fun updateMode(value: SbThemeMode) {
        mode = value
        prefs.edit { putString(KEY_MODE, value.name) }
    }

    fun updateTone(value: SebaroTone) {
        tone = value
        prefs.edit { putString(KEY_TONE, value.id) }
    }

    fun updateReduceMotion(value: Boolean) {
        reduceMotion = value
        prefs.edit { putBoolean(KEY_MOTION, value) }
    }
}

/**
 * The app's language (TEC-10): like the system, German or English. Android 13 and later keep the choice themselves
 * (per-app language, also in the system settings through res/xml/locales_config.xml); below, the app stores it and
 * MainActivity wraps its context. The sebaro wrappers' words (SbMessages) follow the screen's locale either way.
 */
enum class AppLanguage(val tag: String) {
    System(""),
    German("de"),
    English("en");

    companion object {
        private fun fromTag(tag: String?): AppLanguage =
            entries.firstOrNull { it.tag.isNotEmpty() && tag?.startsWith(it.tag) == true } ?: System

        fun current(context: Context): AppLanguage =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val locales = context.getSystemService(LocaleManager::class.java).applicationLocales
                if (locales.isEmpty) System else fromTag(locales[0].language)
            } else {
                fromTag(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_LANGUAGE, null))
            }

        fun apply(activity: Activity, language: AppLanguage) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // the system recreates the activity in the new language
                activity.getSystemService(LocaleManager::class.java).applicationLocales =
                    if (language == System) LocaleList.getEmptyLocaleList() else LocaleList.forLanguageTags(language.tag)
            } else {
                activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit { putString(KEY_LANGUAGE, language.tag) }
                activity.recreate()
            }
        }

        /** Below Android 13: the activity's context in the stored language. */
        fun wrap(base: Context): Context {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) return base
            val tag = base.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_LANGUAGE, null)
            if (tag.isNullOrEmpty()) return base
            val config = Configuration(base.resources.configuration)
            config.setLocale(Locale.forLanguageTag(tag))
            return base.createConfigurationContext(config)
        }
    }
}
