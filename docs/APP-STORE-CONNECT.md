# Pitch Atlas App Store Connect Pack

Use this as the paste source for the first iOS submission. It is scoped to the v1 binary only: native SwiftUI, offline reference manual, no account, no analytics, no network requests, no data collection.

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
- Build: `1` or the next monotonic App Store Connect build number

## Subtitle

`A field manual for pitch craft`

30 characters.

## Promotional Text

`An offline field manual for how pitches are gripped, shaped, sourced, and understood.`

87 characters.

## Description

`Pitch Atlas is a native, offline field manual for the craft of pitching. It explains how pitches are gripped, how they move, who made them famous, and how solid each claim is.`

`The app is built around a simple rule: sourced, not corrected. A measured figure, a pitcher quote, a coach observation, and an unverified claim do not wear the same label. Every pitch read shows its evidence tier so the gap stays visible.`

`Inside the app:`

`- A searchable pitch index, from four-seams and sliders to lost pitches and banned doctored balls.`
`- Native seam specimens with sourced motion cues and a seam-informed schematic.`
`- A grip library built from first-party grip photography and first-person notes.`
`- Craftsmen and lost-pitches wings for the pitchers, pitch names, and techniques that shaped the language.`
`- A sources browser so the reader can see where each claim came from.`

`Pitch Atlas does not require an account. It does not collect data. It works on first launch without a network connection because the v1 reference library is bundled inside the app.`

## Keywords

`baseball,pitching,grips,pitches,spin,curveball,slider,changeup,fastball,sources`

78 characters.

## URLs

- Marketing URL: `https://pitch-atlas.com/`
- Support URL: `https://pitch-atlas.com/`
- Privacy URL: `https://pitch-atlas.com/privacy`

Current blocker: `https://pitch-atlas.com/privacy` must render publicly before submission. From the June 9, 2026 check, the homepage rendered, but `/privacy` returned an internal error.

## App Privacy

Set App Privacy to `Data Not Collected`.

Truth table for the v1 binary:

- No account creation.
- No login.
- No analytics SDK.
- No advertising SDK.
- No tracking.
- No user-generated content.
- No network request in normal use.
- Device motion is used only on-device for the foil rake and is not stored or transmitted.

Do not include the web community/Supabase layer in the iOS v1 privacy label. That is a separate web surface and a future app version.

## Age Rating

Expected result: `4+`.

Questionnaire posture:

- No violence.
- No medical treatment advice.
- No gambling.
- No unrestricted web access.
- No user-generated content.
- No account or social features.
- Educational sports reference content only.

## Export Compliance

Answer: no non-exempt encryption.

The project sets `ITSAppUsesNonExemptEncryption` to `false`. The v1 app has no custom encryption and makes no normal-use network requests.

## App Review Notes

Paste from `docs/APP-REVIEW-NOTES.md`, then add the current build proof:

`This build was verified on an iPhone simulator before submission. It launches into the native Pitch Atlas tab shell, loads the bundled index/grip/source content, and contains no login, WebView, analytics, or network-write path.`

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
