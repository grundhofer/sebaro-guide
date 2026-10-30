import SwiftUI

/// The same start (D49, D52, spec/03 §14; D91 I9a). The system launch screen shows `bg` and the start tile (the
/// exported `Launch.xcassets`: colour set „SebaroBg“, image „StartTile“, 96 pt, the symbol without the code, D62);
/// `SbStart` repeats exactly that picture as the first SwiftUI frame, so nothing jumps, and keeps it **only while the
/// app really loads** (`ready == false`). Then the tile moves in 200 ms with the emphasized easing onto the 32 pt
/// header tile (marked with `.sbStartTarget()`, which `sbTopLevelNavigation` does), the ground turns transparent and
/// the content enters from below (8 pt). With reduced motion the tile fades out where it stands. Runs once per
/// launch; never longer than the loading, never a logo animation, a progress bar or a spinner.
public struct SbStart<Content: View>: View {
    let product: SebaroProduct
    let ready: Bool
    let content: Content
    @StateObject private var model = SbStartModel()
    private var context = SbContext()

    public init(product: SebaroProduct, ready: Bool, @ViewBuilder content: () -> Content) {
        self.product = product
        self.ready = ready
        self.content = content()
    }

    public var body: some View {
        ZStack {
            content
                .environment(\.sbStartModel, model)
                .offset(y: model.phase == .waiting && !context.reduceMotion ? SebaroX.enterDistance : 0)
                .opacity(model.phase == .waiting ? 0 : 1)
            if model.phase != .done {
                GeometryReader { geo in
                    let origin = geo.frame(in: .global).origin
                    let centre = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    let flying = model.phase == .moving && !context.reduceMotion
                    let target = model.target.map { CGPoint(x: $0.midX - origin.x, y: $0.midY - origin.y) } ?? centre
                    let scale = (model.target?.width ?? SebaroX.startTileSize) / SebaroX.startTileSize
                    ZStack {
                        context.tone.bg.opacity(model.phase == .waiting ? 1 : 0)
                        SbSignTile(product, size: SebaroX.startTileSize, withCode: false)
                            .scaleEffect(flying ? scale : 1)
                            .position(flying ? target : centre)
                            .opacity(model.phase == .moving && context.reduceMotion ? 0 : 1)
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(model.phase == .waiting)
                .accessibilityHidden(true)
            }
        }
        .onAppear { if ready { finish() } }
        .onChange(of: ready) { _, new in if new { finish() } }
    }

    private func finish() {
        guard model.phase == .waiting else { return }
        let reduce = context.reduceMotion
        // reduced motion: the tile fades over the fade token, 200 ms under both settings (D102 (52), spec/03 §13.1)
        let animation = reduce ? SebaroMotion.easingStandard.animation(duration: SebaroX.enterFadeDuration)
                               : SebaroMotion.easingEmphasized.animation(duration: SebaroMotion.durationLong)
        withAnimation(animation) { model.phase = .moving } completion: { model.phase = .done }
    }
}

@MainActor
final class SbStartModel: ObservableObject {
    enum Phase { case waiting, moving, done }
    @Published var phase: Phase = .waiting
    @Published var target: CGRect?
}

private struct SbStartModelKey: EnvironmentKey {
    static let defaultValue: SbStartModel? = nil
}

extension EnvironmentValues {
    var sbStartModel: SbStartModel? {
        get { self[SbStartModelKey.self] }
        set { self[SbStartModelKey.self] = newValue }
    }
}

public extension View {
    /// Marks the header tile the start tile lands on (spec/03 §14): reports its frame and stays hidden until the
    /// start tile has arrived, so the picture is never doubled.
    func sbStartTarget() -> some View { modifier(SbStartTarget()) }
}

struct SbStartTarget: ViewModifier {
    @Environment(\.sbStartModel) private var model
    func body(content: Content) -> some View {
        if let model {
            SbStartTargetBody(content: content, model: model)
        } else {
            content
        }
    }
}

private struct SbStartTargetBody<C: View>: View {
    let content: C
    @ObservedObject var model: SbStartModel
    var body: some View {
        content
            .opacity(model.phase == .done ? 1 : 0)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { model.target = geo.frame(in: .global) }
                        .onChange(of: geo.frame(in: .global)) { _, new in model.target = new }
                }
            }
    }
}
