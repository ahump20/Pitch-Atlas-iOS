# Archive study — native contract

The five existing tabs share one session-owned `CompareSelection`. Atlas and Index expose the paper study table; filed specimen cards have a Compare context-menu and VoiceOver action; detail offers a visible Compare button in its study panel. Selecting a third pitch asks which existing slot to replace. Dismissing the sheet or changing tabs preserves the pair. A new process begins with an empty table.

`pitchatlas://compare?a=four-seam&b=slider&view=grips&hand=right&orientation=top` opens the comparison sheet. `view` accepts grips/cues/movement, `hand` right/left, and `orientation` top/side/thumb. Options default when absent. Both slugs must resolve to different filed entries in the bundled store. Unknown values, duplicate query keys, missing/unfiled slugs, or duplicate pitches show an explicit error and retain the existing pair.

Hold, Fingers, Seam, and Cue show the original bundled Claims with their source/confidence labels. Variant selection surfaces attributed prose; it never substitutes invented variant geometry. Movement is qualitative sourced prose, with no added numerical readings or simulated trajectories.

Inspection reuses SeamBall and SeamMath. Orthographic model views project both seam and marker coordinates through the same function; left hand mirrors their final screen coordinates. These are labeled seam-informed schematics, not measured grip geometry. The inspection slider zooms the model in its bounded viewport and Reset restores 1x. The existing dimensional detail stage remains available.

Study controls use native menus, scrolling, scalable text, descriptive accessibility labels, explicit text selection states, and selection haptics. No new idle motion is introduced; the existing native renderer retains its Reduce Motion fallback. Shared backdrop decoration drops out under Reduce Transparency, leaving solid charcoal, while the study table remains opaque paper.

Community, authentication, bundle JSON, backend configuration, and release settings are unchanged. The bundle remains usable offline. This change does not establish physical-device performance, first-launch airplane-mode proof, VoiceOver interaction completion, or App Store delivery.

## Release-preparation evidence — 2026-09-05

Evidence levels are deliberately separate:

- **Source and automated behavior:** commit `c9881fdf658eff9f9111b5e63afa45383544e649` on `codex/archive-within-reach` contains the study/compare implementation. The completed native suite reported 68 passing tests, including compare selection and link validation. Those tests prove model and view logic; they do not prove the rendered experience.
- **Simulator-visible behavior:** not certified in this pass. The dedicated Air simulator was booted and retained without resetting its data, but a system “Open in Pitch Atlas?” confirmation sheet obscured the attempted screenshots. A temporary UI-test harness then stalled behind concurrent Xcode work. The same commit was built in an isolated Pro QA checkout, but that simulator remained at `Waiting on BackBoard`; direct install and UI-test launch did not complete. Contaminated screenshots were discarded rather than presented as proof.
- **Physical-device behavior:** `xcrun devicectl list devices` found a paired, available iPhone 16 (`iPhone17,3`). The app was not installed or run on it during this pass. There is therefore no device-visible, VoiceOver-completed, thermal, or frame-rate evidence, and no claim of iPhone 13-class performance.
- **Offline behavior:** the study and comparison inputs remain bundled and their implementation makes no new runtime network request. First-launch airplane-mode behavior was not completed on simulator or device, so offline support remains source-backed rather than player-visible evidence.
- **Deep links:** valid, invalid, duplicate-key, duplicate-pitch, and missing/unfiled cases are covered by the green automated suite. Simulator confirmation of the invalid-link error was attempted but is not claimed because the UI harness did not finish.
- **Accessibility:** source inspection confirms scalable native text and controls, descriptive schematic labels, explicit selection states, Reduce Motion reuse, and Reduce Transparency handling. Dynamic Type screenshots, VoiceOver task completion, and simulator preference runs remain open because no clean runtime capture completed.

Archive preparation reached `.build/ArchiveWithinReach-unsigned.xcarchive` on the Air (about 54 MB). Its `Products/Applications/PitchAtlas.app` exists and `codesign -dv` reports that it is not signed. This is useful compile/package evidence only; it is not exportable for TestFlight. The signed Air archive attempt failed in the SSH session with `CodeSign ... errSecInternalComponent`. The Pro has the generated development-team setting but `security find-identity -v -p codesigning` reports zero valid signing identities, so it cannot replace the Air signing step. No export, upload, App Store Connect change, or release/account change was made.

Before TestFlight, finish these gates on a healthy simulator/device session: capture normal and accessibility text-size study/compare screens including top, side, and thumb orientations; complete the compare flow with VoiceOver plus Reduce Motion and Reduce Transparency; verify valid and invalid links; perform first-launch airplane-mode testing; run on the paired iPhone; then unlock the signing identity in an interactive Air session, create a signed archive, validate/export it, and inspect the exported IPA before upload.
