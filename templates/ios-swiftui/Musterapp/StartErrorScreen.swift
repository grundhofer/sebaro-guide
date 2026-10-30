import SebaroDesign
import SwiftUI

/// What the app shows instead of its places when the entries file cannot be opened (`StoreError`): one calm sentence
/// what happened, that the entries stay unchanged on this device, and what helps (TXT-07). No primary action and no
/// bottom bar: there is nothing to do in the app until the file can be read.
struct StartErrorScreen: View {
    let error: StoreError
    @Environment(\.words) private var words

    var body: some View {
        SbScreen {
            ScrollView {
                SbCallout(.error, text: words(error == .unreadable ? "start.error.unreadable" : "start.error.newer"),
                          title: words("start.error.title"))
                    .padding(SebaroSpacing.gutter)
            }
        }
    }
}
