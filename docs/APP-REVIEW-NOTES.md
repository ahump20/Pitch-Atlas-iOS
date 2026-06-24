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
9. Use the item menu to block a different user, then review the private blocked list in Account and Safety.
10. Return to Account and Safety to delete the account.

## Community Safety

- Posting, reporting, blocking, image uploads, and account deletion require sign-in.
- Community posts are user-submitted field notes, not measured claims.
- Reports are write-only for normal clients and can auto-hide content through backend policy/trigger rules.
- Blocking hides community content both ways, prevents unsafe direct replies, and can be undone from Account and Safety.
- Account deletion calls the JWT-protected Supabase `delete-account` Edge Function.

## Media

iOS v1 accepts still images only through PhotosPicker. There is no video upload, GIF upload, live camera capture, or camera permission.

## Privacy

The app does not track users and does not include ads. It collects account email/user ID, user-written content, and uploaded still images only for app functionality and moderation/safety. App privacy labels should not say “Data Not Collected.”

## Native Value

The app is not a wrapped website. Pitch Atlas uses native SwiftUI navigation, native pitch/grip screens, native bundled content, native source/provenance rendering, native account/safety flows, and native community surfaces.

## Build Notes

- Bundle ID: `com.pitchatlas.app`
- Privacy policy: `https://pitch-atlas.com/privacy`
- Support: `https://pitch-atlas.com/support`
- No Firebase, Appwrite, CloudKit, push notifications, WebView, camera capture, video upload, or BSI dependency.
