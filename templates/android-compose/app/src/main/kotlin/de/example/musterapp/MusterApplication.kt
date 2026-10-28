package de.example.musterapp

import android.app.Application

/** Holds the app's state across configuration changes (rotation, language); the entries are kept in filesDir. */
class MusterApplication : Application() {
    val settings by lazy { SettingsStore(this) }
    val entries by lazy { EntryStore.open(filesDir) }
}
