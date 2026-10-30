# App Review Notes

Paste into App Store Connect for build `1.2.0 (13)`.

Pitch Atlas is a native SwiftUI iPhone app for how baseball pitches are gripped and thrown. The reference manual is bundled in the app and works while logged out. Community participation is anonymous-first: no sign-in screen gates posting. Contributing creates a Supabase anonymous account silently on the first write, and the user can optionally claim that account (Sign in with Apple or email) to keep it across devices. Image uploads are the one community feature that requires a claimed (permanent) account, enforced server-side.

## Where Community Posting Lives (Guideline 2.3)

Version `1.2.0` redesigned the pitch pages, so the path below replaces the one written for `1.1.0 (11)`. Every filed pitch page carries both community surfaces near its end. The fastest review path:

1. Launch the app on iPhone. It opens on `Atlas`.
2. Tap `Study this grip →` under the opening headline. This opens the `Four-seam` pitch page.
3. Swipe up until the chapter `Field notes from the bullpen.` and the `Log a field note` box appear (well past the grip, the lessons and the history; about two thirds of the way down).
4. **Field note:** tap `Write a note →`. At the top of the form, turn on `I accept the community guidelines` and `I confirm I am 17 or older before posting or uploading`. Enter a handle in `Submitted by` and a grip cue in `The tweak`, then tap `File field note →`. New field notes stay private until a person reviews them, so the note will not appear in the list right away; the form confirms it was sent for review.
5. **Discussion post:** keep swiping to the bar marked `Discussion · Talk through the four-seam` and tap it to open the drawer. Turn on the same two switches if they are not already on, enter a handle in `Your name` and a comment, then tap `File post`. The line `Filed ✓` confirms the server accepted it, and the post appears in the thread.
6. No sign-in is shown before either path. The app creates a Supabase anonymous account silently on first write.

The same field notes and Discussion drawer sit on every filed pitch page; the Discussion drawer alone also sits on the softball pitches, the lost-pitch files, the Learn topics and the repertoire pages.

## Reviewer Path

1. Launch the app.
2. Browse Atlas, Index, Grips, Craftsmen, and Sources without signing in.
3. Use the path above to file a field note or a discussion post. This works without account setup; an anonymous account is created behind the scenes on first contribution.
4. Use the menu on any post or note to report it or to block a different user. These also work anonymously.
5. Tap the account button at the top right of Atlas to open Account and Safety: the account shows as "Anonymous contributor" with a "Claim this record" block. Claim it with Sign in with Apple or an email confirmation link; the same account (and its posts) is preserved.
6. For image upload, claim the account first (uploads require a permanent account), then accept image terms and choose a still image with PhotosPicker.
7. Review the private blocked list in Account and Safety.
8. Return to Account and Safety to delete the account (works for anonymous and claimed accounts).

## Suggesting a Post for Review (new in 1.2.0)

Atlas, each pitch page and each craftsman page end their credited-clip shelf with a fold, `Know a pitching post that belongs here?`. A reader can paste a public X, Instagram, TikTok or YouTube URL and a short reason and tap `Send to review`. This is a write, so it creates the same silent anonymous account. The suggestion goes to a private review queue that no reader can see; nothing publishes from it until a person checks and tags the post. No media is uploaded through it.

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
- Version: `1.2.0`
- Build: `13`
- Privacy policy: `https://pitch-atlas.com/privacy`
- Support: `https://pitch-atlas.com/support`
- No Firebase, Appwrite, CloudKit, push notifications, camera capture, video upload, or BSI dependency. The only `WKWebView` is the credited TikTok teaching-clip embed described under **Embedded Teaching Clips** above. There is no app-content webview or web wrapper.
- Production Supabase block RPCs were applied on 2026-06-24 as migration `20260624194451 block_user_rpcs`.

## Final Build Proof

Build `1.2.0 (13)` was archived from `main` at `35c9584` (PR #37, tag `v1.2.0-build13`, also `release/1.2.0`) on 2026-10-30 after the full suite passed (524 tests, 0 failed), GitHub CI and Xcode Cloud run 42 passed on that commit, and the production release gate filed a field note, a discussion post and a reply under one handle and then deleted its throwaway account in the app. App Store Connect reports build `13` (`d12be2a7-0af3-4cc3-998b-69a225f54d53`) as `VALID`, uploaded `2026-10-30T12:46:57-07:00`, min OS `17.0`, `usesNonExemptEncryption=false`. It was submitted as review submission `0b7dce83-8e94-415f-9d89-404ba3c941ab` at `2026-10-30T19:49:12.249Z` (`WAITING_FOR_REVIEW`). Record: `docs/review-evidence/2026-10-30-build-13-submitted.md`.

Before it, build `1.2.0 (12)` was archived from `release/1.2.0` (`ac72447`) on 2026-10-30 after the full suite passed (522 tests, 0 failed) and `testReviewerPath` walked the path above from a fresh install. App Store Connect reports build `12` as `VALID`, `APP_STORE_ELIGIBLE`, uploaded `2026-10-30T08:57:03-07:00`, min OS `17.0`, `usesNonExemptEncryption=false`. It was submitted as review submission `5fe9bf01-253c-40c9-986e-28aa98d445a1` at `2026-10-30T16:28:48.708Z` (`WAITING_FOR_REVIEW`). Record: `docs/review-evidence/2026-10-30-build-12-submitted.md`. Withdrawn the same day (`DEVELOPER_REJECTED`, before any review): the production release gate showed build `12` could not file a discussion post ("Sign in before doing that."), and field notes take the same path. Build `13` replaces it.

History: `1.1.0 (11)` was submitted 2026-07-03, rejected 2026-07-07 under Guideline 2.3 because Apple could not find Community posting, and approved after these notes gave the exact path; its proof is in `docs/review-evidence/2026-07-03-build-11-screens/`.
