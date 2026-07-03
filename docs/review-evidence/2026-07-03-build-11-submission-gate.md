# Build 11 Submission Gate

Date: 2026-07-03

## Current Result

- [verified] `1.0.1 (10)` was manually released after Austin approved the brief public release of the older approved version.
- [verified] App Store Connect then reported `1.0.1` as `READY_FOR_SALE`.
- [verified] `1.1.0` was created as App Store version `db6cb47d-3547-4acd-91ba-d41857b65c67`.
- [verified] Build `11` (`04554def-bc16-4176-bfbf-396979f7d496`) was attached to `1.1.0`.
- [verified] The `en-US` App Store localization was updated: description `1463` characters, What's New `623`, promotional text `85`, keywords `79`.
- [verified] App Review notes were updated to `3062` characters and `demoAccountRequired=false`.
- [verified] Media Manager for `1.1.0` now has exactly five build-11 screenshots, all `COMPLETE`, all `1320x2868`.
- [verified] Review submission `7f3ac406-4831-42b9-b7be-b284a494a781` was submitted at `2026-07-03T22:50:48.918Z`.
- [verified] Final App Store Connect readback: `1.1.0` is `WAITING_FOR_REVIEW`; `1.0.1` is `READY_FOR_SALE`.

## Known

- [verified] Source checkout: `/Users/AustinHumphrey/pa-ios-release` at `b45bbe8` / `origin/main`, version `1.1.0`, build `11`, bundle `com.pitchatlas.app`.
- [verified] App Store Connect build `04554def-bc16-4176-bfbf-396979f7d496` is build `11`, pre-release version `1.1.0`, `VALID`, `APP_STORE_ELIGIBLE`, uploaded `2026-07-03T09:05:52-07:00`, min OS `17.0`, and `usesNonExemptEncryption=false`.
- [verified] The earlier gate was real: before `1.0.1` was released, App Store Connect had `1.0.1 (10)` in `PENDING_DEVELOPER_RELEASE`, and creating a new `1.1.0` App Store version returned `409 ENTITY_ERROR.RELATIONSHIP.INVALID`.
- [verified] Build `11` is in the internal TestFlight group `Pitch Atlas Internal`. It is not in `Pitch Atlas Internal Testers` or the external public-link group.
- [verified] XcodeBuildMCP `test_sim` passed `65` tests, `0` failed.
- [verified] Production Supabase includes the PR #151 migrations: `20260703164350_field_note_rank_trigger_security` and `20260703164408_discussion_media_read_policy_grant`.
- [verified] Fresh build-11 screenshots were captured from the 6.9-inch simulator at `1320x2868`.
- [verified] Apple Help says a new app version can be initiated only when the current version status is `Ready for Distribution`; Apple Help also describes `Pending Developer Release` as a manual-release state whose listed action is `Release This Version`.
- [verified] The Chrome extension/backend path was checked for logged-in UI inspection. Chrome is running, the Codex Chrome Extension is installed and enabled in `Profile 1`, and the native-host manifest is correct, but `agent.browsers.list()` still returned no available Chrome backend after retry. Per the Chrome plugin instructions, App Store Connect was not driven through an unrelated browser tool.
- [verified] The "remove availability, then release" detour is not safe to run silently. Apple exposes app availability as territory-level public App Store availability; the current app is available in the first 50 territories returned by the API, including USA, FRA, DEU, GBR, and AUT. Apple's release docs say manual release makes the version available in countries or regions where the App Store status is Available or Available on App Release.

## Screenshot Set

- `2026-07-03-build-11-screens/01-atlas-home.png`
- `2026-07-03-build-11-screens/02-pitch-detail-slider.png`
- `2026-07-03-build-11-screens/03-grips.png`
- `2026-07-03-build-11-screens/04-index.png`
- `2026-07-03-build-11-screens/05-sources.png`

## Unknown

- [unknown] Apple review timing and outcome for `1.1.0 (11)`.
- [unknown] Exact App Store propagation timing for the now-live `1.0.1 (10)` build across all storefronts.

## Open

- Monitor App Store Connect for Apple review state changes on review submission `7f3ac406-4831-42b9-b7be-b284a494a781`.
- When Apple approves `1.1.0`, release it manually if it lands in `PENDING_DEVELOPER_RELEASE`.
- If Austin wants UI inspection before choosing a release/reset path, restore the Chrome bridge first. The local checks show the extension and native host are installed, but the Codex browser backend is not discoverable in this session.
- The `PitchAtlasReleaseGate` UI test was not run in this pass. Its source comment says it deletes the test post/account afterward, but the code only submits a production discussion post. Do not run it until cleanup is implemented or manual cleanup is planned.
