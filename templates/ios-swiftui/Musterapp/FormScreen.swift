import SebaroDesign
import SwiftUI

/// The values of the form while it is open.
struct FormDraft: Equatable {
    var title = ""
    var note = ""
    var priority = Priority.normal
    var effort = 1
    var remind = SbTimeOfDay(18)

    init() {}

    init(entry: Entry?, words: Words) {
        guard let entry else { return }
        title = entry.title(words)
        note = entry.note(words)
        priority = entry.priority
        effort = entry.effort
        remind = entry.remind
    }

    var input: EntryInput {
        EntryInput(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                   note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                   priority: priority, effort: effort, remind: remind)
    }
}

/// Form as sebaro's full-height sheet with „Sichern“ at the bottom (MOB-07, EBE-04): „Beispieldaten“ while an invented
/// sample is edited unchanged (BEL-09), labels above the fields (EIN-01), „(optional)“ on the voluntary note, nothing
/// on the required title; the primary action stays enabled and says „Titel fehlt.“ at the empty field, focus on it
/// (STA-03); segments that turn into a select at large text (EIN-04, ZUG-09); the stepper and the time row with its
/// sheet (EIN-06); the data-path line under the action (BEL-10); „Abbrechen“ with changes asks „Abbrechen“ ·
/// „Verwerfen“ · „Sichern“ (AKT-11), and a swipe down cannot close the sheet while there are changes.
struct FormScreen: View {
    enum Field: Hashable { case title, note }

    static let noteMax = 500

    let request: FormRequest
    let store: EntryStore
    let words: Words
    let onClose: () -> Void
    private let initial: FormDraft
    private let sample: Bool
    @State private var draft: FormDraft
    @State private var errors: [Field: String] = [:]
    @State private var askUnsaved: Bool
    @FocusState private var focus: Field?

    /// `draft` and `askUnsaved` start the form in a given state (tests and screenshots).
    init(request: FormRequest, store: EntryStore, words: Words, onClose: @escaping () -> Void,
         draft: FormDraft? = nil, askUnsaved: Bool = false) {
        self.request = request
        self.store = store
        self.words = words
        self.onClose = onClose
        var entry: Entry?
        if case .edit(let id) = request { entry = store.entry(id) }
        let initial = FormDraft(entry: entry, words: words)
        self.initial = initial
        self.sample = entry?.isSample ?? false
        _draft = State(initialValue: draft ?? initial)
        _askUnsaved = State(initialValue: askUnsaved)
    }

    private var isNew: Bool { request == .new }
    var isDirty: Bool { draft != initial }

    var body: some View {
        SbFormSheet(title: words(isNew ? "form.new.title" : "form.edit.title"), isDirty: isDirty,
                    primaryAction: SbPrimaryActionModel(words(isNew ? "form.create" : "form.save"),
                                                        hint: words("hint.local"), action: submit),
                    onCancel: requestClose) {
            VStack(alignment: .leading, spacing: SebaroSpace.s6) {
                // BEL-09: editing an invented sample says so while its words are still the sample's (EntryStore.update)
                if sample && draft.title == initial.title && draft.note == initial.note {
                    SbDemoMarker(words("demo.marker"))
                }
                SbTextField(words("form.title.label"), text: text(\.title, clears: .title), error: errors[.title])
                    .sbFieldFocus($focus, equals: .title)
                SbSegmented(words("form.priority.label"), options: Priority.allCases.map { ($0, words($0.key)) },
                            selection: $draft.priority)
                SbStepper(words("form.effort.label"), value: $draft.effort, range: 1...12,
                          spoken: { words("hours", $0) })
                // the time row is a full-width row with its own gutter, like a list row
                SbTimeRow(words("form.remind.label"), time: $draft.remind, text: words("form.remind.text"))
                    .padding(.horizontal, -SebaroSpacing.gutter)
                SbTextField(words("form.note.label"), text: text(\.note, clears: .note), error: errors[.note],
                            optional: true,
                            counter: words("form.note.counter", words.count(draft.note.count), words.count(Self.noteMax)),
                            multiline: true)
                    .sbFieldFocus($focus, equals: .note)
            }
        }
        .sbUnsavedDialog(isPresented: $askUnsaved,
                         title: isNew ? words("unsaved.new.title") : words("unsaved.edit.title", initial.title),
                         message: words(isNew ? "unsaved.new.text" : "unsaved.edit.text"),
                         saveHint: .onDevice, onSave: submit, onDiscard: onClose)
    }

    /// A field's text; typing removes its error (spec/12 §7).
    private func text(_ key: WritableKeyPath<FormDraft, String>, clears field: Field) -> Binding<String> {
        Binding(get: { draft[keyPath: key] }, set: {
            // the field writes its unchanged text back when it takes focus; only a real change removes the error
            guard $0 != draft[keyPath: key] else { return }
            draft[keyPath: key] = $0
            errors[field] = nil
        })
    }

    /// „Abbrechen“: closes at once without changes, else asks (AKT-11).
    func requestClose() {
        if isDirty { askUnsaved = true } else { onClose() }
    }

    func submit() {
        let check = SbRequiredFields.check([(id: Field.title, label: words("form.title.label"), value: draft.title)],
                                           messages: words.messages)
        var found = check.errors
        if draft.note.count > Self.noteMax {
            found[.note] = words("form.note.too.long", words.count(draft.note.count), words.count(Self.noteMax))
        }
        errors = found
        if let first = check.first ?? found.keys.first {
            focus = first
            return
        }
        switch request {
        case .new: store.add(draft.input, today: Day.today())
        case .edit(let id): store.update(id, draft.input, words: words)
        }
        onClose()
    }
}
