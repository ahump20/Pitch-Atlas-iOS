# 2026-10-30 Build 13 Submitted

Purpose: record why `1.2.0 (12)` was withdrawn, what `1.2.0 (13)` fixes, how the
fix was proven, and the App Store Connect state after build 13 went to App
Review. Every App Store Connect value below was read back from its API on
2026-10-30, not copied from notes.

## Why build 12 was withdrawn

The production release gate (`PitchAtlasReleaseGate`, run against the real
Supabase project) showed build 12 could not file anonymous community writes.
The discussion composer answered "Sign in before doing that." and nothing
reached the server. Field notes go through the same step, so they failed too.
Build 12 was `WAITING_FOR_REVIEW` with automatic release on approval, so the
review submission `5fe9bf01-253c-40c9-986e-28aa98d445a1` was cancelled before
Apple reviewed it. The version showed `DEVELOPER_REJECTED` until build 13 was
attached.

## Root cause

Before every post, reply or field note, the app saves the handle the
contributor typed to their profile. That update asked the server to send the
updated profile row back (`Prefer: return=representation`). The `profiles`
table is readable column by column. Signed-in clients cannot read `is_admin`,
`created_at`, `updated_at` or `media_terms_accepted_at`. So the server refused
the whole update with "permission denied" and the write never ran. The app then
mapped that refusal to "Sign in before doing that.", which sends an anonymous
contributor toward the sign-in path that would orphan their record.

Proven three ways:

1. The request itself: `testSavingTheHandleAsksForNoRowBack` records the PATCH
   and failed on `Prefer: return=representation` before the fix.
2. The database catalog (read-only query): `authenticated` holds no SELECT on
   those four `profiles` columns.
3. A production A/B: the gate failed on build-12 source with "Sign in before
   doing that." and passed on the fixed source.

The server's grants and row security were not changed. The site's client
already asks for no row back.

## The fix (PR #37, merged as `35c9584`)

- `ecc0d4c`: saving the handle asks for no row back (`returning: .minimal`).
  A privilege or row-security refusal now reads "Could not save that just now.
  Try again." Only a real missing or expired login asks for sign-in. Tests:
  `testSavingTheHandleAsksForNoRowBack`, `testARefusedWriteNeverAsksAnAnonymousContributorToSignIn`
  (both failed first, then passed).
- `1dec974`: build number `13` in `project.yml`, the pinned test moved with it.
  Content regenerated from a fresh clone of web `main` at `47e21e6`: no change.
- `1d84f34`: the release gate files a field note, a discussion post and a reply
  under one handle, checks the post shows under that handle, and deletes its
  throwaway account through Account & Safety.
- `48358e2`: a debug-only `PA_OFFLINE` switch and `testOfflineFirstLaunch`
  (below). Compiled out of the release build: the archived binary has no
  `PA_OFFLINE` or `PA_PITCH` string.

An anonymous contributor's own `profiles.display_name` stays empty. The
server's profile-update policy excludes anonymous accounts (web migration
`20260606011014`), and the site behaves the same. Each post, reply and note
carries the typed handle on its own row, which is what readers see.

## Verification

- Full suite on `48358e2`: 524 tests, 0 failures. GitHub CI `build-and-test`
  passed on the same commit. Xcode Cloud run 42 on the merge `35c9584`:
  `SUCCEEDED`.
- Production release gate (gate8), fixed source: passed. While the test held,
  the server had one post, one reply and one field note, each with display
  name "Release gate", from an anonymous author with no email. After the
  in-app account deletion, the same read-only query returned nothing: the rows
  are removed with the account (`author_id` references `profiles` with
  `ON DELETE CASCADE`).
- Every gate run that day left zero rows behind, each checked by SQL afterwards.
- `testReviewerPath` walked the App Review path from a fresh install.
- `testTrayClearsTheTabBar` passed at the largest accessibility text size.
- Offline first launch, `testOfflineFirstLaunch` (`PA_SHOTS=offline`), from a
  fresh install on the iPhone 17 Pro simulator with every app request refused
  as "not connected": Atlas opens with the bundled grip photo, the four-seam
  page reads, the field notes say "Couldn't load the field notes. The server
  didn't answer." with Try again, the Discussion drawer shows "Could not load
  the discussion." with the same reason, and Index, Grips, Craftsmen and
  Sources (with its real "as of October 24, 2026" line) all render. It failed
  with the network up ("The field notes never said they couldn't load") and
  passed offline.
- Not verified here: airplane mode on a physical iPhone. The simulator run
  refuses requests inside the app; it does not switch off the device radio.

## Result

- Source: `main` at `35c9584` ("Pitch Atlas iOS 1.2.0 (13): anonymous posting
  files again (#37)"), tag `v1.2.0-build13`, also `release/1.2.0`. `v1.2.0`
  stays on `ac72447`, the build-12 commit. Archived locally from a clean clone
  of that commit with the committed package pins and uploaded with
  `xcodebuild -exportArchive`.
- `1.2.0` App Store version: `79432a3b-8a70-486c-8dc2-ddc2ad6107fe`, release
  type `AFTER_APPROVAL`, state `WAITING_FOR_REVIEW`.
- Attached build: `13` (`d12be2a7-0af3-4cc3-998b-69a225f54d53`), `VALID`,
  uploaded `2026-10-30T12:46:57-07:00`, min OS `17.0`,
  `usesNonExemptEncryption=false`.
- Review submission: `0b7dce83-8e94-415f-9d89-404ba3c941ab`, submitted
  `2026-10-30T19:49:12.249Z`, state `WAITING_FOR_REVIEW`.
- App Review notes: `2688` characters, the build-12 text with its first line
  naming build 13. Demo account required: `false`.

Waiting for review is not public availability. The App Store page
(`https://apps.apple.com/app/id6778277388`) shows `1.2.0` only after Apple
approves it and the automatic release runs.

## Listing and media (unchanged from build 12)

- en-US description `1862`, What's New `941`, promotional text `138`,
  keywords `98` characters.
- `APP_IPHONE_67`: ten 1320 × 2868 screenshots, all `COMPLETE`.
- App preview `pitch-atlas-preview.mp4`: `COMPLETE`.
- Age rating and privacy labels as recorded in
  `docs/review-evidence/2026-10-30-build-12-submitted.md`.

## Review findings not fixed for build 13

- CodeRabbit (PR #37) said the gate's "Reply filed ✓" check can never pass
  because that message is hidden from VoiceOver. The gate8 log shows the check
  found it and passed, and the reply row was confirmed by SQL. Checking a
  message hidden from VoiceOver is still fragile. Deferred: check the rendered
  reply in the thread instead.
- CodeRabbit said Xcode Cloud would renumber the archive above 13. It does not
  apply: uploads come only from a local archive, which keeps the number as
  written. `docs/CI.md` now says so.
