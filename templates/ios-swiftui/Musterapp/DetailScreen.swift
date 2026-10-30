import SebaroDesign
import SwiftUI

/// Sub-screen: system back button and inline title (NAV-05), „Beispieldaten“ on an invented sample (BEL-09), state as
/// glyph and word (STA-01), facts flat (DAT-03), the one primary action at the bottom (AKT-01, AKT-02); at the end of
/// the content the final step without trash and the deletion with trash, both with the 45° cut (AKT-07, FOR-04), both
/// asking first in sebaro's dialog (AKT-08, EBE-03).
struct DetailScreen: View {
    let entry: Entry
    let onEdit: () -> Void
    let onFinish: () -> Void
    let onDelete: () -> Void
    @Environment(\.words) private var words
    @Environment(\.sebaroTone) private var tone
    @State private var askDelete = false
    @State private var askFinish = false

    var body: some View {
        let open = entry.state == .open
        let title = entry.title(words)
        let note = entry.note(words)
        // a done entry can no longer change, so its screen has no next step and no primary action
        SbScreen(primaryAction: open ? SbPrimaryActionModel(words("detail.edit"), icon: "edit", action: onEdit) : nil) {
            ScrollView {
                VStack(alignment: .leading, spacing: SebaroSpace.s6) {
                    // BEL-09: an invented sample says so under its title; the user's own entries never carry the marker
                    if entry.isSample { SbDemoMarker(words("demo.marker")) }
                    if open {
                        SbStatus(.neutral, word: words("state.open"), glyph: .pending)
                    } else {
                        SbStatus(.success, word: words("state.done"))
                    }
                    // ZUG-09, TXT-15: the user's own note wraps at spaces and hyphenates only a word wider than the line
                    SbWrapText(note.isEmpty ? words("detail.no.note") : note, style: .body)
                        .foregroundStyle(note.isEmpty ? tone.textMuted : tone.text)
                    SbMetaList([SbMetaItem(words("detail.created"), value: words.dayDate(entry.created)),
                                SbMetaItem(words("detail.priority"), value: words(entry.priority.key)),
                                SbMetaItem(words("detail.effort"), value: words("hours", entry.effort)),
                                SbMetaItem(words("detail.remind"), value: entry.remind.text)],
                               labels: true)
                    VStack(alignment: .leading, spacing: SebaroSpace.s4) {
                        if open {
                            SbDangerAction(words("detail.finish")) { askFinish = true }
                        }
                        SbDangerAction(words("detail.delete"), icon: "trash") { askDelete = true }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SebaroSpacing.gutter)
                .padding(.vertical, SebaroSpace.s4)
            }
        }
        .sbNavigationTitle(title)
        .sbConfirmDialog(isPresented: $askDelete, title: words("dialog.delete.title"),
                         message: words("dialog.delete.text", title), confirm: words("dialog.delete.confirm"),
                         onConfirm: onDelete)
        .sbConfirmDialog(isPresented: $askFinish, title: words("dialog.finish.title"),
                         message: words("dialog.finish.text", title), confirm: words("dialog.finish.confirm"),
                         onConfirm: onFinish)
    }
}
