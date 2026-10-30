import SebaroDesign
import SwiftUI

/// Top-level list: search, groups with their count in the head (HAL-05, DAT-01), done rows recede (DAT-02), the end
/// sentence, the empty state with the primary action below (DAT-07), „Beispieldaten“ in each sample row (BEL-09) and
/// „Ausblenden“ in the row's context menu (no swipe, MOB-06) with an undo toast (EBE-05).
struct ListScreen: View {
    let store: EntryStore
    @Binding var query: String
    let toasts: SbToastState
    let tabs: SbTabBar
    let onCreate: () -> Void
    @Environment(\.words) private var words

    var body: some View {
        let visible = store.entries.filter { !$0.hidden }
        let needle = query.trimmingCharacters(in: .whitespaces)
        let shown = needle.isEmpty ? visible : visible.filter {
            $0.title(words).localizedCaseInsensitiveContains(needle) || $0.note(words).localizedCaseInsensitiveContains(needle)
        }
        SbScreen(primaryAction: SbPrimaryActionModel(words("list.create"), icon: "plus", action: onCreate), tabs: tabs) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if visible.isEmpty {
                        SbEmptyState(words("list.empty.title"), text: words("list.empty.text"))
                    } else {
                        SbSearchField(words("list.search.label"), text: $query, placeholder: words("list.search.placeholder"))
                            .padding(.horizontal, SebaroSpacing.gutter)
                            .padding(.vertical, SebaroSpace.s4)
                        if shown.isEmpty {
                            SbEmptyState(words("list.nohit.title", needle), text: words("list.nohit.text"))
                        } else {
                            groups(shown)
                            SbListEnd(words("list.end"))
                        }
                    }
                }
            }
            .sbToastHost(toasts)
        }
        // without a product id the export has no sign tile, so the top-level title stands inline (see README,
        // „Lücken der Vorlage“); a product uses .sbTopLevelNavigation(title:product:) with its tile
        .sbNavigationTitle(words("list.title"))
    }

    @ViewBuilder
    private func groups(_ shown: [Entry]) -> some View {
        ForEach([EntryState.open, .done], id: \.self) { state in
            let group = shown.filter { $0.state == state }
            if !group.isEmpty {
                SbListHeader(words(state == .open ? "group.open" : "group.done"), count: group.count)
                ForEach(group) { entry in row(entry) }
            }
        }
    }

    private func row(_ entry: Entry) -> some View {
        NavigationLink(value: entry.id) {
            SbListRow(entry.title(words), meta: words("list.meta.created", words.noteDate(entry.created)),
                      done: entry.state == .done) {
                // BEL-09: each invented sample carries the marker in its row, the user's entries never
                if entry.isSample { SbDemoMarker(words("demo.marker")) }
            }
        }
        .buttonStyle(.plain)
        .sbContextMenu([SbMenuItem(words("list.hide"), icon: "eye-off") { hide(entry) }])
    }

    /// Hides the entry and offers „Rückgängig“ in a toast (EBE-05: the toast for an undoable step, never for a result).
    func hide(_ entry: Entry) {
        store.setHidden(entry.id, true)
        toasts.show(SbToastData(words("list.hidden.toast", entry.title(words)), actionLabel: words("toast.undo")) {
            store.setHidden(entry.id, false)
        })
    }
}
