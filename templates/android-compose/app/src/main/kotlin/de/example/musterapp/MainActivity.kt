package de.example.musterapp

import android.content.Context
import android.graphics.Color as AndroidColor
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import de.sebaro_ventures.design.designsystem.SbThemeMode
import de.sebaro_ventures.design.designsystem.SebaroAppTheme

class MainActivity : ComponentActivity() {
    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(AppLanguage.wrap(newBase))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // edge-to-edge (spec/08 §2.2): SbScreen and SbTopBar consume the system bar insets themselves
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        val app = application as MusterApplication
        setContent {
            val settings = app.settings
            val dark = when (settings.mode) {
                SbThemeMode.System -> isSystemInDarkTheme()
                SbThemeMode.Light -> false
                SbThemeMode.Dark -> true
            }
            // the system bar icons follow the app's own choice, not only the system's
            DisposableEffect(dark) {
                val style = SystemBarStyle.auto(AndroidColor.TRANSPARENT, AndroidColor.TRANSPARENT) { dark }
                enableEdgeToEdge(statusBarStyle = style, navigationBarStyle = style)
                onDispose {}
            }
            val language = remember { AppLanguage.current(this) }
            SebaroAppTheme(mode = settings.mode, reduceMotion = settings.reduceMotion, tone = settings.tone) {
                MusterApp(
                    store = app.entries,
                    settings = settings,
                    language = language,
                    onLanguage = { AppLanguage.apply(this, it) },
                )
            }
        }
    }
}
