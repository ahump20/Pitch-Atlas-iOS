# Pitch Atlas App Store Connect Pack

Status: 2026-06-24 production submission for `com.pitchatlas.app`.

Preview copy refreshed through the App Store Connect API on 2026-06-25 while version
`1.0.1` was still `WAITING_FOR_REVIEW`. Screenshot replacement with the Build 9
captures was attempted, but Apple returned `STATE_ERROR`: screenshots cannot be
created while the app screenshots resource is waiting for review. The existing
submitted screenshots remain intact.

Build `1.0.1 (8)` is the submitted release target. App Store Connect reported version `1.0` as previously approved/closed, rejected `1.0.0 (5)`, and accepted build `6` on 2026-06-24 before the final visual/loading pass. Build `8` supersedes builds `6` and `7`.

Verified 2026-06-24 through the App Store Connect API:

- Build `8`: `VALID`, uploaded `2026-06-24T15:17:20-07:00`, min OS `17.0`, `usesNonExemptEncryption=false`, delivery/build ID `d0b21f93-8605-42ec-8cfc-2e37a3fbb95e`.
- App version `1.0.1`: `WAITING_FOR_REVIEW` with attached build `8`.
- Review submission `2ff1c0bd-732e-43af-89a0-f42c0ece6ea6`: `WAITING_FOR_REVIEW`, submitted `2026-06-24T22:23:10.524Z`.
- Internal TestFlight: build `8` is in `Pitch Atlas Internal` via all-build access and explicitly in `Pitch Atlas Internal Testers`.
- External public-link TestFlight group was not changed.
- Chrome UI verification was unavailable from Codex because the Chrome extension backend did not respond, so ASC state was verified through the official API instead.
- This run did not drive a physical TestFlight install on a tester device from this shell.

## App Identity

- App name: `Pitch Atlas`
- Bundle ID: `com.pitchatlas.app`
- SKU: `pitch-atlas-ios`
- Primary category: `Sports`
- Secondary category: `Education`
- Pricing: `Free`
- Platform: `iOS`
- Device family: `iPhone`
- Version: `1.0.1`
- Build: `8`

## Canonical Xcode Project

Archive and upload from `PitchAtlas.xcodeproj` in the main `Pitch-Atlas-iOS` repo/worktree only. The local skeleton at `/Users/AustinHumphrey/Pitch-Atlas-iOS-local-skeleton-20260608-221355/Pitch Atlas/Pitch Atlas.xcodeproj` is a prototype and is intentionally retargeted to `com.pitchatlas.local-skeleton` so it cannot collide with the production App Store bundle.

## Subtitle

`A field manual for pitch craft`

## Promotional Text

`Grips, seam tells, source tiers, and pitch craft, with no fake movement numbers.`

80 characters.

## What's New

`Pitch cards read faster, first-party grip photos appear earlier, source tiers now show text labels, Index rows scan cleaner, and Account and Safety language is easier to follow.`

177 characters.

## Description

Pitch Atlas is a native field manual for the craft of pitching. It starts with the hand on the ball: seams, fingertips, thumb pressure, release feel, and the hitter's clock.

The app is built around one rule: sourced, not corrected. A measured claim, a pitcher account, a coach read, and a thin historical note do not wear the same label. Pitch Atlas keeps that gap visible.

Inside the app:

- A searchable index from four-seams and sliders to splitters, sweepers, lost pitches, and doctored-ball lore.
- Native pitch cards with seam-informed specimens, movement language, family labels, and source tiers.
- A grip library built from first-party photographs and first-person notes, clearly marked as grip evidence rather than tracked pitch data.
- Craftsmen and lost-pitches sections for the people, pitch names, and teaching lines that shaped the craft.
- A sources browser that shows where the claims came from and when the content was checked.
- Optional community field notes for signed-in users, with reporting, blocking, still-image uploads, and account deletion.

Most of the reference library is bundled for first launch. An account is only needed for community actions. No ads. No tracking. No fake spin numbers.

## Keywords

`baseball,pitching,grips,pitches,spin,curveball,slider,changeup,fastball,sources`

79 characters.

## URLs

- Marketing URL: `https://pitch-atlas.com/`
- Support URL: `https://pitch-atlas.com/support`
- Privacy URL: `https://pitch-atlas.com/privacy`

Verified 2026-06-24: support and privacy routes return HTTP 200 through Cloudflare.

## App Privacy

Do not set `Data Not Collected`. Match `PitchAtlas/Resources/PrivacyInfo.xcprivacy`.

Collected data, all linked to identity, none used for tracking, all for App Functionality:

- Email Address: account sign-in.
- User ID: the Supabase account identifier.
- Other User-Generated Content: field notes, discussion posts, reports.
- Photos or Videos: still images the user chooses to attach.

Truth table for this binary:

- Optional account. Sign-in is required only for community posting, reporting, blocking, image uploads, and account deletion.
- Sign in with Apple is supported.
- No analytics SDK.
- No advertising SDK.
- No tracking.
- No Firebase, Appwrite, CloudKit, push notifications, WebView, camera capture, or video upload.
- Device motion is used only on-device for the foil card effect and stops when Reduce Motion is enabled.

## Age Rating

Expected posture: answer the questionnaire honestly and let App Store Connect compute the rating. The reference content is baseball instruction; the community surface is gated by sign-in, guidelines acceptance, and a 17+ posting/upload confirmation.

- User-generated content: yes.
- Posting and uploads require sign-in.
- Reporting, blocking, guidelines, image terms, and in-app account deletion are present.
- No gambling, unrestricted web access, camera capture, video upload, or medical treatment advice.

## Export Compliance

Answer: uses only exempt encryption through standard HTTPS/ATS. `ITSAppUsesNonExemptEncryption` is false in the generated Info.plist.

## App Review Notes

Paste from `docs/APP-REVIEW-NOTES.md`. It includes the final build, MacBook test, TestFlight, Supabase, and App Review proof for `1.0.1 (8)`.

If reviewer credentials are required, provide a Supabase test account in the App Store Connect reviewer credentials fields only.

## Screenshots To Capture

Build 9 internal evidence captures:

- `docs/review-evidence/build-9-screenshots/atlas-home.png`
- `docs/review-evidence/build-9-screenshots/pitch-detail-four-seam.png`
- `docs/review-evidence/build-9-screenshots/index.png`
- `docs/review-evidence/build-9-screenshots/grips.png`
- `docs/review-evidence/build-9-screenshots/sources.png`
- `docs/review-evidence/build-9-screenshots/account-safety.png`

These six Build 9 files are internal evidence only for now. They are `1206 x 2622`,
the Apple-accepted 6.3-inch iPhone portrait size for iPhone 17 Pro / iPhone 16 Pro
class devices.

Live App Store Connect screenshot set: still the submitted five-image set. It
stays that way until the version leaves `WAITING_FOR_REVIEW` or the submission is
intentionally removed from review and replaced.

For every final screenshot report, verify the rendered state first, then include annotated design/UX critique with at least 10 high-level fixes or improvements per image.

## Release Gates

- Production Supabase project `cloeoulvrrfcbitrjpso` exposes `block_user`, `unblock_user`, and `my_blocked_users` to authenticated clients.
- Clean iPhone 17 Pro simulator testing passed: 28 tests, 0 failures. The signed Release iPhoneOS app resolves to bundle ID `com.pitchatlas.app`, version `1.0.1`, build `8`, and `ITSAppUsesNonExemptEncryption=false`.
- App Store Connect build `8` is `VALID`, attached to app version `1.0.1`, and submitted for App Review as `WAITING_FOR_REVIEW`.
- Internal TestFlight has build `8` in `Pitch Atlas Internal` through all-build access and explicitly in `Pitch Atlas Internal Testers`.
- The external public-link TestFlight group was not changed.

## Internal Brand Guardrail

Do not use Blaze Sports Intel, BSI marks, BSI copy, BSI account language, or BSI support surfaces for this submission. Pitch Atlas is its own app and product.
