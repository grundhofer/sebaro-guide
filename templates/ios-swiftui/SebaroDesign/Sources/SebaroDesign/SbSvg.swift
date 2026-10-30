import Foundation
import SwiftUI

/// The SVG subset of the generated icon sprite (icons/dist/sprite.svg, tools/icons.py) and the generated sign tiles
/// (brand/inline/tile-<id>[-small].svg, brand_assets.py): `symbol`/`svg` with `viewBox`, nested `g` with
/// `translate`/`scale`/`matrix` transforms, `path` (M L H V C S Q T A Z, absolute and relative), `circle`, `ellipse`,
/// `rect` (rx/ry), the paint attributes `fill`, `stroke`, `stroke-width`, `fill-rule` and `class`. Read at run time from
/// the package resources, so Swift draws exactly the generated geometry: there is no second icon source (one source
/// per fact) and no hand-made asset catalog. Anything outside the subset is reported in `problems`, never skipped.
public struct SbSvgDocument: Sendable {
    public let viewBox: CGRect
    public let shapes: [SbSvgShape]
    public let problems: [String]
}

/// One drawn element with its resolved paint.
public struct SbSvgShape: Sendable {
    public enum Paint: Sendable, Equatable { case none, current, color(String) }
    public let path: Path
    public let fill: Paint
    public let stroke: Paint
    /// nil = inherit the stroke width of the use site (the sprite's per-size width, icons.json grammar.strokes).
    public let strokeWidth: CGFloat?
    public let evenOdd: Bool
    public let classes: [String]
}

enum SbSvgParser {
    static func parseDocument(_ data: Data) -> (symbols: [String: SbSvgDocument], root: SbSvgDocument?) {
        let delegate = Delegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        if !parser.parse() {
            delegate.problems.append("XML: \(parser.parserError?.localizedDescription ?? "unknown error")")
        }
        delegate.finishRoot()
        return (delegate.symbols, delegate.root)
    }

    struct Style {
        var fill: SbSvgShape.Paint = .current      // SVG default fill is black; every sebaro file sets it, ink = tint
        var stroke: SbSvgShape.Paint = .none
        var strokeWidth: CGFloat?
        var evenOdd = false
        var transform = CGAffineTransform.identity
        var classes: [String] = []
    }

    final class Delegate: NSObject, XMLParserDelegate {
        var symbols: [String: SbSvgDocument] = [:]
        var root: SbSvgDocument?
        var problems: [String] = []
        private var stack: [Style] = [Style()]
        private var current: (id: String, viewBox: CGRect, shapes: [SbSvgShape], problems: [String])?
        private var rootBox: CGRect?
        private var rootShapes: [SbSvgShape] = []
        private var rootProblems: [String] = []
        private var skipDepth = 0

        func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?,
                    attributes a: [String: String] = [:]) {
            if skipDepth > 0 { skipDepth += 1; return }
            var style = applyStyle(stack.last!, a)
            switch name {
            case "svg":
                rootBox = SbSvgParser.viewBox(a["viewBox"]) ?? SbSvgParser.viewBox("0 0 \(a["width"] ?? "24") \(a["height"] ?? "24")")
                stack.append(style)
            case "symbol":
                current = (a["id"] ?? "", SbSvgParser.viewBox(a["viewBox"]) ?? CGRect(x: 0, y: 0, width: 24, height: 24), [], [])
                style.transform = .identity
                stack.append(style)
            case "g":
                stack.append(style)
            case "path", "circle", "ellipse", "rect":
                var problems: [String] = []
                let path: Path?
                switch name {
                case "path": path = SbSvgPathParser.parse(a["d"] ?? "", problems: &problems)
                case "circle":
                    let r = num(a["r"]), cx = num(a["cx"]), cy = num(a["cy"])
                    path = Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
                case "ellipse":
                    let rx = num(a["rx"]), ry = num(a["ry"]), cx = num(a["cx"]), cy = num(a["cy"])
                    path = Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
                default:
                    let r = CGRect(x: num(a["x"]), y: num(a["y"]), width: num(a["width"]), height: num(a["height"]))
                    let rx = a["rx"].map(num) ?? a["ry"].map(num) ?? 0, ry = a["ry"].map(num) ?? rx
                    path = Path(roundedRect: r, cornerSize: CGSize(width: rx, height: ry))
                }
                if let path {
                    let shape = SbSvgShape(path: path.applying(style.transform), fill: style.fill, stroke: style.stroke,
                                           strokeWidth: style.strokeWidth.map { $0 * scaleOf(style.transform) },
                                           evenOdd: style.evenOdd, classes: style.classes)
                    if current != nil { current!.shapes.append(shape) } else { rootShapes.append(shape) }
                }
                if !problems.isEmpty {
                    if current != nil { current!.problems += problems } else { rootProblems += problems }
                }
                stack.append(style)
            case "title", "desc", "defs", "style", "metadata":
                skipDepth = 1
            default:
                let p = "unsupported element <\(name)>"
                if current != nil { current!.problems.append(p) } else { rootProblems.append(p) }
                skipDepth = 1
            }
        }

        func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
            if skipDepth > 0 { skipDepth -= 1; return }
            if stack.count > 1 { stack.removeLast() }
            if name == "symbol", let c = current {
                symbols[c.id] = SbSvgDocument(viewBox: c.viewBox, shapes: c.shapes, problems: c.problems)
                current = nil
            }
        }

        func finishRoot() {
            if let box = rootBox, symbols.isEmpty {
                root = SbSvgDocument(viewBox: box, shapes: rootShapes, problems: rootProblems + problems)
            }
        }

        private func applyStyle(_ base: Style, _ a: [String: String]) -> Style {
            var s = base
            if let f = a["fill"] { s.fill = SbSvgParser.paint(f) }
            if let st = a["stroke"] { s.stroke = SbSvgParser.paint(st) }
            if let w = a["stroke-width"], let v = Double(w) { s.strokeWidth = CGFloat(v) }
            if let r = a["fill-rule"] { s.evenOdd = (r == "evenodd") }
            if let c = a["class"] { s.classes = c.split(separator: " ").map(String.init) }
            // The sprite's tone classes paint with the ink too (the system has no second icon tone on iOS).
            if s.classes.contains("sb-sym-tone") { s.fill = .current }
            if s.classes.contains("sb-sym-tone-stroke") { s.stroke = .current }
            if let t = a["transform"] { s.transform = SbSvgParser.transform(t).concatenating(base.transform) }
            return s
        }

        private func num(_ s: String?) -> CGFloat { CGFloat(Double(s ?? "0") ?? 0) }
        private func scaleOf(_ t: CGAffineTransform) -> CGFloat { sqrt(abs(t.a * t.d - t.b * t.c)) }
    }

    static func viewBox(_ s: String?) -> CGRect? {
        guard let s else { return nil }
        let v = s.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
        return v.count == 4 ? CGRect(x: v[0], y: v[1], width: v[2], height: v[3]) : nil
    }

    static func paint(_ s: String) -> SbSvgShape.Paint {
        switch s.trimmingCharacters(in: .whitespaces) {
        case "none": return .none
        case "currentColor": return .current
        case let other: return .color(other)
        }
    }

    /// `translate(x y)`, `scale(s [t])`, `matrix(a b c d e f)`, applied left to right as in SVG.
    static func transform(_ s: String) -> CGAffineTransform {
        var result = CGAffineTransform.identity
        let scanner = s as NSString
        let regex = try! NSRegularExpression(pattern: #"(translate|scale|matrix)\s*\(([^)]*)\)"#)
        for m in regex.matches(in: s, range: NSRange(location: 0, length: scanner.length)) {
            let kind = scanner.substring(with: m.range(at: 1))
            let v = scanner.substring(with: m.range(at: 2))
                .split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }.map { CGFloat($0) }
            let t: CGAffineTransform
            switch kind {
            case "translate": t = CGAffineTransform(translationX: v.first ?? 0, y: v.count > 1 ? v[1] : 0)
            case "scale": t = CGAffineTransform(scaleX: v.first ?? 1, y: v.count > 1 ? v[1] : (v.first ?? 1))
            default: t = v.count == 6 ? CGAffineTransform(a: v[0], b: v[1], c: v[2], d: v[3], tx: v[4], ty: v[5]) : .identity
            }
            // SVG: transform="A B" maps a point p to A(B(p)).
            result = t.concatenating(result)
        }
        return result
    }
}

/// SVG path data → SwiftUI Path, with the endpoint arc conversion of SVG 1.1 F.6.
enum SbSvgPathParser {
    static func parse(_ d: String, problems: inout [String]) -> Path {
        var path = Path()
        let tokens = tokenize(d)
        var i = 0
        var cmd: Character = "M"
        var cur = CGPoint.zero, start = CGPoint.zero
        var lastCtrl: CGPoint?, lastQuad: CGPoint?
        func n() -> CGFloat? {
            guard i < tokens.count, case .number(let v) = tokens[i] else { return nil }
            i += 1
            return v
        }
        while i < tokens.count {
            if case .command(let c) = tokens[i] { cmd = c; i += 1 }
            let rel = cmd.isLowercase
            let base = rel ? cur : .zero
            switch cmd.uppercased() {
            case "M":
                guard let x = n(), let y = n() else { problems.append("path: bad M"); return path }
                cur = CGPoint(x: base.x + x, y: base.y + y); start = cur
                path.move(to: cur)
                cmd = rel ? "l" : "L"           // further pairs are line-tos
                lastCtrl = nil; lastQuad = nil
            case "L":
                guard let x = n(), let y = n() else { problems.append("path: bad L"); return path }
                cur = CGPoint(x: base.x + x, y: base.y + y); path.addLine(to: cur); lastCtrl = nil; lastQuad = nil
            case "H":
                guard let x = n() else { problems.append("path: bad H"); return path }
                cur = CGPoint(x: (rel ? cur.x : 0) + x, y: cur.y); path.addLine(to: cur); lastCtrl = nil; lastQuad = nil
            case "V":
                guard let y = n() else { problems.append("path: bad V"); return path }
                cur = CGPoint(x: cur.x, y: (rel ? cur.y : 0) + y); path.addLine(to: cur); lastCtrl = nil; lastQuad = nil
            case "C":
                guard let x1 = n(), let y1 = n(), let x2 = n(), let y2 = n(), let x = n(), let y = n()
                else { problems.append("path: bad C"); return path }
                let c1 = CGPoint(x: base.x + x1, y: base.y + y1), c2 = CGPoint(x: base.x + x2, y: base.y + y2)
                cur = CGPoint(x: base.x + x, y: base.y + y)
                path.addCurve(to: cur, control1: c1, control2: c2); lastCtrl = c2; lastQuad = nil
            case "S":
                guard let x2 = n(), let y2 = n(), let x = n(), let y = n() else { problems.append("path: bad S"); return path }
                let c1 = lastCtrl.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let c2 = CGPoint(x: base.x + x2, y: base.y + y2)
                cur = CGPoint(x: base.x + x, y: base.y + y)
                path.addCurve(to: cur, control1: c1, control2: c2); lastCtrl = c2; lastQuad = nil
            case "Q":
                guard let x1 = n(), let y1 = n(), let x = n(), let y = n() else { problems.append("path: bad Q"); return path }
                let c = CGPoint(x: base.x + x1, y: base.y + y1)
                cur = CGPoint(x: base.x + x, y: base.y + y)
                path.addQuadCurve(to: cur, control: c); lastQuad = c; lastCtrl = nil
            case "T":
                guard let x = n(), let y = n() else { problems.append("path: bad T"); return path }
                let c = lastQuad.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                cur = CGPoint(x: base.x + x, y: base.y + y)
                path.addQuadCurve(to: cur, control: c); lastQuad = c; lastCtrl = nil
            case "A":
                guard let rx = n(), let ry = n(), let rot = n(), let large = n(), let sweep = n(), let x = n(), let y = n()
                else { problems.append("path: bad A"); return path }
                let end = CGPoint(x: base.x + x, y: base.y + y)
                addArc(&path, from: cur, to: end, rx: rx, ry: ry, rotation: rot, large: large != 0, sweep: sweep != 0)
                cur = end; lastCtrl = nil; lastQuad = nil
            case "Z":
                path.closeSubpath(); cur = start; lastCtrl = nil; lastQuad = nil
                // a number after Z would be a syntax error; the next token must be a command
                if i < tokens.count, case .number = tokens[i] { problems.append("path: number after Z"); return path }
            default:
                problems.append("path: unsupported command \(cmd)")
                return path
            }
        }
        return path
    }

    enum Token { case command(Character), number(CGFloat) }

    static func tokenize(_ d: String) -> [Token] {
        var out: [Token] = []
        var numberText = ""
        func flush() {
            if !numberText.isEmpty, let v = Double(numberText) { out.append(.number(CGFloat(v))) }
            numberText = ""
        }
        var prev: Character = " "
        for ch in d {
            if "MmLlHhVvCcSsQqTtAaZz".contains(ch) {
                flush(); out.append(.command(ch))
            } else if ch == "-" && !(prev == "e" || prev == "E") {
                flush(); numberText = "-"
            } else if ch == "." && numberText.contains(".") && !numberText.contains("e") {
                flush(); numberText = "."
            } else if ch.isNumber || ch == "." || ch == "e" || ch == "E" || ch == "-" {
                numberText.append(ch)
            } else {
                flush()
            }
            prev = ch
        }
        flush()
        return out
    }

    /// SVG elliptical arc (endpoint parameterisation) as cubic segments.
    static func addArc(_ path: inout Path, from p0: CGPoint, to p1: CGPoint, rx rxIn: CGFloat, ry ryIn: CGFloat,
                       rotation: CGFloat, large: Bool, sweep: Bool) {
        if p0 == p1 { return }
        var rx = abs(rxIn), ry = abs(ryIn)
        if rx == 0 || ry == 0 { path.addLine(to: p1); return }
        let phi = rotation * .pi / 180, cphi = cos(phi), sphi = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1p = cphi * dx + sphi * dy, y1p = -sphi * dx + cphi * dy
        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 { rx *= sqrt(lambda); ry *= sqrt(lambda) }
        let num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
        let den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
        var coef = den == 0 ? 0 : sqrt(max(0, num / den))
        if large == sweep { coef = -coef }
        let cxp = coef * rx * y1p / ry, cyp = -coef * ry * x1p / rx
        let cx = cphi * cxp - sphi * cyp + (p0.x + p1.x) / 2
        let cy = sphi * cxp + cphi * cyp + (p0.y + p1.y) / 2
        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
            return a
        }
        let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var delta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
        if !sweep && delta > 0 { delta -= 2 * .pi }
        if sweep && delta < 0 { delta += 2 * .pi }
        let segments = max(1, Int(ceil(abs(delta) / (.pi / 2))))
        let step = delta / CGFloat(segments)
        let k = 4.0 / 3.0 * tan(step / 4)
        var t = theta1
        func point(_ a: CGFloat) -> CGPoint {
            CGPoint(x: cx + rx * cos(a) * cphi - ry * sin(a) * sphi, y: cy + rx * cos(a) * sphi + ry * sin(a) * cphi)
        }
        func deriv(_ a: CGFloat) -> CGPoint {
            CGPoint(x: -rx * sin(a) * cphi - ry * cos(a) * sphi, y: -rx * sin(a) * sphi + ry * cos(a) * cphi)
        }
        for s in 0..<segments {
            let t2 = t + step
            let a = point(t), b = (s == segments - 1) ? p1 : point(t2)
            let da = deriv(t), db = deriv(t2)
            path.addCurve(to: b, control1: CGPoint(x: a.x + k * da.x, y: a.y + k * da.y),
                          control2: CGPoint(x: b.x - k * db.x, y: b.y - k * db.y))
            t = t2
        }
    }
}

// MARK: - Icons

/// The icon set of the system (icons/dist/sprite.svg + icons.json, tools/icons.py; ICONS-GUIDE), read once from the
/// package resources. Names are the sprite ids: `home`, `home--filled`, `success--filled-16` …
public enum SbIcons {
    struct Store: Sendable {
        let symbols: [String: SbSvgDocument]
        let strokes: [String: Double]
        let problems: [String]
    }

    static let store: Store = {
        var problems: [String] = []
        var symbols: [String: SbSvgDocument] = [:]
        if let url = Bundle.module.url(forResource: "sprite", withExtension: "svg"),
           let data = try? Data(contentsOf: url) {
            symbols = SbSvgParser.parseDocument(data).symbols
        } else {
            problems.append("Resources/Icons/sprite.svg is missing")
        }
        var strokes: [String: Double] = [:]
        if let url = Bundle.module.url(forResource: "icons", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let grammar = json["grammar"] as? [String: Any], let s = grammar["strokes"] as? [String: Double] {
            strokes = s
        } else {
            problems.append("Resources/Icons/icons.json (grammar.strokes) is missing")
        }
        for (id, doc) in symbols where !doc.problems.isEmpty {
            problems.append("\(id): " + doc.problems.joined(separator: "; "))
        }
        return Store(symbols: symbols, strokes: strokes, problems: problems)
    }()

    /// Every sprite id.
    public static var names: [String] { store.symbols.keys.sorted() }
    /// What the sprite reader could not read (empty when every symbol is in the subset).
    public static var problems: [String] { store.problems }

    public static func symbol(_ name: String) -> SbSvgDocument? { store.symbols[name] }

    /// The sprite id and stroke width for a display size: 16 pt takes the 16-px master (`<name>--16`, stroke m16)
    /// when it exists, else the 24 master with stroke s16; 20/24/32/48 take the 24 master with s20/s24/s32/s48
    /// (icons.json grammar.strokes, the same numbers as sprite.css).
    static func resolve(_ name: String, size: CGFloat) -> (id: String, stroke: CGFloat)? {
        let strokes = store.strokes
        func w(_ key: String, _ fallback: Double) -> CGFloat { CGFloat(strokes[key] ?? fallback) }
        if size <= 16 {
            let small = name.hasSuffix("--filled") ? name + "-16" : name + "--16"
            if store.symbols[small] != nil { return (small, w("m16", 1.5)) }
            return store.symbols[name] != nil ? (name, w("s16", 2.25)) : nil
        }
        guard store.symbols[name] != nil else { return nil }
        if name.hasSuffix("--spot") { return (name, w("spot", 2)) }
        switch size {
        case ..<22: return (name, w("s20", 1.8))
        case ..<28: return (name, w("s24", 1.75))
        case ..<40: return (name, w("s32", 1.5))
        default: return (name, w("s48", 1.125))
        }
    }
}

/// Draws a document in a rect: `ink` replaces every paint (currentColor and fixed colours alike), so the geometry is
/// the generated one and the colour is a role of the caller. Shapes whose class is in `skipClasses` are not drawn.
struct SbSvgCanvas: View {
    let document: SbSvgDocument
    let ink: Color
    var strokeWidth: CGFloat = 1.75
    var skipClasses: Set<String> = []

    var body: some View {
        Canvas { ctx, size in
            let box = document.viewBox
            let s = min(size.width / box.width, size.height / box.height)
            let dx = (size.width - box.width * s) / 2 - box.minX * s
            let dy = (size.height - box.height * s) / 2 - box.minY * s
            let t = CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: dx, ty: dy)
            for shape in document.shapes where skipClasses.isDisjoint(with: shape.classes) {
                let p = shape.path.applying(t)
                if shape.fill != .none {
                    ctx.fill(p, with: .color(ink), style: FillStyle(eoFill: shape.evenOdd))
                }
                if shape.stroke != .none {
                    ctx.stroke(p, with: .color(ink),
                               style: StrokeStyle(lineWidth: (shape.strokeWidth ?? strokeWidth) * s,
                                                  lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
}

/// An icon of the system set at a display size (16, 20, 24, 32, 48 pt), in the caller's foreground colour.
/// Decorative by default (hidden from VoiceOver); give icon-only buttons an accessibility label (German, the action).
public struct SbIcon: View {
    let name: String
    let size: CGFloat
    let color: Color?

    public init(_ name: String, size: CGFloat = SebaroSize.iconLg, color: Color? = nil) {
        self.name = name
        self.size = size
        self.color = color
    }

    public var body: some View {
        Group {
            if let r = SbIcons.resolve(name, size: size), let doc = SbIcons.symbol(r.id) {
                if let color {
                    SbSvgCanvas(document: doc, ink: color, strokeWidth: r.stroke)
                } else {
                    SbIconForeground(document: doc, stroke: r.stroke)
                }
            } else {
                // Fail loud in debug builds: a name that is not in the sprite is a bug of the caller.
                Color.clear.onAppear { assertionFailure("SbIcon: no icon '\(name)' in icons/dist/sprite.svg") }
            }
        }
        .frame(width: size * aspect, height: size)
        .accessibilityHidden(true)
    }

    /// Width / height of the symbol: 1 for icons, 4:3 for the 128 × 96 spots (pass the height as `size`).
    private var aspect: CGFloat {
        guard let box = SbIcons.symbol(name)?.viewBox, box.height > 0 else { return 1 }
        return box.width / box.height
    }
}

/// Draws with the inherited foreground style (Canvas needs a concrete Color; `.foregroundStyle` reaches it through
/// a mask).
private struct SbIconForeground: View {
    let document: SbSvgDocument
    let stroke: CGFloat
    var body: some View {
        Rectangle().fill(.foreground).mask(SbSvgCanvas(document: document, ink: .black, strokeWidth: stroke))
    }
}
