# Build 11 Submission Gate

Date: 2026-07-03

## Known

- [verified] Source checkout: `/Users/AustinHumphrey/pa-ios-release` at `b45bbe8` / `origin/main`, version `1.1.0`, build `11`, bundle `com.pitchatlas.app`.
- [verified] App Store Connect build `04554def-bc16-4176-bfbf-396979f7d496` is build `11`, pre-release version `1.1.0`, `VALID`, `APP_STORE_ELIGIBLE`, uploaded `2026-07-03T09:05:52-07:00`, min OS `17.0`, and `usesNonExemptEncryption=false`.
- [verified] App Store Connect still has `1.0.1 (10)` in `PENDING_DEVELOPER_RELEASE`, attached to build `a953bb8c-e419-40e2-a339-b02830b966df`.
- [verified] Creating a new `1.1.0` App Store version returned `409 ENTITY_ERROR.RELATIONSHIP.INVALID`: "You cannot create a new version of the App in the current state."
- [verified] Build `11` is in the internal TestFlight group `Pitch Atlas Internal`. It is not in `Pitch Atlas Internal Testers` or the external public-link group.
- [verified] XcodeBuildMCP `test_sim` passed `65` tests, `0` failed.
- [verified] Production Supabase includes the PR #151 migrations: `20260703164350_field_note_rank_trigger_security` and `20260703164408_discussion_media_read_policy_grant`.
- [verified] Fresh build-11 screenshots were captured from the 6.9-inch simulator at `1320x2868`.

## Screenshot Set

- `2026-07-03-build-11-screens/01-atlas-home.png`
- `2026-07-03-build-11-screens/02-pitch-detail-slider.png`
- `2026-07-03-build-11-screens/03-grips.png`
- `2026-07-03-build-11-screens/04-index.png`
- `2026-07-03-build-11-screens/05-sources.png`

## Unknown

- [unknown] Whether Apple Support or App Store Connect UI can reset/cancel the `1.0.1` pending developer release without putting build `10` on sale. The API create path is blocked.
- [unknown] Whether Austin wants build `10` manually released as the unlock step. That would make the older approved version public before `1.1.0` can be submitted.

## Open

- Do not paste 1.1.0 anonymous-first metadata or upload build-11 screenshots onto the existing `1.0.1` App Store version. That would mismatch the approved build.
- Once the `1.0.1` pending-release slot is resolved, create the `1.1.0` App Store version, attach build `11`, update the App Store localization, upload the five July 3 screenshots, and submit for review.
- The `PitchAtlasReleaseGate` UI test was not run in this pass. Its source comment says it deletes the test post/account afterward, but the code only submits a production discussion post. Do not run it until cleanup is implemented or manual cleanup is planned.
