# Connected native learning evidence

The Grips library now searches authored record text and leads to its filed specimen or basic pitch file. Study and Compare share the selected variant; comparison can inspect either selected specimen and return to the retained pair/view. Grip, Variants, Lessons, Discussion and Sources address actual specimen sections. Craftsman, Learn and Lost Pitch readers have editorial chapter targets. Photo inspection has explicit accessible zoom/reset controls and respects Reduce Motion.

The five-tab app, original geometry, bundled authored data, source/confidence semantics and native community safeguards remain intact. No new pitch facts, photo assets, auth actions or community writes were introduced. README, UI copy and provenance model continue the sourced-not-corrected principle.

## Source and review custody

Implementation started at authoritative Air `9f7e7c4fbfce0663c1870178f2563663b5fc6c75`, branch `codex/archive-within-reach`. Nine-file learning patch SHA256 `499bd9268a3470731f80d3381f07391a6cdbb43454dabd29f61f214bfba95f3e` received independent scoped source acceptance. Runtime review added two Grips action text-color modifiers and one narrow confidence-color mapping (ten source/test files total). Contrast-only independent review passed.

Simulator QA is `/tmp/Pitch-Atlas-iOS-archive-qa.yjwdi0` on Pro, device `983D5CE0-7F5B-4580-8C53-EADB3D15399C` (iPhone17Pro, iOS26.5). All ten changed source/test file SHA256s match authoritative Air. Of all56 tracked Swift files, only `PitchAtlasApp.swift` differs: the documented three-line DEBUG PA_COMPARE handler. Existing PA_TAB, PA_PITCH and PA_CRAFTSMAN are authoritative DEBUG hooks. None modifies production behavior. A release archive must use authoritative tracked Air source, never this QA overlay.

## Verification

- Existing focused test receipt was read, not rerun:9 passed,0 failed,0 skipped. This receipt predates the presentation-only contrast changes.
- Original learning simulator build passed. Both contrast follow-up builds passed; final log `/tmp/pa-native-learning-provenance-build.log` ends `BUILD SUCCEEDED`.
- Actual uninterrupted662.286667s recording: Grips search/empty-state recovery, four-seam filtered result, filed Four-seam study, Gerrit Cole variant, Compare plus Two-seam, Cues, selected Two-seam specimen, native Back to same pair/Cues/Cole, Done and native return to retained Grips query and2/2 tray. No route injection after initial Grips tab. This recording predates the presentation-only contrast correction.
- Edited accelerated excerpt is explicitly labeled and its source intervals documented separately. Original remains retained.
- Final-build specimen Variants/Lessons/Discussion/Sources chapter taps each landed on intended content. Discussion selected its read-only panel and preserved unchecked gates. Source ledger showed filed citations and retrieval dates.
- Final-build Sources provenance legend exposes distinct secondhand/community labels and their explanations.
- Final-build photo zoom100→150→Reset100 confirmed the image returned to its initial aspect-fit scale. Close was then explicitly tapped and exited to the original Grips scroll position. Full pan/VoiceOver traversal is not inferred from this check.
- Maximum Dynamic Type (accessibility-extra-extra-extra-large) specimen capture shows readable reflow and chapter navigation switching to a menu. ReduceMotionEnabled and EnhancedBackgroundContrastEnabled were set/read back as1; these defaults receipts do not certify all motion or transparency behavior.

Evidence root on Pro: `/Users/AustinHumphrey/Pitch-Atlas/artifacts/native/archive-world/learning-continuity/`. `recording-ledger.md`, `final-source-parity.json`, `all-swift-parity.json`, focused test receipt and original/edited videos retain custody. Image/manifest hashes are recorded with the artifact handoff; raw private media remains local rather than committed.

## Bounded contrast measurements

Measured full-color text pixels, sRGB relative luminance:

- Grips action text changed from powder `#6CACE4` on dominant button fill `#36434E` (4.184:1) to existing bone `#F6F1E6` (9.008:1). Button fill, layout and action semantics are unchanged.
- `color(forConfidence:)` maps secondhand/community to existing warm `#EDC7AA`, preserving distinct text labels. It measures10.087:1 on `#24221F`,8.114:1 on `#3D3023`; source screenshot confirms the intended text pixels. Global sandBright and unrelated decorations remain unchanged.

These measurements cover the stated pairs only, not app-wide contrast certification.

## Release archive and current native availability

The authoritative learning source is commit `53985e721e7f2fc9bae823399b0861d41d91f02b` on Air branch `codex/archive-within-reach`. At the release check, Air had only the protected untracked inputs `PitchAtlas/Resources/grips.zip` and `PitchAtlasTests/SurfaceSnapshots.swift`; neither was altered. The detached Pro release checkout `/tmp/PitchAtlas-native-release-53985e7` was clean at that same commit.

Pro produced `/tmp/PitchAtlas-learning-53985e7-Pro.xcarchive` from that clean checkout with `CODE_SIGNING_ALLOWED=NO`; the receipt records exit code `0`, finished `2026-09-06T00:56:20.458167+00:00`, and the log ends `** ARCHIVE SUCCEEDED **`. Archive metadata identifies arm64 `com.pitchatlas.app`, marketing version `1.1.0`, build `11`, minimum iOS `17.0`, SDK `26.5`, and Xcode build `17F113`. Its `SigningIdentity` and `Team` fields are empty, and `codesign` confirms the app is not signed. This is compile/archive proof only; it is not a signed export, install, TestFlight upload, or App Store delivery receipt.

Local custody receipts under `/Users/AustinHumphrey/Pitch-Atlas/artifacts/native/archive-world/learning-continuity/` are `pro-archive-53985e7-receipt.json` (SHA256 `1ca398b82ca090ab694ac82129442a375ea7c3822595ffc2d5a9e24496501f9d`) and `pro-archive-53985e7.log` (SHA256 `45bbcab3d78038160534509bef9c5f550d38159bc568879f21742339effb507f`).

A fresh read-only check at `2026-09-06T01:19:11Z` found zero valid code-signing identities on Pro. Air reported five valid identities: two Apple Development, two Apple Distribution, and one Developer ID Application identity. `xcrun devicectl list devices` on both Pro and Air reported Austin's paired iPhone 16 (`iPhone17,3`, identifier `08A570D5-B423-5EF4-8D92-8602C23DDE92`) as `available (paired)`. These checks establish present identity and device visibility only. A subsequent bounded development export, described below, failed; identity enumeration alone does not establish signing-key access.

## Signed export diagnostic

The successful Pro archive was transferred to Air. Its74-file content-ledger SHA256 matched exactly: `e9e2f5f3acad634466176b69091194aa7c56fe8adf029f397bc1fde251c1b1de`. One `xcodebuild -exportArchive` attempt using existing Apple Development signing failed at codesign with `errSecInternalComponent`, exit70. No IPA was produced; no retry or keychain/account/profile/permission change was made. The retained Air log is `/tmp/PitchAtlas-development-export-53985e7-attempt1.log`, SHA256 `68207b74a778d9348810b257bc9fdaae5c0498cb445dfa22f5577e05a3921da9`.

The available paired iPhone already contains com.pitchatlas.app1.1.0(11). Its local-data state was not established, so this check did not replace the installation. The source revision remains53985e7; later evidence-only commits do not change the archived code. This is an unsigned archive success and a failed signed export, not TestFlight readiness.

## Remaining verification boundaries

Full spoken VoiceOver traversal, every native utility/error/auth route, native softball coverage, first-launch airplane-mode acceptance, physical device60fps/thermal profiling, signed export and TestFlight/App Store delivery are not established by these receipts. Current simulator CPU observations are not physical-device performance proof. Earlier scope audit remains the inventory of broader product/release gaps.

## Index reading-place and study-link follow-up

Source `f285654724be2e2379916edc7f9f42f3074a45a4` captures the visible Index row
before navigation and protects it from covered-view layout changes. Query,
family, status and sort intentionally reset it. Reverse scrolling to the header
clears a stale deep-row anchor. The two basic-file study links now use direct
native destinations; Study this first includes its spacer in the tap area. The
inherited PitchAtlasEntry mapping remains for related-family navigation.

Independent source reviews passed. Eight focused restoration tests passed.
CI34008866623 passed83tests/0failures, build and content drift for earlier6bb960c
on GitHub merge ref856ee65. Final f285654 CI34009442833 also passed83tests,
zero failures, build and content drift on merge ref03a3db0.
The final f285654 simulator build passed in10.9seconds. Four changed Swift files
match the clean source; temporary Index diagnostic prints were removed. The
existing three-line QA-only PA_COMPARE overlay remains confined to the capture
checkout and is absent from the release archive.

Actual row restoration passed for Four-Seam and a genuinely deeper Split-Finger
row. Partial-row offsets normalize to row top (47.3points and11.7points in the
measured cases), so this is not exact pixel restoration. Actual Split-Finger Basic
→ Study this first → Splitter → native Back to Basic → Back to filtered Index
passed with titles and Back labels inspected. Reversing to the header and
Grips→Index retained query `a` and Fastballs. A deliberate150%-zoom/right-pan/
Reset/Close photograph check also passed; the full image returned centered at100%.

Two initial automation judgments were corrected: the cropped starting row was
Four-Seam, not Two-Seam; a study-link tap under the floating tab bar selected
Grips, while the original Basic file remained intact in Index. Source changes
were assessed against actual coordinate logs and an unobscured link. These
corrections do not stand in for physical VoiceOver or cancelled-edge-swipe proof.

Clean source f285654 produced `/tmp/PitchAtlas-learning-f285654-Pro.xcarchive`
on Pro, exit0, finished2026-09-06T03:41:40Z. It is unsigned arm64,
com.pitchatlas.app1.1.0(11), minimum iOS17. The receipt SHA256 is
`86bd2a73336e776b7cab7f809d269a33fa8773c308e2c365ad5e2e07f965d333`;
log SHA256 is `130466290adf127ff4ae50154017019a7939198ee90d3ae14dca469c381b3c73`.
The prior53985e7 Air export failure is not a signed-export attempt of this source.
No new signing retry, physical install, production or TestFlight delivery occurred.

Local artifacts are under
`/Users/AustinHumphrey/Pitch-Atlas/artifacts/native/archive-world/context-acceptance/`.
The current cross-platform evidence is maintained in Pitch Atlas web
`docs/NATIVE-CONTEXT-EVIDENCE.md`; raw screenshots, recordings and build receipts
remain local. Source and confidence labels, bundled offline claims, rights,
moderation, and shared seam geometry are unchanged.

### Related-family navigation repair

The fully visible Two-Seam sibling pill failed to open on f285654. Final source
`e48650169741f41bef978de95f2de8512c370a39` uses a direct native destination for
related-family links and a44-point minimum full hit area. Independent review
passed; the final simulator build passed in14.9seconds. Actual Index → Four-Seam
Basic → Four-Seam specimen → Two-Seam → Four-Seam specimen → Four-Seam Basic →
Index passed with rendered titles, Back labels and selected tab verified. Root
inspected the Two-Seam still. The uninterrupted recording is227.02seconds; the
separate4x derivative is accelerated review footage, not frame-rate evidence.
Five changed Swift files match clean source; no Index diagnostic prints remain.

Clean exact-source archive `/tmp/PitchAtlas-learning-e486501-Pro.xcarchive`
succeeded at2026-09-06T03:52:48Z, exit0, unsigned arm64, version1.1.0(11), minimum
iOS17. Receipt SHA256 `accaf8ad3bdf08cad2a5648d63d3e528a54f11e37d1254fbc82ceb37927c5539`;
log SHA256 `03358325f09fbe00093eca8ca71b80a233516053c857a98358bac874c1841078`.
This source includes the sibling repair missing from the f285654 archive.
Signing and all physical-device acceptance remain separate.

Final e486501 CI34009999020 passed83tests/0failures, build and content drift on
GitHub merge refa050710. The74-file archive ledger matched after transfer to Air:
`/tmp/PitchAtlas-e486501-transfer/PitchAtlas-learning-e486501-Pro.xcarchive`.
Ledger SHA256 `d9c6d9df32ff8b44201f37c51ac8ec5b60543043b57a47943e490f5e18af19d3`;
transfer ZIP SHA256 `52bf9bd04c658f90fcd80687f397cf0967fc312887f45c704f2245ab19056214`.
No new signing attempt followed. The accelerated sibling clip measures57.19seconds.
