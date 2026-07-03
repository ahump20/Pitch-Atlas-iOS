# Pitch Atlas App Store Connect Pack

Status: 2026-07-03 release gate for `com.pitchatlas.app`; build `1.1.0 (11)` is valid in App Store Connect, but the App Store review submission is blocked by the older approved `1.0.1 (10)` version sitting in `PENDING_DEVELOPER_RELEASE`.

Update, 2026-07-03 afternoon: App Store Connect API readback shows build `11`
(`04554def-bc16-4176-bfbf-396979f7d496`) as `VALID`, uploaded
`2026-07-03T09:05:52-07:00`, pre-release version `1.1.0`, min OS `17.0`,
`APP_STORE_ELIGIBLE`, and `usesNonExemptEncryption=false`. Build `11` is in the
internal TestFlight group `Pitch Atlas Internal`; it is not in `Pitch Atlas
Internal Testers` or the external public-link group. The App Store version list
still contains only `1.0.1` (`PENDING_DEVELOPER_RELEASE`) and `1.0` (`READY_FOR_SALE`).
Creating a new `1.1.0` App Store version through `POST /v1/appStoreVersions`
returned `409 ENTITY_ERROR.RELATIONSHIP.INVALID`: "You cannot create a new
version of the App in the current state." Do not release build `10` as a
workaround unless Austin explicitly chooses to put the older build into public
distribution. Once the `1.0.1` pending-release slot is released, canceled, or
reset in App Store Connect, create the `1.1.0` version, attach build `11`, paste
the updated copy below, upload the July 3 screenshots, and submit that version
for review.

Build `11` local proof: XcodeBuildMCP built and launched the app on the
`Pitch Atlas 6.9 Screenshot iPhone` simulator. `test_sim` passed `65` tests,
`0` failures. Fresh 6.9-inch screenshots live in
`docs/review-evidence/2026-07-03-build-11-screens/` at `1320x2868`. App Store
Connect currently has one `APP_IPHONE_67` screenshot set with five complete
images attached to `1.0.1`; no App Preview videos are present. Do not paste the
1.1 anonymous-first copy onto `1.0.1`, because that version is still attached to
build `10`.

Supabase production proof: the web repo is on `a703784`
(`fix(db): repair the community grants-hardening fallout (field notes +
discussion media) (#151)`), and the live Supabase migration list includes
`20260703164350_field_note_rank_trigger_security` and
`20260703164408_discussion_media_read_policy_grant`.

Update, 2026-07-03: the pre-archive release gate (now a real XCUITest — the
`PitchAtlasReleaseGate` scheme, never run by CI) caught and fixed two 1.1.0
write-path bugs against production before archive: the delete-account call sent
a stale cached token (401 after an overnight session; fixed by refreshing the
session through the SDK), and community insert payloads carried a client-minted
`id` that sits outside the column-scoped INSERT grants, denying the whole
insert (fixed by mirroring the web contract — server-generated id, read back
via RETURNING; pinned by a payload-shape unit test). Field-note posting had
been gated on a server-side grant fix from the web repo; PR #151 is now on web
`main` and its two July 3 migrations are live in Supabase production.

Update, 2026-07-02: version `1.1.0` build `11` prepared on `release/1.1.0` — the
"Specimen Comes Alive" wave: the native 3D specimen ball (SceneKit, seam-informed
schematic label preserved), anonymous-first community with a claimable record,
the field-note Tried this / Helpful loop with live ranking, teaching clips
(poster-gated remote embeds), the dormant archival-film layer, and the launch
line corrected to the identity line. Ship path: local signed archive (the same
path build 10 shipped through) → TestFlight internal. **Do not submit 1.1.0 for
review while the 1.0.1 (10) submission is still open** — one active submission
per platform; if 1.0.1 is approved, release or hold it and then submit 1.1.0;
if rejected, fold the response into 1.1.0 and submit that instead. The
description/truth-table corrections for anonymous-first (below) must be pasted
into ASC when 1.1.0's store version is created.

Update, 2026-06-25: build `1.0.1 (10)` was uploaded from the local signed
archive after the tab-bar gutter fix and App Store Connect reports it as
`VALID` (`a953bb8c-e419-40e2-a339-b02830b966df`, uploaded
`2026-06-25T21:59:10-07:00`). It is assigned to the internal TestFlight group
`Pitch Atlas Internal Testers`, and the all-builds internal group should also
see it.

Update, 2026-06-26: App Store Connect submission was moved from build `9` to
build `10`. The previous waiting review submission was removed, build `10` was
attached to version `1.0.1`, reviewer notes were refreshed for build `10`, and
new review submission `eb1c9764-d7af-4ce8-8896-938e7f25fb96` was submitted at
`2026-06-26T08:53:05.618Z`.

Build `1.0.1 (10)` is the submitted release target. App Store Connect reported version `1.0` as previously approved/closed, rejected `1.0.0 (5)`, and accepted build `6` on 2026-06-24 before the final visual/loading pass. Build `10` supersedes builds `6`, `7`, `8`, and `9`.

Verified 2026-06-26 through the App Store Connect API:

- Build `10`: `VALID`, uploaded `2026-06-25T21:59:10-07:00`, min OS `17.0`, `usesNonExemptEncryption=false`, build ID `a953bb8c-e419-40e2-a339-b02830b966df`.
- App version `1.0.1`: `WAITING_FOR_REVIEW` with attached build `10`.
- Review submission `eb1c9764-d7af-4ce8-8896-938e7f25fb96`: `WAITING_FOR_REVIEW`, submitted `2026-06-26T08:53:05.618Z`.
- Internal TestFlight: build `10` is in `Pitch Atlas Internal Testers`, and the all-builds internal group should also see it.
- External public-link TestFlight group was not changed.
- Chrome UI verification was unavailable from Codex because the Chrome extension backend did not respond, so ASC state was verified through the official API instead.
- This run did not drive a physical TestFlight install on a tester device from this shell.

## App Identity

- App name: `Pitch Atlas`
- Bundle ID: `com.pitchatlas.app`
- SKU: `pitch-atlas-ios`
- Primary category: `Sports`
- Secondary category: `Education`
- Pricing: `Free`
- Platform: `iOS`
- Device family: `iPhone`
- Version: `1.1.0`
- Build: `11`

## Canonical Xcode Project

Archive and upload from `PitchAtlas.xcodeproj` in the main `Pitch-Atlas-iOS` repo/worktree only. The local skeleton at `/Users/AustinHumphrey/Pitch-Atlas-iOS-local-skeleton-20260608-221355/Pitch Atlas/Pitch Atlas.xcodeproj` is a prototype and is intentionally retargeted to `com.pitchatlas.local-skeleton` so it cannot collide with the production App Store bundle.

## Subtitle

`A field manual for pitch craft`

## Promotional Text

`An offline field manual for how pitches are gripped, shaped, sourced, and understood.`

85 characters.

## What's New — 1.1.0

`The specimen comes alive: an interactive 3D ball on every filed pitch — warm leather, raised seam, and the fingertip pressure marks of the grip, drawn from the same sourced geometry as the schematic. Drag to turn it; the honest 2D schematic remains for Reduce Motion. Community is now anonymous-first: file a note with no account, then claim your record with Apple or email whenever you want it to travel. Field notes gained the Tried this / Helpful loop with live ranking, filed specimens gained teaching clips, and the launch screen now carries the line the product lives by: Preserving & Progressing the Art of the Pitch.`

## Description

Pitch Atlas is a native field manual for the craft of pitching. It explains how pitches are gripped, how they move, who made them famous, and how solid each claim is.

The app is built around a simple rule: sourced, not corrected. A measured figure, a pitcher quote, a coach observation, and an unverified claim do not wear the same label. Every pitch read shows its evidence tier so the gap stays visible.

Inside the app:

- A searchable pitch index, from four-seams and sliders to lost pitches and banned doctored balls.
- Native seam specimens with sourced motion cues and seam-informed schematics.
- A grip library built from first-party grip photography and first-person notes.
- Craftsmen and lost-pitches wings for the pitchers, pitch names, and techniques that shaped the language.
- A sources browser so the reader can see where each claim came from.
- An optional, free community layer: post field notes and discussion, report content, and block contributors with no account setup — an anonymous record is created on your first contribution, and you can claim it with Sign in with Apple or email to keep it across devices and attach still images.

The full reference library is bundled inside the app, so it works on first launch without an account and without a network connection. Community participation needs no sign-in: posting, reporting, and blocking work anonymously. Sign-in exists only to claim your record across devices and to attach images.

## Keywords

`baseball,pitching,grips,pitches,spin,curveball,slider,changeup,fastball,sources`

79 characters.

## URLs

- Marketing URL: `https://pitch-atlas.com/`
- Support URL: `https://pitch-atlas.com/support`
- Privacy URL: `https://pitch-atlas.com/privacy`

Verified 2026-06-24: support and privacy routes return HTTP 200 through Cloudflare.

## App Privacy

Do not set `Data Not Collected`. Match `PitchAtlas/Resources/PrivacyInfo.xcprivacy`.

Collected data, all linked to identity, none used for tracking, all for App Functionality:

- Email Address: account sign-in.
- User ID: the Supabase account identifier.
- Other User-Generated Content: field notes, discussion posts, reports.
- Photos or Videos: still images the user chooses to attach.

Truth table for this binary:

- Optional account, anonymous-first. Community posting, reporting, and blocking work with no sign-in (an anonymous account is created server-side on the first write). Sign in with Apple / email exists to claim the record; image uploads require a claimed account.
- Sign in with Apple is supported.
- No analytics SDK.
- No advertising SDK.
- No tracking.
- No Firebase, Appwrite, CloudKit, push notifications, camera capture, or video upload.
- One WKWebView exists: the teaching-clip embed on a specimen page. It loads nothing until the poster is tapped, plays a remote TikTok embed (never rehosted), and is not a web wrapper around app content.
- Device motion is used only on-device for the foil card effect and the specimen ball's resting parallax, and stops when Reduce Motion is enabled.

## Age Rating

Expected posture: answer the questionnaire honestly and let App Store Connect compute the rating. The reference content is baseball instruction; community contribution is gated by guidelines acceptance and a 17+ posting/upload confirmation (sign-in is optional — contribution is anonymous-first).

- User-generated content: yes.
- Posting and uploads require sign-in.
- Reporting, blocking, guidelines, image terms, and in-app account deletion are present.
- No gambling, unrestricted web access, camera capture, video upload, or medical treatment advice.

## Export Compliance

Answer: uses only exempt encryption through standard HTTPS/ATS. `ITSAppUsesNonExemptEncryption` is false in the generated Info.plist.

## App Review Notes

Paste from `docs/APP-REVIEW-NOTES.md` after the `1.1.0` App Store version slot exists. It includes the final build, simulator test, TestFlight, Supabase, and App Store Connect proof for `1.1.0 (11)`.

If reviewer credentials are required, provide a Supabase test account in the App Store Connect reviewer credentials fields only.

## Screenshots To Capture

Required iPhone set:

- Atlas home: card-style specimen, `Pitch Atlas`, `Sourced, not corrected`, and tab bar.
- Pitch Index: search and family filters.
- Pitch detail: native seam specimen, source badges, grip/coaching sections, and community surface.
- Grip Library: first-party grip photography and `not tracked data` framing.
- Sources: provenance/source browser.
- Account and Safety: sign-in, safety notes, reports/blocks/account deletion path.

For every final screenshot report, verify the rendered state first, then include annotated design/UX critique with at least 10 high-level fixes or improvements per image.

## Release Gates

- Production Supabase project `cloeoulvrrfcbitrjpso` exposes `block_user`, `unblock_user`, and `my_blocked_users` to authenticated clients.
- Clean 6.9-inch simulator testing passed: 65 tests, 0 failures. App Store Connect build `11` resolves to pre-release version `1.1.0`, build `11`, min OS `17.0`, `APP_STORE_ELIGIBLE`, and `ITSAppUsesNonExemptEncryption=false`.
- App Store Connect build `11` is `VALID` but cannot yet be submitted because the only editable review slot is blocked by `1.0.1 (10)` in `PENDING_DEVELOPER_RELEASE`.
- Internal TestFlight has build `11` in `Pitch Atlas Internal`; `Pitch Atlas Internal Testers` and the external public-link group were not changed.
- The new screenshots are captured locally and ready, but not uploaded to App Store Connect because no `1.1.0` App Store version exists yet.

## Internal Brand Guardrail

Do not use Blaze Sports Intel, BSI marks, BSI copy, BSI account language, or BSI support surfaces for this submission. Pitch Atlas is its own app and product.
