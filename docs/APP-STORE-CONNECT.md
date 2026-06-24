# Pitch Atlas App Store Connect Pack

> **Status 2026-06-24 (repo prep):** App Store Connect and TestFlight state is
> not proven from this checkout. Before archive, open the live App Store Connect
> record and verify the current version state, highest processed build, privacy
> labels, age rating, review notes, screenshots, and TestFlight groups.
>
> **Build-number rule:** the repo baseline is build 4 because earlier notes say
> App Store Connect already processed build 3. If the live console already has
> build 4 or higher, bump `CURRENT_PROJECT_VERSION` again before archive. Attach
> only the build that was smoke-tested through TestFlight.

Use this as the paste source for the next iOS submission. It is scoped to the v1 binary: native SwiftUI, an offline bundled reference manual, plus an optional Supabase-backed community layer (sign-in, field notes, discussion posts, image uploads). The reference content works on first launch with no account and no network.

## App Identity

- App name: `Pitch Atlas`
- Bundle ID: `com.pitchatlas.app`
- SKU: `pitch-atlas-ios`
- Primary category: `Sports`
- Secondary category: `Education`
- Pricing: `Free`
- Platform: `iOS`
- Device family: `iPhone`
- Version: `1.0.0`
- Build: `4` repo baseline. Verify App Store Connect before archive; bump again
  if the live console already has build 4 or higher.

## Subtitle

`A field manual for pitch craft`

30 characters.

## Promotional Text

`An offline field manual for how pitches are gripped, shaped, sourced, and understood.`

87 characters.

## Description

`Pitch Atlas is a native field manual for the craft of pitching. It explains how pitches are gripped, how they move, who made them famous, and how solid each claim is.`

`The app is built around a simple rule: sourced, not corrected. A measured figure, a pitcher quote, a coach observation, and an unverified claim do not wear the same label. Every pitch read shows its evidence tier so the gap stays visible.`

`Inside the app:`

`- A searchable pitch index, from four-seams and sliders to lost pitches and banned doctored balls.`
`- Native seam specimens with sourced motion cues and a seam-informed schematic.`
`- A grip library built from first-party grip photography and first-person notes.`
`- Craftsmen and lost-pitches wings for the pitchers, pitch names, and techniques that shaped the language.`
`- A sources browser so the reader can see where each claim came from.`
`- An optional, free community layer: sign in to post field notes and discussion, attach still images, report content, block contributors, and delete your account.`

`The full reference library is bundled inside the app, so it works on first launch without an account and without a network connection. An account is only needed for community actions: posting, reporting, blocking, uploads, and account deletion.`

## Keywords

`baseball,pitching,grips,pitches,spin,curveball,slider,changeup,fastball,sources`

78 characters.

## URLs

- Marketing URL: `https://pitch-atlas.com/`
- Support URL: `https://pitch-atlas.com/support`
- Privacy URL: `https://pitch-atlas.com/privacy`

Pre-submit URL check: open the Marketing, Support, and Privacy URLs above from a
logged-out browser. Do not submit if any page fails to render publicly.

## App Privacy

The binary collects data, so do NOT set `Data Not Collected`. Declare exactly what `PitchAtlas/Resources/PrivacyInfo.xcprivacy` declares — four collected data types, all linked to identity, none used for tracking, all for App Functionality:

- **Email Address** — account sign-in (Supabase auth / Sign in with Apple relay).
- **User ID** — the Supabase account identifier.
- **Other User-Generated Content** — community field notes, discussion posts, reports.
- **Photos or Videos** — still images the user chooses to attach (PhotosPicker, image-only; no video, no live camera capture).

Truth table for the v1 binary:

- Optional account. Sign-in is required only for community posting; the reference manual works logged out.
- Sign in with Apple is supported (entitlement present).
- No analytics SDK.
- No advertising SDK.
- No tracking (`NSPrivacyTracking` is false; no tracking domains).
- User-generated content exists: community posts and image uploads, with report and block tooling and account deletion in-app.
- Network requests occur only for the Supabase community/auth layer; the bundled reference content is fully offline.
- Device motion is used only on-device for the foil rake and is not stored or transmitted.

## Age Rating

Expected posture: answer the questionnaire honestly and let App Store Connect
compute the rating. The reference content is baseball instruction; the community
surface is gated by sign-in, guidelines acceptance, and a 17+ posting/upload
confirmation.

Questionnaire posture:

- No violence.
- No medical treatment advice.
- No gambling.
- No unrestricted web access.
- **User-generated content: YES** — community posts and images, gated behind sign-in, with in-app reporting, user blocking, and account deletion (Guideline 1.2 moderation set).
- Educational sports reference content plus a moderated community.

## Export Compliance

Answer: uses encryption, exempt only (standard HTTPS/ATS for the Supabase calls; no custom encryption).

The project sets `ITSAppUsesNonExemptEncryption` to `false`, which matches the exempt posture.

## App Review Notes

Paste from `docs/APP-REVIEW-NOTES.md`, then add the current build proof:

`This build was verified on an iPhone simulator before submission. It launches into the native Pitch Atlas tab shell and loads the bundled index/grip/source content with no account and no network. The optional community layer signs in through Supabase (Sign in with Apple supported) and supports field notes, discussion posts, still-image upload, reporting, contributor blocking/unblocking, and account deletion. No analytics, no ads, no tracking, no WebView.`

If the reviewer needs a sign-in, provide a Supabase test account in the review notes credentials fields.

## Screenshots To Capture

Required iPhone screenshot set:

- Atlas home: shows `Pitch Atlas`, `Sourced, not corrected`, native specimen, and tab bar.
- Pitch Index: shows search and family filters.
- Pitch detail: shows native seam specimen, source badges, and grip/coaching sections.
- Grip Library: shows first-party grip photography and `not tracked data` framing.
- Sources: shows provenance/source browser.

Use iPhone 6.9-inch screenshots if App Store Connect asks for the current largest size. Add 6.5-inch only if App Store Connect does not auto-scale from the submitted set.

## Internal Brand Guardrail

Do not use Blaze Sports Intel, BSI marks, BSI copy, BSI account language, or BSI support surfaces for this submission. Pitch Atlas is its own app and product.
