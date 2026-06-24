# Pitch Atlas iOS — Fable 5 Return Wave

Date: 2026-06-24
Branch: `fable5/return-wave-prep`

This is the native companion to the web playbook in `ahump20/Pitch-Atlas/docs/fable5/RETURN-WAVE.md`.

## Current app state

Repo read from `main` on 2026-06-24:

- Bundle ID: `com.pitchatlas.app`
- Team: `CQNJJ423X3`
- iOS minimum: `17.0`
- Device family: iPhone only
- `MARKETING_VERSION`: `1.0.1`
- `CURRENT_PROJECT_VERSION`: `5`
- `docs/APP-STORE-CONNECT.md`: version `1.0.1` / build `5` selected for review and `WAITING_FOR_REVIEW`

Do not regress docs back to stale `1.0.0 build 3` language unless App Store Connect proves that train is active again.

## Native card-port target

Port the elevated web card language after the web visuals stabilize:

1. machined chrome/gold nameplate
2. dark foil with device-motion rake, reduced-motion honored
3. movement wheel on card back
4. chip row: family / source tier / edition
5. sunburst/depth behind seam-ball window where applicable

## New scaffold

`PitchAtlas/Components/ScoutMovementWheel.swift` is present on this branch.

It is intentionally not wired yet. Wire it after the web card back is final so the app ports the settled language instead of chasing churn.

## Primary files

- `PitchAtlas/Components/ContentCards.swift`
- `PitchAtlas/Components/CardBackPanel.swift`
- `PitchAtlas/Components/ScoutMovementWheel.swift`
- `PitchAtlas/Core/Motion/MotionProvider.swift`
- `PitchAtlas/Resources/PrivacyInfo.xcprivacy`
- `docs/APP-STORE-CONNECT.md`
- `docs/APP-REVIEW-NOTES.md` if present or created

## Acceptance

- `xcodegen generate` succeeds.
- `./scripts/build.sh test` succeeds.
- Device motion is used only for the foil effect and remains disabled under Reduce Motion.
- No fabricated pitch numbers appear anywhere in the card port.
- Source/confidence language stays visible on card backs.
- Screenshot set is refreshed after card port, not before.

## Screenshot set

Use 6.9-inch iPhone captures unless App Store Connect asks for another required size.

1. Atlas home
2. Pitch Index
3. Pitch detail
4. Grip Library
5. Sources
6. Account/community safety

## Account-gated / Austin-gated

Do not fake or invent:

- reviewer test account
- App Store Connect state
- TestFlight install proof
- production Supabase mutation proof

If not verified from account/API/device, state it as pending.
