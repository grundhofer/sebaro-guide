package de.example.musterapp

import android.content.res.Resources
import android.util.AtomicFile
import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.ui.res.stringArrayResource
import java.io.File
import java.io.IOException
import java.time.LocalDate
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.json.JSONArray
import org.json.JSONObject

enum class EntryState { Open, Done }

enum class Priority(@param:StringRes val label: Int) {
    Low(R.string.priority_low),
    Normal(R.string.priority_normal),
    High(R.string.priority_high),
}

/**
 * One entry of the list. [Done] entries are finished for good and can no longer be edited.
 *
 * [sample] is the index of an invented sample entry in res/values (BEL-09): its title and note are looked up only
 * when shown, so they follow a language change, and the screens mark it „Beispieldaten“. A user's entry has
 * [sample] null and keeps [typedTitle] and [typedNote] exactly as typed.
 */
@Immutable
data class Entry(
    val id: Int,
    val typedTitle: String,
    val typedNote: String,
    val priority: Priority,
    val created: LocalDate,
    val state: EntryState = EntryState.Open,
    val hidden: Boolean = false,
    val sample: Int? = null,
) {
    val isSample: Boolean get() = sample != null

    fun title(resources: Resources): String =
        sample?.let { resources.getStringArray(R.array.sample_titles)[it] } ?: typedTitle

    fun note(resources: Resources): String =
        sample?.let { resources.getStringArray(R.array.sample_notes)[it] } ?: typedNote
}

/** The entry's title in the screen's language (a sample) or as typed (the user's). */
@Composable
fun Entry.title(): String = sample?.let { stringArrayResource(R.array.sample_titles)[it] } ?: typedTitle

/** The entry's note in the screen's language (a sample) or as typed (the user's). */
@Composable
fun Entry.note(): String = sample?.let { stringArrayResource(R.array.sample_notes)[it] } ?: typedNote

/**
 * The app's entries, kept on this device in one small JSON file (org.json from the Android platform, no extra
 * library). Every change writes the whole file on a background thread, atomically. A product with many entries or
 * queries takes Room or DataStore instead.
 */
class EntryStore private constructor(private val file: AtomicFile?, initial: List<Entry>) {
    val entries = mutableStateListOf<Entry>().apply { addAll(initial) }
    private val writer = Executors.newSingleThreadExecutor { Thread(it, "entry-store").apply { isDaemon = true } }

    fun get(id: Int): Entry? = entries.firstOrNull { it.id == id }

    fun add(title: String, note: String, priority: Priority, today: LocalDate): Int {
        val id = (entries.maxOfOrNull { it.id } ?: 0) + 1
        entries.add(0, Entry(id, title, note, priority, today))
        save()
        return id
    }

    /**
     * A sample whose title and note the user leaves as shown stays a sample; once either is changed, the entry is
     * the user's, with both texts as they stand.
     */
    fun update(id: Int, title: String, note: String, priority: Priority, resources: Resources) = change(id) {
        if (it.isSample && title == it.title(resources) && note == it.note(resources)) {
            it.copy(priority = priority)
        } else {
            it.copy(typedTitle = title, typedNote = note, priority = priority, sample = null)
        }
    }

    fun finish(id: Int) = change(id) { it.copy(state = EntryState.Done) }

    fun setHidden(id: Int, hidden: Boolean) = change(id) { it.copy(hidden = hidden) }

    fun delete(id: Int) {
        entries.removeAll { it.id == id }
        save()
    }

    /** Waits until every change so far is in the file (tests, and before a process may end on purpose). */
    fun flush() {
        writer.submit {}.get(5, TimeUnit.SECONDS)
    }

    private fun change(id: Int, block: (Entry) -> Entry) {
        val i = entries.indexOfFirst { it.id == id }
        if (i >= 0) {
            entries[i] = block(entries[i])
            save()
        }
    }

    private fun save() {
        val target = file ?: return
        val text = encode(entries.toList())
        writer.execute {
            val out = target.startWrite()
            try {
                out.write(text.toByteArray(Charsets.UTF_8))
                target.finishWrite(out)
            } catch (e: IOException) {
                // the old file stays; the error ends the app loudly rather than losing entries unseen
                target.failWrite(out)
                throw e
            }
        }
    }

    companion object {
        private const val VERSION = 1

        /**
         * The entries in [dir]/entries.json; on the first start the invented samples (BEL-09), written there at once,
         * so a deleted sample stays deleted.
         */
        fun open(dir: File): EntryStore {
            val file = AtomicFile(File(dir, "entries.json"))
            val stored = if (file.baseFile.exists()) decode(String(file.readFully(), Charsets.UTF_8)) else null
            return EntryStore(file, stored ?: samples()).also { if (stored == null) it.save() }
        }

        /** The invented samples in memory only, for previews and tests. */
        fun sample(): EntryStore = EntryStore(null, samples())

        private fun samples(): List<Entry> {
            val priorities = listOf(Priority.High, Priority.Normal, Priority.Low, Priority.Normal, Priority.Normal)
            val states = listOf(EntryState.Open, EntryState.Open, EntryState.Open, EntryState.Done, EntryState.Done)
            return priorities.indices.map { i ->
                Entry(
                    id = i + 1,
                    typedTitle = "",
                    typedNote = "",
                    priority = priorities[i],
                    created = LocalDate.of(2026, 10, 20 - 2 * i),
                    state = states[i],
                    sample = i,
                )
            }
        }

        private fun encode(entries: List<Entry>): String {
            val list = JSONArray()
            entries.forEach { e ->
                list.put(
                    JSONObject()
                        .put("id", e.id)
                        .put("title", e.typedTitle)
                        .put("note", e.typedNote)
                        .put("priority", e.priority.name)
                        .put("created", e.created.toString())
                        .put("state", e.state.name)
                        .put("hidden", e.hidden)
                        .apply { e.sample?.let { put("sample", it) } },
                )
            }
            return JSONObject().put("version", VERSION).put("entries", list).toString()
        }

        private fun decode(text: String): List<Entry> {
            val list = JSONObject(text).getJSONArray("entries")
            return List(list.length()) { i ->
                val o = list.getJSONObject(i)
                Entry(
                    id = o.getInt("id"),
                    typedTitle = o.getString("title"),
                    typedNote = o.getString("note"),
                    priority = Priority.valueOf(o.getString("priority")),
                    created = LocalDate.parse(o.getString("created")),
                    state = EntryState.valueOf(o.getString("state")),
                    hidden = o.getBoolean("hidden"),
                    sample = if (o.has("sample")) o.getInt("sample") else null,
                )
            }
        }
    }
}
