# Pitch Atlas iOS

Native iPhone app for the craft of pitching. Standalone product, separate from Blaze Sports Intel, and companion to [pitch-atlas.com](https://pitch-atlas.com).

**Sourced, not corrected.** Claims carry source/confidence context. Community posts are firsthand notes, not measured proof.

## What v1 is

- A bundled pitch/grip reference manual that stays usable while logged out.
- Native SwiftUI screens for Atlas, Index, Grips, Craftsmen, Sources, About, Account/Safety, pitch details, and community panels.
- Supabase-backed community/auth using the existing Pitch Atlas project `cloeoulvrrfcbitrjpso`.
- Account-gated field notes, discussion posts, reports, blocks, image uploads, and account deletion.
- Image-only upload from PhotosPicker. No video upload. No live camera capture. No push notifications.
- No Firebase, Appwrite, CloudKit, or BSI backend.

The Supabase migration source of truth remains the web/backend repo: `ahump20/Pitch-Atlas`. iOS consumes that backend; it does not own duplicate migrations.

## Build

```bash
xcodegen generate
./scripts/build.sh build
./scripts/build.sh test
```

`PitchAtlas.xcodeproj` is generated from `project.yml` and is not hand-edited.

## Source Of Truth

The bundled reference content is generated from the Pitch Atlas web repo and committed into `PitchAtlas/Resources/Content/*.json`. The live community layer is Supabase:

- URL: `https://cloeoulvrrfcbitrjpso.supabase.co`
- iOS bundle ID: `com.pitchatlas.app`
- App URL scheme: `pitchatlas://`
- Privacy/support URLs: `https://pitch-atlas.com/privacy` and `https://pitch-atlas.com/support`

## Release Blockers

- Verify the live Supabase project health, community RPCs, blocked-content behavior, media upload/readback, and `delete-account` before TestFlight.
- Recheck Supabase branch/migration health from `ahump20/Pitch-Atlas`. Prior release notes recorded `MIGRATIONS_FAILED`; repair it if the live console still reports that.
- Verify Apple Developer/App Store Connect for `com.pitchatlas.app`: Sign in with Apple, signing, Xcode Cloud release workflow, screenshots, privacy labels, age rating, reviewer notes, and the highest processed build.
