# Pitch Atlas App Store Connect Pack

Status: 2026-06-24 production submission for `com.pitchatlas.app`.

This pack is the App Store Connect source of truth for build **1.0.1 (6)**. The stale June 10 build-3 submission note is intentionally removed. App Store Connect reported version `1.0` as previously approved/closed, rejected `1.0.0 (5)`, and rejected build `5` as already uploaded on 2026-06-24. Build `6` was uploaded, processed as `VALID`, attached to version `1.0.1`, assigned to internal TestFlight groups, and submitted for App Review on 2026-06-24.

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
- Build floor: `6`

## Subtitle

`A field manual for pitch craft`

## Promotional Text

`An offline field manual for how pitches are gripped, shaped, sourced, and understood.`

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

The full reference library is bundled inside the app, so it works on first launch without an account and without a network connection. An account is only needed for community posting and safety actions.

## Keywords

`baseball,pitching,grips,pitches,spin,curveball,slider,changeup,fastball,sources`

## URLs

- Marketing URL: `https://pitch-atlas.com/`
- Support URL: `https://pitch-atlas.com/support`
- Privacy URL: `https://pitch-atlas.com/privacy`

Verified 2026-06-24: support and privacy routes return HTTP 200 through
Cloudflare.

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

Expected posture: educational sports reference with user-generated content disclosed honestly.

- User-generated content: yes.
- Posting and uploads require sign-in.
- Reporting, blocking, guidelines, image terms, and in-app account deletion are present.
- No gambling, unrestricted web access, camera capture, video upload, or medical treatment advice.

## Export Compliance

Answer: uses only exempt encryption through standard HTTPS/ATS. `ITSAppUsesNonExemptEncryption` is false in the generated Info.plist.

## App Review Notes

Paste from `docs/APP-REVIEW-NOTES.md`. It already includes the final build, MacBook test, TestFlight, Supabase, and App Review proof for `1.0.1 (6)`.

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
- Xcode `My Mac` testing for the Designed for iPad/iPhone runtime passed: 26 tests, 0 failures.
- App Store Connect build `6` is `VALID`, attached to app version `1.0.1`, and submitted for App Review. The fresh review submission ID is `abc039da-c681-4cb7-85e0-a6a21e6841ba`, state `WAITING_FOR_REVIEW`.
- Internal TestFlight has build `6` in `Pitch Atlas Internal` and `Pitch Atlas Internal Testers`. The external public-link group was not changed.
- Chrome UI verification was unavailable from Codex because the Chrome extension backend did not respond, so App Store Connect state was verified through the official API instead.

## Internal Brand Guardrail

Do not use Blaze Sports Intel, BSI marks, BSI copy, BSI account language, or BSI support surfaces for this submission. Pitch Atlas is its own app and product.
