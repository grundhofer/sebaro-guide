package de.example.musterapp

import androidx.activity.compose.BackHandler
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import de.sebaro_ventures.design.designsystem.SbNavItem
import de.sebaro_ventures.design.designsystem.SbNavigationBar
import de.sebaro_ventures.design.designsystem.SbToastData
import de.sebaro_ventures.design.designsystem.rememberSbToastState
import de.sebaro_ventures.design.icons.SebaroIcons
import java.time.LocalDate

/** Where the app is. The three top-level places carry the bottom navigation (NAV-03); the rest are sub-screens. */
sealed interface Route {
    data object Entries : Route
    data object Data : Route
    data object Settings : Route
    data class Detail(val id: Int) : Route
    data class Form(val id: Int?) : Route

    companion object {
        val topLevel = listOf(Entries, Data, Settings)

        fun encode(route: Route): String = when (route) {
            Entries -> "entries"
            Data -> "data"
            Settings -> "settings"
            is Detail -> "detail:${route.id}"
            is Form -> "form:${route.id ?: ""}"
        }

        fun decode(text: String): Route = when {
            text == "data" -> Data
            text == "settings" -> Settings
            text.startsWith("detail:") -> Detail(text.removePrefix("detail:").toInt())
            text.startsWith("form:") -> Form(text.removePrefix("form:").toIntOrNull())
            else -> Entries
        }
    }
}

private val RouteStackSaver = listSaver<SnapshotStateList<Route>, String>(
    save = { stack -> stack.map(Route::encode) },
    restore = { saved -> mutableStateListOf<Route>().apply { addAll(saved.map(Route::decode)) } },
)

/** The app: a stack of places, the first one always top-level. */
@Composable
fun MusterApp(
    store: EntryStore,
    settings: SettingsStore,
    language: AppLanguage,
    onLanguage: (AppLanguage) -> Unit,
) {
    val stack = rememberSaveable(saver = RouteStackSaver) { mutableStateListOf<Route>(Route.Entries) }
    var query by rememberSaveable { mutableStateOf("") }
    val toasts = rememberSbToastState()
    val route = stack.last()

    fun open(next: Route) {
        stack.add(next)
    }

    fun back() {
        if (stack.size > 1) stack.removeAt(stack.lastIndex)
    }

    BackHandler(enabled = stack.size > 1) { back() }

    val navigation = @Composable {
        MusterNavigation(
            selected = Route.topLevel.indexOf(stack.first()),
            onSelect = { i ->
                stack.clear()
                stack.add(Route.topLevel[i])
            },
        )
    }

    when (route) {
        Route.Entries -> {
            val hiddenMessage = stringResource(R.string.list_hidden_toast)
            val undo = stringResource(R.string.toast_undo)
            val resources = LocalContext.current.resources
            ListScreen(
                entries = store.entries.filterNot { it.hidden },
                query = query,
                onQuery = { query = it },
                onOpen = { open(Route.Detail(it)) },
                onCreate = { open(Route.Form(null)) },
                onHide = { entry ->
                    store.setHidden(entry.id, true)
                    // EBE-05: a reversible result outside the primary action, with „Rückgängig“
                    toasts.show(
                        SbToastData(
                            message = hiddenMessage.format(entry.title(resources)),
                            actionLabel = undo,
                            onAction = { store.setHidden(entry.id, false) },
                        ),
                    )
                },
                toasts = toasts,
                navigation = navigation,
            )
        }
        Route.Data -> DataScreen(navigation = navigation)
        Route.Settings -> SettingsScreen(
            mode = settings.mode,
            onMode = settings::updateMode,
            tone = settings.tone,
            onTone = settings::updateTone,
            reduceMotion = settings.reduceMotion,
            onReduceMotion = settings::updateReduceMotion,
            language = language,
            onLanguage = onLanguage,
            navigation = navigation,
        )
        is Route.Detail -> {
            val entry = store.get(route.id)
            if (entry == null) {
                LaunchedEffect(route) { back() }
            } else {
                DetailScreen(
                    entry = entry,
                    onBack = ::back,
                    onEdit = { open(Route.Form(entry.id)) },
                    onFinish = { store.finish(entry.id) },
                    onDelete = {
                        store.delete(entry.id)
                        back()
                    },
                )
            }
        }
        is Route.Form -> {
            val entry = route.id?.let(store::get)
            val resources = LocalContext.current.resources
            FormScreen(
                initial = entry,
                onSave = { title, note, priority ->
                    if (entry == null) {
                        val id = store.add(title, note, priority, LocalDate.now())
                        stack.removeAt(stack.lastIndex)
                        open(Route.Detail(id))
                    } else {
                        store.update(entry.id, title, note, priority, resources)
                        back()
                    }
                },
                onClose = ::back,
            )
        }
    }
}

/** Bottom navigation: icon and word (NAV-02), the current place filled with the 3 dp line (NAV-01). */
@Composable
fun MusterNavigation(selected: Int, onSelect: (Int) -> Unit) {
    SbNavigationBar(
        items = listOf(
            SbNavItem(stringResource(R.string.nav_entries), SebaroIcons.Outline.Home, SebaroIcons.Filled.Home),
            SbNavItem(stringResource(R.string.nav_data), SebaroIcons.Outline.ChartBar, SebaroIcons.Filled.ChartBar),
            SbNavItem(stringResource(R.string.nav_settings), SebaroIcons.Outline.Settings, SebaroIcons.Filled.Settings),
        ),
        selectedIndex = selected,
        onSelect = onSelect,
    )
}
