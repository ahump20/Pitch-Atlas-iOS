# App Review Notes

Paste into App Store Connect for build `1.0.1 (7)`.

Pitch Atlas is a native SwiftUI iPhone app for how baseball pitches are gripped and thrown. The reference manual is bundled in the app and works while logged out. Community features use Supabase only after sign-in.

## Reviewer Path

1. Launch the app.
2. Browse Atlas, Index, Grips, Craftsmen, and Sources without signing in.
3. Open Atlas, then Account and Safety, to sign in with Apple or email magic link.
4. Open a pitch detail and scroll to Community.
5. Accept the community guidelines and 17+ confirmation.
6. Submit a Field Note or Discussion post.
7. For image upload, accept image terms and choose a still image with PhotosPicker.
8. Use the item menu to report content.
9. Use the item menu to block a different user, then review the private blocked list in Account and Safety.
10. Return to Account and Safety to delete the account.

## Community Safety

- Posting, reporting, blocking, image uploads, and account deletion require sign-in.
- Reading community content is open so visitors can inspect public field notes before creating an account.
- Community posts are user-submitted field notes, not measured claims.
- Field-note inputs are validated against live Supabase limits before submission.
- Reports are write-only for normal clients and can auto-hide content through backend policy/trigger rules.
- Blocking hides community content both ways, prevents unsafe direct replies, and can be undone from Account and Safety.
- Account deletion calls the JWT-protected Supabase `delete-account` Edge Function.

## Media

iOS v1 accepts still images only through PhotosPicker. There is no video upload, GIF upload, live camera capture, or camera permission.

## Privacy

The app does not track users and does not include ads. It collects account email/user ID, user-written content, and uploaded still images only for app functionality and moderation/safety. App privacy labels should not say `Data Not Collected`.

## Native Value

The app is not a wrapped website. Pitch Atlas uses native SwiftUI navigation, native pitch/grip screens, native bundled content, native source/provenance rendering, native account/safety flows, and native community surfaces.

## Build Notes

- Bundle ID: `com.pitchatlas.app`
- Version: `1.0.1`
- Build: `6`
- Privacy policy: `https://pitch-atlas.com/privacy`
- Support: `https://pitch-atlas.com/support`
- No Firebase, Appwrite, CloudKit, push notifications, WebView, camera capture, video upload, or BSI dependency.
- Production Supabase block RPCs were applied on 2026-06-24 as migration `20260624194451 block_user_rpcs`.

## Final Build Proof

Build `1.0.1 (7)` was verified on the MacBook with a clean iPhone 17 Pro simulator run: 28 tests passed, 0 failed. The signed Release iPhoneOS app metadata resolves to bundle ID `com.pitchatlas.app`, version `1.0.1`, build `7`, and `ITSAppUsesNonExemptEncryption=false`.

Build `7` supersedes the earlier build `6` binary and should be attached to app version `1.0.1` after App Store Connect processing. Build `6` was previously `VALID`, attached to app version `1.0.1`, and assigned to the internal TestFlight groups `Pitch Atlas Internal` and `Pitch Atlas Internal Testers`.

Screenshot proof and the required design critique are in `docs/review-evidence/2026-06-24-ios-screenshot-report.md`.
