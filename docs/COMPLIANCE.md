# Pitch Atlas iOS Compliance Contract

This file describes the submitted binary. Do not keep competing offline/no-login claims in this repo.

## Scope

Pitch Atlas v1 is a native SwiftUI iPhone app with bundled reference content and a Supabase-backed community layer.

- Logged-out users can browse the bundled reference manual. Reads never create an account.
- Anonymous-first since 1.1.0: filing a field note, posting, replying, reporting, and blocking need no sign-in. The first write mints an anonymous account (`AuthSessionStore.ensureSessionForWrite()`, the app's only mint site); Sign in with Apple or an email claim upgrades it in place.
- Image uploads require a claimed account (server policy). Account deletion works for anonymous and claimed accounts alike.
- Since 1.2.0 a reader can suggest a public pitching post (X, Instagram, TikTok or YouTube URL plus a 10–300 character reason) from the "Know a pitching post that belongs here?" fold on Atlas, a pitch page or a craftsman page. Sending one is a write: it mints an anonymous account the same way and inserts one row into `external_content_suggestions`, a private review queue that readers cannot read and that never publishes on its own. The fold carries no guidelines or 17+ gate, because nothing in it is shown to other users; whether to gate it anyway is an open owner decision.
- Supabase project `cloeoulvrrfcbitrjpso` is reused. Do not create a second project.
- `ahump20/Pitch-Atlas` remains the Supabase migration/function source of truth.
- iOS uploads are image-only from PhotosPicker. No video upload, GIF upload, live camera capture, push notifications, Firebase, Appwrite, CloudKit, or any outside backend. A clip filed on the website plays in the system video player, muted until the viewer turns it up; the app never uploads one.
- Teaching clips are remote embeds only: TikTok's official player loads in the app's single `WKWebView` behind a poster tap, credited on-screen, with an outbound link to the original post. No third-party media bytes ship in the bundle — embed-or-link, never rehost (rights record: web repo `docs/MEDIA-LEDGER.md`, rows T1–T3).

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

- Confirm the `external_content_suggestions` insert grant/policy is live for the anonymous role (a read with the publishable key returns 42501, which proves the table exists and is private, not that inserts work). File one suggestion from a TestFlight build, or read the policy in the Supabase console. Automated tests and screenshot runs never submit this form.
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
