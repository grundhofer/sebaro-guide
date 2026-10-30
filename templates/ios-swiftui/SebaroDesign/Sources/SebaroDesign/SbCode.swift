import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Code, diff, place (spec/02 §3.10, §3.19, §3.27; D67, D85, D91 B13a, D18)

/// The five looks of code (spec/01 §1.8, D67): three muted tones, comments text-muted, everything else text.
public enum SbCodeLook: Sendable { case plain, keyword, string, constant, comment }

/// A run of code in one look (the web's `sb-tok-*` spans).
public struct SbCodeSpan: Sendable {
    public let text: String
    public let look: SbCodeLook
    public init(_ text: String, look: SbCodeLook = .plain) {
        self.text = text
        self.look = look
    }
}

/// The spans as text in their looks; sebaro Mono 500 only, so no bold and no italic.
func sbCodeText(_ spans: [SbCodeSpan], ink: Color, muted: Color) -> AttributedString {
    spans.reduce(into: AttributedString()) { out, span in
        var run = AttributedString(span.text)
        run.foregroundColor = switch span.look {
        case .plain: ink
        case .keyword: SebaroSyntax.keyword
        case .string: SebaroSyntax.string
        case .constant: SebaroSyntax.constant
        case .comment: muted
        }
        out.append(run)
    }
}

/// What the copy button shows: „Kopieren“, after a press „Kopiert“ for 2 s (sb-controls.js); a later press restarts it.
struct SbCopyState: Equatable {
    var presses = 0
    var copied = false
    static let hold: Duration = .seconds(2)

    mutating func press() -> Int {
        presses += 1
        copied = true
        return presses
    }

    /// The timer of press `n` ends: only the latest press clears the word.
    mutating func expire(_ n: Int) { if n == presses { copied = false } }
}

/// Code block (spec/02 §3.10, the one form): on `surfaceSunken`, radius container; a bar with `language` (caption
/// text-muted) and the copy button („Kopieren“, then „Kopiert“ for 2 s; the plain code goes to the clipboard), a hairline
/// under it; then `code` in sebaro Mono (code role) in its five looks, 16 pt inside, without wrapping: long lines scroll
/// sideways inside the block, never the screen. `label` names the code area for VoiceOver. Code reads left to right in
/// every language.
public struct SbCodeBlock: View {
    let code: [SbCodeSpan]
    let language: String?
    let label: String?
    private var context = SbContext()
    @State private var copy = SbCopyState()

    public init(_ code: [SbCodeSpan], language: String? = nil, label: String? = nil) {
        self.code = code
        self.language = language
        self.label = label
    }

    public init(_ code: String, language: String? = nil, label: String? = nil) {
        self.init([SbCodeSpan(code)], language: language, label: label)
    }

    public var body: some View {
        let plain = code.map(\.text).joined()
        VStack(alignment: .leading, spacing: 0) {
            // the language and the copy button in one row; at large text the button goes under the language
            ViewThatFits(in: .horizontal) {
                HStack(spacing: SebaroSpace.s2) {
                    languageText
                    Spacer(minLength: 0)
                    copyButton(plain).fixedSize()
                }
                VStack(alignment: .leading, spacing: 0) {
                    languageText
                    copyButton(plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, SebaroSpace.s4).padding(.trailing, SebaroSpace.s1)
            .overlay(alignment: .bottom) { Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline) }
            ScrollView(.horizontal) {
                Text(sbCodeText(code, ink: context.tone.text, muted: context.tone.textMuted))
                    .sbFont(.code).fixedSize()
                    .padding(SebaroSpace.s4)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .environment(\.layoutDirection, .leftToRight)
            .accessibilityLabel(Text(label ?? ""))
            .accessibilityValue(Text(plain))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(context.tone.surfaceSunken, in: RoundedRectangle(cornerRadius: SebaroRadius.container, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: SebaroRadius.container, style: .continuous))
    }
    @ViewBuilder private var languageText: some View {
        if let language {
            SbWrapText.name(language, style: .caption).foregroundStyle(context.tone.textMuted)
                .frame(minHeight: SebaroSize.targetTouch)
        }
    }

    private func copyButton(_ plain: String) -> some View {
        let m = context.messages
        return Button {
            #if canImport(UIKit)
            UIPasteboard.general.string = plain
            #endif
            let n = copy.press()
            Task { @MainActor in
                try? await Task.sleep(for: SbCopyState.hold)
                copy.expire(n)
            }
        } label: {
            HStack(spacing: SebaroSpace.s1) {
                SbIcon("copy--16", size: SebaroSize.iconSm, color: context.tone.textMuted)
                SbWrapText(copy.copied ? m.codeCopied : m.codeCopy, style: .label).foregroundStyle(context.tone.text)
            }
            .padding(.horizontal, SebaroSpace.s3)
            .frame(minHeight: SebaroSize.targetTouch)
            .contentShape(Rectangle())
        }
        .buttonStyle(SbFillPressStyle())
    }
}

/// A button with the pressed fill (radius control) and the focus ring; no ripple.
struct SbFillPressStyle: ButtonStyle {
    @Environment(\.sebaroTone) private var tone
    @Environment(\.isFocused) private var focused
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? tone.pressedFill : Color.clear,
                        in: RoundedRectangle(cornerRadius: SebaroRadius.control))
            .modifier(SbFocusRing(shape: RoundedRectangle(cornerRadius: SebaroRadius.control), focused: focused))
    }
}

/// The kind of a diff line: unchanged, added (+) or removed (− U+2212).
public enum SbDiffKind: Sendable { case same, added, removed }

/// One line of a diff: its kind, its code in the five looks and its numbers in the old and the new version.
public struct SbDiffLine: Sendable {
    public let kind: SbDiffKind
    public let code: [SbCodeSpan]
    public let old: Int?
    public let new: Int?
    public init(_ kind: SbDiffKind, code: [SbCodeSpan], old: Int? = nil, new: Int? = nil) {
        self.kind = kind
        self.code = code
        self.old = old
        self.new = new
    }
}

/// One hunk: its head („@@ -4,4 +4,5 @@“) and its lines.
public struct SbDiffHunk: Sendable {
    public let head: String
    public let lines: [SbDiffLine]
    public init(_ head: String, lines: [SbDiffLine]) {
        self.head = head
        self.lines = lines
    }
}

/// Diff (spec/02 §3.19, TXT-11, D85): two versions on `surfaceSunken`, radius container. The bar: `file` and
/// `versions`; then the hunks in sebaro Mono, scrolling sideways together: the head in text-muted, each line with its
/// two numbers (text-muted), its sign (+, − or a space) and its code; an added or removed line has the fill
/// `successSubtle` / `dangerSubtle`, never without its sign. Last the counts („2 Zeilen hinzugefügt, 1 entfernt“).
/// VoiceOver reads each line with „hinzugefügt: “ / „entfernt: “ before the code.
public struct SbDiff: View {
    let file: String
    let hunks: [SbDiffHunk]
    let versions: String?
    private var context = SbContext()
    @State private var viewport: CGFloat = 0

    public init(file: String, hunks: [SbDiffHunk], versions: String? = nil) {
        self.file = file
        self.hunks = hunks
        self.versions = versions
    }

    /// What VoiceOver reads for a line: „5 6 hinzugefügt: let x = 1“.
    static func sentence(_ line: SbDiffLine, _ m: SbMessages) -> String {
        let prefix = switch line.kind { case .same: ""; case .added: m.diffAdded; case .removed: m.diffRemoved }
        let numbers = [line.old, line.new].compactMap { $0 }.map(String.init).joined(separator: " ")
        let code = line.code.map(\.text).joined()
        return numbers.isEmpty ? prefix + code : "\(numbers) \(prefix)\(code)"
    }

    public var body: some View {
        let m = context.messages
        let lines = hunks.flatMap(\.lines)
        let added = lines.filter { $0.kind == .added }.count, removed = lines.filter { $0.kind == .removed }.count
        let digits = max(2, String(lines.map { max($0.old ?? 0, $0.new ?? 0) }.max() ?? 0).count)
        let numberProbe = String(repeating: "0", count: digits)
        VStack(alignment: .leading, spacing: 0) {
            SbWrapRow(spacing: SebaroSpace.s3) {
                SbWrapText.fileName(file).font(captionStrong).foregroundStyle(context.tone.text)
                if let versions { SbWrapText(versions, style: .caption).foregroundStyle(context.tone.textMuted) }
            }
            .padding(.horizontal, SebaroSpace.s4).padding(.vertical, SebaroSpace.s2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) { Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline) }
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(hunks.enumerated()), id: \.offset) { _, hunk in
                        Text(hunk.head).sbFont(.code).foregroundStyle(context.tone.textMuted).fixedSize()
                            .padding(.horizontal, SebaroSpace.s4).padding(.vertical, SebaroSpace.s1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(Array(hunk.lines.enumerated()), id: \.offset) { _, line in
                            row(line, probe: numberProbe)
                        }
                    }
                }
                .padding(.vertical, SebaroSpace.s2)
                // every line as wide as the widest, and at least the block: the fills reach the edge
                .frame(minWidth: viewport, alignment: .leading)
            }
            .background(GeometryReader { g in Color.clear.preference(key: SbLineWidthKey.self, value: g.size.width) })
            .onPreferenceChange(SbLineWidthKey.self) { [$viewport] w in if $viewport.wrappedValue != w { $viewport.wrappedValue = w } }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .environment(\.layoutDirection, .leftToRight)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(m.diffRegion(file)))
            SbWrapText(m.diffSum(added, removed, SbMessages.formatCount(added, locale: context.currentLocale),
                                 SbMessages.formatCount(removed, locale: context.currentLocale)))
                .font(sbChartLabelFont(context.scheme)).foregroundStyle(context.tone.textMuted)
                .padding(.horizontal, SebaroSpace.s4).padding(.vertical, SebaroSpace.s2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline) }
        }
        .background(context.tone.surfaceSunken)
        .clipShape(RoundedRectangle(cornerRadius: SebaroRadius.container, style: .continuous))
    }

    private var captionStrong: Font {
        let caption = SebaroTextStyle.caption.resolve(context.scheme), strong = SebaroTextStyle.bodyStrong.resolve(context.scheme)
        return SebaroFonts.font(SebaroTextFace(family: caption.family, size: caption.size, lineHeight: caption.lineHeight,
                                               weight: strong.weight, weightValue: strong.weightValue, tracking: caption.tracking),
                                relativeTo: .caption, monospacedDigits: false)
    }

    private func row(_ line: SbDiffLine, probe: String) -> some View {
        let (sign, fill): (String, Color) = switch line.kind {
        case .same: (" ", .clear)
        case .added: ("+", .sbSuccessSubtle)
        case .removed: ("\u{2212}", .sbDangerSubtle)
        }
        return HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s2) {
            number(line.old, probe: probe)
            number(line.new, probe: probe)
            Text(sign).sbFont(.code).foregroundStyle(context.tone.text).fixedSize()
            Text(sbCodeText(line.code, ink: context.tone.text, muted: context.tone.textMuted)).sbFont(.code).fixedSize()
        }
        .padding(.horizontal, SebaroSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Self.sentence(line, context.messages)))
    }

    private func number(_ n: Int?, probe: String) -> some View {
        Text(probe).sbFont(.code).hidden()
            .overlay(alignment: .trailing) {
                Text(n.map(String.init) ?? "").sbFont(.code).foregroundStyle(context.tone.textMuted).fixedSize()
            }
            .fixedSize()
    }
}

/// A small map drawn in code (spec/02 §3.27), in the units of a `width` × `height` view box: `water` areas, `roads` and
/// `mainRoads` as SVG path data and the `marker` centre.
public struct SbMapSketch: Sendable {
    public let width: CGFloat
    public let height: CGFloat
    public let marker: CGPoint
    public let water: [String]
    public let roads: [String]
    public let mainRoads: [String]
    public init(width: CGFloat, height: CGFloat, marker: CGPoint, water: [String] = [], roads: [String] = [],
                mainRoads: [String] = []) {
        self.width = width
        self.height = height
        self.marker = marker
        self.water = water
        self.roads = roads
        self.mainRoads = mainRoads
    }
}

/// The map link for an address: `maps://?q=<address>` (Apple Maps; the app opens it with `openURL`).
public func sbGeoURL(_ address: String) -> URL? {
    var c = URLComponents()
    c.scheme = "maps"
    c.host = ""
    c.queryItems = [URLQueryItem(name: "q", value: address)]
    return c.url
}

/// Place (spec/02 §3.27, D91 B13a): the 20 pt pin in text and `address` in body, `demoMarker` after it; with `onOpenMap`
/// the link „In Karten öffnen“ with the external-link glyph; then the small static map, `map` drawn in code or
/// `mapImage` (a local image), at most 360 pt wide, 1 pt border-strong frame, radius container, described by
/// `mapDescription`. Never tiles or scripts from a map server (D18).
public struct SbPlace: View {
    let address: String
    let demoMarker: String?
    let onOpenMap: (() -> Void)?
    let map: SbMapSketch?
    let mapImage: Image?
    let mapDescription: String?
    private var context = SbContext()

    public init(_ address: String, demoMarker: String? = nil, onOpenMap: (() -> Void)? = nil, map: SbMapSketch? = nil,
                mapImage: Image? = nil, mapDescription: String? = nil) {
        precondition(map == nil || mapImage == nil, "SbPlace: a sketch or an image, not both")
        precondition((map == nil && mapImage == nil) || mapDescription != nil, "SbPlace: a map needs mapDescription")
        self.address = address
        self.demoMarker = demoMarker
        self.onOpenMap = onOpenMap
        self.map = map
        self.mapImage = mapImage
        self.mapDescription = mapDescription
    }

    public var body: some View {
        let m = context.messages
        let shape = RoundedRectangle(cornerRadius: SebaroRadius.container, style: .continuous)
        VStack(alignment: .leading, spacing: SebaroSpace.s3) {
            HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s2) {
                SbIcon("pin", size: SebaroSize.iconMd, color: context.tone.text).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    SbWrapRow(spacing: SebaroSpace.s1) {
                        SbWrapText(address, style: .body).foregroundStyle(context.tone.text)
                        if let demoMarker { SbDemoMarker(demoMarker) }
                    }
                    if let onOpenMap {
                        Button(action: onOpenMap) {
                            HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s0_5) {
                                SbWrapText(m.placeOpenMap)
                                SbIcon("external-link--16", size: SebaroSize.iconSm, color: context.tone.text)
                            }
                        }
                        .buttonStyle(SbTextActionStyle())
                        .accessibilityAddTraits(.isLink)
                    }
                }
            }
            if map != nil || mapImage != nil {
                Group {
                    if let map { SbMapSketchCanvas(map: map) } else if let mapImage { mapImage.resizable().scaledToFit() }
                }
                .padding(SebaroBorderWidth.control)
                .frame(maxWidth: 360)   // the web's max-inline-size: 360px; no token
                .clipShape(shape)
                .overlay(shape.strokeBorder(context.tone.borderStrong, lineWidth: SebaroBorderWidth.control))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(mapDescription ?? ""))
                .accessibilityAddTraits(.isImage)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SbMapSketchCanvas: View {
    let map: SbMapSketch
    @Environment(\.sebaroTone) private var tone

    var body: some View {
        var problems: [String] = []
        let water = map.water.map { SbSvgPathParser.parse($0, problems: &problems) }
        let roads = map.roads.map { SbSvgPathParser.parse($0, problems: &problems) }
        let main = map.mainRoads.map { SbSvgPathParser.parse($0, problems: &problems) }
        return Canvas { ctx, size in
            let k = size.width / map.width
            var c = ctx
            c.scaleBy(x: k, y: k)
            c.fill(Path(CGRect(x: 0, y: 0, width: map.width, height: map.height)), with: .color(tone.bg))
            for p in water { c.fill(p, with: .color(tone.surfaceSunken)) }
            for p in roads { c.stroke(p, with: .color(tone.border), lineWidth: 6) }
            for p in main { c.stroke(p, with: .color(tone.borderStrong), lineWidth: 9) }
            let ring = CGRect(x: map.marker.x - 20, y: map.marker.y - 20, width: 40, height: 40)
            c.fill(Path(ellipseIn: ring), with: .color(tone.bg))
            c.stroke(Path(ellipseIn: ring), with: .color(tone.text), lineWidth: 2)
        }
        .aspectRatio(map.width / map.height, contentMode: .fit)
        .overlay {
            GeometryReader { g in
                let k = g.size.width / map.width
                SbIcon("pin", size: 24 * k, color: tone.text)
                    .position(x: map.marker.x * k, y: map.marker.y * k)
            }
        }
    }
}
