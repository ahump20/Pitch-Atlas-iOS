import SwiftUI

// =============================================================================
// Pitch Atlas — About
// =============================================================================
// Web: pages/AboutPage.tsx, in its order and words. The header on Austin's own
// archive paper with its two ways in, then what it is (the archive's ladder and
// six values), where it came from, the nearby field, the useful imperfection,
// why it exists, and the known, unknown and open. Pure prose: nothing here is
// read from the bundle, so there is no data state to show.
// =============================================================================

struct AboutView: View {
    var body: some View {
        ZStack {
            FieldBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHero(eyebrow: "About Pitch Atlas",
                                title: Text("Preserve and progress the ")
                                    + Text("art of the pitch").foregroundStyle(PitchAtlasMaterials.foilType())
                                    + Text("."),
                                sub: Text(AboutCopy.sub),
                                trail: [Crumb(label: "Pitch Atlas", path: "home"), Crumb(label: "About")],
                                atmosphere: AtmospherePlate(src: "/atmosphere/archive-paper.webp", opacity: 0.2)) {
                        ways.padding(.top, 32)
                    }
                    whatItIs
                    whereItCameFrom
                    nearbyField
                    imperfection
                    whyItExists
                    knownUnknownOpen
                    SiteFooter(path: "/about")
                }
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsScrollProgress()
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(markSize: 26, wordSize: 20) }
        }
    }

    // MARK: - The two ways in

    /// `mt-8 flex flex-wrap gap-3`: the wax seal into the index, the outlined
    /// button into the source model.
    private var ways: some View {
        FlowRow(spacing: 12, lineSpacing: 12) {
            RouteButton(path: "repertoire") {
                Text("Open the Pitch Index") + Text(" →")
            }
            .buttonStyle(.pitch(.waxSeal))
            .accessibilityLabel("Open the Pitch Index")
            RouteButton(path: "sources") {
                Text("Read the source model") + Text(" →")
            }
            .buttonStyle(OutlineMonoButtonStyle())
            .accessibilityLabel("Read the source model")
        }
    }

    // MARK: - What it is

    private var whatItIs: some View {
        PageSection {
            SectionKick(text: "What it is")
            SectionTitle(text: "The part a chart cannot hold.", measure: 15).padding(.top, 12)
            ForEach(AboutCopy.whatItIs, id: \.self) { paragraph in
                PageProse(text: paragraph, size: 15, measure: 50).padding(.top, 16)
            }
            ladder.padding(.top, 40)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(AboutCopy.values.enumerated()), id: \.offset) { index, row in
                    NumberedRow(index: index, label: row.label, text: row.text, inset: 20, textSize: 14)
                }
            }
            .overlay(alignment: .top) { PageInk.rule.frame(height: 1).accessibilityHidden(true) }
            .padding(.top, 32)
        }
    }

    /// The archive hierarchy: each layer under a bone rule, its mono index on a
    /// 24pt line and its name beneath.
    private var ladder: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(AboutCopy.layers.enumerated()), id: \.offset) { index, layer in
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "L%02d", index + 1))
                        .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                        .tracking(em: 0.14, size: 9)
                        .monospacedDigit()
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .padding(.top, 8)
                        .frame(minHeight: 24, alignment: .top)
                        .accessibilityHidden(true)
                    MonoCaps(text: layer, size: 10, trackingEm: 0.08, ink: PitchAtlasTheme.bone)
                }
                .padding(.top, 1 + 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { PageInk.rule.frame(height: 1).accessibilityHidden(true) }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Layer \(index + 1), \(layer)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pitch Atlas archive hierarchy")
    }

    // MARK: - Where it came from

    private var whereItCameFrom: some View {
        PageSection {
            SectionKick(text: "Where it came from")
            SectionTitle(text: "The line between thrower and pitcher.", measure: 14).padding(.top, 12)
            paragraphs(AboutCopy.origin).padding(.top, 32)
            SeamRouteLink(label: "See the grip library", path: "grips").padding(.top, 24)
        }
    }

    // MARK: - The nearby field

    private var nearbyField: some View {
        PageSection {
            SectionKick(text: "The nearby field")
            SectionTitle(text: "There are competitors. They answer different questions.", measure: 16).padding(.top, 12)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(AboutCopy.field.enumerated()), id: \.offset) { index, row in
                    fieldRow(row)
                        .overlay(alignment: .bottom) {
                            if index < AboutCopy.field.count - 1 {
                                PageInk.rule.frame(height: 1).accessibilityHidden(true)
                            }
                        }
                }
            }
            // inside the table's 1pt rim
            .padding(1)
            .background(RoundedRectangle(cornerRadius: 18).fill(PitchAtlasTheme.paper2))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(PageInk.rule, lineWidth: 1))
            .padding(.top, 32)
        }
    }

    /// One row of the field, as a phone stacks its three columns.
    private func fieldRow(_ row: AboutCopy.FieldRow) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            MonoCaps(text: "Category", trackingEm: 0.16)
            AthleticHeading(text: row.label).padding(.top, 8)
            FlowRow(spacing: 12, lineSpacing: 4) {
                ForEach(row.examples, id: \.url) { ExternalMonoLink(label: $0.label, url: $0.url) }
            }
            .padding(.top, 8)
            MonoCaps(text: "Best question", trackingEm: 0.16).padding(.top, 16)
            PageProse(text: row.answer, size: 14, ink: PitchAtlasTheme.bone).padding(.top, 8)
            MonoCaps(text: "Where Pitch Atlas fits", trackingEm: 0.16).padding(.top, 16)
            PageProse(text: row.gap, size: 14).padding(.top, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Useful imperfection

    private var imperfection: some View {
        PageSection {
            SectionKick(text: "Useful imperfection")
            SectionTitle(text: "The rough edge is not a style trick.", measure: 15).padding(.top, 12)
            paragraphs(AboutCopy.imperfection).padding(.top, 32)
        }
    }

    // MARK: - Why it exists

    private var whyItExists: some View {
        PageSection {
            SectionKick(text: "Why it exists")
            SectionTitle(text: "A grip dies with the arm.", measure: 13).padding(.top, 12)
            paragraphs(AboutCopy.why).padding(.top, 32)
            SeamRouteLink(label: "Walk the lost-pitches wing", path: "lost-pitches").padding(.top, 24)
        }
    }

    // MARK: - Known, unknown, open

    private var knownUnknownOpen: some View {
        PageSection {
            SectionKick(text: "Known, unknown, open")
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(AboutCopy.truths.enumerated()), id: \.offset) { index, row in
                    // the unknown wears the seam: its label and its rim
                    let unknown = index == 1
                    PageCard(radius: 14, rim: unknown ? PageInk.unknownRim : PageInk.rule) {
                        MonoCaps(text: row.label, trackingEm: 0.16,
                                 ink: unknown ? PitchAtlasTheme.seamBright : PitchAtlasTheme.kicker)
                        PageProse(text: row.text, size: 14).padding(.top, 12)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.top, 32)
        }
    }

    /// Body paragraphs at 16, a 16pt step between them.
    private func paragraphs(_ texts: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(texts, id: \.self) { PageProse(text: $0, size: 16, measure: 64) }
        }
    }
}

/// AboutPage.tsx's words.
enum AboutCopy {
    struct Example: Hashable { let label: String; let url: String }
    struct FieldRow { let label: String; let examples: [Example]; let answer: String; let gap: String }

    static let sub = "Pitch Atlas canonizes, catalogs, and contextualizes baseball's craft knowledge: the grips, variants, feel cues, forgotten experiments, master examples, and field notes that too often disappear when nobody files them."

    static let whatItIs = [
        "A dashboard can tell you what the ball did. It cannot always tell you where the thumb sat, which seam caught the pad, or why one pitcher swears by a hold another pitcher cannot make work.",
        "That is the gap. Pitch Atlas treats the grip as the specimen and the source label as part of the interface.",
        "The goal is not nostalgia. It is continuity: keep the art from vanishing quietly and give the next generation something to study, challenge, refine, and carry forward.",
    ]

    /// LAYER_ROWS
    static let layers = ["Baseball", "Pitching", "Pitch craft", "Grip", "Individual specimen"]

    /// VALUE_ROWS
    static let values: [(label: String, text: String)] = [
        ("Every pitch has history",
         "A pitch starts as something a hand can actually hold. Thumb, seam, pressure, feel, lineage, and the reason it survived are the record."),
        ("Every grip is evidence",
         "The grip is not decoration around the pitch. It is evidence of how the pitch was taught, adjusted, argued over, and made physical."),
        ("Every upload can matter",
         "A contributor note can become a personal one-of-one specimen when rights, context, and source labels travel with it."),
        ("The source is visible",
         "A claim does not get smoothed into authority. Official data, pitcher words, coach observation, analysis, secondhand record, and community notes all wear different labels."),
        ("Variants are allowed to disagree",
         "The atlas does not crown one correct grip. It lets credible versions sit side by side, because pitchers do not all have the same hand, release, or feel cue."),
        ("Missingness stays visible",
         "If the grip record is thin, the page says so. A blank file with honest edges is better than a full card padded with fake certainty."),
    ]

    static let origin = [
        "Behind the Art of Pitching is feel, obsession, self-belief, and command of the mind. The hand is only the first clue.",
        "Upon briefly meeting Roger Clemens at a W. 6th Street bar named Rio in Austin, TX, I jumped at the chance I wasn’t sure I’d have again. Tossing my anxiety aside, I said, “Man, I modeled my game after you and Nolan — from mechanics to mentality.”",
        "Roger responded without hesitation, “What’s the difference between us?” — nearly as if probing my knowledge. I jabbed back, “The Express… he was a Thrower. The Rocket… you’re a Pitcher.”",
        "We bumped fists. He bought my mother and me a round. We both went on enjoying Parents’ Weekend.",
        "Pitch Atlas exists to preserve and progress the art of the pitch. It keeps the oral techniques and traditions of the game free and accessible, without freezing the craft in place or pretending one grip ends the conversation.",
        "The first grips filed here are photographs of my own hand. I worked a four-pitch mix in games: four-seam, two-seam, a three-finger changeup, and a 12-6 curve, with a splitter that rode along for certain spots. There’s no circle change in the set — my hands were too small to form one, so the file says that instead of faking a textbook page.",
        "I file it as a pitcher’s own words, not tracked data, because that is what it is. It surfaced the gap the atlas now works: where the pads sat, which seam the fingers rode, why one pitch stayed in the pocket and another never fit.",
    ]

    /// FIELD_ROWS. Outside products keep their names, as the site names them.
    static let field: [FieldRow] = [
        FieldRow(label: "Measurement dashboards",
                 examples: [Example(label: "Baseball Savant", url: "https://baseballsavant.mlb.com/leaderboard/pitch-movement"),
                            Example(label: "PitchComp", url: "https://pitchcomp.app/")],
                 answer: "What did the ball do after release?",
                 gap: "They are built around measured movement, pitch identity, and outcome. The hand on the ball is usually outside the frame."),
        FieldRow(label: "Smart balls and lab tools",
                 examples: [Example(label: "pitchLogic", url: "https://pitchlogic.com/baseball"),
                            Example(label: "CleanFuego", url: "https://www.cleanfuego.com/")],
                 answer: "What feedback can a pitcher get from a rep?",
                 gap: "They connect feel to data or visual feedback. They do not try to carry forward a public archive of sourced grip variants."),
        FieldRow(label: "Coaching and pitch design",
                 examples: [Example(label: "Driveline", url: "https://www.drivelinebaseball.com/remote-pitch-design/"),
                            Example(label: "Pitching Coach U", url: "https://www.pitchingcoachu.com/gripdatabase"),
                            Example(label: "Mustard", url: "https://apps.apple.com/us/app/mustard-pitching/id1526812408")],
                 answer: "What should this athlete try next?",
                 gap: "That is coaching. Pitch Atlas is reference first: it records the grip, the read, the source, and the limit of the claim."),
        FieldRow(label: "Grip pages and clips",
                 examples: [Example(label: "Driveline grip notes", url: "https://help.drivelinebaseball.com/portal/en/kb/driveline-help/about-my-training/general-training-advice/pitch-grips")],
                 answer: "Show me one way to hold it.",
                 gap: "The usual format is a page, clip, PDF, or post. Useful, but scattered. Hard to compare. Easy to lose."),
    ]

    static let imperfection = [
        "Pitch Atlas has a wabi-sabi streak when it leaves the record imperfect on purpose: a missing grip stays missing, a community note stays a field note, and a schematic does not call itself measured if the constants are not pinned.",
        "That is good only when it protects trust. The useful roughness is source honesty, hand texture, and visible limits. Fake patina would be worse than a plain page.",
    ]

    static let why = [
        "A grip is oral tradition. A coach reshapes a kid's fingers in a bullpen. A teammate shows a seam trick between starts. A pitcher feels his way to a hold nobody taught him. Almost none of it gets written down with a name attached, and the measurement era did not fix that. Cameras and radar now record what the ball does after release down to the inch. The hand before release stayed where it always was: in dugouts, in scattered clips, in memory.",
        "The lost-pitches wing shows the price. Holds that won real games survive as fragments because nobody filed them while the arm was still around to ask. Pitch Atlas exists to file the hold while it can still be asked about. It preserves the lineage while leaving room for mutation. Sourced, because memory earns trust through provenance. Uncorrected, because the variant a textbook would flag is sometimes the one that fit a real hand.",
        "Nobody built this before because nobody had to own it. Coaching sells the next adjustment. Media sells what the ball just did. Trackers sell the measurement. An archive of sourced grips pays off years later, when someone wants to know how a pitch was actually held. Preserve the pitches baseball almost forgot. Progress the craft for the pitchers still searching.",
    ]

    /// TRUTH_ROWS
    static let truths: [(label: String, text: String)] = [
        ("Known", "Pitch Atlas is a living museum of grips, pitch variants, craftsmen, lost pitches, and shape language. The live pages carry source and confidence labels."),
        ("Unknown", "A still grip photo does not prove velocity, spin, command, injury risk, or final movement. That takes tracking data, video context, or a direct source."),
        ("Open", "The archive gets stronger as more clean grip photos, pitcher-owned notes, and measured first-party tests can be filed without breaking the source model."),
    ]
}
