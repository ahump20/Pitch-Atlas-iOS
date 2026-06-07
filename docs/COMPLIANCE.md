# Pitch Atlas iOS — Compliance & Scope Lock (v1)

This document is the enforced contract for the first App Store submission. It is written *before* the screens are built so no auth, tracking, or third-party-media path ever enters the binary. Every decision here maps to a specific App Store Review Guideline.

## The v1 scope cut (the highest-leverage review decision)

**v1 ships the reference manual only — no accounts, no login, no community, no network writes.**

This single cut clears five obligations at once:

| If v1 had... | Guideline triggered | Avoided because |
|---|---|---|
| Any login / account | 4.8 Sign in with Apple (if any social login), 5.1.1(v) in-app account deletion | No login at all. The whole reference experience is usable logged-out. |
| User-generated content (forums/field notes) | 1.2 — required filtering, reporting, blocking, contact, EULA | No UGC surface in the binary. |
| Any off-device data collection | 5.1.1, App Privacy label, ATT | Nothing leaves the device. Label = "Data Not Collected". |

**Enforcement:** the v1 binary contains **no Supabase client, no auth code, no network-write path, no "sign in" affordance.** A build audit (grep for `supabase`, `signIn`, `URLSession` write calls, auth tokens) must come back empty before submission. The community layer is reserved behind a single `@AppStorage` feature-flag stub and is **not** wired.

The web community backend (Supabase project `cloeoulvrrfcbitrjpso`, anonymous-karma + discussion + field-notes, already live) is reused **as-is in v2** — v2 is additive, not a rebuild.

## No web view in v1 — the specimen is native (third-party media is moot)

**v1 ships with no `WKWebView` at all.** The interactive WebGL 3D specimen — and therefore the web bundle that carried the rejection-grade third-party embeds (`PitchingNinjaTweet.tsx` → `twimg.com`, `StreamableFacade.tsx` iframe, the baked tweet JSON) — is **not in the binary.** Each pitch's specimen is drawn **natively in SwiftUI** (`SeamBall`) from the same closed-form figure-eight seam equation the web uses, so the physics cannot drift, and a holographic foil rakes across the specimen card via CoreMotion as the phone tilts.

This makes the v1 compliance story strictly simpler and safer than the original island plan:

1. **5.2 IP** — no MLB footage, no third-party creator video, no embeds anywhere. The visual actor is the original seam specimen and the developer's own grip photography.
2. **Offline + 4.7/2.5.2** — there is no remote code and no network call of any kind. The app is offline by construction; "works in airplane mode" is trivially true.

The interactive WebGL 3D specimen (drag-to-spin, live spin-axis vector) is a planned **v1.1** enhancement, to be added as a bundled, offline, custom-scheme island with the embeds stripped — verified on hardware before it ships. It is **out of scope for the v1 submission.**

## Guideline 4.2 (minimum functionality) — the top rejection risk, and the rebuttal

A content/reference product is the textbook 4.2.2 target ("a website zipped in a WebView"). The defense is structural: the app is **100% native** — native tab bar, a native searchable pitch index with family filters, a native offline grip library, native craftsmen / lost-pitches wings, a native sources/provenance browser, and a **native specimen drawn from the real seam equation** — with all content bundled and working offline on first launch. There is no web view to mistake for a wrapped website. See `APP-REVIEW-NOTES.md` for the reviewer-facing argument.

## Privacy

- App Privacy label: **Data Not Collected.** No analytics SDK, no tracking, no ATT prompt, no `NSUserTrackingUsageDescription`.
- `PrivacyInfo.xcprivacy`: declares no tracking and required API-reason codes only.
- Privacy policy URL (5.1.1(i)): hosted on `pitch-atlas.com`, **scoped to what the v1 binary does (nothing collected)** — it must not describe the web community's Supabase data practices, or it contradicts the label.

## IP / content safety (5.2)

- Austin's own grips, photos, and prose: safe (5.2.1 — owned outright; grip photos tagged "not tracked data").
- No MLB/team trademarks, no scraped player photos, no re-hosted third-party video in the binary or its bundled `dist/`.
- Visual actor is always the seam specimen or first-party photography.

## Age rating

Expected **4+ / 9+**. Educational/reference content, no objectionable material, no UGC. Complete the 2026 age-rating questionnaire in App Store Connect before the first submission.

## Export compliance

`ITSAppUsesNonExemptEncryption = false` set in the Info.plist so TestFlight uploads never stall on the encryption question (only standard HTTPS, no proprietary crypto).

## Account / auth posture

- **v1:** none. No login surface anywhere.
- **v2:** the existing Supabase anonymous sign-in → email/Apple claim-to-rank flow. Sign in with Apple becomes mandatory only if any social login button appears (4.8). The manual is never gated behind an account.
