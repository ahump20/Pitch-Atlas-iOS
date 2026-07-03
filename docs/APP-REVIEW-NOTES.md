# App Review Notes

Paste into App Store Connect for build `1.1.0 (11)`.

Pitch Atlas is a native SwiftUI iPhone app for how baseball pitches are gripped and thrown. The reference manual is bundled in the app and works while logged out. Community participation is anonymous-first: no sign-in screen gates posting. Contributing creates a Supabase anonymous account silently on the first write, and the user can optionally claim that account (Sign in with Apple or email) to keep it across devices. Image uploads are the one community feature that requires a claimed (permanent) account, enforced server-side.

## Reviewer Path

1. Launch the app.
2. Browse Atlas, Index, Grips, Craftsmen, and Sources without signing in.
3. Open a pitch detail and scroll to Community. No sign-in is required to contribute.
4. Accept the community guidelines and 17+ confirmation.
5. Submit a Field Note or Discussion post — this works without any account setup; an anonymous account is created behind the scenes on the first contribution.
6. Use the item menu to report content or block a different user. These also work anonymously.
7. Open Atlas, then Account and Safety: the account shows as "Anonymous contributor" with a "Claim this record" block. Claim it with Sign in with Apple or an email confirmation link; the same account (and its posts) is preserved.
8. For image upload, claim the account first (uploads require a permanent account), then accept image terms and choose a still image with PhotosPicker.
9. Review the private blocked list in Account and Safety.
10. Return to Account and Safety to delete the account (works for anonymous and claimed accounts).

## Guideline 5.1.1(v) Posture

Sign-in is never forced for non-account features. The full reference manual is readable with no account, and community contribution itself needs no sign-in — the anonymous account is created lazily and invisibly on the first write. Apple or email sign-in exists only to claim the record (keep it across devices) and to unlock image uploads, which are restricted to permanent accounts for moderation accountability.

## Community Safety

- Reporting, blocking, and text posting work anonymously; each write rides a real (anonymous) Supabase account, so rate limits, banned-term filters, and moderation apply to every contributor.
- Image uploads and the upload-terms acceptance require a claimed (non-anonymous) account, enforced by server policy.
- Account deletion requires an existing session (anonymous or claimed).
- Reading community content is open and never creates an account.
- Community posts are user-submitted field notes, not measured claims.
- Field-note inputs are validated against live Supabase limits before submission.
- Reports are write-only for normal clients and can auto-hide content through backend policy/trigger rules.
- Blocking hides community content both ways, prevents unsafe direct replies, and can be undone from Account and Safety.
- Account deletion calls the JWT-protected Supabase `delete-account` Edge Function.

## Media

iOS v1 accepts still images only through PhotosPicker. There is no video upload, GIF upload, live camera capture, or camera permission.

## Embedded Teaching Clips

Ships in the first build after `1.0.1 (10)`. Four of the twelve filed-specimen screens (four-seam, two-seam, slider, circle-change) show one short, credited teaching clip embedded from TikTok — three clips total; the Nolan Ryan clip files against both fastballs. Each uses TikTok's own official player (`https://www.tiktok.com/player/v1/<id>`) inside a `WKWebView` — the same public embed any website uses. These are supplementary teaching references; the app is fully usable without them, and every other surface is native SwiftUI.

- Each clip is credited to the original creator on-screen, with a "Watch on TikTok" button that opens the original post.
- Nothing is downloaded, re-encoded, or re-hosted. TikTok serves the video from its own player; the app bundles no clip file. (Rights record: web repo `docs/MEDIA-LEDGER.md`, rows T1–T3.)
- No autoplay, and no network request until the user taps the native poster tile to load the player. If the player fails to load, the card says so and the outbound link remains the path to the clip.
- This is the only `WKWebView` in the app and its only third-party embed. It is not a web wrapper — navigation, content, and provenance rendering are all native.

## Privacy

The app does not track users and does not include ads. It collects account email/user ID, user-written content, and uploaded still images only for app functionality and moderation/safety. App privacy labels should not say `Data Not Collected`.

## Native Value

The app is not a wrapped website. Pitch Atlas uses native SwiftUI navigation, native pitch/grip screens, native bundled content, native source/provenance rendering, native account/safety flows, and native community surfaces.

## Build Notes

- Bundle ID: `com.pitchatlas.app`
- Version: `1.1.0`
- Build: `11`
- Privacy policy: `https://pitch-atlas.com/privacy`
- Support: `https://pitch-atlas.com/support`
- No Firebase, Appwrite, CloudKit, push notifications, camera capture, video upload, or BSI dependency. The only `WKWebView` is the credited TikTok teaching-clip embed described under **Embedded Teaching Clips** above. There is no app-content webview or web wrapper.
- Production Supabase block RPCs were applied on 2026-06-24 as migration `20260624194451 block_user_rpcs`.

## Final Build Proof

Build `1.1.0 (11)` was verified on the MacBook with the 6.9-inch Pitch Atlas screenshot simulator on 2026-07-03: 65 tests passed, 0 failed. App Store Connect reports build `11` as `VALID`, `APP_STORE_ELIGIBLE`, uploaded `2026-07-03T09:05:52-07:00`, with min OS `17.0` and `ITSAppUsesNonExemptEncryption=false`.

Build `11` supersedes builds `6` through `10` for the next review submission. App Store Connect readback on 2026-07-03 showed build `11` in the internal TestFlight group `Pitch Atlas Internal`. The App Store review submission is not yet created because App Store Connect still has `1.0.1 (10)` in `PENDING_DEVELOPER_RELEASE`; creating a `1.1.0` version returned `409 ENTITY_ERROR.RELATIONSHIP.INVALID`.

Screenshot proof for build `11` is in `docs/review-evidence/2026-07-03-build-11-screens/`.
