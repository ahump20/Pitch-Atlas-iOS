# Pitch Atlas iOS Compliance Contract

This file describes the submitted binary. Do not keep competing offline/no-login claims in this repo.

## Scope

Pitch Atlas v1 is a native SwiftUI iPhone app with bundled reference content and a Supabase-backed community layer.

- Logged-out users can browse the bundled reference manual.
- Sign-in is required for posting, reporting, blocking, uploading images, and deleting an account.
- Supabase project `cloeoulvrrfcbitrjpso` is reused. Do not create a second project.
- `ahump20/Pitch-Atlas` remains the Supabase migration/function source of truth.
- iOS v1 is image-only from PhotosPicker. No video upload, GIF upload, live camera capture, push notifications, Firebase, Appwrite, CloudKit, or BSI dependency.

## App Review Safety

User content triggers Apple Guideline 1.2 obligations. The app must ship with:

- community guidelines acceptance before posting
- 17+ confirmation before posting or uploading
- media terms before image upload
- report actions on notes/posts
- block/unblock support
- support contact link
- in-app account deletion backed by the `delete-account` Edge Function

The backend now has `blocked_users`, blocked-content filtering, narrowed report grants, and a JWT-protected `delete-account` function. Remaining Supabase advisor warnings for public community reads are intentional only where visible community content is public; document any accepted warning before submission.

## Privacy

App Store privacy labels must not say “Data Not Collected.”

Expected labels for this binary:

- Contact Info: Email Address
- Identifiers: User ID
- User Content: Other User Content
- Photos or Videos: Photos

All are linked to the user and used for app functionality/community safety. Tracking is false. There is no ATT prompt.

`PrivacyInfo.xcprivacy` declares the same data types and the UserDefaults required-reason API used for local community acceptance flags.

## Backend Release Gate

Verify before submission:

- Supabase project `cloeoulvrrfcbitrjpso` is active.
- iOS community RPCs are present: `block_user`, `unblock_user`, and `my_blocked_users`.
- Field notes use the live enum values and reject invalid rows.
- Discussion media can upload, insert metadata, sign for readback, report, and stop serving after hide/delete.
- Blocking hides content both ways and prevents direct replies.
- `delete-account` Edge Function is active with `verify_jwt = true`.
- `public.is_admin()` is not executable by anon/authenticated roles.

Open checks:

- Recheck Supabase GitHub branch/migration health from the web/backend repo. Prior release notes recorded `MIGRATIONS_FAILED`; do not rely on automatic Supabase branch/deploy behavior if the live console still reports that.
- Review security advisors for intentionally public community reads (`field_notes`, `discussion_posts`, `discussion_media`, `profiles`) and signed-in own-state tables before submission.
- Leaked password protection remains disabled. If password sign-in is enabled in Supabase Auth, turn it on. If only Apple and magic link are enabled, document that no password credential is collected.

## App Store Metadata

- Bundle ID: `com.pitchatlas.app`
- Display name: `Pitch Atlas`
- Privacy URL: `https://pitch-atlas.com/privacy`
- Support URL: `https://pitch-atlas.com/support`
- Current screenshot target: 6.9-inch iPhone screenshots
- Age rating answers must reflect user-generated content and the 17+ community gate.
