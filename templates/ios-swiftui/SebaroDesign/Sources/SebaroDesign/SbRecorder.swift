import SwiftUI

// MARK: - Audio row (spec/02 §3.25; D91 B11b; spec/08 §14.29)

/// What the app's player is doing: playing or not, the position and the length in seconds, or failed.
public struct SbPlayback: Equatable, Sendable {
    public var playing: Bool
    public var position: TimeInterval
    public var duration: TimeInterval
    public var failed: Bool

    public init(playing: Bool = false, position: TimeInterval = 0, duration: TimeInterval = 0, failed: Bool = false) {
        self.playing = playing
        self.position = position
        self.duration = duration
        self.failed = failed
    }
}

/// A media time as the web writes it (sb-media.js): m:ss, from one hour h:mm:ss, Latin digits in every language.
public func sbMediaClock(_ seconds: TimeInterval) -> String {
    let all = max(0, Int(seconds))
    let h = all / 3600, m = all / 60 % 60, s = all % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
}

/// Audio row (B11b): `title` in label and the time „0:12 / 0:42“ (caption, text-muted, tabular; VoiceOver „0:12 von
/// 0:42“) on top, under them the 48 pt play / pause button (named „<name> abspielen“ / „<name> anhalten“) and the seek
/// bar (4 pt border-strong rail, accent fill, a 24 pt ring thumb; drag or tap; VoiceOver adjusts ±5 s). Failed: „Die
/// Aufnahme lässt sich nicht abspielen.“ after the danger glyph, announced. Stateless: the app's player plays
/// (`onPlayPause`, `onSeek` in seconds), loads nothing before the first press and starts nothing by itself.
public struct SbAudioRow: View {
    let title: String
    let playback: SbPlayback
    let name: String
    let hairline: Bool
    let onPlayPause: () -> Void
    let onSeek: (TimeInterval) -> Void
    private var context = SbContext()

    public init(_ title: String, playback: SbPlayback, name: String? = nil, hairline: Bool = false,
                onPlayPause: @escaping () -> Void, onSeek: @escaping (TimeInterval) -> Void) {
        self.title = title
        self.playback = playback
        self.name = name ?? title
        self.hairline = hairline
        self.onPlayPause = onPlayPause
        self.onSeek = onSeek
    }

    public var body: some View {
        let m = context.messages
        let now = sbMediaClock(playback.position), total = sbMediaClock(playback.duration)
        VStack(alignment: .leading, spacing: SebaroSpace.s1) {
            SbWrapRow(spacing: SebaroSpace.s2) {
                Text(title).sbFont(.label).foregroundStyle(context.tone.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(now) / \(total)").sbFont(.caption).monospacedDigit().foregroundStyle(context.tone.textMuted)
                    .accessibilityLabel(Text(m.mediaPosition(now, total)))
            }
            if playback.failed {
                HStack(alignment: .firstTextBaseline, spacing: SebaroSpace.s1) {
                    SbIcon("error--filled", size: SebaroSize.iconSm, color: .sbDanger)
                    Text(m.audioFailed).sbFont(.caption).foregroundStyle(context.tone.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .onAppear { SbAnnounce.polite(m.audioFailed) }
            } else {
                HStack(spacing: SebaroSpace.s2) {
                    SbIconButton(playback.playing ? "pause" : "play",
                                 label: playback.playing ? m.mediaPause(name) : m.mediaPlay(name), action: onPlayPause)
                    SbSeekBar(position: playback.position, duration: playback.duration, onSeek: onSeek)
                        .accessibilityLabel(Text(m.mediaSeek))
                        .accessibilityValue(Text(m.mediaPosition(now, total)))
                }
            }
        }
        .padding(.vertical, SebaroSpace.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) {
            if hairline { Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline) }
        }
    }
}

/// The seek bar of the audio row (the web's sb-range): a 48 pt target with the 4 pt rail, the accent fill and the
/// 24 pt ring thumb; VoiceOver adjusts it by 5 s.
struct SbSeekBar: View {
    let position: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    @Environment(\.sebaroTone) private var tone
    @Environment(\.layoutDirection) private var direction

    var body: some View {
        GeometryReader { geo in
            let thumb = SebaroSize.iconLg
            let share = duration > 0 ? min(max(position / duration, 0), 1) : 0
            let track = geo.size.width - thumb
            let x = thumb / 2 + track * share
            ZStack(alignment: .leading) {
                Rectangle().fill(tone.borderStrong).frame(height: SebaroSpace.s1)
                    .padding(.horizontal, thumb / 2)
                Rectangle().fill(Color.sbAccent).frame(width: track * share, height: SebaroSpace.s1)
                    .offset(x: thumb / 2)
                Circle().fill(tone.bg)
                    .overlay(Circle().strokeBorder(Color.sbAccent, lineWidth: SebaroX.layerLineWidth))
                    .frame(width: thumb, height: thumb)
                    .offset(x: x - thumb / 2)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                guard duration > 0, track > 0 else { return }
                let at = direction == .rightToLeft ? geo.size.width - g.location.x : g.location.x
                onSeek(duration * min(max((at - thumb / 2) / track, 0), 1))
            })
        }
        .frame(height: SebaroSize.targetTouch)
        .accessibilityElement()
        .accessibilityAdjustableAction { dir in
            switch dir {
            case .increment: onSeek(min(position + 5, duration))
            case .decrement: onSeek(max(position - 5, 0))
            @unknown default: break
            }
        }
    }
}

/// Words that stand in one line while they fit and wrap whole between parts (`SbFlowRow` in Compose): the parts
/// keep their ideal width up to the line's width, the next part goes to the next line.
struct SbWrapRow: Layout {
    var spacing: CGFloat

    private func lines(_ width: CGFloat, _ subviews: Subviews) -> [[(LayoutSubview, CGSize)]] {
        var out: [[(LayoutSubview, CGSize)]] = [[]]
        var x: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(ProposedViewSize(width: width, height: nil))
            let w = min(size.width, width)
            if x > 0 && x + spacing + w > width {
                out.append([])
                x = 0
            }
            x += (x > 0 ? spacing : 0) + w
            out[out.count - 1].append((s, CGSize(width: w, height: size.height)))
        }
        return out
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let ls = lines(width, subviews)
        let h = ls.map { $0.map(\.1.height).max() ?? 0 }.reduce(0, +) + spacing * CGFloat(max(ls.count - 1, 0))
        let w = ls.map { l in l.map(\.1.width).reduce(0, +) + spacing * CGFloat(max(l.count - 1, 0)) }.max() ?? 0
        return CGSize(width: proposal.width ?? w, height: h)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in lines(bounds.width, subviews) {
            let h = line.map(\.1.height).max() ?? 0
            var x = bounds.minX
            for (s, size) in line {
                s.place(at: CGPoint(x: x, y: y + (h - size.height) / 2), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += h + spacing
        }
    }
}

// MARK: - Own recording (spec/02 §3.25.1; D105 (8)–(11); spec/08 §14.29.1)

/// What an own recording is doing (D105 (8)–(11)); the app's recorder owns it and its timing.
public enum SbRecording: Equatable, Sendable {
    /// Nothing recorded yet.
    case none
    /// Recording runs: `elapsed` seconds since the start, `level` 0…1 the microphone's level now.
    case running(elapsed: TimeInterval, level: Double)
    /// A recording exists, played as in `SbAudioRow`.
    case recorded(SbPlayback)
    /// The person refused the microphone.
    case denied
}

/// Own recording (D105 (8)–(11)): a row like `SbAudioRow`. `.none` = `title` with „Noch keine Aufnahme.“ and the
/// secondary action „Aufnehmen“ (microphone), `rationale` the app's sentence under it before the system's prompt;
/// `.running` = the time („0:07“, tabular) and „Stopp“ as a word, with the grey level bar (hidden from VoiceOver, which
/// hears „Aufnahme läuft.“ once); `.recorded` = `SbAudioRow` with „Neu aufnehmen“ and „Löschen …“ (`onDelete`: the
/// app asks with `sbConfirmDialog` first); `.denied` = the sentence and „Einstellungen öffnen“ (`onOpenSettings`).
/// Stateless.
public struct SbRecorderRow: View {
    let title: String
    let recording: SbRecording
    let rationale: String?
    let name: String
    let hairline: Bool
    let onRecord: () -> Void
    let onStop: () -> Void
    let onPlayPause: () -> Void
    let onSeek: (TimeInterval) -> Void
    let onDelete: () -> Void
    let onOpenSettings: (() -> Void)?
    private var context = SbContext()

    public init(_ title: String, recording: SbRecording, rationale: String? = nil, name: String? = nil,
                hairline: Bool = false, onRecord: @escaping () -> Void, onStop: @escaping () -> Void,
                onPlayPause: @escaping () -> Void, onSeek: @escaping (TimeInterval) -> Void,
                onDelete: @escaping () -> Void, onOpenSettings: (() -> Void)? = nil) {
        self.title = title
        self.recording = recording
        self.rationale = rationale
        self.name = name ?? title
        self.hairline = hairline
        self.onRecord = onRecord
        self.onStop = onStop
        self.onPlayPause = onPlayPause
        self.onSeek = onSeek
        self.onDelete = onDelete
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        let m = context.messages
        if case .recorded(let playback) = recording {
            VStack(alignment: .leading, spacing: 0) {
                SbAudioRow(title, playback: playback, name: name, hairline: hairline,
                           onPlayPause: onPlayPause, onSeek: onSeek)
                SbWrapRow(spacing: SebaroSpace.s3) {
                    Button(action: onRecord) { recordLabel(m.recordAgain) }.buttonStyle(SbSecondaryButtonStyle())
                    SbDangerAction(m.recordDelete, action: onDelete)
                }
                .padding(.bottom, SebaroSpace.s2)
            }
        } else {
            VStack(alignment: .leading, spacing: SebaroSpace.s2) {
                SbWrapRow(spacing: SebaroSpace.s2) {
                    Text(title).sbFont(.label).foregroundStyle(context.tone.text)
                        .fixedSize(horizontal: false, vertical: true)
                    switch recording {
                    case .none:
                        Text(m.recordNone).sbFont(.caption).foregroundStyle(context.tone.textMuted)
                    case .running(let elapsed, _):
                        Text(sbMediaClock(elapsed)).sbFont(.caption).monospacedDigit()
                            .foregroundStyle(context.tone.textMuted)
                    default:
                        EmptyView()
                    }
                }
                switch recording {
                case .none:
                    Button(action: onRecord) { recordLabel(m.record) }.buttonStyle(SbSecondaryButtonStyle())
                    if let rationale {
                        Text(rationale).sbFont(.caption).foregroundStyle(context.tone.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                case .running(_, let level):
                    HStack(spacing: SebaroSpace.s3) {
                        Button(m.recordStop, action: onStop).buttonStyle(SbSecondaryButtonStyle())
                        SbLevelBar(level: level)
                            .accessibilityElement()
                            .accessibilityLabel(Text(m.recordRunning))
                            .onAppear { SbAnnounce.polite(m.recordRunning) }
                    }
                case .denied:
                    Text(m.recordDenied).sbFont(.caption).foregroundStyle(context.tone.text)
                        .fixedSize(horizontal: false, vertical: true)
                    if let onOpenSettings {
                        Button(m.recordSettings, action: onOpenSettings).buttonStyle(SbTextActionStyle())
                    }
                case .recorded:
                    EmptyView()
                }
            }
            .padding(.vertical, SebaroSpace.s2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) {
                if hairline { Rectangle().fill(context.tone.border).frame(height: SebaroBorderWidth.hairline) }
            }
        }
    }

    private func recordLabel(_ word: String) -> some View {
        HStack(spacing: SebaroSpacing.inline) {
            SbIcon("microphone", size: SebaroSize.iconLg)
            Text(word)
        }
    }
}

/// The microphone's level: the audio row's 4 pt rail in border with the level in text-muted from the start edge; it
/// is not read (the bar carries the one sentence „Aufnahme läuft.“, D103).
struct SbLevelBar: View {
    let level: Double
    @Environment(\.sebaroTone) private var tone
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(tone.border)
                Rectangle().fill(tone.textMuted).frame(width: geo.size.width * min(max(level, 0), 1))
            }
            .frame(height: SebaroSpace.s1)
            .frame(maxHeight: .infinity)
        }
        .frame(height: SebaroSize.targetTouch)
    }
}
