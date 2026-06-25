# App Review Notes

Paste into App Store Connect after replacing any build-specific placeholders.

Pitch Atlas is a native SwiftUI iPhone app for how baseball pitches are gripped and thrown. The reference manual is bundled in the app and works while logged out. Community features use Supabase only after sign-in.

## Reviewer Path

1. Launch the app.
2. Browse Atlas, Index, Grips, Craftsmen, and Sources without signing in.
3. Open Atlas → Account and Safety to sign in with Apple or email magic link.
4. Open a pitch detail and scroll to Community.
5. Accept the community guidelines and 17+ confirmation.
6. Submit a Field Note or Discussion post.
7. For image upload, accept image terms and choose a still image with PhotosPicker.
8. Use the item menu to report content.
9. Use the item menu to block a different user.
10. Return to Account and Safety to delete the account.

## Community Safety

- Posting, reporting, blocking, image uploads, and account deletion require sign-in.
- Community posts are user-submitted field notes, not measured claims.
- Reports are write-only for normal clients and can auto-hide content through backend policy/trigger rules.
- Blocking hides community content both ways and prevents unsafe direct replies.
- Account deletion calls the JWT-protected Supabase `delete-account` Edge Function.

## Media

iOS v1 accepts still images only through PhotosPicker. There is no video upload, GIF upload, live camera capture, or camera permission.

## Embedded teaching clips

Three of the twelve filed-specimen screens (four-seam, two-seam, slider, circle-change) show one short, credited teaching clip embedded from TikTok using TikTok's own official player (`https://www.tiktok.com/player/v1/<id>`) inside a `WKWebView` — the same public embed any website uses. These are supplementary teaching references; the app is fully usable without them, and every other surface is native SwiftUI.

- Each clip is credited to the original creator on-screen, with a "Watch on TikTok" button that opens the original post.
- Nothing is downloaded, re-encoded, or re-hosted. TikTok serves the video from its own player; the app bundles no clip file. (Rights record: web repo `docs/MEDIA-LEDGER.md`, rows T1–T3.)
- No autoplay: the player shows its cover frame and the user taps play.
- This is the only `WKWebView` in the app and its only third-party embed. It is not a web wrapper — navigation, content, and provenance rendering are all native.

## Privacy

The app does not track users and does not include ads. It collects account email/user ID, user-written content, and uploaded still images only for app functionality and moderation/safety. App privacy labels should not say “Data Not Collected.”

## Native Value

The app is not a wrapped website. Pitch Atlas uses native SwiftUI navigation, native pitch/grip screens, native bundled content, native source/provenance rendering, native account/safety flows, and native community surfaces.

## Build Notes

- Bundle ID: `com.pitchatlas.app`
- SKU: `pitch-atlas-ios`
- Apple ID: `6778277388`
- Team ID: `CQNJJ423X3`
- Local marketing version: `1.0.0`
- User-reported submitted build: build 3, submitted 2026-06-09, awaiting App Review. I did not verify App Store Connect status in this pass.
- Privacy policy: `https://pitch-atlas.com/privacy`
- Support: `https://pitch-atlas.com/support`
- No Firebase, Appwrite, CloudKit, push notifications, camera capture, video upload, or BSI dependency. The only `WKWebView` is the credited TikTok teaching-clip embed described under **Embedded teaching clips** above — there is no app-content webview or web wrapper.

## Return Wave Checks, 2026-06-24

Known:

- [verified] Supabase project `cloeoulvrrfcbitrjpso` still reports branch `main` as `MIGRATIONS_FAILED`; preview status is `ACTIVE_HEALTHY`.
- [verified] Live migrations include the iOS preflight pair (`20260609031936_ios_app_store_preflight`, `20260609032249_ios_app_store_grant_cleanup`) plus the later hardening migrations through `20260615204244_pin_remaining_helper_search_paths`.
- [verified] Live RLS read policies for `field_notes`, `discussion_posts`, and `discussion_media` call `private.blocked_between((select auth.uid()), ...)`, so block hiding is enforced server-side.
- [verified] Live `blocked_users` client grants are column-narrowed: authenticated clients can insert `blocked_id`; no anonymous `blocked_users` grant appeared in the live column-grant query.
- [verified] `private.blocked_between`, `private.is_admin`, and `public.is_admin` are security-definer functions with pinned empty `search_path`.
- [verified] Bundled content was regenerated from the web repo on this branch: 12 pitches, 40 repertoire entries, 12 craftsmen, 15 lost pitches, 10 knowledge wings, 7 grip entries, 274 sources. Source freshness comes from the source bundle: `2026-06-10`.

Unknown:

- [unknown] App Store Connect review status. The submitted build status needs the logged-in App Store Connect account.
- [unknown] Supabase Auth redirect allowlist. The app code uses `pitchatlas://auth-callback`; the dashboard must also allow `https://pitch-atlas.com/*` for web auth.
- [unknown] `CURRENT_PROJECT_VERSION` in `project.yml` is `2`, while the return-wave context says App Store Connect has build 3. Let App Store Connect be source of truth before archiving v1.0.1.

Open:

- [open] Fable 5 still needs a reviewer test account or reviewer instructions that do not require one.
- [open] Fable 5 still needs device/simulator screenshots and a signed archive/TestFlight/App Store submission for v1.0.1.
- [open] Supabase leaked-password protection remains a dashboard decision.
- [open] The native content model still carries old optional numeric fields (`spinRateRpm`, `ivbInches`, `horizontalInches`, `velocity`). Do not surface them in the card port; reconcile the model in the v1.0.1 cleanup.

## App Store Metadata Draft

- Name: `Pitch Atlas`
- Subtitle: `Grip-first pitch reference`
- Category: Sports
- Promotional text: `Read baseball pitches by grip, source, and shape. Pitch Atlas keeps the craft visible without pretending every movement cue is tracked data.`
- Description: `Pitch Atlas is a native iPhone field manual for baseball pitches. Browse filed specimens, grip photos, source notes, pitch families, lost pitches, craftsmen, and plain-English movement reads. The bundled reference works without an account. Optional community notes require sign-in and carry reporting, blocking, media terms, and account deletion. Every claim is sourced or clearly marked as a gap.`
- Keywords: `baseball,pitching,grips,pitch design,fastball,breaking ball,changeup,coaching,field notes`
- Support URL: `https://pitch-atlas.com/support`
- Privacy URL: `https://pitch-atlas.com/privacy`
- Marketing URL: `https://pitch-atlas.com/`
- Copyright: `2026 Austin Humphrey`
- Export compliance: no non-exempt encryption.
- Age rating: answer for user-generated content and the in-app 17+ community gate.

## Screenshot Set

Apple's current screenshot spec accepts one to ten JPEG/JPG/PNG files per device class. For the iPhone 6.9-inch display bucket, use a 1320 x 2868 portrait master when possible; Apple also accepts 1290 x 2796 and 1260 x 2736. Source: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/

Capture these six 6.9-inch portrait screens:

1. Atlas: hero/specimen wall with the elevated return-wave card visible.
2. Index: searchable pitch index, family/status rows visible.
3. Detail: one filed specimen detail with seam ball, source tier, and no numeric movement claim.
4. Grips: Grip Library media card with first-party grip material and proof-limit copy.
5. Sources: provenance ladder and source ledger, showing `sourcesLastChecked`.
6. Account: Account and Safety screen with Sign in with Apple, privacy/support links, community safety controls.

Screenshot rules:

- Use real bundled content only. No fake usernames, invented notes, or sample stats.
- Keep status bar and device chrome consistent across the set.
- Do not show private email, payment, token, or Supabase project secrets.
- Do not include BSI branding.

## App Icon Spec

Fable 5 should produce the AppIcon asset from a square 1024 x 1024 master. Direction: Pitch Atlas seal/ball mark, dark void field, small chrome/gold edge, no text, no third-party baseball marks, no Sluggers marks, no rounded corners baked into the bitmap. Keep the icon legible at Settings size before archiving.
