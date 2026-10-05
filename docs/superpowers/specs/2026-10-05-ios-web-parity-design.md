# Pitch Atlas iOS 1.2 — web parity design

**Status:** approved 2026-10-05. The implementation plans in `docs/superpowers/plans/2026-10-05-ios-web-parity-*.md` argue from this file.

**Source of truth:** GitHub `ahump20/Pitch-Atlas` @ `main` (`3f518f6`, 2026-10-01) and live pitch-atlas.com. If this document and the shipped site disagree, the site wins and this document is corrected in the same pass. Content and design tokens are generated from the web source, never hand-written.

## Goal

Ship Pitch Atlas 1.2 to the App Store: an iPhone app that looks, reads and behaves like pitch-atlas.com does today, submitted for review and released on approval.

## Where things stand (verified 2026-10-05)

- The App Store build is 1.1.0 (11), released 2026-07-08. Between 2026-09-05 and 2026-10-01 the website changed its color system, card system, home story, Index and specimen pages. The app has none of it.
- Three things are wrong in the shipped app:
  1. **Split discussions.** The app files specimen threads under `pitch:<slug>`; the site uses the bare slug. Posts made in one never show in the other.
  2. **Field notes look public when they are not.** Since July the server holds new notes for review (`visibility = 'pending'`). The app says "Field note submitted" and lists the note as if public.
  3. **Stale content.** The bundle predates the ember 1-of-1 and is one source short.

## Decisions

1. **Headings.** Follow the live site: Newsreader for the home hero (italic second line `#d0ae82`) and SectionHero pages; Anton uppercase for section titles; Hanken body; Martian Mono labels. The web's `design-language.md` §2 line that retires Newsreader is stale and is corrected in the web pass.
2. **Backend.** Supabase stays (shared with the website). No Appwrite.
3. **Hero copy** is the live line: "The pitch, in your hand."
4. **Platform contract.** `docs/PLATFORM-CONTRACT.md` (web) is stale about Lost Pitches, Grips and Compare being web-only; corrected in the web pass.
5. **Softball** is built natively, reached from Atlas. The web's scope record (`APP-SCOPE-RECONCILIATION.md`) is updated in the web pass.
6. **The dog companion leaves the app.** The website removed it in June as a brand cue that competes with the grip-first archive read, and Pitch Atlas is a standalone product. The companion, its toggle and its tests are removed; the scroll-progress tracking it rode is kept (renamed) for the Muybridge pitcher.
7. **Trust: seven labels, three colors.** The data keeps all seven confidence labels; the screen maps them to the web's three tier colors exactly as `CONFIDENCE_COLOR` does. A dot never appears without its label.
8. **Tab bar stays:** Atlas · Index · Grips · Craftsmen · Sources. Atlas carries the web's "More" set (Learn, Lost Pitches, Softball, Shape Lab, Movement Map, Compare, About, Account), each one tap away.
9. **Ambient loops.** The shipped site runs slow ambient loops (restored 2026-09-23, `abaca76`). The app runs the same loops only while on screen, and stops them under Reduce Motion and Low Power Mode. The brand book's "nothing loops at rest" line is corrected in the web pass.
10. **Warm tan on the web.** Gold tokens are gone, but tan hexes still render in the web's archive/world/compare CSS (hero italic `#d0ae82`, compare tray, study links `#e4b182`, delivery plate). The app matches what visitors see; whether tan stays is flagged to the owner, not changed.
11. **The card back is dark.** The rendered back is the "scout file" (`.v2-back`, radial `#15120f`→`#0a0908`, key/value rows). The cream `.rfx-cardback` and its gold frame are dead CSS and are not ported.
12. **Index controls, settled from live markup.** ROWS/BINDER is a pill toggle (mono 12pt, .06em, uppercase; on = burnt `#BF5700`, white text). The cyan segmented control is the specimen's VIEW and HAND toggle. "Filter & sort" is a 36pt bone-2 pill with a white/14 border, burnt when open. The Index title is Anton, −7° skew, bone.
13. **Icons.** SF Symbols stay (Dynamic Type scaling and native controls), set to the web's weight; a Lucide glyph is imported as a custom symbol only where SF has no match.
14. **Chapter rail marks location.** Like the web's `ChapterSections.tsx` (IntersectionObserver band −15%/−55%, `aria-current="location"`), the app highlights the chapter in the upper band of the screen and gives it the selected accessibility trait. No progress bar.

## Design rationale (research)

No end-user research exists; the web's own scenarios are labeled design targets. The design rests on the owner's direction and on published work:

| Design | What the research adds | So the app… |
|---|---|---|
| Every pitch is a filed specimen; one card at three densities | Collecting is driven by goals, memory, legacy and belonging (Lee, Brennan & Wyllie 2022) | ports the card tiers; adds no unlocks, streaks or leaderboards |
| The ember four-seam is the only 1 of 1 | Scarcity adds value mainly to things people can own or trade (Lynn 1991; Roux, Goldsmith & Cannon 2023) | keeps the ember singular and matte as a centerpiece; "1 of 1" appears nowhere else |
| Words over numbers | Narrative and statistical evidence persuade about equally (Xu 2022) | hides empty numeric slots; links out for numbers |
| Three trust colors, seven labels | Stating uncertainty costs little trust (van der Bles et al. 2020); color-only encodings fail color-blind readers (Jiang, Arunkumar & Bryan 2026) | every dot keeps its words and glyph |
| Built for the bullpen | Touch builds little ownership on phones (Brasel & Gips 2014; Ştir & Zaiţ 2022) | bullpen check; gyroscope tilt on the hero card only |
| Alive, then still | Motion-heavy video provokes symptoms in vestibular migraine (Bourdillon et al. 2026) | loops run only on screen; off under Reduce Motion and Low Power |
| Hidden notes and rotating quotes | Information gaps spark curiosity and frustration (Schweitzer et al. 2023); effort rises near completion (Kivetz, Urminsky & Zheng 2006) | the set stays completable, the counter quiet, nothing gated |
| Anonymous-first community | Belonging motive (Lee et al. 2022) | anonymous-first stays; the split key and the "submitted" wording are fixed |

Copy rule: app and store copy come from the live site's own lines and the owner's own words, plain and factual. The store description drops "sourced, not corrected" (retired by the owner).

## Gap table (web → app today → 1.2)

| Area | Web | App (1.1.0 + Sept branch) | 1.2 |
|---|---|---|---|
| Field | void `#070509` | `#15120F` in SwiftUI, `#070509` in nav/launch | `#070509` everywhere |
| Interaction accent | cyan `#5FE0EA` | retired `#37D6FF` | `#5FE0EA` |
| Gold | removed | gold rims, gold craftsman rail, "Gold · 1 of 1" | gone; ember on four-seam only |
| Foil | Electric Burnt Chrome | rainbow foil | Burnt Chrome |
| Trust | 3 colors + label always printed | 7 colors | 3 colors, 7 labels |
| Family | `--c1/--c2/--c3` triads + exceptions + throwbacks | single colors | triads, exceptions, throwbacks |
| Type | Newsreader, Anton, Hanken, Martian (14 faces) | 6 faces | full weights, web type roles, Dynamic Type |
| Motion | 120/190/400/700/900 ms on `(.22,1,.36,1)`; ambient loops | ad hoc | tokens; loops on screen only |
| Cards | Tier A 5:7 card (flip to dark back), Tier B plate, Tier C hatched row | no 5:7 card | all three |
| Controls | chrome/ghost buttons, cyan-ruled search, chips, ROWS/BINDER, 44px | system buttons; targets under 44pt | ported, 44pt |
| Home | seven-section story + Muybridge pitcher | older hero | the web story, in order |
| Index | rows/binder, filter & sort, Compare per filed row, ledger, lineage map | list + search | full |
| Specimen | chapter rail, 4-step study, view/hand toggles, lift the hand, variants, lessons, notes, discussion, sources, pager | partial | full |
| Discussion | specimens, basic files, lost pitches, Learn wings, softball | specimens only, split key | all, shared with web |
| Softball, Shape Lab, Movement Map | live | none | added |
| Hidden notes (10), quotes | live | none | added |
| Media rail + suggestions | live | teaching clips only | added; X as outbound links |
| Content | 12 / 42 / 13 / 15 / 10 wings / 7 grips / 299 sources | Sept 6 bundle, 298 sources | regenerated from web main |

## Architecture

1. **Generated foundation.** `tools/generate-content` reads the web repo's `src/data` and also emits `design-tokens.json` from the web's browser-resolved `.design-sync/artifact/tokens.json`, the foil/ember stops in `src/index.css`, and the accent/tier maps in `src/components`. A parity test fails when Swift theme values differ from that file; the CI drift job (switched to `git status --porcelain`) fails when the committed bundle differs from web main.
2. **Theme.** `PitchAtlasTheme` holds tokens 1:1 with web main; ink changes by surface context (`.void`, `.object`, `.cream`) through an environment value. Materials (foil, foil-type, ember, throwback card foils), family and per-pitch accents, motion tokens and radii live beside it. No hex literals outside `Core/Theme/`.
3. **Components** mirror the web's design-system parts (buttons, kicker, hairline, stamp, tag/chip, pill toggle, segmented toggle, search field, select, dialog, toast, trust marks, rows). Every control has a 44pt hit area.
4. **Cards.** Tier A `PitchSpecimenCard` (5:7, foil stock, arched stage, cream read plate, strip; drag tilt ≤14°, gyroscope ≤10° on the hero card only; 400ms flip to the dark scout-file back with a "Flip card" accessibility action and a crossfade under Reduce Motion). Ember stock on the four-seam only. Tier B plate (3px top lip). Tier C hatched index row.
5. **Screens** follow the live routes: Atlas (seven sections, Muybridge plate 273), Index (rows/binder, filter & sort, Compare, ledger, lineage), Specimen (chapter rail, four-step study), basic file, Craftsmen, Lost Pitches, Learn, Grips, Compare, Sources, About, Account; plus Softball, Shape Lab, Movement Map, hidden notes, quotes, media rail. Any new section that would ship rough becomes a named fast-follow.
6. **Community.** One `CommunityTopic` type builds every key in the web's formats (bare slug, `repertoire:<id>`, `lost:<slug>`, `learn:<slug>` on non-boundary wings, `softball:<slug>`). Field notes read through `list_public_field_notes`; after filing the app says "Sent for review · it stays private until approved." Delete-own-post ports the web's reply guard. Every data surface has loading, empty and error states, each with a reason.

## Guardrails

- iOS 17.0 floor: no MeshGradient, ScrollPosition struct, onScrollGeometryChange, onScrollVisibilityChange, onScrollPhaseChange, two-argument onGeometryChange, `Tab`, navigationTransition.
- No invented data: no fabricated numbers, freshness or community posts. Every claim keeps its source and tier.
- No web view of the site. Rights-first media: embed-or-link, never rehost.
- Contrast: 4.5:1 body text, 3:1 large text and graphics. Small burnt-orange text on the void (4.43:1) is set in bone instead; tier color lives on the dot, labels are bone-2.
- The app builds and its tests pass after every commit.

## Verification

1. Unit tests: existing suite (minus the companion tests) plus token parity, contrast, topic keys, field-note RPC decode, tier mapping, family triads, softball/tidbit/quote decode, font loading.
2. Screenshot pairs: every screen on the iPhone 17 Pro Max simulator against the same route on pitch-atlas.com at 440px, each annotated with at least ten fixes, iterated until only nitpicks remain.
3. Offline first launch: bundled content works with the network unreachable; community surfaces show their error state with a reason.
4. Bullpen check: from a cold offline launch any filed grip is three taps away or fewer; every control 44pt; 4.5:1 text with Increase Contrast; nothing essential behind the 3D ball.
5. Accessibility: largest Dynamic Type, VoiceOver walk, Reduce Motion (nothing moves at rest), a words-only path for every visual teaching moment.
6. Community: production read paths only. The release-gate UI test, which posts to production, runs only with automated account teardown.
7. Release: 1.2.0 with the next build number, new screenshots and copy, review notes with an exact tap path to every place a user can post, `AFTER_APPROVAL`, state `WAITING_FOR_REVIEW`.

## References (published research)

1. Lynn, M. (1991). Scarcity effects on value. *Psychology & Marketing*, 8(1). https://doi.org/10.1002/mar.4220080105
2. Roux, C., Goldsmith, K., & Cannon, C. (2023). *Journal of the Academy of Marketing Science*. https://doi.org/10.1007/s11747-023-00956-0
3. Pornpitakpan, C. (2004). The persuasiveness of source credibility. *Journal of Applied Social Psychology*. https://doi.org/10.1111/j.1559-1816.2004.tb02547.x
4. van der Bles, A. M., et al. (2020). *PNAS*. https://doi.org/10.1073/pnas.1913678117
5. Jiang, Arunkumar & Bryan (2026). *IEEE TVCG*. https://doi.org/10.1109/tvcg.2025.3634261
6. Brasel, S. A., & Gips, J. (2014). *Journal of Consumer Psychology*. https://doi.org/10.1016/j.jcps.2013.10.003
7. Ştir & Zaiţ (2022). *International Journal of Human–Computer Interaction*. https://doi.org/10.1080/10447318.2022.2131263
8. Schweitzer et al. (2023). *Organizational Behavior and Human Decision Processes*. https://doi.org/10.1016/j.obhdp.2023.104276
9. Kivetz, R., Urminsky, O., & Zheng, Y. (2006). *Journal of Marketing Research*. https://doi.org/10.1509/jmkr.43.1.39
10. Tractinsky, N., Katz, A. S., & Ikar, D. (2000). *Interacting with Computers*. https://doi.org/10.1016/s0953-5438(00)00031-x
11. Tuch, A. N., et al. (2012). *Computers in Human Behavior*. https://doi.org/10.1016/j.chb.2012.03.024
12. Robins, D., & Holmes, J. (2008). *Information Processing & Management*. https://doi.org/10.1016/j.ipm.2007.02.003
13. van Laer, T., et al. (2014). *Journal of Consumer Research*. https://doi.org/10.1086/673383
14. Xu (2022). *Health Communication*. https://doi.org/10.1080/10410236.2022.2137750
15. Bourdillon et al. (2026). *Otology & Neurotology*. https://doi.org/10.1097/mao.0000000000004948
16. Lee, Brennan & Wyllie (2022). *International Journal of Consumer Studies*. https://doi.org/10.1111/ijcs.12770
