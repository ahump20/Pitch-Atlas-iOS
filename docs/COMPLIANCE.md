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

Verified:

- Supabase project `cloeoulvrrfcbitrjpso` is active.
- `ios_app_store_preflight` migration applied.
- `ios_app_store_grant_cleanup` migration applied.
- `delete-account` Edge Function is active with `verify_jwt = true`.
- `public.is_admin()` is no longer executable by anon/authenticated roles.

Still open:

- Supabase GitHub branch status reports `MIGRATIONS_FAILED` as of 2026-06-24. Preview status is `ACTIVE_HEALTHY`, but do not rely on automatic Supabase branch/deploy behavior until this is repaired from the web/backend repo.
- Security advisors still warn about public GraphQL visibility for intentionally public community tables (`field_notes`, `discussion_posts`, `discussion_media`, `profiles`) and signed-in visibility for own-state tables. Keep those warnings reviewed before submission.
- Leaked password protection remains disabled. If password sign-in is enabled in Supabase Auth, turn it on. If only Apple and magic link are enabled, document that no password credential is collected.
- Supabase Auth redirect allowlist still needs dashboard proof for `https://pitch-atlas.com/*` and `pitchatlas://auth-callback`.
- The iOS content model still has legacy optional numeric fields from the old motion schema. They must not be surfaced in v1.0.1 card UI; reconcile them against the web words-only schema before widening the native movement surfaces.

## App Store Metadata

- Bundle ID: `com.pitchatlas.app`
- Display name: `Pitch Atlas`
- Privacy URL: `https://pitch-atlas.com/privacy`
- Support URL: `https://pitch-atlas.com/support`
- Current screenshot target: 6.9-inch iPhone screenshots
- Age rating answers must reflect user-generated content and the 17+ community gate.
