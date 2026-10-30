# iOS Web Parity — Plan 1: Foundation (content, tokens, theme, type)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Regenerate the app's content from web main, generate every design token (colors, tiers, accents, foils, motion, radii) from the web source into Swift, bundle the web's exact 14 font faces, and move the theme onto those generated values, so no color in the app is hand-written and drift fails CI.

**Architecture:** `tools/generate-content` already turns web `src/data` into bundled JSON. It gains a token module that reads the web's browser-resolved `.design-sync/artifact/tokens.json`, the foil/ember stops and throwback card foils in `src/index.css`, and the accent/tier/status maps in `src/components`, then writes `Resources/Content/design-tokens.json` and `PitchAtlas/Core/Theme/Generated/WebTokens.swift` from one in-memory object. The hand-written theme (`PitchAtlasTheme`, `PitchAccents`, `PitchAtlasMaterials`, `PitchAtlasMotion`, `PitchAtlasType`) only names roles and points at `WebTokens`. A CI script fails on any drift (including new files) and on any color literal outside `Core/Theme/`.

**Tech Stack:** Swift 5 / SwiftUI (iOS 17.0 floor), XcodeGen, XCTest; Node 22 + tsx for the generator; Python fontTools (+brotli) for the one-time font import.

**Spec:** `docs/superpowers/specs/2026-10-05-ios-web-parity-design.md`

## Global Constraints

- iOS 17.0 deployment floor. No MeshGradient, ScrollPosition struct, onScrollGeometryChange, onScrollVisibilityChange, onScrollPhaseChange, two-argument onGeometryChange, `Tab`, navigationTransition.
- Web source of truth: `ahump20/Pitch-Atlas` @ `main` (`3f518f6`), passed to the generator as `PITCH_ATLAS_WEB=<fresh clone>`. Never generate from `~/Pitch-Atlas` (stale, dirty).
- Content JSON and color values are generated, never hand-written. Swift reads colors only through `WebTokens` (generated) via the theme.
- No color literal (`Color(hex:`, `Color(red:`, `Color(white:`, `UIColor(red:`, `UIColor(white:`, `#colorLiteral`) outside `PitchAtlas/Core/Theme/`.
- The app builds and `./scripts/build.sh test` passes after every commit.
- Commit messages: `type(scope): description`, ending with the session attribution lines.
- Never print or commit secrets. The untracked `grips.zip` and `SurfaceSnapshots.swift` live only in the original checkout and never enter this worktree.

## Review Focus

1. A web token that is a reference (`{color-ink-2}`), a 3-digit hex (`#fff`), or an 8-digit hex with alpha (`#d8d1c029`) must resolve to the right RGB *and* alpha; an unresolvable reference must fail generation loudly, not emit a default. (Task 5 test: `testPaletteResolvesReferencesAndAlpha`.)
2. An unknown confidence string in a future bundle must still render a colored dot, a glyph and a label (fallback = unverified), never an empty label. (Task 8 test: `testUnknownConfidenceFallsBackToUnverifiedEverywhere`.)
3. CSS gradient stops with fractional percentages (`24.5%`) and both `#rrggbb` and `rgba()` forms must parse in order with exact locations. (Task 5 test: `testThrowbackFoilStopsParseFractionalLocations`.)
4. One missing or corrupt new bundle (softball, quotes, …) must not take down the store: the other collections still load and `status` names the file. (Task 4 test: `testStoreToleratesAMissingOptionalBundle`.)
5. Custom fonts must scale with Dynamic Type and every bundled face must resolve by PostScript name; a missing face is a test failure, not a silent system-font fallback. (Task 11 test: `testEveryWebFontFaceResolves`.)

---

### Task 1: The drift check sees new files

**Files:**
- Create: `scripts/check-generated-drift.sh`
- Modify: `.github/workflows/ios.yml` (content-drift job, last step)

**Interfaces:**
- Produces: `scripts/check-generated-drift.sh` — exits 0 when `PitchAtlas/Resources/Content`, `PitchAtlas/Core/Theme/Generated` and the two generated color sets are clean in `git status --porcelain`; exits 1 and lists paths otherwise. Later tasks add paths only by editing the `paths` array.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Fails when anything the generator owns differs from what is committed —
# including brand-new files, which `git diff --quiet` cannot see.
set -euo pipefail
cd "$(dirname "$0")/.."
paths=(
  PitchAtlas/Resources/Content
  PitchAtlas/Core/Theme/Generated
  PitchAtlas/Resources/Assets.xcassets/AccentColor.colorset
  PitchAtlas/Resources/Assets.xcassets/LaunchBackground.colorset
)
drift="$(git status --porcelain -- "${paths[@]}")"
if [ -n "$drift" ]; then
  echo "::error::generated files are stale - a web change was not regenerated into the app."
  echo "Fix: cd tools/generate-content && PITCH_ATLAS_WEB=/path/to/Pitch-Atlas npm run generate  (then commit the result)."
  echo "$drift"
  git --no-pager diff --stat -- "${paths[@]}" || true
  exit 1
fi
echo "✓ generated files match web source"
```

- [ ] **Step 2: Prove it catches a new file**

Run: `chmod +x scripts/check-generated-drift.sh && ./scripts/check-generated-drift.sh; touch PitchAtlas/Resources/Content/zz-probe.json; ./scripts/check-generated-drift.sh; echo "exit=$?"; rm PitchAtlas/Resources/Content/zz-probe.json; ./scripts/check-generated-drift.sh`
Expected: first run `✓ generated files match web source`; second run prints `?? PitchAtlas/Resources/Content/zz-probe.json` and `exit=1`; third run `✓`.

- [ ] **Step 3: Point CI at the script**

Replace the `run:` body of the step "Fail on any drift vs the committed bundle" with `./scripts/check-generated-drift.sh`, and rename the step "Fail on any drift vs the committed generated files".

- [ ] **Step 4: Run the suite and commit**

Run: `./scripts/build.sh test` → Expected: `Executed 83 tests, with 0 failures`.
```bash
git add scripts/check-generated-drift.sh .github/workflows/ios.yml
git commit -m "ci(content): catch new generated files in the drift check"
```

---

### Task 2: Regenerate content from web main

**Files:**
- Modify: `PitchAtlasTests/PitchAtlasTests.swift` (new test after `testSpecimenGradeTravelsAndOnlyTheChaseIsGold`)
- Regenerate: `PitchAtlas/Resources/Content/*.json`

**Interfaces:**
- Consumes: web clone at `$WEB` (`/private/tmp/claude-501/-Users-AustinHumphrey-Pitch-Atlas-iOS/da536c3a-9916-4072-8673-4a0c8426f6d1/scratchpad/web-main`, commit `3f518f6`).

- [ ] **Step 1: Write the failing test**

```swift
    /// The four-seam is the one 1-of-1, and since 2026-09-23 the web calls it
    /// Ember (the key keeps its historical `gold` name). Read straight off the
    /// generated bundle, so a stale bundle fails here.
    func testFourSeamWearsTheEmberOneOfOne() {
        let store = PitchStore()
        let chase = store.pitches.first { $0.display.specimenNo == "00" }
        XCTAssertEqual(chase?.display.slug, "four-seam")
        XCTAssertEqual(chase?.specimenGrade.key, .gold)
        XCTAssertEqual(chase?.specimenGrade.label, "Ember · 1 of 1")
    }
```

- [ ] **Step 2: Run it and watch it fail**

Run: `./scripts/build.sh test 2>&1 | grep -E "testFourSeamWearsTheEmberOneOfOne|Executed"`
Expected: FAIL — `("Optional("Gold · 1 of 1")") is not equal to ("Optional("Ember · 1 of 1")")`.

- [ ] **Step 3: Regenerate**

Run: `cd tools/generate-content && PITCH_ATLAS_WEB=$WEB npm run generate`
Expected: `sources.json` reports 299 records; `✓ wrote 10 files`.

- [ ] **Step 4: Run the suite**

Run: `./scripts/build.sh test`
Expected: `Executed 84 tests, with 0 failures`. If a decode test fails, the web added a field shape the models reject: fix the model (never the JSON) and note it in the ledger.

- [ ] **Step 5: Commit**

```bash
git add PitchAtlas/Resources/Content PitchAtlasTests/PitchAtlasTests.swift
git commit -m "chore(content): regenerate the bundle from web main (ember 1 of 1, 299 sources)"
```

---

### Task 3: Learn wings carry `boundaryOnly`

**Files:**
- Modify: `PitchAtlas/Core/Data/ContentModels.swift` (`KnowledgeWing`)
- Test: `PitchAtlasTests/PitchAtlasTests.swift`

**Interfaces:**
- Produces: `KnowledgeWing.boundaryOnly: Bool?` and `KnowledgeWing.allowsDiscussion: Bool` (`boundaryOnly != true`), consumed by Plan 5's `CommunityTopic.learn`.

- [ ] **Step 1: Write the failing test** (reads the raw JSON so nothing is hardcoded)

```swift
    /// Arm-health and youth wings are boundary-only on the web: no discussion
    /// thread. The flag must survive decoding, matched against the raw bundle.
    func testBoundaryOnlyWingsDecodeFromTheBundle() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "knowledge", withExtension: "json"))
        let raw = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [[String: Any]])
        let expected = Set(raw.filter { ($0["boundaryOnly"] as? Bool) == true }.compactMap { $0["slug"] as? String })
        XCTAssertFalse(expected.isEmpty, "the bundle should carry at least one boundary-only wing")
        let store = PitchStore()
        let decoded = Set(store.knowledge.filter { $0.boundaryOnly == true }.map(\.slug))
        XCTAssertEqual(decoded, expected)
        for wing in store.knowledge { XCTAssertEqual(wing.allowsDiscussion, !expected.contains(wing.slug)) }
    }
```

- [ ] **Step 2: Run it** → Expected: compile error `value of type 'KnowledgeWing' has no member 'boundaryOnly'`.

- [ ] **Step 3: Implement**

In `KnowledgeWing` add after `related`:
```swift
    /// Web `KnowledgeWing.boundaryOnly`: an education-only wing (arm health,
    /// youth) that opens no discussion thread.
    let boundaryOnly: Bool?
    var allowsDiscussion: Bool { boundaryOnly != true }
```

- [ ] **Step 4: Run the suite** → Expected: `Executed 85 tests, with 0 failures`.

- [ ] **Step 5: Commit**

```bash
git add PitchAtlas/Core/Data/ContentModels.swift PitchAtlasTests/PitchAtlasTests.swift
git commit -m "feat(content): decode boundary-only Learn wings"
```

---

### Task 4: Bundle softball, tidbits, quotes, media and plate 273

**Files:**
- Modify: `tools/generate-content/generate.ts`
- Create: `PitchAtlas/Core/Data/WingModels.swift` (softball, tidbits, quotes, external media, craftsman media, plate 273)
- Modify: `PitchAtlas/Core/Data/PitchStore.swift`, `PitchAtlas/Core/Data/ContentModels.swift` (`ContentManifest.contentHash`)
- Test: `PitchAtlasTests/WingBundleTests.swift`

**Interfaces:**
- Produces (Swift): `PitchStore.softball: SoftballBundle`, `.tidbits: [Tidbit]`, `.quotes: [AtlasQuote]`, `.externalMedia: ExternalMediaBundle`, `.craftsmanMedia: [CraftsmanMediaItem]`, `.plate273: Plate273?`; lookups `softballPitch(slug:)`, `softballCraftsman(slug:)`, `tidbit(id:)`, `craftsmanMedia(forCraftsman:)`, `externalItems(forPitch:)`.
- Produces (bundle): `softball.json`, `tidbits.json`, `quotes.json`, `external-media.json`, `craftsman-media.json`, `plate-273.json`; manifest counts keys `softball.pitches`, `softball.craftsmen`, `tidbits.json`, `quotes.json`, `external-media.items`, `craftsman-media.json`, `plate-273.frames`.

- [ ] **Step 1: Write the failing tests** (`PitchAtlasTests/WingBundleTests.swift`)

```swift
import XCTest
@testable import PitchAtlas

final class WingBundleTests: XCTestCase {
    func testWingBundlesDecodeAndMatchManifest() {
        let store = PitchStore()
        if case .failed(let message) = store.status { XCTFail("decode failed: \(message)") }
        let counts = store.manifest.counts
        XCTAssertEqual(store.softball.pitches.count, counts["softball.pitches"])
        XCTAssertEqual(store.softball.craftsmen.count, counts["softball.craftsmen"])
        XCTAssertEqual(store.tidbits.count, counts["tidbits.json"])
        XCTAssertEqual(store.quotes.count, counts["quotes.json"])
        XCTAssertEqual(store.externalMedia.items.count, counts["external-media.items"])
        XCTAssertEqual(store.craftsmanMedia.count, counts["craftsman-media.json"])
        XCTAssertEqual(store.plate273?.frames.count, counts["plate-273.frames"])
        XCTAssertFalse(store.softball.pitches.isEmpty)
        XCTAssertFalse(store.tidbits.isEmpty)
    }

    func testEveryWingClaimCarriesASource() {
        let store = PitchStore()
        let claims = store.softball.pitches.flatMap { [$0.grip, $0.spin, $0.movement] }
            + store.softball.windmillPhases.map(\.what)
            + store.tidbits.map(\.claim)
            + store.quotes.map(\.claim)
        XCTAssertFalse(claims.isEmpty)
        for claim in claims { XCTAssertNotNil(claim.source, "unsourced claim: \(claim.value.prefix(60))") }
    }

    func testPlateFramesAreClosedStraightLineOutlines() throws {
        let plate = try XCTUnwrap(PitchStore().plate273)
        XCTAssertEqual(plate.rights, "public-domain")
        XCTAssertEqual(plate.frames.count, plate.frameCount)
        for frame in plate.frames {
            XCTAssertEqual(frame.viewBox.count, 4)
            XCTAssertFalse(frame.subpaths.isEmpty)
            for sub in frame.subpaths { XCTAssertGreaterThanOrEqual(sub.count, 3); sub.forEach { XCTAssertEqual($0.count, 2) } }
        }
    }

    func testOutboundOnlyMediaIsNeverEmbedded() {
        for item in PitchStore().externalMedia.items where item.platform == "x" {
            XCTAssertNotNil(URL(string: item.canonicalUrl), "\(item.id) has no outbound URL")
        }
    }

    func testStoreToleratesAMissingOptionalBundle() throws {
        // A bundle with only the core files: the wing collections fall back empty
        // and status names the missing file; the core collections still load.
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        for name in ["manifest", "pitches", "repertoire", "craftsmen", "lost-pitches", "knowledge", "grips",
                     "sources", "archive-images", "teaching-clips"] {
            let url = try XCTUnwrap(Bundle.main.url(forResource: name, withExtension: "json"))
            try FileManager.default.copyItem(at: url, to: temp.appendingPathComponent("\(name).json"))
        }
        let bundle = try XCTUnwrap(Bundle(path: temp.path))
        let store = PitchStore(bundle: bundle)
        XCTAssertFalse(store.pitches.isEmpty)
        XCTAssertTrue(store.softball.pitches.isEmpty)
        guard case .failed(let message) = store.status else { return XCTFail("missing softball.json should be reported") }
        XCTAssertTrue(message.contains("softball.json"))
    }
}
```

- [ ] **Step 2: Run** → Expected: compile errors (`PitchStore` has no member `softball`, …).

- [ ] **Step 3: Generator**

In `generate.ts`, extend the `Promise.all` import list with
`imp('softball/index.ts'), imp('softball/fundamentals.ts'), imp('tidbits/index.ts'), imp('quotes/index.ts'), imp('media/external.ts'), imp('media/craftsmen.ts'), imp('media/plate273.ts')`
bound to `softball, softballFund, tidbits, quotes, external, craftsmanMedia, plate273`. Add the plate parser and the bundles:

```ts
import { readFile } from 'node:fs/promises'
import { createHash } from 'node:crypto'

/*
  Plate 273 ships as ten traced outlines (public domain). Only straight-line
  path commands occur (M/L/Z), so each frame becomes numeric subpaths the app
  draws with Path — the outline is generated from the web file, never redrawn.
*/
async function plateFrames(svgPath: string) {
  const svg = await readFile(svgPath, 'utf8')
  const frames = [...svg.matchAll(/<symbol id="(f\d+)" viewBox="([^"]+)">\s*<path[^>]* d="([^"]+)"/g)]
  if (frames.length === 0) throw new Error(`no frames in ${svgPath}`)
  return frames.map(([, id, viewBox, d]) => {
    if (/[^MLZ0-9.\-\s]/.test(d)) throw new Error(`${id}: unexpected path command`)
    const subpaths = d.split('Z').map((s) => s.trim()).filter(Boolean).map((sub) =>
      [...sub.matchAll(/[ML]\s*(-?\d+(?:\.\d+)?)\s*(-?\d+(?:\.\d+)?)/g)].map((m) => [Number(m[1]), Number(m[2])]))
    return { id, viewBox: viewBox.split(/\s+/).map(Number), subpaths }
  })
}

const plate = plate273.PLATE_273
const plateFile = join(WEB, 'public', plate.src.replace(/^\//, ''))
const plateBundle = {
  viewBox: plate.viewBox, frameCount: plate.frames, plate: plate.plate, title: plate.title,
  maker: plate.maker, work: plate.work, year: plate.year, rights: plate.rights, source: plate.source,
  frames: await plateFrames(plateFile),
}
```

Add to `bundles`:
```ts
  'softball.json': {
    fastpitchCopy: softballFund.SOFTBALL_FASTPITCH_COPY,
    hubFastpitchBlurb: softballFund.SOFTBALL_HUB_FASTPITCH_BLURB,
    pitches: softball.SOFTBALL_PITCHES,
    craftsmen: softball.SOFTBALL_CRAFTSMEN,
    windmillPhases: softball.WINDMILL_PHASES,
    fundamentalBlocks: softball.FUNDAMENTAL_BLOCKS,
    slowpitchNotes: softball.SLOWPITCH_NOTES,
    slowpitchCraft: softball.SLOWPITCH_CRAFT,
    slowpitchFormats: softball.SLOWPITCH_FORMATS,
  },
  'tidbits.json': tidbits.TIDBITS,
  // The rotating pool the web UI reads: curated lines plus every craftsman quote.
  'quotes.json': quotes.quotePool(),
  // Embed-or-link: TikTok rows play in the official player; X rows link out.
  'external-media.json': { sources: external.EXTERNAL_SOURCES, items: external.EXTERNAL_CONTENT_ITEMS },
  'craftsman-media.json': craftsmanMedia.allCraftsmanMedia(),
  'plate-273.json': plateBundle,
```

Replace `counts[file] = countOf(data)` with explicit counts for object-shaped bundles:
```ts
const explicitCounts: Record<string, Record<string, number>> = {
  'softball.json': { 'softball.pitches': softball.SOFTBALL_PITCHES.length, 'softball.craftsmen': softball.SOFTBALL_CRAFTSMEN.length },
  'external-media.json': { 'external-media.items': external.EXTERNAL_CONTENT_ITEMS.length },
  'plate-273.json': { 'plate-273.frames': plateBundle.frames.length },
}
// inside the loop:
  if (explicitCounts[file]) Object.assign(counts, explicitCounts[file])
  else counts[file] = countOf(data)
```

Stamp the manifest with a content hash over every written bundle (sorted name + bytes), so the stamp changes exactly when shipped content changes and needs no clock:
```ts
const hash = createHash('sha256')
for (const file of Object.keys(bundles).sort()) hash.update(file).update(await readFile(join(OUT, file)))
// manifest: { counts, sourcesLastChecked, contentHash: hash.digest('hex') }
```

If a craftsman-media row carries a baked third-party post body (the `x-rivera` row's tweet JSON), drop that field at the boundary — X rows ship as credited outbound links only.

- [ ] **Step 4: Swift models** (`PitchAtlas/Core/Data/WingModels.swift`)

```swift
import Foundation

// =============================================================================
// Wing bundles — softball, tidbits, quotes, media, plate 273
// =============================================================================
// Generated from web src/data by tools/generate-content. Enum-like strings stay
// String so a new web value can never brick the decode; every figure is a Claim.
// =============================================================================

struct SoftballCopy: Codable, Hashable {
    let description: String
    let heroSub: String
    let phaseLede: String
}

struct SoftballPitch: Codable, Hashable, Identifiable {
    let slug: String
    let name: String
    let family: String
    let specimenNo: String
    let status: String
    let tagline: String
    let intro: String
    let grip: Claim
    let spin: Claim
    let movement: Claim
    let role: String
    let physicsNote: Claim?
    let openQuestion: String?
    let notableThrowers: String?
    let flagship: Bool?
    var id: String { slug }
}

struct WindmillPhase: Codable, Hashable, Identifiable {
    let num: String
    let name: String
    let what: Claim
    var id: String { num }
}

struct FundamentalBlock: Codable, Hashable, Identifiable {
    let id: String
    let index: String
    let label: String
    let lede: String
    let claims: [Claim]
    let educational: Bool?
}

struct SlowpitchNote: Codable, Hashable {
    let label: String
    let claim: Claim
}

struct SoftballBundle: Codable, Hashable {
    let fastpitchCopy: SoftballCopy
    let hubFastpitchBlurb: String
    let pitches: [SoftballPitch]
    let craftsmen: [Craftsman]
    let windmillPhases: [WindmillPhase]
    let fundamentalBlocks: [FundamentalBlock]
    let slowpitchNotes: [SlowpitchNote]
    let slowpitchCraft: [String]
    let slowpitchFormats: [String]

    static let empty = SoftballBundle(
        fastpitchCopy: SoftballCopy(description: "", heroSub: "", phaseLede: ""), hubFastpitchBlurb: "",
        pitches: [], craftsmen: [], windmillPhases: [], fundamentalBlocks: [], slowpitchNotes: [],
        slowpitchCraft: [], slowpitchFormats: [])
}

/// A hidden note: one real, sourced fact filed at a named place in the archive.
struct Tidbit: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let claim: Claim
    let eggLocation: String
}

struct AtlasQuote: Codable, Hashable, Identifiable {
    let id: String
    let attribution: String
    let context: String?
    let claim: Claim
}

struct ExternalSource: Codable, Hashable, Identifiable {
    let id: String
    let platform: String
    let name: String
    let handle: String
    let canonicalUrl: String
    let trustLane: String
    let ingestMethod: String
    let autoPublish: Bool
    let active: Bool
}

struct ExternalContentTags: Codable, Hashable {
    let pitchSlugs: [String]
    let craftsmanSlugs: [String]
    let families: [String]
    let topics: [String]
}

struct ExternalContentItem: Codable, Hashable, Identifiable {
    let id: String
    let platform: String
    let externalId: String
    let canonicalUrl: String
    let sourceId: String
    let sourceName: String
    let sourceHandle: String
    let sourceUrl: String
    let title: String
    let lede: String
    let sourceCaption: String?
    let publishedAt: String
    let retrievedAt: String
    let tags: ExternalContentTags
    let trustLane: String
    let moderationState: String
    let availability: String
    let embedMode: String
    let featured: Bool?
    /// Published and not removed — the same gate as the web's externalContentFor.
    var isShowable: Bool { moderationState == "published" && availability != "removed" }
}

struct ExternalMediaBundle: Codable, Hashable {
    let sources: [ExternalSource]
    let items: [ExternalContentItem]
    static let empty = ExternalMediaBundle(sources: [], items: [])
}

struct CraftsmanMediaItem: Codable, Hashable, Identifiable {
    let kind: String
    let id: String
    let title: String
    let lede: String
    let author: String
    let authorUrl: String
    let url: String
    let retrievedAt: String
    let craftsmanSlug: String
    let craftsmanName: String
    let clip: TeachingClip?
}

struct Plate273Frame: Codable, Hashable, Identifiable {
    let id: String
    /// [minX, minY, width, height] of the frame's own box.
    let viewBox: [Double]
    /// Closed straight-line outlines, each an array of [x, y] points (even-odd fill).
    let subpaths: [[[Double]]]
}

struct Plate273: Codable, Hashable {
    let viewBox: String
    let frameCount: Int
    let plate: Int
    let title: String
    let maker: String
    let work: String
    let year: Int
    let rights: String
    let source: Source
    let frames: [Plate273Frame]
}
```

In `ContentManifest` add `let contentHash: String?`. In `PitchStore` add the six stored properties and load them after `teachingClips`:
```swift
        self.softball = load("softball", SoftballBundle.self, fallback: .empty)
        self.tidbits = load("tidbits", [Tidbit].self, fallback: [])
        self.quotes = load("quotes", [AtlasQuote].self, fallback: [])
        self.externalMedia = load("external-media", ExternalMediaBundle.self, fallback: .empty)
        self.craftsmanMedia = load("craftsman-media", [CraftsmanMediaItem].self, fallback: [])
        self.plate273 = load("plate-273", Plate273?.self, fallback: nil)
```
and the lookups:
```swift
    func softballPitch(slug: String) -> SoftballPitch? { softball.pitches.first { $0.slug == slug } }
    func softballCraftsman(slug: String) -> Craftsman? { softball.craftsmen.first { $0.slug == slug } }
    func tidbit(id: String) -> Tidbit? { tidbits.first { $0.id == id } }
    func craftsmanMedia(forCraftsman slug: String) -> [CraftsmanMediaItem] { craftsmanMedia.filter { $0.craftsmanSlug == slug } }
    func externalItems(forPitch slug: String) -> [ExternalContentItem] {
        externalMedia.items.filter { $0.isShowable && $0.tags.pitchSlugs.contains(slug) }
    }
```
The missing-file message must read `"<name>.json — …"` (it already does via `load`).

- [ ] **Step 5: Generate, run, verify**

Run: `cd tools/generate-content && PITCH_ATLAS_WEB=$WEB npm run generate && cd ../.. && ./scripts/build.sh test`
Expected: generator lists the six new files; `Executed 90 tests, with 0 failures`.

- [ ] **Step 6: Commit**

```bash
git add tools/generate-content/generate.ts PitchAtlas/Core/Data PitchAtlas/Resources/Content PitchAtlasTests/WingBundleTests.swift
git commit -m "feat(content): bundle softball, hidden notes, quotes, media and plate 273 from web main"
```

---

### Task 5: Generate the design tokens

**Files:**
- Create: `tools/generate-content/tokens.ts`
- Modify: `tools/generate-content/generate.ts` (call `writeTokens`), `tools/generate-content/tsconfig.json` (`include` adds `tokens.ts`)
- Create (generated): `PitchAtlas/Resources/Content/design-tokens.json`, `PitchAtlas/Core/Theme/Generated/WebTokens.swift`, both color sets' `Contents.json`
- Create: `PitchAtlas/Core/Theme/WebTokenTypes.swift`
- Test: `PitchAtlasTests/DesignTokenParityTests.swift`

**Interfaces:**
- Produces (Swift, hand-written types): `struct WebColor: Hashable { let rgb: UInt32; let alpha: Double }`, `struct WebStop { let color: WebColor; let location: Double }`, `struct WebGradient { let angle: Double; let stops: [WebStop] }`, `struct WebAccent { let c1, c2, c3: UInt32; let finish: String? }`, `struct WebCardFinish { let foil: WebGradient; let ring: WebColor; let ringIn: WebColor }`, `extension Color { init(web: WebColor) }`, `extension UIColor { convenience init(web: WebColor) }`.
- Produces (generated): `WebTokens.Palette.<camelName>: WebColor` for every web color token plus `WebTokens.Palette.all: [String: WebColor]` keyed by the web token name; `WebTokens.Gradient.foil/foilType/ember`; `WebTokens.CardFinish.powder/teal`; `WebTokens.Tier.dot/ink/glyph/label/meaning/group: [String: …]` keyed by confidence raw value; `WebTokens.LostTier.color: [String: WebColor]`; `WebTokens.Status.indexColor: [String: WebColor]`, `WebTokens.Status.edge: Set<String>`, `WebTokens.Status.label: [String: String]`; `WebTokens.Family.accent: [String: UInt32]`; `WebTokens.Accent.byPitch: [String: WebAccent]`, `.fallback`, `.burnt`; `WebTokens.Motion.settle: [Double]` (4 control points), `.tinyMs/.shortMs/.mediumMs/.slowMs/.sweepMs: Double`; `WebTokens.Radius.sm/md/lg/pill: Double` (points); `WebTokens.Fonts.faces: [(family: String, weight: Int, italic: Bool)]`; `WebTokens.CreamInk.ink/ink2/ink3: WebColor`; `WebTokens.sourceRef: String`.

- [ ] **Step 1: Write the failing parity tests**

```swift
import XCTest
import SwiftUI
@testable import PitchAtlas

/// The generated Swift tokens and the generated JSON come from one object in the
/// generator; this pins that both committed files still agree (a hand edit to
/// either fails here), and that the alpha/reference resolution is right.
final class DesignTokenParityTests: XCTestCase {
    private func tokens() throws -> [String: Any] {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "design-tokens", withExtension: "json"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }
    private func color(_ any: Any?) -> WebColor? {
        guard let d = any as? [String: Any], let hex = d["hex"] as? String, let alpha = d["alpha"] as? Double,
              let rgb = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        return WebColor(rgb: rgb, alpha: alpha)
    }

    func testEveryPaletteTokenMatchesTheGeneratedSwift() throws {
        let palette = try XCTUnwrap(try tokens()["palette"] as? [String: Any])
        XCTAssertEqual(palette.count, WebTokens.Palette.all.count)
        for (name, value) in palette { XCTAssertEqual(WebTokens.Palette.all[name], color(value), name) }
    }

    func testPaletteResolvesReferencesAndAlpha() {
        XCTAssertEqual(WebTokens.Palette.all["color-void"], WebColor(rgb: 0x070509, alpha: 1))
        XCTAssertEqual(WebTokens.Palette.all["color-dim"], WebTokens.Palette.all["color-ink-2"], "{color-ink-2} reference")
        XCTAssertEqual(WebTokens.Palette.all["color-white"], WebColor(rgb: 0xFFFFFF, alpha: 1), "#fff short hex")
        let navyLine = WebTokens.Palette.all["color-navy-line"]
        XCTAssertEqual(navyLine?.rgb, 0xD8D1C0)
        XCTAssertEqual(navyLine?.alpha ?? 0, Double(0x29) / 255, accuracy: 0.0001)
    }

    func testTiersAreThreeColorsAcrossSevenLabels() throws {
        XCTAssertEqual(WebTokens.Tier.label.count, 7)
        XCTAssertEqual(Set(WebTokens.Tier.dot.values).count, 3)
        for raw in ClaimConfidence.allCases.map(\.rawValue) {
            XCTAssertNotNil(WebTokens.Tier.dot[raw], raw)
            XCTAssertNotNil(WebTokens.Tier.ink[raw], raw)
            XCTAssertFalse(WebTokens.Tier.glyph[raw, default: ""].isEmpty, raw)
            XCTAssertFalse(WebTokens.Tier.label[raw, default: ""].isEmpty, raw)
        }
        XCTAssertEqual(WebTokens.Tier.dot["official-data"]?.rgb, 0xBF5700)
        XCTAssertEqual(WebTokens.Tier.dot["community-firsthand"]?.rgb, 0x8FBAD6)
        XCTAssertEqual(WebTokens.Tier.dot["unverified"]?.rgb, 0xFF2D44)
        XCTAssertEqual(WebTokens.Tier.ink["reputable-analysis"]?.rgb, 0x3D6A8A)
    }

    func testGradientsMatchTheJSONAndTheCSSOrder() throws {
        let gradients = try XCTUnwrap(try tokens()["gradients"] as? [String: [String: Any]])
        let swift: [String: WebGradient] = ["foil": WebTokens.Gradient.foil, "foilType": WebTokens.Gradient.foilType,
                                            "ember": WebTokens.Gradient.ember]
        for (name, gradient) in swift {
            let json = try XCTUnwrap(gradients[name])
            XCTAssertEqual(json["angle"] as? Double, gradient.angle, name)
            let stops = try XCTUnwrap(json["stops"] as? [[String: Any]])
            XCTAssertEqual(stops.count, gradient.stops.count, name)
            XCTAssertEqual(gradient.stops.map(\.location), gradient.stops.map(\.location).sorted(), "\(name) out of order")
        }
        XCTAssertEqual(WebTokens.Gradient.foil.angle, 112)
        XCTAssertEqual(WebTokens.Gradient.foil.stops.count, 21)
        XCTAssertEqual(WebTokens.Gradient.ember.angle, 150)
        XCTAssertEqual(WebTokens.Gradient.ember.stops.first?.color.rgb, 0x2A1208)
    }

    func testThrowbackFoilStopsParseFractionalLocations() {
        let powder = WebTokens.CardFinish.powder
        XCTAssertTrue(powder.foil.stops.contains { abs($0.location - 0.245) < 0.0001 && $0.color.rgb == 0xFFF6F7 })
        XCTAssertEqual(powder.ring.rgb, 0xC41E3A)
        XCTAssertEqual(powder.ringIn.alpha, 0.34, accuracy: 0.0001)
        XCTAssertEqual(WebTokens.CardFinish.teal.ring.rgb, 0x00B2A9)
    }

    func testAccentTriadsCoverEverySpecimenAndSoftballPitch() {
        let store = PitchStore()
        for pitch in store.pitches { XCTAssertNotNil(WebTokens.Accent.byPitch[pitch.slug], pitch.slug) }
        for pitch in store.softball.pitches { XCTAssertNotNil(WebTokens.Accent.byPitch[pitch.slug], pitch.slug) }
        XCTAssertEqual(WebTokens.Accent.byPitch["twelve-six"]?.finish, "powder")
        XCTAssertEqual(WebTokens.Accent.byPitch["circle-change"]?.finish, "teal")
        XCTAssertEqual(WebTokens.Accent.burnt, 0xBF5700)
        XCTAssertEqual(WebTokens.Family.accent["breaking"], 0x5FE0EA)
    }

    func testMotionAndRadiusTokens() {
        XCTAssertEqual(WebTokens.Motion.settle, [0.22, 1, 0.36, 1])
        XCTAssertEqual([WebTokens.Motion.tinyMs, WebTokens.Motion.shortMs, WebTokens.Motion.mediumMs,
                        WebTokens.Motion.slowMs, WebTokens.Motion.sweepMs], [120, 190, 400, 700, 900])
        XCTAssertEqual(WebTokens.Radius.sm, 6)
        XCTAssertEqual(WebTokens.Radius.lg, 10)
    }

    func testColorSetsAreGeneratedFromTheTokens() throws {
        let accent = try XCTUnwrap(UIColor(named: "AccentColor"))
        let launch = try XCTUnwrap(UIColor(named: "LaunchBackground"))
        XCTAssertEqual(rgb(accent), WebTokens.Palette.all["color-cyan"]?.rgb)
        XCTAssertEqual(rgb(launch), WebTokens.Palette.all["color-void"]?.rgb)
    }

    private func rgb(_ color: UIColor) -> UInt32 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (UInt32((r * 255).rounded()) << 16) | (UInt32((g * 255).rounded()) << 8) | UInt32((b * 255).rounded())
    }
}
```

- [ ] **Step 2: Run** → Expected: compile errors (`cannot find 'WebTokens' in scope`).

- [ ] **Step 3: Hand-written token types** (`PitchAtlas/Core/Theme/WebTokenTypes.swift`)

```swift
import SwiftUI
import UIKit

// The value types the generated WebTokens.swift is written in. Hand-written so
// the generated file stays pure data.

struct WebColor: Hashable {
    let rgb: UInt32
    let alpha: Double
}

struct WebStop: Hashable {
    let color: WebColor
    let location: Double
}

/// A CSS `linear-gradient(<angle>deg, …)` — angle in CSS degrees (0 = to top,
/// 90 = to right), stops 0…1 in source order.
struct WebGradient: Hashable {
    let angle: Double
    let stops: [WebStop]
}

struct WebAccent: Hashable {
    let c1: UInt32
    let c2: UInt32
    let c3: UInt32
    let finish: String?
}

struct WebCardFinish: Hashable {
    let foil: WebGradient
    let ring: WebColor
    let ringIn: WebColor
}

extension Color {
    init(web: WebColor) {
        self.init(.sRGB,
                  red: Double((web.rgb >> 16) & 0xFF) / 255,
                  green: Double((web.rgb >> 8) & 0xFF) / 255,
                  blue: Double(web.rgb & 0xFF) / 255,
                  opacity: web.alpha)
    }
    init(rgb: UInt32) { self.init(web: WebColor(rgb: rgb, alpha: 1)) }
}

extension UIColor {
    convenience init(web: WebColor) {
        self.init(red: CGFloat((web.rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((web.rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(web.rgb & 0xFF) / 255,
                  alpha: web.alpha)
    }
}
```

- [ ] **Step 4: The token generator** (`tools/generate-content/tokens.ts`)

Implements, in this order, with every failure a thrown `Error` naming the token:
1. `readPalette(WEB)`: load `.design-sync/artifact/tokens.json`; for every `color.tokens[]` entry resolve `{name}` references recursively (cycle → throw), parse `#rgb`, `#rrggbb`, `#rrggbbaa` into `{hex: '#RRGGBB', alpha}` (alpha rounded to 4 places); a value that is not a hex after resolution → throw.
2. `cssGradient(css, varName)`: find `--<varName>: linear-gradient(<angle>deg,` and parse stops `<color> <pct>%` until `);` where color is `#hex` or `rgba(r,g,b,a)`; locations `pct/100`.
3. `cardFinish(css, cls)`: inside the `.rfx-card.<cls> {` block read `--card-foil`, `--card-ring`, `--card-ring-in`.
4. Imports through a second root `const COMP = join(WEB, 'src', 'components')`: `refractor/accents.ts` (`ACCENT`, `FALLBACK_ACCENT`, `BURNT`), `sections/family-accent.ts` (`FAMILY_ACCENT`), `provenance/refractorClaimMeta.ts` (`CONFIDENCE_COLOR`), `index/statusBadgeMeta.ts` (`SEAM_STATUSES`, `STATUS_LABEL`); `src/data/types.ts` (`CONFIDENCE_META`).
5. Text-only extraction (these files are TSX and import React, so they are read, never imported): the `GLYPH` record in `provenance/ConfidenceLabel.tsx`, the `CARD_INK` record in `refractor/specimenFace.tsx`, the `TIER_COLOR` record in `lost-pitches/EraTimeline.tsx`, and the `STATUS` record's `color` per key in `sections/PitchIndex.tsx`. Regex: `const NAME[^=]*=\s*{([\s\S]*?)\n}` then `'?([\w-]+)'?\s*:\s*(?:{\s*color:\s*)?'([^']+)'` per line. Every `var(--x)` value resolves through the palette (`--color-tier-first` → palette `color-tier-first`); unknown → throw.
6. Motion from `motion.tokens` (`pa-ease-settle` cubic-bezier → 4 numbers; `pa-motion-*` → ms), radius from `radius.tokens` (`rem × 16`, `999px` → 999), fonts from `type.fonts`.
7. Build one object `{ sourceRef, palette, gradients, cardFinish, tiers, lostTiers, status, family, accents, motion, radius, fonts }`, write it as `design-tokens.json` (2-space JSON + newline), and render `WebTokens.swift` from the same object: names camelCased from the web token name with the leading `color-` dropped (`color-paper-2` → `paper2`, `ctl-on-accent` → `ctlOnAccent`); a Swift keyword or duplicate name → throw. Every color literal is emitted as `WebColor(rgb: 0xRRGGBB, alpha: A)`; dictionaries sorted by key; header comment `// GENERATED by tools/generate-content/tokens.ts from ahump20/Pitch-Atlas — do not edit. Source: <sourceRef>`.
8. `creamInk`: from the first `@theme {` block of `index.css`, the `--color-ink`, `--color-ink-2`, `--color-ink-3` declarations (the cream-stock inks the dark layers override) → `WebTokens.CreamInk.ink/ink2/ink3`.
9. Write the two color sets (`AccentColor` ← `color-cyan`, `LaunchBackground` ← `color-void`) in Xcode's `Contents.json` format (sRGB, components as `0xNN` strings, alpha `1.000`).

`generate.ts` imports `writeTokens` and calls it after the bundles, passing `WEB`, `OUT`, and the Swift/asset output paths; `design-tokens.json` is included in the content hash.

- [ ] **Step 5: Generate and run**

Run: `cd tools/generate-content && npx tsc --noEmit && PITCH_ATLAS_WEB=$WEB npm run generate && cd ../.. && ./scripts/build.sh test`
Expected: `tsc` clean; generator prints `design-tokens.json` and `WebTokens.swift`; `Executed 98 tests, with 0 failures`.

- [ ] **Step 6: Commit**

```bash
git add tools/generate-content PitchAtlas/Core/Theme PitchAtlas/Resources/Content PitchAtlas/Resources/Assets.xcassets PitchAtlasTests/DesignTokenParityTests.swift
git commit -m "feat(theme): generate every design token from the web source"
```

---

### Task 6: Theme roles over the generated tokens (added beside the old ones)

**Files:**
- Create: `PitchAtlas/Core/Theme/PitchAccents.swift`, `PitchAtlas/Core/Theme/PitchAtlasMaterials.swift`, `PitchAtlas/Core/Theme/PitchAtlasMotion.swift`
- Test: `PitchAtlasTests/ThemeRoleTests.swift`

**Interfaces:**
- Produces: `PitchAccents.triad(for slug: String) -> WebAccent`, `PitchAccents.familyColor(_ family: RepertoireFamily) -> Color`, `PitchAccents.familyColor(_ family: PitchFamily) -> Color`, `PitchAccents.accentInk(_ rgb: UInt32) -> Color` (bone for burnt), `PitchAccents.accentButton(fill: UInt32) -> (background: UInt32, foreground: UInt32)`, `PitchAccents.contrast(_ a: UInt32, _ b: UInt32) -> Double`; `PitchAtlasMaterials.gradient(_ g: WebGradient, aspect: CGFloat) -> LinearGradient`, `PitchAtlasMaterials.cssEndpoints(angle: Double, aspect: CGFloat) -> (start: UnitPoint, end: UnitPoint)`, `.foil/.foilType/.ember(aspect:)`, `.cardFoil(finish: String?, aspect:)`; `PitchAtlasMotion.settle(_ ms: Double) -> Animation`, `.tiny/.short/.medium/.slow/.sweep: Animation`, `.cardEase: Animation` (`timingCurve(0.2, 0.8, 0.2, 1, duration: 0.4)`), `.tiltSpring: Animation` (`spring(response: 0.314, dampingRatio: 0.7)`), `.specimenEase: Animation` (`timingCurve(0.16, 1, 0.3, 1, duration: 0.4)`), `PitchAtlasMotion.animation(_ base: Animation, reduceMotion: Bool) -> Animation?`.

- [ ] **Step 1: Write the failing tests**

```swift
import XCTest
import SwiftUI
@testable import PitchAtlas

final class ThemeRoleTests: XCTestCase {
    func testAccentButtonMatchesTheWebAlgorithm() {
        // Vectors from web src/components/refractor/accents.ts accentButton().
        let cases: [(UInt32, UInt32, UInt32)] = [
            (0xBF5700, 0xBF5700, 0xFFFFFF), (0x5FE0EA, 0x5FE0EA, 0x06121B), (0x5B7F96, 0x63859B, 0x06121B),
            (0x6E757B, 0x6E757B, 0xFFFFFF), (0xB9D4E5, 0xB9D4E5, 0x06121B), (0xFF4D46, 0xFF4D46, 0x06121B),
            (0x3F5768, 0x3F5768, 0xFFFFFF), (0x7F97A8, 0x7F97A8, 0x06121B),
        ]
        for (fill, background, foreground) in cases {
            let result = PitchAccents.accentButton(fill: fill)
            XCTAssertEqual(result.background, background, String(fill, radix: 16))
            XCTAssertEqual(result.foreground, foreground, String(fill, radix: 16))
        }
    }

    func testContrastMatchesTheWebFormula() {
        XCTAssertEqual(PitchAccents.contrast(0x070509, 0xBF5700), 4.425, accuracy: 0.001)
        XCTAssertEqual(PitchAccents.contrast(0x221E18, 0x7C8294), 4.324, accuracy: 0.001)
    }

    func testCssAngleEndpointsOnASquare() {
        let p = PitchAtlasMaterials.cssEndpoints(angle: 112, aspect: 1)
        XCTAssertEqual(p.start.x, -0.1035, accuracy: 0.001)
        XCTAssertEqual(p.start.y, 0.2559, accuracy: 0.001)
        XCTAssertEqual(p.end.x, 1.1035, accuracy: 0.001)
        XCTAssertEqual(p.end.y, 0.7441, accuracy: 0.001)
        let down = PitchAtlasMaterials.cssEndpoints(angle: 180, aspect: 5.0 / 7.0)
        XCTAssertEqual(down.start.x, 0.5, accuracy: 0.0001); XCTAssertEqual(down.start.y, 0, accuracy: 0.0001)
        XCTAssertEqual(down.end.y, 1, accuracy: 0.0001)
    }

    func testFamilyColorsAreTheWebInkwells() {
        XCTAssertEqual(PitchAccents.familyRGB(.fastball), 0xBF5700)
        XCTAssertEqual(PitchAccents.familyRGB(.offspeed), 0xD8CFBB)
        XCTAssertEqual(PitchAccents.familyRGB(.breaking), 0x5FE0EA)
        XCTAssertEqual(PitchAccents.familyRGB(.specialty), 0xB9D4E5)
        XCTAssertEqual(PitchAccents.familyRGB(.banned), 0xFF4D46)
    }

    func testUnknownSlugFallsBackToTheNeutralTriad() {
        XCTAssertEqual(PitchAccents.triad(for: "not-a-slug"), WebTokens.Accent.fallback)
    }

    func testReduceMotionDropsAnimation() {
        XCTAssertNil(PitchAtlasMotion.animation(PitchAtlasMotion.medium, reduceMotion: true))
        XCTAssertNotNil(PitchAtlasMotion.animation(PitchAtlasMotion.medium, reduceMotion: false))
    }
}
```

- [ ] **Step 2: Run** → Expected: compile errors (`cannot find 'PitchAccents'`).

- [ ] **Step 3: Implement**

`PitchAccents.swift`:
```swift
import SwiftUI

/// Per-pitch and per-family accents, ported from web refractor/accents.ts and
/// sections/family-accent.ts. Values come from the generated WebTokens.
enum PitchAccents {
    static func triad(for slug: String) -> WebAccent { WebTokens.Accent.byPitch[slug] ?? WebTokens.Accent.fallback }

    static func familyRGB(_ family: RepertoireFamily) -> UInt32 {
        WebTokens.Family.accent[family.rawValue] ?? WebTokens.Accent.fallback.c3
    }
    static func familyRGB(_ family: PitchFamily) -> UInt32 {
        WebTokens.Family.accent[family.rawValue] ?? WebTokens.Accent.fallback.c3
    }
    static func familyColor(_ family: RepertoireFamily) -> Color { Color(rgb: familyRGB(family)) }
    static func familyColor(_ family: PitchFamily) -> Color { Color(rgb: familyRGB(family)) }

    /// Small type that would take an accent: burnt orange measures ~4.4:1 on the
    /// void, so small print beside it goes bone. Every other accent passes through.
    static func accentInk(_ rgb: UInt32) -> Color {
        rgb == WebTokens.Accent.burnt ? Color(web: WebTokens.Palette.bone) : Color(rgb: rgb)
    }

    private static let ctaDark: UInt32 = WebTokens.Palette.ctlOnAccent.rgb
    private static let ctaLight: UInt32 = WebTokens.Palette.white.rgb

    /// The accent-filled action button: dark ink while it reads at 4.5:1, white
    /// where white does, else lift the fill toward white in 5% steps.
    static func accentButton(fill: UInt32) -> (background: UInt32, foreground: UInt32) {
        for step in 0...20 {
            let background = step == 0 ? fill : towardWhite(fill, Double(step) * 0.05)
            if contrast(ctaDark, background) >= 4.5 { return (background, ctaDark) }
            if step == 0 && contrast(ctaLight, background) >= 4.5 { return (background, ctaLight) }
        }
        return (ctaLight, ctaDark)
    }

    static func contrast(_ a: UInt32, _ b: UInt32) -> Double {
        let (la, lb) = (luminance(a), luminance(b))
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    private static func luminance(_ rgb: UInt32) -> Double {
        func channel(_ v: UInt32) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel((rgb >> 16) & 0xFF) + 0.7152 * channel((rgb >> 8) & 0xFF) + 0.0722 * channel(rgb & 0xFF)
    }

    private static func towardWhite(_ rgb: UInt32, _ amount: Double) -> UInt32 {
        func lift(_ v: UInt32) -> UInt32 { UInt32((Double(v) + (255 - Double(v)) * amount).rounded()) }
        return (lift((rgb >> 16) & 0xFF) << 16) | (lift((rgb >> 8) & 0xFF) << 8) | lift(rgb & 0xFF)
    }
}
```
(JavaScript's `Math.round` rounds .5 up; Swift `.rounded()` rounds half away from zero — identical for these non-negative values.)

`PitchAtlasMaterials.swift`:
```swift
import SwiftUI

/// The web's metallic materials as SwiftUI gradients. CSS angles are honored for
/// the drawn shape's aspect ratio, so a 112° foil rakes the same way on a 5:7 card.
enum PitchAtlasMaterials {
    /// CSS linear-gradient geometry: the gradient line passes through the center
    /// along the angle's direction and its length makes the corners hit 0% and 100%.
    static func cssEndpoints(angle: Double, aspect: CGFloat) -> (start: UnitPoint, end: UnitPoint) {
        let theta = angle * .pi / 180
        let (w, h) = (Double(aspect), 1.0)
        let (dx, dy) = (sin(theta), -cos(theta))
        let half = (abs(w * dx) + abs(h * dy)) / 2
        return (UnitPoint(x: 0.5 - dx * half / w, y: 0.5 - dy * half / h),
                UnitPoint(x: 0.5 + dx * half / w, y: 0.5 + dy * half / h))
    }

    static func gradient(_ g: WebGradient, aspect: CGFloat) -> LinearGradient {
        let ends = cssEndpoints(angle: g.angle, aspect: aspect)
        return LinearGradient(stops: g.stops.map { .init(color: Color(web: $0.color), location: $0.location) },
                              startPoint: ends.start, endPoint: ends.end)
    }

    static func foil(aspect: CGFloat = 5.0 / 7.0) -> LinearGradient { gradient(WebTokens.Gradient.foil, aspect: aspect) }
    static func foilType(aspect: CGFloat = 4) -> LinearGradient { gradient(WebTokens.Gradient.foilType, aspect: aspect) }
    static func ember(aspect: CGFloat = 5.0 / 7.0) -> LinearGradient { gradient(WebTokens.Gradient.ember, aspect: aspect) }

    static func finish(_ name: String?) -> WebCardFinish? {
        switch name {
        case "powder": return WebTokens.CardFinish.powder
        case "teal": return WebTokens.CardFinish.teal
        default: return nil
        }
    }
    static func cardFoil(finish name: String?, aspect: CGFloat = 5.0 / 7.0) -> LinearGradient {
        gradient(finish(name)?.foil ?? WebTokens.Gradient.foil, aspect: aspect)
    }
}
```
(Checked: θ = 112° on a square gives half-length 0.6509 and `start = (−0.1035, 0.2562)`, `end = (1.1035, 0.7438)`, within the test's 0.001 tolerance; 0° = to top, y grows downward.)

`PitchAtlasMotion.swift`:
```swift
import SwiftUI

/// Web motion tokens: 120/190/400/700/900 ms on the settle curve (.22,1,.36,1),
/// the card ease (.2,.8,.2,1) and the specimen ease (.16,1,.3,1).
enum PitchAtlasMotion {
    static func settle(_ ms: Double) -> Animation {
        let c = WebTokens.Motion.settle
        return .timingCurve(c[0], c[1], c[2], c[3], duration: ms / 1000)
    }
    static let tiny = settle(WebTokens.Motion.tinyMs)
    static let short = settle(WebTokens.Motion.shortMs)
    static let medium = settle(WebTokens.Motion.mediumMs)
    static let slow = settle(WebTokens.Motion.slowMs)
    static let sweep = settle(WebTokens.Motion.sweepMs)
    static let cardEase = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.4)
    static let specimenEase = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.4)
    /// The web tilt spring, ω = 20 rad/s, ζ = 0.7 → response 2π/20.
    static let tiltSpring = Animation.spring(response: 0.314, dampingRatio: 0.7)

    /// Reduce Motion: no animation at all (the state lands still).
    static func animation(_ base: Animation, reduceMotion: Bool) -> Animation? { reduceMotion ? nil : base }
}
```

- [ ] **Step 4: Run** → Expected: `Executed 104 tests, with 0 failures`.

- [ ] **Step 5: Commit**

```bash
git add PitchAtlas/Core/Theme PitchAtlasTests/ThemeRoleTests.swift
git commit -m "feat(theme): accents, materials and motion read the generated tokens"
```

---

### Task 7: Re-route shared meanings to web roles

**Files:**
- Modify: `PitchAtlas/Components/ContentCards.swift:14-87`, `PitchAtlas/App/PitchAtlasApp.swift:149`, and every `SectionLabel(..., color: PitchAtlasTheme.powder)` / `StatusPill(..., tone: …)` call listed below
- Modify: `PitchAtlas/Core/Theme/PitchAtlasTheme.swift` (add role tokens)
- Test: `PitchAtlasTests/ThemeRoleTests.swift`

**Interfaces:**
- Produces: `PitchAtlasTheme.kicker` (= web `kicker` → cyan), `PitchAtlasTheme.success` (web `color-ok`), `PitchAtlasTheme.caution` (web `color-amber`), `PitchAtlasTheme.lostEdge` (web `color-sand-bright`); `RepertoireStatus.tone` = web PitchIndex `STATUS` color; `RepertoireStatus.badgeTone` = web `StatusBadge` (edge → seam, else bone-2); `DocumentationTier.tone` = web `TIER_COLOR`.

- [ ] **Step 1: Write the failing tests** (append to `ThemeRoleTests`)

```swift
    func testStatusAndTierTonesFollowTheWebMaps() {
        for status in RepertoireStatus.allCases {
            XCTAssertEqual(status.toneRGB, WebTokens.Status.indexColor[status.rawValue]?.rgb, status.rawValue)
        }
        XCTAssertEqual(RepertoireStatus.alias.badgeToneRGB, WebTokens.Palette.seam.rgb)
        XCTAssertEqual(RepertoireStatus.rare.badgeToneRGB, WebTokens.Palette.bone2.rgb)
        XCTAssertEqual(DocumentationTier.documented.toneRGB, WebTokens.Tier.dot["official-data"]?.rgb)
        XCTAssertEqual(DocumentationTier.partial.toneRGB, WebTokens.Tier.dot["reputable-analysis"]?.rgb)
        XCTAssertEqual(DocumentationTier.legend.toneRGB, WebTokens.Tier.dot["unverified"]?.rgb)
    }

    func testFamilyAccentsReadTheWebInkwells() {
        XCTAssertEqual(RepertoireFamily.fastball.accentRGB, 0xBF5700)
        XCTAssertEqual(PitchFamily.breaking.accentRGB, 0x5FE0EA)
    }
```

- [ ] **Step 2: Run** → Expected: compile errors (`toneRGB` missing).

- [ ] **Step 3: Implement**
  - `PitchFamily.accent` / `RepertoireFamily.accent` → `PitchAccents.familyColor(self)`; add `accentRGB` (`PitchAccents.familyRGB(self)`).
  - `RepertoireStatus.tone` → `Color(web: WebTokens.Status.indexColor[rawValue] ?? WebTokens.Palette.bone2)`, `toneRGB`; `badgeTone`/`badgeToneRGB` → seam when `WebTokens.Status.edge.contains(rawValue)`, else bone-2. (`RepertoireStatus` raw values must equal the web keys — `near-extinct`, `not-a-pitch`; check the enum's raw values and map through them.)
  - `DocumentationTier.tone`/`toneRGB` → `WebTokens.LostTier.color[rawValue]`.
  - Theme roles in `PitchAtlasTheme`: `static let kicker = Color(web: WebTokens.Palette.kicker)`, `success = Color(web: WebTokens.Palette.ok)`, `caution = Color(web: WebTokens.Palette.amber)`, `lostEdge = Color(web: WebTokens.Palette.sandBright)`.
  - Call sites: every `SectionLabel(text:…, color: PitchAtlasTheme.powder)` → `PitchAtlasTheme.kicker` (About, Index, Sources, Account, Atlas, Grips, Lost Pitches, Craftsmen, Learn); `.tint(PitchAtlasTheme.powder)` → `.tint(PitchAtlasTheme.kicker)`; `okBright` → `success`; `amberBright` used as a warning/status (`AccountView` 108/186/369, `CommunityPanel` 109/512, `PitchAtlasUI` 362, "Educational use" labels) → `caution`; `amberBright` used as a section accent ("What it really is", "Study this first") → `kicker`; `sandBright` (lost/legend edge, compare rule) → `lostEdge`; `PitchDetailView:166` grade color → `PitchAtlasTheme.bone2` (the ember badge is restyled in Plan 2); `PitchDetailView:572` chase dot → `PitchAccents.triad(for: sib.slug).c3`; `ContentCards:465` gold craftsman rail → `lostEdge` for legends, `PitchAtlasTheme.machined` for the rest (Plan 2 restyles the plate); `PitchAtlasUI:49` violet glow → `PitchAtlasTheme.kicker.opacity(0.045)`; `PitchAtlasUI:269` powder tick → `kicker`.

- [ ] **Step 4: Run** → Expected: `Executed 106 tests, with 0 failures`; `grep -rnE "PitchAtlasTheme\.(okBright|amberBright|violet|lime|powder|sandBright)" PitchAtlas --include='*.swift' | grep -v Core/Theme` prints nothing except `BlazeInlineCompanionView` (removed in Plan 2).

- [ ] **Step 5: Commit**

```bash
git add -A PitchAtlas PitchAtlasTests
git commit -m "refactor(theme): route family, status and tier tones through the web maps"
```

---

### Task 8: Three trust colors, seven labels

**Files:**
- Modify: `PitchAtlas/Core/Theme/PitchAtlasTheme.swift` (`color(forConfidence:)`, `cardbackColor(forConfidence:)` → `cardInk(forConfidence:)`), `PitchAtlas/Core/Data/ContentModels.swift` (`ClaimConfidence.glyph`, labels read `WebTokens.Tier.label`), `PitchAtlas/Components/ProvenanceViews.swift` (labels bone-2; dot keeps tier color)
- Test: `PitchAtlasTests/PitchAtlasTests.swift` (`testConfidenceColorFallback` rewritten), `ThemeRoleTests`

**Interfaces:**
- Produces: `PitchAtlasTheme.color(forConfidence raw: String) -> Color` (3 colors), `PitchAtlasTheme.cardInk(forConfidence raw: String) -> Color` (cream inks), `ClaimConfidence.glyph: String`, `ClaimConfidence(lenient raw: String)` (unknown → `.unverified`).

- [ ] **Step 1: Write the failing tests**

Replace `testConfidenceColorFallback` with:
```swift
    func testConfidenceColorFallback() {
        XCTAssertEqual(PitchAtlasTheme.color(forConfidence: "official-data"), Color(web: WebTokens.Tier.dot["official-data"]!))
        XCTAssertEqual(PitchAtlasTheme.color(forConfidence: "secondhand-attributed"), Color(web: WebTokens.Tier.dot["reputable-analysis"]!))
        XCTAssertEqual(PitchAtlasTheme.color(forConfidence: "not-a-tier"), Color(web: WebTokens.Tier.dot["unverified"]!))
    }
```
and add to `ThemeRoleTests`:
```swift
    func testUnknownConfidenceFallsBackToUnverifiedEverywhere() {
        let c = ClaimConfidence(lenient: "something-new")
        XCTAssertEqual(c, .unverified)
        XCTAssertEqual(c.glyph, "⊘")
        XCTAssertEqual(c.label, "Unverified")
        XCTAssertEqual(PitchAtlasTheme.cardInk(forConfidence: "something-new"), Color(web: WebTokens.Tier.ink["unverified"]!))
    }

    func testEveryConfidenceHasGlyphAndWebLabel() {
        for c in ClaimConfidence.allCases {
            XCTAssertEqual(c.label, WebTokens.Tier.label[c.rawValue])
            XCTAssertEqual(c.glyph, WebTokens.Tier.glyph[c.rawValue])
        }
    }
```

- [ ] **Step 2: Run** → Expected: compile errors (`cardInk`, `glyph`, `init(lenient:)`).

- [ ] **Step 3: Implement**
  - `color(forConfidence:)` → `Color(web: WebTokens.Tier.dot[raw] ?? WebTokens.Tier.dot["unverified"]!)`; `cardInk(forConfidence:)` likewise over `WebTokens.Tier.ink`. Remove `cardbackColor(forConfidence:)` and repoint its one caller to `color(forConfidence:)` (the card back is dark stock, so it takes the dot colors).
  - `ClaimConfidence.label`/`meaning` read `WebTokens.Tier.label/meaning`; add `glyph` from `WebTokens.Tier.glyph`; add `init(lenient:)`; make the `Claim` decoder use the lenient init (custom `init(from:)` on `ClaimConfidence` that decodes the string and maps unknowns to `.unverified`).
  - `ProvenanceViews`: wherever a tier label's text is painted with the tier color, paint it `PitchAtlasTheme.bone2`; the dot keeps `color(forConfidence:)`; the glyph sits beside the label.

- [ ] **Step 4: Run** → Expected: `Executed 108 tests, with 0 failures`.

- [ ] **Step 5: Commit**

```bash
git add -A PitchAtlas PitchAtlasTests
git commit -m "feat(provenance): three trust colors across the seven labels"
```

---

### Task 9: Repoint the base palette, system chrome and backdrop

**Files:**
- Modify: `PitchAtlas/Core/Theme/PitchAtlasTheme.swift` (void, press, paper2, paper3, bone, bone2, bone3, ink2, ink3, cyan, cyanDeep, seamBright, sandBright, machined, navyLine; ink context), `PitchAtlas/Core/Theme/PitchAtlasSpacing.swift` (radii), `PitchAtlas/App/PitchAtlasApp.swift` (`AppChromeAppearance`), `PitchAtlas/Core/Scene3D/SpecimenSceneBuilder.swift` (~L427 accent), `PitchAtlas/Components/PitchAtlasUI.swift` (`FieldBackdrop`), `PitchAtlas/Core/Motion/MotionProvider.swift:57`
- Test: `ThemeRoleTests`

**Interfaces:**
- Produces: `enum InkContext { case void, object, cream }`, `EnvironmentValues.inkContext`, `View.inkContext(_:)`, `struct ContextInk: ShapeStyle` (`resolve(in:)` picks per context), `PitchAtlasTheme.text2: ContextInk` / `.text3: ContextInk`; `leatherPress()` sets `.object`.

- [ ] **Step 1: Write the failing tests**

```swift
    func testBasePaletteIsTheWebField() {
        XCTAssertEqual(PitchAtlasTheme.voidRGB, 0x070509)
        XCTAssertEqual(PitchAtlasTheme.cyanRGB, 0x5FE0EA)
        XCTAssertEqual(PitchAtlasTheme.bone2RGB, WebTokens.Palette.bone2.rgb)
    }

    func testInkFollowsTheSurface() {
        XCTAssertEqual(InkContext.void.text3RGB, WebTokens.Palette.ink3.rgb)
        XCTAssertEqual(InkContext.object.text3RGB, WebTokens.Palette.bone3.rgb)
        XCTAssertEqual(InkContext.object.text2RGB, WebTokens.Palette.bone2.rgb)
        XCTAssertEqual(InkContext.cream.text2RGB, WebTokens.CreamInk.ink2.rgb)
        XCTAssertGreaterThanOrEqual(PitchAccents.contrast(PitchAtlasTheme.pressRGB, InkContext.object.text3RGB), 4.5)
    }
```
(`InkContext.cream` reads `WebTokens.CreamInk` — the base `@theme` block's `--color-ink/-2/-3`, which the dark layers override and the cream stock still uses.)

- [ ] **Step 2: Run** → Expected: compile errors.

- [ ] **Step 3: Implement**
  - Each base token reads `WebTokens.Palette.<name>`; add `…RGB` accessors used by tests.
  - `ContextInk: ShapeStyle` with `func resolve(in environment: EnvironmentValues) -> Color` choosing `ink2/ink3` (void), `bone2/bone3` (object) or the cream inks; `PitchAtlasTheme.bone2`/`ink3` call sites that sit inside `leatherPress` read correctly without edits because `leatherPress()` applies `.environment(\.inkContext, .object)`. Where a call site needs a concrete `Color` (shadows, `.tint`), use the void value.
  - Radii from the web: `PitchAtlasRadius.chip = WebTokens.Radius.sm`, `panel = 12`, `tile = 14`, `card = 9` (card stock), add `cardField = 4`, `plate = 13`, `indexRow = 14`, `input = 12`, `select = 10`, `pill = 999`. (The web's per-component radii live in CSS rules; Plan 2's component-color extraction adds them to the generator — until then these literal radii carry a comment naming the web rule.)
  - `AppChromeAppearance`: field/bone/bone2/cyan from `UIColor(web:)` of the tokens.
  - `SpecimenSceneBuilder` accent → `UIColor(web: WebTokens.Palette.cyan)`.
  - `FieldBackdrop`: drop the `#A87C4B` brown glow; dot grid (22pt tile, bone at 0.05, radial mask), two depth pools tinted by a `sceneTint: Color` parameter (default `Color(web: WebTokens.Palette.columbia)`), grain at 0.035 opacity.
  - `MotionProvider:57` rainbow foil → `PitchAtlasMaterials.foil()`.

- [ ] **Step 4: Run** → Expected: `Executed 110 tests, with 0 failures`; simulator launch shows a near-black field (no brown cast).

- [ ] **Step 5: Commit**

```bash
git add -A PitchAtlas PitchAtlasTests
git commit -m "feat(theme): the web field, inks by surface, cyan chrome"
```

---

### Task 10: Ball materials move into the theme; no color literal outside it

**Files:**
- Create: `PitchAtlas/Core/Theme/BallMaterial.swift`, `scripts/check-no-color-literals.sh`
- Modify: `PitchAtlas/Features/PitchDetail/SeamBall.swift`, `PitchAtlas/Core/Scene3D/SpecimenSceneBuilder.swift`, `PitchAtlas/Core/Scene3D/LeatherMaps.swift`, `PitchAtlas/Components/PitchAtlasUI.swift`, `PitchAtlas/Components/ContentCards.swift`, `.github/workflows/ios.yml`

**Interfaces:**
- Produces: `BallMaterial.leather/leatherShade/leatherHighlight/seam/stitch/…` (`Color` and `UIColor` pairs, each line citing the web ball material it ports); `scripts/check-no-color-literals.sh` (exit 1 listing offending lines).

- [ ] **Step 1: Write the check and watch it fail**

```bash
#!/usr/bin/env bash
# Every color in the app comes from the theme (which reads the generated web
# tokens). A literal anywhere else is drift waiting to happen.
set -euo pipefail
cd "$(dirname "$0")/.."
pattern='Color\(hex:|Color\(red:|Color\(white:|Color\(\.sRGB|UIColor\(red:|UIColor\(white:|UIColor\(hue:|#colorLiteral|CGColor\(red:'
hits="$(grep -rnE "$pattern" PitchAtlas --include='*.swift' | grep -v '^PitchAtlas/Core/Theme/' || true)"
if [ -n "$hits" ]; then
  echo "::error::color literals outside PitchAtlas/Core/Theme/:"
  echo "$hits"
  exit 1
fi
echo "✓ no color literals outside the theme"
```
Run: `chmod +x scripts/check-no-color-literals.sh && ./scripts/check-no-color-literals.sh; echo "exit=$?"` → Expected: lists the SeamBall/SceneBuilder/LeatherMaps/UI literals, `exit=1`.

- [ ] **Step 2: Move every literal** into `BallMaterial` (ball/scene/leather) or `PitchAtlasTheme` (UI), keeping identical values; for UI literals that duplicate a web token, use the token instead.

- [ ] **Step 3: Run the check and the suite** → Expected: `✓ no color literals outside the theme`; `Executed 110 tests, with 0 failures`.

- [ ] **Step 4: Add to CI** — in the `build-and-test` job, before "Build": a step `- name: No color literals outside the theme\n  run: ./scripts/check-no-color-literals.sh`.

- [ ] **Step 5: Commit**

```bash
git add -A PitchAtlas scripts .github/workflows/ios.yml
git commit -m "refactor(theme): ball materials join the theme; CI rejects stray color literals"
```

---

### Task 11: The web's fourteen font faces and the type roles

**Files:**
- Create: `tools/fonts/import-web-fonts.py`, `PitchAtlas/Core/Theme/PitchAtlasType.swift`
- Replace: `PitchAtlas/Resources/Fonts/*.ttf` (14 faces), `PitchAtlas/Resources/Fonts/LICENSES.md`
- Modify: `project.yml` (`UIAppFonts`), `PitchAtlas/Core/Theme/PitchAtlasTheme.swift` (font helpers)
- Test: `PitchAtlasTests/FontTests.swift`

**Interfaces:**
- Produces: `PitchAtlasType.Face` (`newsreader400/400i/500/600/600i`, `hanken400/400i/500/600/700`, `martian400/500/600`, `anton400`) with `postScriptName`; `PitchAtlasType.font(_ face:, size:, relativeTo:) -> Font`; roles `heroTitle(size:)`, `heroItalic(size:)`, `sectionTitle(size:)` (Anton, no skew), `kicker` (Martian 500, 11, tracking 0.2em), `label` (Martian 400, 11, 0.18em), `chromeCTA` (Martian 600, 11, 0.14em), `chip` (9.5), `segment` (12), `statusPill` (8), `cardCue` (Newsreader italic), `body(size:)` (Hanken 400); `View.tracking(em:size:)` helper. Existing `PitchAtlasTheme.anton/newsreader/newsreaderItalic/hanken/hankenMedium/martian` keep their signatures and resolve to the new faces.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import UIKit
@testable import PitchAtlas

final class FontTests: XCTestCase {
    /// Every face the web loads (design-tokens.json `fonts`) is bundled and
    /// resolves by PostScript name — a silent system fallback would fail here.
    func testEveryWebFontFaceResolves() {
        XCTAssertEqual(WebTokens.Fonts.faces.count, PitchAtlasType.Face.allCases.count)
        for face in PitchAtlasType.Face.allCases {
            XCTAssertNotNil(UIFont(name: face.postScriptName, size: 12), face.postScriptName)
            XCTAssertTrue(WebTokens.Fonts.faces.contains { $0.family == face.family && $0.weight == face.weight && $0.italic == face.italic },
                          "\(face) is not a web face")
        }
    }

    func testCustomFontsScaleWithDynamicType() {
        let base = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont(name: PitchAtlasType.Face.hanken400.postScriptName, size: 17)!,
                                                              compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
        let ax5 = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont(name: PitchAtlasType.Face.hanken400.postScriptName, size: 17)!,
                                                             compatibleWith: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))
        XCTAssertGreaterThan(ax5.pointSize, base.pointSize * 2)
    }
}
```

- [ ] **Step 2: Run** → Expected: compile error (`PitchAtlasType` missing).

- [ ] **Step 3: Import the faces**

`tools/fonts/import-web-fonts.py` downloads the 14 Latin `woff2` files the web loads (`@fontsource/newsreader@5.2.10`, `hanken-grotesk@5.2.8`, `martian-mono@5.2.7`, `anton@5.2.7` — the versions pinned in web `package-lock.json`) from `cdn.jsdelivr.net/npm/@fontsource/<pkg>@<ver>/files/<file>.woff2`, decompresses each to TTF with fontTools (`flavor = None`), names it `<PostScriptName>.ttf`, and prints a sha256 table for `LICENSES.md`. Run it with a venv that has `fonttools` and `brotli`. Delete the six old TTFs. PostScript names: `Anton-Regular`, `Newsreader16pt16pt-Regular`, `-Italic`, `-Medium`, `-SemiBold`, `-SemiBoldItalic`, `HankenGrotesk-Regular`, `-Italic`, `-Medium`, `-SemiBold`, `-Bold`, `MartianMonoSemiExpanded-Regular`, `-Medium`, `-SemiBold`.

- [ ] **Step 4: Register and implement** — `project.yml` `UIAppFonts` lists the 14 file names; `PitchAtlasType.swift` defines `Face` (`CaseIterable`, `family`, `weight`, `italic`, `postScriptName`) and the roles with `Font.custom(_:size:relativeTo:)`; the old `PitchAtlasTheme` helpers forward to it (`martian` → Martian SemiExpanded 400, `hankenMedium` → Hanken 500).

- [ ] **Step 5: Run** → Expected: `xcodegen generate` clean; `Executed 112 tests, with 0 failures`.

- [ ] **Step 6: Commit**

```bash
git add -A tools/fonts PitchAtlas/Resources/Fonts PitchAtlas/Core/Theme project.yml PitchAtlasTests/FontTests.swift
git commit -m "feat(type): bundle the web's fourteen font faces and its type roles"
```

---

### Task 12: Retire the old palette; contrast tests guard the roles

**Files:**
- Modify: `PitchAtlas/Core/Theme/PitchAtlasTheme.swift` (delete `okBright`, `amberBright`, `tealGlow`, `violet`, `lime`, `navyLift`, `gold`, rainbow `foil`, `chrome`, `cardbackForest`, `cardbackGoldInk` and every unused token), `PitchAtlas/Components/PitchAtlasUI.swift` (delete `FoilRake`), any remaining callers
- Test: `PitchAtlasTests/DesignTokenContrastTests.swift`

**Interfaces:**
- Consumes: `PitchAccents.contrast(_:_:)`, `InkContext.*RGB`, `PitchAtlasTheme.*RGB`.

- [ ] **Step 1: Write the contrast tests**

```swift
import XCTest
@testable import PitchAtlas

/// Every text/background pairing the app uses, at WCAG thresholds: 4.5:1 for
/// body text, 3:1 for large text and graphics (tier dots, rules).
final class DesignTokenContrastTests: XCTestCase {
    private let field = WebTokens.Palette.void.rgb
    private let press = WebTokens.Palette.press.rgb

    func testBodyTextRoles() {
        let pairs: [(String, UInt32, UInt32)] = [
            ("bone on void", WebTokens.Palette.bone.rgb, field),
            ("ink-2 on void", WebTokens.Palette.ink2.rgb, field),
            ("ink-3 on void", WebTokens.Palette.ink3.rgb, field),
            ("bone on press", WebTokens.Palette.bone.rgb, press),
            ("bone-2 on press", InkContext.object.text2RGB, press),
            ("bone-3 on press", InkContext.object.text3RGB, press),
            ("cyan on void", WebTokens.Palette.cyan.rgb, field),
            ("on-accent on cyan", WebTokens.Palette.ctlOnAccent.rgb, WebTokens.Palette.cyan.rgb),
            ("white on burnt", WebTokens.Palette.white.rgb, WebTokens.Accent.burnt),
            ("placeholder on control", WebTokens.Palette.ctlPlaceholder.rgb, WebTokens.Palette.ctlBg.rgb),
        ]
        for (name, fg, bg) in pairs { XCTAssertGreaterThanOrEqual(PitchAccents.contrast(fg, bg), 4.5, name) }
    }

    func testTierDotsAreVisibleGraphics() {
        for (raw, dot) in WebTokens.Tier.dot {
            XCTAssertGreaterThanOrEqual(PitchAccents.contrast(dot.rgb, field), 3, "\(raw) dot on void")
            XCTAssertGreaterThanOrEqual(PitchAccents.contrast(dot.rgb, press), 3, "\(raw) dot on press")
        }
    }

    func testSmallBurntTextIsNeverUsedOnTheVoid() {
        XCTAssertLessThan(PitchAccents.contrast(WebTokens.Accent.burnt, field), 4.5, "if this ever passes, the bone rule can relax")
        XCTAssertEqual(PitchAccents.accentInk(WebTokens.Accent.burnt), Color(web: WebTokens.Palette.bone))
    }
}
```
(Add `import SwiftUI` for `Color`.)

- [ ] **Step 2: Run** → Expected: PASS for pairs already true; any failure is a real contrast defect — fix the role (never the threshold) and ledger it.

- [ ] **Step 3: Delete the retired tokens and `FoilRake`**, fix the compile errors by moving each caller to its web role.

- [ ] **Step 4: Run** → Expected: `Executed 115 tests, with 0 failures`; `./scripts/check-no-color-literals.sh` ✓; `grep -rnE "okBright|amberBright|tealGlow|\bviolet\b|\blime\b|navyLift|FoilRake|0x37D6FF" PitchAtlas --include='*.swift'` prints nothing.

- [ ] **Step 5: Commit**

```bash
git add -A PitchAtlas PitchAtlasTests
git commit -m "refactor(theme): retire the pre-September palette behind contrast tests"
```
