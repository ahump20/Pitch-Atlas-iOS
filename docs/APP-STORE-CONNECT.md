# Pitch Atlas App Store Connect Pack

Current work: candidate `1.2.0 (14)` for `com.pitchatlas.app`, addressing the November 2 rejection of submission `0b7dce83-8e94-415f-9d89-404ba3c941ab` (build 13). Build 14 upload, native acceptance, final metadata readback, and resubmission are pending. Historical waiting-for-review states below are not current status.

## App identity and release source

- App name: `Pitch Atlas`
- Bundle ID: `com.pitchatlas.app`
- SKU: `pitch-atlas-ios`
- Primary category: `Sports`
- Secondary category: `Education`
- Pricing: `Free`
- Platform/device family: `iOS / iPhone`
- Candidate version/build: `1.2.0 (14)`

Archive from the release checkout's generated `PitchAtlas.xcodeproj` and record its commit, archive identity, signing result, and upload receipt. The old local skeleton using `com.pitchatlas.local-skeleton` is not a release source.

## November remediation

Implemented candidate changes:

- Versioned Community Terms and EULA acceptance plus an 18+ confirmation on all contribution paths, including public-post suggestions.
- Immediate local Hide and Report hiding on posts, replies, field notes, and media.
- Persistent failed-report queue with retries in Account > Safety.
- Direct Contact developer form naming Austin Humphrey, reachable from Account > Safety and Support, with an optional reply email and server-confirmed delivery.
- Pending images remain private until approval.
- Native terms describe automated public removal and contributor restriction within 24 hours, with permanent removal/ejection for confirmed violations; they do not promise staffed human review within 24 hours.
- Customer Support privacy disclosure added.

Production verification: the Apple Auth provider is enabled and its public settings endpoint returned HTTP 200 with `external.apple=true`. The moderation migration and contact RPC are deployed, production transaction checks completed, and a real deadline-sweep cron run succeeded at `2026-11-05 04:20:00 UTC`. These are backend results; native Apple sign-in and other candidate acceptance checks are still pending.

## Store copy

Subtitle:

`A field manual for pitch craft`

Promotional text, retained from the 1.2.0 listing:

`The pitch, in your hand: grips, seams and sources, now with a softball wing and a slow-pitch Flight Lab that puts the zone at your height.`

### What's New — 1.2.0

The October 30 listing copy is retained below as historical submitted text. Any revision for build 14 must be read back from App Store Connect after saving.

```text
1.2.0 brings the app level with pitch-atlas.com.

Softball gets its own wing: fastpitch and slow-pitch rooms, the pitches, and the pitchers who made them.

The slow-pitch Flight Lab puts the zone at your height. Pick a rulebook (USSSA, USA Softball or USA Senior), set where you stand, and watch each lob drop through it: where it crosses the plate, where your barrel meets it, and where to look for it to land. It is a drawing, not a radar gun. No spin or speed figures.

Pick two pitches and lay them side by side. Open one on the grip bench to study the hold, the release and the flight in one place.

The pitch index is rebuilt: rows or a binder, with filters. Ten hidden notes are tucked around the archive.

Discussion posts now file under a handle you type, never your email. You can also suggest a public pitching post; a person checks it before anything shows.

And the screens hold together at the largest accessibility text sizes.
```

### Description

Pitch Atlas is a native field manual for the craft of pitching. It explains how pitches are gripped, how they move, who made them famous, and how solid each claim is.

A measured figure, a pitcher quote, a coach observation, and an unverified claim carry different evidence labels. Each pitch shows its sources.

Inside the app:

- A searchable pitch index, from four-seams and sliders to lost pitches and banned doctored balls.
- Native seam specimens and grip schematics.
- A grip library built from first-party grip photography and first-person notes.
- Craftsmen and lost-pitches wings for the pitchers and techniques that shaped the game.
- A source browser.
- Optional community field notes and discussion for contributors 18 or older who accept the Community Terms and EULA. An anonymous record is created on the first write; Apple or email sign-in can claim it across devices. Still-image attachments require a claimed account.
- Hide, report, block, and direct developer contact controls.

The reference library is bundled and works on first launch without an account or network connection. Reporting, blocking, and developer contact do not require a claimed account.

This is candidate copy, not a claim that the current listing already contains it.

### Keywords

`baseball,pitching,grips,pitches,spin,curveball,slider,changeup,fastball,sources`

### URLs

- Marketing: https://pitch-atlas.com/
- Support: https://pitch-atlas.com/support
- Privacy: https://pitch-atlas.com/privacy

Verify current page content and availability before resubmission; old HTTP checks do not establish current publication.

## App privacy

Do not set Data Not Collected. Match `PitchAtlas/Resources/PrivacyInfo.xcprivacy`.

All listed data is linked to the user, used for App Functionality, and not used for tracking:

- Email Address: account access and optional support reply address.
- User ID: contributor identifier, including anonymous IDs.
- Other User Content: field notes, discussion, replies, suggestions, and reports.
- Customer Support: private messages voluntarily sent through Contact developer.
- Photos or Videos: still-image attachments; no native video upload.

Current App Store Connect label publication/readback is pending. Opening Contact developer sends no data; submission sends the message, optional reply email, and contributor ID.

Other binary facts:

- No analytics or advertising SDK, tracking, ATT prompt, push notifications, or camera capture.
- Apple/email sign-in is optional for reference access and anonymous text participation.
- Images require a claimed account and remain private until approved.
- TikTok teaching clips load through one poster-gated WKWebView; the app is otherwise native and does not rehost those clips.
- Device motion is used only on-device and respects Reduce Motion.

## Age rating

The candidate requires 18+ confirmation and updated Community Terms and EULA acceptance for posting, replying, field notes, public-post suggestions, and image uploads. Reporting, blocking, and contacting the developer remain available without contribution consent.

Apple requested an 18+ rating for this submission. Set and verify the App Store age-rating override to 18+ in addition to the in-app contribution gate. Answer the questionnaire from actual features, including user-generated content, safety controls, and age assurance. The old October 30 calculated rating is not current validation; record the final questionnaire and 18+ rating readback before submission.

## Export compliance

The app uses standard HTTPS/ATS and `ITSAppUsesNonExemptEncryption=false`. Confirm the generated archive and App Store Connect answer agree.

## Review notes and response

Candidate reviewer paths and evidence are in `docs/APP-REVIEW-NOTES.md`. An unsent response draft is in the investigation outputs as `review-response-build14-draft.md`. Complete its runtime and upload evidence placeholders before sending.

No reviewer account is required for browsing, anonymous text participation, reporting, blocking, or Contact developer. If Apple needs a claimed test account for image review, use the private App Store Connect reviewer-credentials fields.

## Release gates for build 14

| Gate | Status |
| --- | --- |
| Native source parsing, privacy plist, diff whitespace | Passed for the safety changes. |
| New safety unit tests | 11 added; runtime result pending. |
| Production Apple provider | Enabled; HTTP 200 settings readback confirms `external.apple=true`. |
| Production moderation/contact | Deployed; backend checks and actual scheduled execution verified. |
| Native Apple sign-in/claim | Pending. |
| Native contribution, hide/report retry, contact, block, image, deletion paths | Pending. |
| Final archive/signing and build identity | Pending. |
| Upload receipt and App Store Connect processing/validity | Pending. |
| Build 14 attached to version 1.2.0 | Pending. |
| Privacy labels, age rating, reviewer notes, screenshots/preview readback | Pending. |
| Review response sent and new submission status | Pending. |

Capture current rendered screens before changing screenshots. Existing listing media is historical until confirmed representative of the candidate.

## Historical evidence

Preserve dated records under `docs/review-evidence/`:

- Build 13: October 30 archive and submission proof at `2026-10-30-build-13-submitted.md`; subsequently rejected in the November 2 notice referenced above.
- Build 12: October 30 submission proof at `2026-10-30-build-12-submitted.md`; withdrawn before review after the production anonymous-post failure.
- Build 11: July review screenshots at `2026-07-03-build-11-screens/`; historical reviewer-path evidence.

Old test totals, uploads, and WAITING_FOR_REVIEW readbacks certify only their dated builds. They must not be reused as final build-14 evidence.

## Product boundary

Pitch Atlas is its own app. Do not introduce Blaze Sports Intel marks, copy, accounts, or support surfaces into this submission.
