# Pitch Atlas iOS Screenshot Report

Date: 2026-06-24
Device: iPhone 17 Pro simulator, iOS 26.5
Build target: `com.pitchatlas.app`, version `1.0.1`, build floor `6`
Capture method: XcodeBuildMCP `build_run_sim`, `snapshot_ui`, and `screenshot`

Functional test proof: Xcode `My Mac` destination for the iOS Designed for iPad/iPhone runtime, 28 tests passed, 0 failed.
Submission proof: App Store Connect build `6` processed as `VALID`, attached to version `1.0.1`, assigned to internal TestFlight, and submitted for App Review as `WAITING_FOR_REVIEW`.

## Atlas Home

Raw: `2026-06-24-atlas-home.jpg`
Annotated: `2026-06-24-atlas-home-annotated.jpg`

Rendered state: verified. The app opens into the native Atlas tab shell with `Pitch Atlas`, `Sourced, not corrected`, the featured Four-seam specimen card, visible first-party grip footage, and the five-tab bar.

Critique and fixes:

1. Header is readable, but the top safe-area stack is tall for an App Store crop.
2. The `Pitch Atlas` title has strong voice, but the split display type spends too much of the first screen before the core artifact appears.
3. The italic subtitle has the right tone, but contrast and size are weak at preview scale.
4. Specimen/family labels on the card are too small for the App Store grid.
5. The grip film is real, but the crop needs a clearer hero still where the hand and baseball read instantly.
6. The card action icon is hard to parse without context.
7. The tiny provenance line at the bottom of the image will disappear in smaller previews.
8. The floating tab bar crowds the featured card and makes the lower nameplate feel trapped.
9. Five tab labels fit, but the touch zone feels tight on the narrow capture.
10. The selected tab contrast is strong. Keep that treatment across all tabs.

## Pitch Detail

Raw: `2026-06-24-pitch-detail-four-seam.jpg`
Annotated: `2026-06-24-pitch-detail-four-seam-annotated.jpg`

Rendered state: verified. The restored pitch detail shows `Four-seam`, a native back button, `FOUR-SEAM FASTBALL`, first-party grip media, a source caption, and the global tab shell.

Critique and fixes:

1. The back button is obvious, but it is visually heavy on a narrow viewport.
2. The small navigation title repeats the large heading below. This is acceptable, but the hierarchy could be tighter.
3. `Specimen 00` is too faint to carry collectible-card flavor.
4. The family label is useful, but too small for screenshot proof.
5. The display heading sells the pitch well and should stay.
6. The photo proves real grip work, but the torso/background crop is busy for a hero image.
7. The caption is honest and specific, but too small for quick reading.
8. The source/provenance line is nearly unreadable.
9. The tab bar overlaps the next content section at the bottom of the screen.
10. Keeping global nav on detail is useful because testers can escape without hunting.

## Index

Raw: `2026-06-24-index.jpg`
Annotated: `2026-06-24-index-annotated.jpg`

Rendered state: verified. The Index tab shows the native title, pitch-index intro, search field, family filter chips, fastball section, and pitch rows with aliases, status badges, and disclosure arrows.

Critique and fixes:

1. The navigation title is stable and platform-native.
2. The `INDEX` heading is punchy, but it delays the utility surface.
3. The intro copy is long and italic-heavy. A shorter sentence would scan better.
4. The decorative pitch graphic is charming, but reads as divider before information.
5. The search field is clear and correctly placed.
6. Filter chips get cramped on 368px width, especially `Offspeed & Changeups`.
7. The section explainer is hard to read because of size and contrast.
8. Aliases in list rows are too small and wrap awkwardly.
9. Status badges are legible, but should gain contrast.
10. The tab bar hides lower list context and makes the third visible row feel clipped.

## Grips

Raw: `2026-06-24-grips.jpg`
Annotated: `2026-06-24-grips-annotated.jpg`

Rendered state: verified. The Grips tab shows the founder-voice grip thesis, `not tracked data` disclaimer, Arsenal section, and the five-tab bar.

Critique and fixes:

1. The native navigation title is clean.
2. `GRIPS` has strong brand voice and fits the app.
3. The opening paragraph is too dense before any grip thumbnail appears.
4. The mini diagram is good texture, but too tiny to explain anything.
5. `Not tracked data` is the right honesty cue and should remain high.
6. The disclaimer card text should be larger for accessibility.
7. The Arsenal section begins before there is enough vertical room to read it.
8. Lower content is trapped under the tab bar.
9. The selected tab state is clear.
10. Five tabs fit, but labels are close to minimum readable size.

## Sources

Raw: `2026-06-24-sources.jpg`
Annotated: `2026-06-24-sources-annotated.jpg`

Rendered state: verified. The Sources tab shows `Sources`, the checked date `2026-06-10`, `Checked, not auto-refreshed`, and the provenance ladder.

Critique and fixes:

1. The native title keeps orientation clear.
2. `SOURCES` is legible and brand-right.
3. The subtitle has attitude, but App Review skims would benefit from plainer wording.
4. The checked date is visible, but should say `content checked` near the date.
5. `Checked, not auto-refreshed` is the correct honesty posture.
6. Color dots should not be the only tier differentiator.
7. Tier labels are too small and letter-spaced.
8. Descriptions are useful, but low contrast.
9. The lower tier is hidden by the tab bar.
10. The selected Sources tab state is clear.

## Account And Safety

Raw: `2026-06-24-account-safety.jpg`
Annotated: `2026-06-24-account-safety-annotated.jpg`

Rendered state: verified. The Account route shows the logged-out account posture, Sign in with Apple, email magic-link input, disabled send button, community rules, blocked-contributor privacy note, and visible tab shell.

Critique and fixes:

1. The back button gives a clear return path.
2. The native route title is platform-fit.
3. The `Pitch Atlas` heading overpowers the account/safety purpose.
4. The logged-out value statement is clear.
5. Sign in with Apple is obvious and compliant.
6. The email field needs a visible label, not only placeholder text.
7. The disabled magic-link button is too low contrast.
8. Community rules are dense for first-read safety.
9. The blocked-contributor note is too small and italic.
10. Support, privacy, blocked list, and delete-account paths are below the tab bar in this crop, so App Review screenshots should also include a scrolled safety capture if used for submission.

## Release Screenshot Position

Verified: the core App Store surfaces render in the simulator and the screenshot set proves native UI, bundled content, evidence tiers, grip photography, search/filtering, and account/safety posture.

Open: these simulator captures are 368x800 proof images, not final App Store Connect uploads. Final store screenshots should be captured from the required App Store Connect device sizes before the App Store product-page screenshot set is replaced.
