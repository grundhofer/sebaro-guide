import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(GameController)
import GameController
#endif

/// The two haptic events of D48 (3) with the UIKit generators (D91 I6a), the same names as `rememberSbHaptics()` in
/// Compose (spec/03 §18): `success()` when the primary action succeeded (one short light impulse) and
/// `deleteConfirmed()` when a deletion was confirmed in `SbConfirmDialog` (the stronger warning double impulse).
///
/// Only on the phone and only with touch input (D48, D85). iOS has no input mode like Android, so „touch“ means: an
/// iPhone, no hardware keyboard connected (GameController `GCKeyboard.coalesced`), Switch Control off. iOS itself
/// stays silent when the person turned System Haptics off. Limit: „a keyboard is connected“ is not „the keyboard was
/// just used“; a person who taps the screen while a keyboard is paired gets no impulse. Not checked on a device.
@MainActor
public final class SbHaptics: ObservableObject {
    #if canImport(UIKit) && !os(macOS)
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let warning = UINotificationFeedbackGenerator()
    #endif

    public init() {}

    /// True when the phone is operated by touch (see the type's note).
    public var isTouch: Bool {
        #if canImport(UIKit) && !os(macOS)
        guard UIDevice.current.userInterfaceIdiom == .phone else { return false }
        if UIAccessibility.isSwitchControlRunning { return false }
        #if canImport(GameController)
        if GCKeyboard.coalesced != nil { return false }
        #endif
        return true
        #else
        return false
        #endif
    }

    /// Call shortly before a possible primary action (on press) so the impulse comes without delay.
    public func prepare() {
        #if canImport(UIKit) && !os(macOS)
        if isTouch { light.prepare(); warning.prepare() }
        #endif
    }

    /// The primary action succeeded: one short, light impulse.
    public func success() {
        #if canImport(UIKit) && !os(macOS)
        if isTouch { light.impactOccurred() }
        #endif
    }

    /// A deletion was confirmed: the stronger double impulse.
    public func deleteConfirmed() {
        #if canImport(UIKit) && !os(macOS)
        if isTouch { warning.notificationOccurred(.warning) }
        #endif
    }
}
