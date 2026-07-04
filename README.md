# Pitch Atlas — iOS

A native iPhone reference for how pitches are gripped and thrown. Standalone product; the companion app to [pitch-atlas.com](https://pitch-atlas.com).

**Sourced, not corrected.** Nothing here is marked right or wrong. Every claim is labeled by where it came from and how confident the source is. The reader judges; the atlas only sources.

## What v1 is

A reference manual you can hold — offline, brand-true, tactile:

- The **pitch index** — every pitch a coach, a pitcher, or the tracking taxonomy would call a pitch, honestly labeled (standard / niche / rare / alias / illusion / not-a-pitch / banned).
- **Filed specimens** — native SwiftUI seam specimens with spin-axis orientation, sourced break indicators, and a CoreMotion foil rake.
- The **Grip Library** — first-party grip photography and a pitcher's own first-person account, tagged "not tracked data."
- The **Craftsmen** hall and the **Lost Pitches** wing.
- A full **Sources** screen — every number wears its confidence tier.

No login. Free. iPhone first. The community/Field-Notes layer is a deliberate **v2** (see `docs/COMPLIANCE.md`).

## Architecture (one line)

Native SwiftUI app that renders the v1 experience fully natively: tab shell, searchable index, grip library, craftsmen hall, sources browser, and the seam specimen. The planned v1.1 Three.js island is kept out of the first binary so App Review sees an offline app, not a wrapped website.

## Build

```bash
xcodegen generate          # project.yml -> PitchAtlas.xcodeproj (generated, gitignored)
./scripts/build.sh         # xcodebuild for the iPhone simulator
```

Content is generated from the web repo, not hand-maintained:

```bash
cd tools/generate-content && npm install && npm run generate
# reads ../../../Pitch-Atlas/src/data -> PitchAtlas/Resources/Content/*.json
```

## Repo layout

```
PitchAtlas/
  App/         @main entry, 5-tab shell, deep-link routing
  Core/
    Data/      Codable models (mirror the web types.ts) + PitchStore
    Theme/     PitchAtlasTheme (void-tuned tokens, foil/gold, fonts) + spacing
    DeepLink/  pitchatlas:// routing
    Config/    feature flags
  Features/    Atlas / Index / PitchDetail / Grips / Craftsmen / LostPitches / Learn / Sources / About
  Resources/   generated Content/*.json, grips/*.webp, Fonts/
tools/generate-content/   the web-data -> bundled-JSON generator
docs/          COMPLIANCE.md, APP-REVIEW-NOTES.md
scripts/       build / ship helpers
```

## Source of truth

The content source of truth is the **web repo** (`ahump20/Pitch-Atlas`, locally `~/code/Pitch-Atlas`). The iOS app never maintains a parallel content system — it generates bundled JSON from the web `src/data` at build time, with a schema-drift guard that fails the build if the two diverge. This keeps "Sourced, not corrected" honest across both surfaces.
