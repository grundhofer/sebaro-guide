import SwiftUI

// MARK: - Note data of `check_facts.py --notes` (FACTS-CONTRACT §8.6), the Swift twin of spec/10 §6

/// FACTS-CONTRACT §8.1: the state of a fact or note.
public enum SbFactState: String, Sendable {
    case shown, unverifiedDisclosure = "unverified-disclosure", hidden, stale
}

/// The four check states (D15, FACTS-CONTRACT §6.3) in contract order, worst last.
public enum SbCheckResult: String, Sendable {
    case passed, open, skipped, failed
}

/// One note, texts already in the display language.
public struct SbNote: Sendable {
    public let refs: [String]
    public let state: SbFactState
    public let disclosure: Bool
    public let result: SbCheckResult
    public let stateWord: String
    public let checkedOn: String?
    public let forVersion: String?
    public let by: String?
    public let method: [String]
    public let proofNotes: [String]
    public let reasons: [String]
    public let disclosures: [String]
    public let limits: [String]
    public let notVerified: String?

    /// D21: a reassuring claim only when shown; an outflow also when unverified.
    public var showsClaim: Bool { state == .shown || (disclosure && state == .unverifiedDisclosure) }

    /// „bestanden · geprüft am 10.10.2026 für 1.4.0“; with „nicht belegt“ first when not shown (spec/10 §3.3).
    public func shortLine(withVersion: Bool = true) -> String {
        let line: String
        switch result {
        case .open, .skipped:
            line = checkedOn ?? stateWord
        default:
            let date = [checkedOn, withVersion ? forVersion : nil].compactMap { $0 }.joined(separator: " ")
            line = date.isEmpty ? stateWord : "\(stateWord) · \(date)"
        }
        return state == .shown ? line : [notVerified, line].compactMap { $0 }.joined(separator: " · ")
    }

    /// Method, proof notes, reasons, outflows, limits; the sender („Eigene Prüfung …“) and the link follow.
    public var bodyLines: [String] { method + proofNotes + reasons + disclosures + limits }
}

/// The note data of one product (the claims; `note(_:)` finds one by its fact refs).
public struct SbNotes: Sendable {
    public let productName: String
    public let productVersion: String
    public let demo: String?
    public let claims: [SbNote]
    /// Staleness (FACTS-CONTRACT §8.3): the notes' flag, the notice, the next due date (ISO), the network level.
    public var stale = false
    public var staleNotice: String?
    public var nextDueDate: String?
    public var network = "automatic"
    /// The checks of „Wie geprüft?“ in execution order.
    public var checks: [SbCheck] = []

    public func note(_ refs: String...) -> SbNote? { claims.first { $0.refs == refs } }

    /// R2 at run time: stale by the notes, or with a live path to a remote place after the next due date.
    public func isStale(todayIso: String) -> Bool {
        stale || (network != "none" && nextDueDate.map { todayIso > $0 } ?? false)
    }

    public func count(_ result: SbCheckResult) -> Int { checks.filter { $0.result == result }.count }

    /// Reads the JSON of `python3 tools/check_facts.py facts.json --notes`; `lang` "de" or "en".
    public static func parse(_ data: Data, lang: String = "de") throws -> SbNotes {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let product = root["product"] as? [String: Any],
              let notes = root["notes"] as? [String: Any],
              let claims = notes["claims"] as? [[String: Any]]
        else { throw SbNotesError.notNotes }
        let labels = notes["labels"] as? [String: Any] ?? [:]
        var out = SbNotes(productName: product["name"] as? String ?? "",
                          productVersion: product["version"] as? String ?? "",
                          demo: text(labels["demo"], lang),
                          claims: try claims.map { try note($0, lang) })
        out.stale = notes["stale"] as? Bool ?? false
        out.staleNotice = text(labels["stale"], lang)
        out.nextDueDate = (notes["freshness"] as? [String: Any])?["nextDue"] as? String
        out.network = (root["view"] as? [String: Any])?["network"] as? String ?? "automatic"
        out.checks = (notes["checks"] as? [[String: Any]] ?? []).compactMap { check($0, lang) }
        return out
    }

    static func check(_ o: [String: Any], _ lang: String) -> SbCheck? {
        guard let id = o["id"] as? String, let raw = o["state"] as? String, let result = SbCheckResult(rawValue: raw)
        else { return nil }
        let l = o["labels"] as? [String: Any] ?? [:]
        return SbCheck(id: id, result: result, stateWord: text(l["state"], lang) ?? raw,
                       title: text(o["title"], lang) ?? id, date: text(l["date"], lang), by: text(l["by"], lang),
                       reason: text(o["reason"], lang), limit: text(l["limit"], lang),
                       evidence: (o["evidence"] as? [[String: Any]] ?? []).compactMap { $0["ref"] as? String })
    }

    static func note(_ o: [String: Any], _ lang: String) throws -> SbNote {
        guard let stateRaw = o["state"] as? String, let state = SbFactState(rawValue: stateRaw),
              let resultRaw = o["result"] as? String, let result = SbCheckResult(rawValue: resultRaw)
        else { throw SbNotesError.badNote(o["refs"] as? [String] ?? []) }
        let l = o["labels"] as? [String: Any] ?? [:]
        return SbNote(
            refs: o["refs"] as? [String] ?? [],
            state: state,
            disclosure: o["disclosure"] as? Bool ?? false,
            result: result,
            stateWord: text(l["state"], lang) ?? resultRaw,
            checkedOn: text(l["checkedOn"], lang),
            forVersion: text(l["forVersion"], lang),
            by: text(l["by"], lang),
            method: texts(o["method"], lang),
            proofNotes: texts(o["proofNotes"], lang),
            reasons: (o["reasons"] as? [[String: Any]] ?? []).compactMap { text($0["text"], lang) },
            disclosures: (o["disclosures"] as? [[String: Any]] ?? []).compactMap { outflow($0, lang) },
            limits: texts(l["limits"], lang),
            notVerified: text(l["notVerified"], lang))
    }

    /// „<data> an <to>: <trigger>, <transport>, <retention> (<note>)“ (spec/10 §3.3 item 4).
    static func outflow(_ d: [String: Any], _ lang: String) -> String? {
        guard let l = d["labels"] as? [String: Any] else { return nil }
        let head = [text(l["data"], lang), text(l["to"], lang)].compactMap { $0 }
            .joined(separator: lang == "de" ? " an " : " to ")
        var retention = text(l["retention"], lang)
        if let r = retention, let n = text(l["retentionNote"], lang) { retention = "\(r) (\(n))" }
        let tail = [text(l["trigger"], lang), text(l["transport"], lang), retention, text(l["notVerified"], lang)]
            .compactMap { $0 }.joined(separator: ", ")
        let line = [head, tail].filter { !$0.isEmpty }.joined(separator: ": ")
        return line.isEmpty ? nil : line
    }

    static func text(_ v: Any?, _ lang: String) -> String? {
        guard let o = v as? [String: Any] else { return nil }
        let s = (o[lang] as? String) ?? (o["de"] as? String)
        return (s?.isEmpty ?? true) ? nil : s
    }

    static func texts(_ v: Any?, _ lang: String) -> [String] {
        (v as? [Any] ?? []).compactMap { text($0, lang) }
    }
}

/// One check of the list „Wie geprüft?“ in execution order.
public struct SbCheck: Sendable {
    public let id: String
    public let result: SbCheckResult
    public let stateWord: String
    public let title: String
    public let date: String?
    public let by: String?
    public let reason: String?
    public let limit: String?
    public let evidence: [String]
}

public enum SbNotesError: Error, Equatable {
    case notNotes
    case badNote([String])
}

// MARK: - Claim rows that expand in place (D40, D91 I10a)

/// The glyph of a check state, 16 pt: passed `success--filled` in success, failed `error--filled` in danger, open
/// `pending` and skipped `skipped` in text-muted (the sebaro extras of spec/08 §10).
public struct SbCheckStateGlyph: View {
    let result: SbCheckResult
    @Environment(\.sebaroTone) private var tone
    public init(_ result: SbCheckResult) { self.result = result }
    public var body: some View {
        switch result {
        case .passed: SbIcon("success--filled", size: SebaroSize.iconSm, color: .sbSuccess)
        case .failed: SbIcon("error--filled", size: SebaroSize.iconSm, color: .sbDanger)
        case .open: SbIcon("pending", size: SebaroSize.iconSm, color: tone.textMuted)
        case .skipped: SbIcon("skipped", size: SebaroSize.iconSm, color: tone.textMuted)
        }
    }
}

/// The style of a claim row (`DisclosureGroup` keeps the expanded and collapsed state for VoiceOver): the whole row
/// at least 56 pt is the target, the chevron turns 180° in 120 ms (none under reduced motion), an open row carries
/// the 3 pt accent place line at its start (D48 (2)), the note opens in place below the claim.
public struct SbClaimRowStyle: DisclosureGroupStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        SbClaimRowBody(configuration: configuration)
    }
}

struct SbClaimRowBody: View {
    let configuration: DisclosureGroupStyleConfiguration
    private var context = SbContext()
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SebaroSize.controlLg

    init(configuration: DisclosureGroupStyleConfiguration) { self.configuration = configuration }

    var body: some View {
        let open = configuration.isExpanded
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(SebaroMotion.easingStandard.animation(duration: SebaroMotion.durationShort,
                                                                    reduceMotion: context.reduceMotion)) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: SebaroSpace.s3) {
                    configuration.label.frame(maxWidth: .infinity, alignment: .leading)
                    SbIcon("chevron-down", size: SebaroSize.iconLg, color: context.tone.textMuted)
                        .rotationEffect(.degrees(open ? 180 : 0))
                }
                .padding(.horizontal, SebaroSpacing.gutter)
                .padding(.vertical, SebaroSpace.s2)
                .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(SbRowButtonStyle())
            .accessibilityValue(Text(open ? context.messages.evidenceOpen : context.messages.evidenceClosed))
            if open {
                configuration.content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, SebaroSpacing.gutter)
                    .padding(.bottom, SebaroSpace.s3)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .leading) {
            if open { Rectangle().fill(Color.sbAccent).frame(width: SebaroBorderWidth.strong) }
        }
    }
}

/// One claim with its evidence (D40): the claim (body-strong), the result line (check-state glyph + „bestanden ·
/// geprüft am 09.10.2026“), and the note when opened: method, proof notes, reasons, outflows, limits (text), the
/// sender („Eigene Prüfung, von Hand“, text-muted) and „Wie geprüft?“. `text` is the claim when `note.showsClaim`,
/// else the fact's label (the row then says „nicht belegt“).
public struct SbClaimRow: View {
    let text: String
    let note: SbNote
    let showVersion: Bool
    let onHowChecked: () -> Void
    @State private var open: Bool
    private var context = SbContext()

    public init(_ text: String, note: SbNote, showVersion: Bool = true, initiallyExpanded: Bool = false,
                onHowChecked: @escaping () -> Void) {
        self.text = text
        self.note = note
        self.showVersion = showVersion
        self.onHowChecked = onHowChecked
        self._open = State(initialValue: initiallyExpanded)
    }

    public var body: some View {
        DisclosureGroup(isExpanded: $open) {
            VStack(alignment: .leading, spacing: SebaroSpace.s1) {
                ForEach(Array(note.bodyLines.enumerated()), id: \.offset) { _, line in
                    Text(line).sbFont(.caption).foregroundStyle(context.tone.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let by = note.by { Text(by).sbFont(.caption).foregroundStyle(context.tone.textMuted) }
                Button(context.messages.howChecked, action: onHowChecked).buttonStyle(SbTextActionStyle())
            }
        } label: {
            VStack(alignment: .leading, spacing: SebaroSpace.s0_5) {
                Text(text).sbFont(.bodyStrong).foregroundStyle(context.tone.text)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s1) {
                    SbCheckStateGlyph(note.showsClaim ? note.result : .open)
                    Text(note.shortLine(withVersion: showVersion)).sbFont(.caption).foregroundStyle(context.tone.text)
                }
            }
        }
        .disclosureGroupStyle(SbClaimRowStyle())
    }
}
