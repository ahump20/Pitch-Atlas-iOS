# Pitch Atlas App Store Connect Pack

Status: 2026-06-24 production submission for `com.pitchatlas.app`.

Build `1.0.1 (7)` is the current release target. App Store Connect reported version `1.0` as previously approved/closed, rejected `1.0.0 (5)`, and accepted build `6` on 2026-06-24 before the final visual/loading pass. Build `7` supersedes build `6` for the next TestFlight/App Review binary.

Verified 2026-06-24 through the App Store Connect API:

- Build `6`: `VALID`, uploaded `2026-06-24T13:24:13-07:00`, min OS `17.0`, `usesNonExemptEncryption=false`.
- Build `7`: pending upload from commit `8064020` plus build-number bump.
- App version `1.0.1`: currently submitted with build `6`; update to build `7` after processing.
- Internal TestFlight: build `6` is in `Pitch Atlas Internal` and `Pitch Atlas Internal Testers`; add build `7` after processing.
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
- Build: `6`

## Canonical Xcode Project

Archive and upload from `PitchAtlas.xcodeproj` in the main `Pitch-Atlas-iOS` repo/worktree only. The local skeleton at `/Users/AustinHumphrey/Pitch-Atlas-iOS-local-skeleton-20260608-221355/Pitch Atlas/Pitch Atlas.xcodeproj` is a prototype and is intentionally retargeted to `com.pitchatlas.local-skeleton` so it cannot collide with the production App Store bundle.

## Subtitle

`A field manual for pitch craft`

## Promotional Text

`An offline field manual for how pitches are gripped, shaped, sourced, and understood.`

85 characters.

## Description

Pitch Atlas is a native field manual for the craft of pitching. It explains how pitches are gripped, how they move, who made them famous, and how solid each claim is.

The app is built around a simple rule: sourced, not corrected. A measured figure, a pitcher quote, a coach observation, and an unverified claim do not wear the same label. Every pitch read shows its evidence tier so the gap stays visible.

Inside the app:

- A searchable pitch index, from four-seams and sliders to lost pitches and banned doctored balls.
- Native seam specimens with sourced motion cues and seam-informed schematics.
- A grip library built from first-party grip photography and first-person notes.
- Craftsmen and lost-pitches wings for the pitchers, pitch names, and techniques that shaped the language.
- A sources browser so the reader can see where each claim came from.
- An optional, free community layer: sign in to post field notes and discussion, attach still images, report content, block contributors, and delete your account.

The full reference library is bundled inside the app, so it works on first launch without an account and without a network connection. An account is only needed for community actions: posting, reporting, blocking, uploads, and account deletion.

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

Paste from `docs/APP-REVIEW-NOTES.md`. It includes the final build, MacBook test, TestFlight, Supabase, and App Review proof for `1.0.1 (7)`.

If reviewer credentials are required, provide a Supabase test account in the App Store Connect reviewer credentials fields only.

## Screenshots To Capture

Required iPhone set:

- Atlas home: card-style specimen, `Pitch Atlas`, `Sourced, not corrected`, and tab bar.
- Pitch Index: search and family filters.
- Pitch detail: native seam specimen, source badges, grip/coaching sections, and community surface.
- Grip Library: first-party grip photography and `not tracked data` framing.
- Sources: provenance/source browser.
- Account and Safety: sign-in, safety notes, reports/blocks/account deletion path.

For every final screenshot report, verify the rendered state first, then include annotated design/UX critique with at least 10 high-level fixes or improvements per image.

## Release Gates

- Production Supabase project `cloeoulvrrfcbitrjpso` exposes `block_user`, `unblock_user`, and `my_blocked_users` to authenticated clients.
- Clean iPhone 17 Pro simulator testing passed: 28 tests, 0 failures. The signed Release iPhoneOS app resolves to bundle ID `com.pitchatlas.app`, version `1.0.1`, build `7`, and `ITSAppUsesNonExemptEncryption=false`.
- App Store Connect build `6` is `VALID`, attached to app version `1.0.1`, and submitted for App Review. Build `7` must replace it after processing.
- Internal TestFlight has build `6` in `Pitch Atlas Internal` and `Pitch Atlas Internal Testers`; add build `7` after processing.
- The external public-link TestFlight group was not changed.

## Internal Brand Guardrail

Do not use Blaze Sports Intel, BSI marks, BSI copy, BSI account language, or BSI support surfaces for this submission. Pitch Atlas is its own app and product.
