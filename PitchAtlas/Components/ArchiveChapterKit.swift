import SwiftUI

// =============================================================================
// The archive chapter kit — what a craftsman's file and a lost pitch's file share
// =============================================================================
// Web: pages/CraftsmanChapter.tsx and pages/LostPitchChapter.tsx. Both stage a
// file on `.on-stage` under one faint light, pull a quote behind a seam rule,
// file sourced statements as index cards (provenance/ClaimCard.tsx), and end on
// the same `.rfx-panel` walk: the previous file, the way back to the hall, the
// next file.
// =============================================================================

/// `.on-stage` with its faint light: the void under one colored glow at 72% 34%,
/// gone by 42% of the reach, the whole layer at 10%. (The site's 34pt diagonal
/// hatch sits at 0.6% and is left out.)
struct ArchiveStageGround: View {
    let light: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let cx = w * 0.72, cy = h * 0.34
            let reach = hypot(max(cx, w - cx), max(cy, h - cy))
            ZStack {
                PitchAtlasTheme.void
                RadialGradient(colors: [light, .clear], center: UnitPoint(x: 0.72, y: 0.34),
                               startRadius: 0, endRadius: reach * 0.42)
                    .opacity(0.1)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The pulled quote: Newsreader italic behind a seam rule, its tier and source
/// beneath, its caveat under those.
struct ArchiveQuoteFigure: View {
    let quote: Claim

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\u{201C}\(quote.value)\u{201D}")
                .font(PitchAtlasType.font(.newsreader400i, size: 24, relativeTo: .title2))
                .tracking(em: -0.012, size: 24)
                .foregroundStyle(PitchAtlasTheme.bone)
                .cssLineHeight(1.375, face: .newsreader400i, size: 24, relativeTo: .title2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 40 * 0.5665 * 24, alignment: .leading)
            FlowRow(spacing: 8, lineSpacing: 4, rowAlignment: .center) {
                ConfidenceLabel(confidence: quote.confidence)
                if let source = quote.source {
                    Text("/")
                        .font(PitchAtlasType.body())
                        .foregroundStyle(PitchAtlasTheme.text3)
                        .accessibilityHidden(true)
                    SourceBadge(source: source)
                }
            }
            .padding(.top, 16)
            if let note = quote.note, !note.isEmpty {
                ClaimNote(text: note)
            }
        }
        .padding(.leading, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            Rectangle().fill(PitchAtlasTheme.seamBright.opacity(0.6)).frame(width: 2).accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
    }
}

/// ClaimCard: a claim filed as an index card — the claim, its tier and source,
/// its caveat on a machined rule — on paper-2 under a machined tab.
struct ClaimCard: View {
    let claim: Claim

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(claim.value)
                .font(PitchAtlasType.font(.hanken400, size: 13.5, relativeTo: .footnote))
                .foregroundStyle(PitchAtlasTheme.bone)
                .cssLineHeight(1.625, face: .hanken400, size: 13.5, relativeTo: .footnote)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 58 * 0.56 * 13.5, alignment: .leading)
            FlowRow(spacing: 8, lineSpacing: 4, rowAlignment: .center) {
                ConfidenceLabel(confidence: claim.confidence)
                if let source = claim.source {
                    // a plain span on the card's 16/24 line: the row's first line is 24 tall
                    Text("/")
                        .font(PitchAtlasType.body())
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .cssLineHeight(1.5, face: .hanken400, size: 16, relativeTo: .body)
                        .accessibilityHidden(true)
                    SourceBadge(source: source)
                }
            }
            if let note = claim.note, !note.isEmpty {
                Text(note)
                    .font(PitchAtlasType.font(.hanken400, size: 11, relativeTo: .caption2))
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .cssLineHeight(1.625, face: .hanken400, size: 11, relativeTo: .caption2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 58 * 0.56 * 11, alignment: .leading)
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(PitchAtlasTheme.machined).frame(width: 1).accessibilityHidden(true)
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                // 0 10px 22px -18px: the shadow box shrunk 18 a side, dropped 10, blurred
                RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.45))
                    .padding(18).offset(y: 10).blur(radius: 11)
                RoundedRectangle(cornerRadius: 8).fill(PitchAtlasTheme.paper2)
            }
            .accessibilityHidden(true)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8).strokeBorder(PitchAtlasTheme.machined, lineWidth: 1).accessibilityHidden(true)
        }
        .overlay(alignment: .topLeading) {
            // the index card's tab: 34 by 4 hanging from the top edge at 18
            UnevenRoundedRectangle(bottomLeadingRadius: 3, bottomTrailingRadius: 3)
                .fill(PitchAtlasTheme.machined)
                .frame(width: 34, height: 4)
                .offset(x: 18, y: -1)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
    }
}

/// `.rfx-panel`'s sheen: a white band at 20% of a 101° run, screened at 55%.
struct PanelSheen: View {
    var body: some View {
        GeometryReader { geo in
            let line = CSSGradientLine.points(degrees: 101, size: geo.size)
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .clear, location: 0.06),
                                   .init(color: .white.opacity(0.4), location: 0.2), .init(color: .clear, location: 0.4)],
                           startPoint: line.start, endPoint: line.end)
        }
        .blendMode(.screen)
        .opacity(0.55)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// ChapterNav: the previous file, the way back to the hall, the next file, on a
/// press panel. An end of the run leaves its cell empty, as the site's grid
/// does. Previous and next open the neighbor's file; the hall is the site's own
/// address.
struct ChapterWalk<PrevDestination: View, NextDestination: View>: View {
    /// The walk's name to VoiceOver ("Craftsmen chapters").
    let name: String
    let prevName: String?
    let nextName: String?
    /// The center cell: the hall's name, its line, its path.
    let hallLabel: String
    let hallLine: String
    let hallPath: String
    @ViewBuilder let prevDestination: () -> PrevDestination
    @ViewBuilder let nextDestination: () -> NextDestination

    var body: some View {
        VStack(spacing: 16) {
            if let prevName {
                NavigationLink { prevDestination() } label: { neighbor(prevName, label: "← Previous", trailing: false) }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Previous, \(prevName)")
            } else {
                Color.clear.frame(height: 0)
            }
            RouteButton(path: hallPath) { hall }
                .buttonStyle(.plain)
                .accessibilityLabel("\(hallLabel). \(hallLine.replacingOccurrences(of: " →", with: ""))")
            if let nextName {
                NavigationLink { nextDestination() } label: { neighbor(nextName, label: "Next →", trailing: true) }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Next, \(nextName)")
            } else {
                Color.clear.frame(height: 0)
            }
        }
        .padding(.horizontal, 21)
        .padding(.vertical, 49)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                PitchAtlasTheme.press
                PanelSheen()
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
        .inkContext(.object)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(name)
    }

    private func neighbor(_ title: String, label: String, trailing: Bool) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 4) {
            Text(label.uppercased())
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.text3)
                .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
            Text(title.uppercased())
                .font(PitchAtlasType.font(.anton400, size: 18, relativeTo: .headline))
                .foregroundStyle(PitchAtlasTheme.bone)
                .cssLineHeight(28.0 / 18.0, face: .anton400, size: 18, relativeTo: .headline)
                .multilineTextAlignment(trailing ? .trailing : .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)
        .padding(.leading, trailing ? 16 : 18)
        .padding(.trailing, trailing ? 18 : 16)
        .padding(.vertical, 12)
        .background(alignment: trailing ? .trailing : .leading) {
            // a 2pt cyan border on one side of a 6pt-radius box
            RoundedRectangle(cornerRadius: 6)
                .fill(PitchAtlasTheme.cyan.opacity(0.4))
                .mask(alignment: trailing ? .trailing : .leading) { Rectangle().frame(width: 2) }
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
    }

    private var hall: some View {
        VStack(spacing: 4) {
            Text(hallLabel.uppercased())
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.cyan)
                .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
            Text(hallLine)
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.text2)
                .cssLineHeight(1.375, face: .hanken400, size: 14, relativeTo: .subheadline)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 17)
        .padding(.vertical, 13)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
        .contentShape(Rectangle())
    }
}
