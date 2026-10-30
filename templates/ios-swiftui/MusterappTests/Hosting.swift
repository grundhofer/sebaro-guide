import SebaroDesign
import SwiftUI
import UIKit
import XCTest
@testable import Musterapp

/// One look of a screen: scheme, tone, type size, window size and language.
struct Look: CustomStringConvertible {
    var style: UIUserInterfaceStyle = .light
    var tone: SebaroTone = .cool
    var typeSize: DynamicTypeSize = .large
    var size = Look.phone
    var language = "de"

    /// iPhone 16 / 17 (393 × 852 pt) and the narrowest phone spec/12 serves, the iPhone SE of the first generation
    /// (320 × 568 pt).
    static let phone = CGSize(width: 393, height: 852)
    static let small = CGSize(width: 320, height: 568)

    var description: String {
        [style == .dark ? "dark" : "light", tone == .warm ? "warm" : nil, typeSize == .large ? nil : "ax5",
         size == Look.small ? "320" : "393", language == "de" ? nil : language].compactMap { $0 }.joined(separator: "-")
    }

    var category: UIContentSizeCategory {
        typeSize == .accessibility5 ? .accessibilityExtraExtraExtraLarge : .large
    }
}

/// A screen in a window of its own, as the app shows it: `SebaroAppRoot` with the look's stored choices, the
/// language, the type size. The window belongs to the test host's scene, so sheets and dialogs present for real.
@MainActor
final class Hosted {
    let window: UIWindow
    let host: UIHostingController<AnyView>
    let defaults: UserDefaults

    init(_ view: some View, look: Look) {
        let suite = "musterapp-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        defaults.set(look.style == .dark ? "dark" : "light", forKey: SbThemeMode.storageKey)
        defaults.set(look.tone == .warm ? "warm" : "", forKey: SbSettingKeys.tone)
        defaults.set(look.language, forKey: AppLanguage.storageKey)
        SbNavigationBarAppearance.install(scheme: look.style == .dark ? .dark : .light, tone: look.tone)
        let words = Words(language: look.language)
        let root = AnyView(SebaroAppRoot { view.language(words) }
            .environment(\.dynamicTypeSize, look.typeSize)
            .defaultAppStorage(defaults))
        host = UIHostingController(rootView: root)
        host.traitOverrides.preferredContentSizeCategory = look.category
        host.traitOverrides.userInterfaceStyle = look.style
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        window = scene.map { UIWindow(windowScene: $0) } ?? UIWindow()
        window.frame = CGRect(origin: .zero, size: look.size)
        window.overrideUserInterfaceStyle = look.style
        window.traitOverrides.preferredContentSizeCategory = look.category
        window.rootViewController = host
        window.makeKeyAndVisible()
        if let scene { Self.checkScreen(scene, holds: look.size) }
        settle(1.0)
    }

    /// A look is a phone of its size only when the simulator's screen holds the window and has no safe area at the
    /// sides; otherwise the screen's geometry leaks into the window and every finding of the text check is about the
    /// simulator (an iPhone Duo: 466 × 678 pt with 84 pt on the right).
    static func checkScreen(_ scene: UIWindowScene, holds size: CGSize, file: StaticString = #filePath, line: UInt = #line) {
        let screen = scene.screen.bounds.size
        let probe = UIWindow(windowScene: scene)
        probe.rootViewController = UIViewController()
        probe.isHidden = false
        probe.layoutIfNeeded()
        let sides = (left: probe.safeAreaInsets.left, right: probe.safeAreaInsets.right)
        probe.isHidden = true
        if screen.width < size.width || screen.height < size.height || sides.left > 0 || sides.right > 0 {
            XCTFail("this simulator cannot show a \(Int(size.width)) × \(Int(size.height)) pt look: its screen is "
                    + "\(Int(screen.width)) × \(Int(screen.height)) pt with \(sides.left) pt on the left and \(sides.right) pt "
                    + "on the right; run on an iPhone 16 or 17", file: file, line: line)
        }
    }

    func settle(_ seconds: TimeInterval = 0.5) {
        window.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
        window.layoutIfNeeded()
    }

    /// Every accessibility element of the window, presented sheets and dialogs included.
    var nodes: [AxNode] { AxNode.all(in: window) }

    /// The elements of the topmost presented sheet or dialog, else of the screen: what VoiceOver can reach. The
    /// screen under a sheet is covered (on iOS 17 and 18 also scaled down) and is not measured.
    var topNodes: [AxNode] {
        var top: UIViewController = host
        while let next = top.presentedViewController, !next.isBeingDismissed { top = next }
        return top === host ? nodes : AxNode.all(in: top.view)
    }

    /// Activates the last element whose label starts with `prefix` (a button, a row), as VoiceOver's double tap: the
    /// topmost one, so a sheet's „Eintrag anlegen“ wins over the list's under it.
    @discardableResult
    func activate(_ prefix: String, file: StaticString = #filePath, line: UInt = #line) -> Bool {
        // a pushed screen or a sheet may need a moment longer before its elements are in the tree
        var tries = 0
        while !nodes.contains(where: { $0.label.hasPrefix(prefix) }) && tries < 3 {
            settle(1.0)
            tries += 1
        }
        guard let node = nodes.last(where: { $0.label.hasPrefix(prefix) }) else {
            XCTFail("no element „\(prefix)…“ in \(nodes.map(\.label))", file: file, line: line)
            return false
        }
        let done = node.object.accessibilityActivate()
        settle(1.0)
        return done
    }

    func image(scale: CGFloat = 2) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { ctx in
            if !window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) {
                window.layer.render(in: ctx.cgContext)
            }
        }
    }

    /// The vertical scroll views that can scroll, in window order: a presented sheet's or dialog's last.
    var scrollViews: [UIScrollView] {
        func all(_ view: UIView) -> [UIScrollView] {
            ((view as? UIScrollView).map { [$0] } ?? []) + view.subviews.flatMap(all)
        }
        return all(window).filter {
            !$0.isHidden && $0.contentSize.height + $0.adjustedContentInset.top + $0.adjustedContentInset.bottom > $0.bounds.height + 1
        }
    }

    func close() {
        window.rootViewController?.dismiss(animated: false)
        settle(0.3)
        window.isHidden = true
        window.rootViewController = nil
    }
}

/// One element of the accessibility tree with its frame in screen points.
struct AxNode {
    let label: String
    let frame: CGRect
    let traits: UIAccessibilityTraits
    let object: NSObject

    /// The tree is only built while accessibility runs; the test host switches it on once (as the system does for
    /// VoiceOver), so SwiftUI hands out its elements.
    static let accessibilityOn: Bool = {
        guard let lib = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
              let fn = dlsym(lib, "_AXSApplicationAccessibilitySetEnabled") else { return false }
        unsafeBitCast(fn, to: (@convention(c) (Bool) -> Void).self)(true)
        return true
    }()

    @MainActor
    static func all(in view: UIView) -> [AxNode] {
        precondition(accessibilityOn, "libAccessibility could not be switched on")
        return collect(view)
    }

    @MainActor
    private static func collect(_ object: NSObject) -> [AxNode] {
        if let view = object as? UIView, view.isHidden || view.alpha < 0.01 { return [] }
        if object.isAccessibilityElement {
            return [AxNode(label: object.accessibilityLabel ?? "", frame: object.accessibilityFrame,
                           traits: object.accessibilityTraits, object: object)]
        }
        var children: [NSObject] = []
        if let elements = object.accessibilityElements as? [NSObject] {
            children = elements
        } else {
            let n = object.accessibilityElementCount()
            if n != NSNotFound, n > 0 { children = (0..<n).compactMap { object.accessibilityElement(at: $0) as? NSObject } }
        }
        if children.isEmpty, let view = object as? UIView { children = view.subviews }
        return children.flatMap { collect($0) }
    }
}
