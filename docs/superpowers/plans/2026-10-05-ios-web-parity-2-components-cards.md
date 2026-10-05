# iOS Web Parity — Plan 2: Components, the card system, and Blaze's exit

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the app the web's component kit (buttons, kicker, stamp, chips, both toggles, filter pill, search field, select, dialog, toast, trust marks, scout rows, panels) and its three object registers (the 5:7 specimen card with ember, throwbacks, tilt and the flip to the dark scout back; the Tier B plate; the Tier C index row; the binder), swap them into the components the screens already call, and remove the Blaze companion while keeping its scroll tracking under a neutral name.

**Architecture:** Every measured value comes from the web spec sheet (`scratchpad/web-component-specs.md`, measured on web `main@3f518f6`). Colors the web writes inside component rules (not `@theme`) land in one theme file, `Core/Theme/ComponentInk.swift`, each citing its rule, so the no-literal gate keeps holding. Geometry and state that decide what a visitor sees are pure Swift (`SpecimenCardMetrics`, `CardFrame`, `SpecimenCardContent`, `CardTiltState`, `FlipFace`, `IndexRowStyle`, `BinderLayout`, `ChipAppearance`, …) and are unit-tested; the SwiftUI views read them. Screens keep their layouts (Plan 3 rebuilds those); this plan changes what the shared components look like and adds the new ones.

**Tech Stack:** Swift 5 / SwiftUI (iOS 17.0 floor), XcodeGen, XCTest. Tests run on GitHub Actions through draft PR #36 (`claude/ios-web-parity`).

**Spec:** `docs/superpowers/specs/2026-10-05-ios-web-parity-design.md` (with the measured sheet `web-component-specs.md` in the session scratchpad; every value below is copied from it).

## Global Constraints

- iOS 17.0 floor. No `MeshGradient`, `ScrollPosition` struct, `onScrollGeometryChange`, `onScrollVisibilityChange`, `onScrollPhaseChange`, two-argument `onGeometryChange`, `Tab`, `navigationTransition`.
- No color literal (`Color(hex:`, `Color(red:`, `Color(white:`, `Color(.sRGB`, `UIColor(red:`/`white:`/`hue:`/`hexRGB:`, `#colorLiteral`, `CGColor(red:`) outside `PitchAtlas/Core/Theme/` — `scripts/check-no-color-literals.sh` enforces it in CI.
- Values are the web's. Where the web value fails contrast, lift it the minimum to pass and say so in a comment (the read-plate meta line `#746B5D` 4.22:1 → `#6E655A` 4.60:1).
- Three trust colors, all seven labels. A tier dot never appears without its words.
- Tap targets ≥ 44pt (the painted pill may be smaller; the hit area is not).
- Reduce Motion: tilt off, flip instant, rosin puff off, settle/fade animations off.
- No invented data: card copy comes from the bundled records (`canonical.grip`, `gripDetails`, `physics.shape`, grip entries). A missing value hides its row; nothing is filled in.
- The app builds and its tests pass after every commit. `xcodegen generate` after adding or removing files.
- Commit messages: `type(scope): description`, ending with the session attribution lines.
- Copy never says "sourced, not corrected" and is not written by a voice skill.

## Review Focus

1. **A pitch with no grip photo, no film and no shape claim** (e.g. `eephus`, `forkball`) must still render a whole card: schematic face, "Reference schematic" chip, the reference grip claim as the cue, and a back with only the rows it has. (Task 8 `testContentForPitchWithoutAustinMediaUsesReferenceClaim`, Task 11 `testScoutRowsOmitMissingShape`.)
2. **The card at accessibility text sizes**: the card's print is an object and scales with the card, so at AX sizes the same words must appear below it in scalable text. (Task 9 `testCardWordsRepeatCueAndTierInScalableText`.)
3. **Rapid flip taps and VoiceOver on a flipped card**: only the visible face is reachable; the flip control names the card and its state. (Task 11 `testFlipFaceSwapsAtNinetyDegrees`, `testFlipLabelsNameCardAndState`.)
4. **Narrow phones (320pt)**: micro-type floors (7/8pt) must hold when `u` shrinks; the binder drops to two columns under 640pt. (Task 8 `testMicroTypeFloorsHoldOnSmallCards`, Task 12 `testBinderColumnsByWidth`.)
5. **A vertical scroll that starts on a card** must scroll the page, not tilt the card. (Task 10 `testVerticalDragDoesNotTilt`.)

---

## File map

| File | Responsibility |
|---|---|
| `PitchAtlas/Core/Theme/ComponentInk.swift` (new) | Component-rule colors from web CSS, each cited |
| `PitchAtlas/Core/Scroll/ScrollProgress.swift` (new, from Companion) | Scroll metrics preference + `ScrollProgressController` + `TabScaffold` |
| `PitchAtlas/Components/Surfaces.swift` (new) | `PanelSurface` (`.rfx-panel`), `panelFoil`, `Hairline`, `KickerLabel` rule, `InkStamp` |
| `PitchAtlas/Components/Buttons.swift` (new) | `PitchButtonStyle` (.chrome/.ghost/.waxSeal/.chapter/.link), `RosinPuff` |
| `PitchAtlas/Components/Controls.swift` (new) | `PitchChip`, `PillToggle`, `SegmentToggle`, `FilterSortPill` |
| `PitchAtlas/Components/Fields.swift` (new) | `PitchSearchField`, field/select surfaces, `pitchDialog`, `ToastCenter` + `ToastHost` |
| `PitchAtlas/Components/ProvenanceViews.swift` | `ConfidenceDot`, `ApproxPill`, `ScoutRow`, `ScoutRows` |
| `PitchAtlas/Components/Cards/SpecimenCardModel.swift` (new) | `SpecimenCardMetrics`, `CardFrame`, `SpecimenCardContent`, `ArchedWindow` |
| `PitchAtlas/Components/Cards/SpecimenCard.swift` (new) | The 5:7 front (`PitchSpecimenCard`) |
| `PitchAtlas/Components/Cards/CardTilt.swift` (new) | `CardTiltState`, `cardTilt` modifier, rim rake |
| `PitchAtlas/Components/Cards/CardBack.swift` (new; replaces `CardBackPanel.swift`) | `.v2-back` scout file, `FlipFace`, `FlippableSpecimen`, `CardBackPanel` |
| `PitchAtlas/Components/Cards/WallAndBinder.swift` (new) | `WallMount`, `WallSpecimen`, `BinderSheet`, `PocketCard`, `PocketSlip`, `BinderLayout` |
| `PitchAtlas/Components/Cards/PlateAndRow.swift` (new) | `Plate` (Tier B), `IndexRow` (Tier C), `IndexSeamMark`, `restFor` |
| `PitchAtlas/Components/ContentCards.swift` | keeps `BundledImage`, `GripPhotoTile`, `FamilyDot`, `StatusPill`; `PitchSpecimenCard`/`RepertoireRow` move out; `CraftsmanCard`/`LostPitchCard` become plates |
| Deleted | `PitchAtlas/Features/Companion/*`, Blaze image sets, `PitchAtlasTests/BlazeCompanionTests.swift`, `ArchiveCoverSurface`, signature/archive stock tokens, `companionCoat` |

---

### Task 1: PR #35 follow-ups — no duplicate pair, no jump on each keystroke

**Files:**
- Modify: `PitchAtlas/Features/Study/CompareSelection.swift:33-44`
- Modify: `PitchAtlas/Features/Index/IndexView.swift:114-117`
- Test: `PitchAtlasTests/CompareSelectionTests.swift`, `PitchAtlasTests/IndexScrollRestorationTests.swift`

**Interfaces:**
- Produces: `enum IndexFilterChange { case query, family, status, sort; var resetsToTop: Bool }` (in `IndexView.swift`, internal).

- [ ] **Step 1: Write the failing tests**

```swift
// CompareSelectionTests
func testReplacementNeverDuplicatesAPitchAlreadyInThePair() {
    let state = CompareSelection()
    state.add("four-seam"); state.add("slider"); state.add("cutter")   // cutter waits
    state.remove("four-seam"); state.add("cutter")                      // cutter joins the pair
    XCTAssertEqual(state.slugs, ["slider", "cutter"])
    XCTAssertNil(state.pending, "a pitch that joined the pair is no longer waiting")
    state.replace(0)
    XCTAssertEqual(state.slugs, ["slider", "cutter"])
    XCTAssertEqual(Set(state.slugs).count, state.slugs.count)
}

// IndexScrollRestorationTests
func testTypingKeepsThePlaceWhileFiltersReturnToTop() {
    XCTAssertFalse(IndexFilterChange.query.resetsToTop)
    XCTAssertTrue(IndexFilterChange.family.resetsToTop)
    XCTAssertTrue(IndexFilterChange.status.resetsToTop)
    XCTAssertTrue(IndexFilterChange.sort.resetsToTop)
}
```

- [ ] **Step 2: Run** `xcodebuild build-for-testing … -quiet CODE_SIGNING_ALLOWED=NO` (the local compile check). Expected: compile error `cannot find 'IndexFilterChange' in scope`; after stubbing the enum, CI shows `testReplacementNeverDuplicatesAPitchAlreadyInThePair` failing with `["cutter", "cutter"]`.

- [ ] **Step 3: Implement**

```swift
// CompareSelection
func add(_ slug: String) {
    error = nil
    inspection = nil
    if slugs.contains(slug) { presented = true; return }
    if slugs.count < 2 {
        slugs.append(slug)
        if pending == slug { pending = nil }
    } else { pending = slug }
    presented = true
}
func replace(_ index: Int) {
    guard slugs.indices.contains(index), let pending else { return }
    if !slugs.contains(pending) { slugs[index] = pending }
    self.pending = nil
}

// IndexView.swift (file scope)
/// What changed in the Index controls. Typing narrows the list where the reader
/// already is; a new family, status or sort is a new list and starts at the top.
enum IndexFilterChange {
    case query, family, status, sort
    var resetsToTop: Bool { self != .query }
}

// IndexView body
.onChange(of: query) { applyFilterChange(.query, using: proxy) }
.onChange(of: family) { applyFilterChange(.family, using: proxy) }
.onChange(of: status) { applyFilterChange(.status, using: proxy) }
.onChange(of: sort) { applyFilterChange(.sort, using: proxy) }

private func applyFilterChange(_ change: IndexFilterChange, using proxy: ScrollViewProxy) {
    scrollRestoration.invalidate()
    if change.resetsToTop { proxy.scrollTo(Self.topScrollTarget, anchor: .top) }
}
```
Delete `resetScrollPosition(using:)`.

- [ ] **Step 4: Run** the local compile check, then CI (`ci-test-t1.sh`). Expected: `Executed N tests, with 0 failures` (N = 115 + 2).

- [ ] **Step 5: Commit** `fix(index): typing keeps its place; compare never holds one pitch twice`

---

### Task 2: Blaze leaves; the scroll tracking stays under a neutral name

**Files:**
- Create: `PitchAtlas/Core/Scroll/ScrollProgress.swift`
- Delete: `PitchAtlas/Features/Companion/` (all 8 files), `PitchAtlas/Resources/Assets.xcassets/Blaze*.imageset` (7), `PitchAtlasTests/BlazeCompanionTests.swift`
- Modify: `AtlasView.swift` (54, 112), `IndexView.swift` (106, 145), `GripsView.swift` (91, 112), `CraftsmenView.swift` (28), `SourcesView.swift` (57), `AboutView.swift` (21, 33, 67-…), `PitchAtlasTheme.swift:92-93`
- Test: `PitchAtlasTests/ScrollProgressTests.swift` (new)

**Interfaces:**
- Produces: `@Observable final class ScrollProgressController { private(set) var progress: Double; func update(progress: Double) }`, `View.emitsScrollProgress()`, `TabScaffold<Content>(tab:content:)` (same call shape as today), environment value `ScrollProgressController` (Plan 3's Muybridge pitcher reads it).

- [ ] **Step 1: Write the failing tests** (the companion's two clamp tests move here; its other seven leave with it)

```swift
import XCTest
import UIKit
@testable import PitchAtlas

final class ScrollProgressTests: XCTestCase {
    func testProgressClampsBetweenZeroAndOne() {
        let c = ScrollProgressController()
        c.update(progress: -0.4); XCTAssertEqual(c.progress, 0)
        c.update(progress: 1.7); XCTAssertEqual(c.progress, 1)
        c.update(progress: 0.42); XCTAssertEqual(c.progress, 0.42, accuracy: 1e-9)
    }
    func testRapidChangesStayInsideTheClamp() {
        let c = ScrollProgressController()
        for v in stride(from: -2.0, through: 2.0, by: 0.05) { c.update(progress: v); XCTAssert((0...1).contains(c.progress)) }
    }
    func testProgressFromMetrics() {
        XCTAssertEqual(ScrollProgressController.progress(contentTop: -250, contentHeight: 1500, viewport: 1000), 0.5, accuracy: 1e-9)
        XCTAssertEqual(ScrollProgressController.progress(contentTop: 10, contentHeight: 1500, viewport: 1000), 0)
        XCTAssertEqual(ScrollProgressController.progress(contentTop: -100, contentHeight: 600, viewport: 1000), 1, "content shorter than the screen reads as fully seen once moved")
    }
    func testNoBlazeArtShipsInTheBundle() {
        for name in ["BlazeIdle", "BlazeChasing", "BlazeSniffing", "BlazeCaught", "BlazeConcerned", "BlazeNapping", "BlazeStill"] {
            XCTAssertNil(UIImage(named: name, in: Bundle(for: PitchStore.self), with: nil), name)
        }
    }
}
```
(`Bundle(for: PitchStore.self)` requires `PitchStore` to be a class — it is `@Observable final class`.)

- [ ] **Step 2: Run** the compile check. Expected: `cannot find 'ScrollProgressController' in scope`.

- [ ] **Step 3: Implement** `ScrollProgress.swift`:

```swift
import SwiftUI
import Observation

// =============================================================================
// Scroll progress — how far down its page a tab has been read, 0…1
// =============================================================================
// Preferences flow up to ancestors, never sideways, so the scroll content
// publishes its metrics and the TabScaffold (an ancestor of the scroll) turns
// them into 0…1 for anything below it that wants to move with the page — the
// Muybridge pitcher on Atlas. Nothing reads it to judge a visitor; it is a
// position, like a scrollbar.
// =============================================================================

enum ScrollProgressSpace { static let name = "pitchAtlasTabScroll" }

struct ScrollMetrics: Equatable {
    var contentTop: CGFloat = 0
    var contentHeight: CGFloat = 0
}

struct ScrollMetricsKey: PreferenceKey {
    static var defaultValue = ScrollMetrics()
    static func reduce(value: inout ScrollMetrics, nextValue: () -> ScrollMetrics) {
        let next = nextValue()
        if next.contentHeight > 0 { value = next }
    }
}

@Observable final class ScrollProgressController {
    private(set) var progress: Double = 0
    func update(progress: Double) { self.progress = min(1, max(0, progress)) }
    static func progress(contentTop: CGFloat, contentHeight: CGFloat, viewport: CGFloat) -> Double {
        let span = max(1, contentHeight - viewport)
        let scrolled = max(0, -contentTop)
        return min(1, Double(scrolled / span))
    }
}

private struct EmitScrollProgress: ViewModifier {
    func body(content: Content) -> some View {
        content.background(GeometryReader { geo in
            Color.clear.preference(key: ScrollMetricsKey.self,
                                   value: ScrollMetrics(contentTop: geo.frame(in: .named(ScrollProgressSpace.name)).minY,
                                                        contentHeight: geo.size.height))
        })
    }
}

extension View {
    /// Apply to a tab's scroll content so its read position reaches the TabScaffold.
    func emitsScrollProgress() -> some View { modifier(EmitScrollProgress()) }
}

/// Each tab's root: owns that tab's scroll progress and shares it below.
struct TabScaffold<Content: View>: View {
    let tab: AppTab
    @ViewBuilder var content: Content
    @State private var progress = ScrollProgressController()

    var body: some View {
        GeometryReader { outer in
            content
                .coordinateSpace(name: ScrollProgressSpace.name)
                .onPreferenceChange(ScrollMetricsKey.self) { m in
                    progress.update(progress: ScrollProgressController.progress(
                        contentTop: m.contentTop, contentHeight: m.contentHeight, viewport: outer.size.height))
                }
        }
        .environment(progress)
    }
}
```
Then: `git rm -r PitchAtlas/Features/Companion PitchAtlasTests/BlazeCompanionTests.swift PitchAtlas/Resources/Assets.xcassets/Blaze*.imageset`; replace every `.emitsBlazeScrollProgress()` with `.emitsScrollProgress()`; delete the three `BlazeInlineCompanionView(...)` lines (Atlas 112, Index 145, Grips 112) and anything that only laid them out; in `AboutView` delete the `@AppStorage(BlazeMotionSettings…)` property, the `companionSettingCard` call and its definition; delete `companionCoat` from the theme. Run `xcodegen generate`.

- [ ] **Step 4: Verify the absence** — `grep -rniE "blaze" PitchAtlas PitchAtlasTests project.yml` → Expected: no output. Then CI. Expected: `Executed 110 tests, with 0 failures` (117 − 9 + 4 = 112; adjust to what CI prints and record it).

- [ ] **Step 5: Commit** `refactor(app): retire the Blaze companion; keep tab scroll progress`

---

### Task 3: Component inks and the surfaces — panel, foil panel, hairline, kicker rule, stamp

**Files:**
- Create: `PitchAtlas/Core/Theme/ComponentInk.swift`, `PitchAtlas/Components/Surfaces.swift`
- Modify: `PitchAtlas/Components/PitchAtlasUI.swift` (`SectionLabel`, `HairlineDivider`, `LeatherPress`, `SpecimenCardFrame`), `PitchAtlas/Components/CardBackPanel.swift` (move `InkStamp` out)
- Test: `PitchAtlasTests/ComponentKitTests.swift` (new)

**Interfaces:**
- Produces: `ComponentInk.*` (all names below); `PanelSurface(radius:accent:)` view; `View.panelFoil(radius:)`; `Hairline` view; `SectionLabel(text:color:size:rule:)` with `rule: Bool = false`; `KickerLabel(text:)` = cyan kicker with the 22×2 rule; `InkStamp(text:color:)`; `leatherPress()` now renders `PanelSurface`.

- [ ] **Step 1: Write the failing tests**

```swift
import XCTest
import SwiftUI
@testable import PitchAtlas

@MainActor
final class ComponentKitTests: XCTestCase {
    func testKickerMetricsMatchTheWeb() {
        XCTAssertEqual(KickerLabel.ruleSize, CGSize(width: 22, height: 2))
        XCTAssertEqual(KickerLabel.gap, 9)
        XCTAssertEqual(KickerLabel.trackingEm, 0.2)
    }
    func testStampMetricsMatchTheWeb() {
        XCTAssertEqual(InkStamp.fontSize, 9)
        XCTAssertEqual(InkStamp.padding, EdgeInsets(top: 4, leading: 9, bottom: 4, trailing: 9))
        XCTAssertEqual(InkStamp.rotation, -1)
    }
    func testPanelCatchIsTheRenderedWhiteBand() {
        // :root .rfx-panel::before wins on the dark site (spec 10.1).
        XCTAssertEqual(PanelSurface.catchPeakOpacity, 0.4)
        XCTAssertEqual(PanelSurface.catchLayerOpacity, 0.55)
        XCTAssertEqual(PanelSurface.rimOpacity, 0.16)
    }
    func testSurfacesRender() {
        for view in [AnyView(PanelSurface().frame(width: 200, height: 100)),
                     AnyView(Text("x").panelFoil().frame(width: 200, height: 100)),
                     AnyView(KickerLabel(text: "The filed set")),
                     AnyView(InkStamp(text: "Filed")), AnyView(Hairline().frame(width: 200))] {
            XCTAssertNotNil(ImageRenderer(content: view).uiImage)
        }
    }
}
```

- [ ] **Step 2: Run** the compile check. Expected: `cannot find 'KickerLabel' in scope`.

- [ ] **Step 3: Implement.** `ComponentInk.swift` — every value is copied from the cited web rule (web `main@3f518f6`):

```swift
import SwiftUI

/// Colors the web writes inside component rules rather than @theme, each with
/// its rule. They live in the theme so the no-literal gate holds elsewhere.
enum ComponentInk {
    // Buttons — .v2-cta, .v2-cta--ghost, .btn-foil (index.css §1)
    static let chromeFaceTop = Color(hex: 0x17131D)
    static let chromeFaceBottom = Color(hex: 0x09070E)
    static let ghostFill = Color(hex: 0x0A0908, opacity: 0.55)
    static let sealFaceTop = Color(hex: 0x221B12)
    static let sealFaceBottom = Color(hex: 0x16120D)
    static let sealBorder = Color(hex: 0xC8102E, opacity: 0.55)
    static let sealHalo = Color(hex: 0xC8102E, opacity: 0.32)
    static let rosin = Color(hex: 0xF4EEE2)
    // Controls — .rfx-chip, .pi-toggle, filter panel, search, input, dialog, toast
    static let onCyanInk = Color(hex: 0x06121B)
    static let searchFill = Color(hex: 0x1D1710)
    static let searchIcon = Color(hex: 0xC2C7D6)
    static let inputFill = Color(hex: 0x0B0805)
    static let dialogFill = Color(hex: 0x0E0B15)
    static let filterPanelFill = Color(hex: 0x0E0B15, opacity: 0.5)
    // Card stock — .rfx-card, .rfx-field, .rfx-head, .rfx-stage, .rfx-read, .rfx-strip (index.css 938-1526)
    static let fieldBase = Color(hex: 0x0B0805)
    static let stageDeep = Color(hex: 0x060403)
    static let cardName = Color(hex: 0xFBF7EE)
    static let cardFileLabel = Color(hex: 0x9D927D)
    static let cardStrip = Color(hex: 0xD8CFB8)
    static let gripChipFill = Color(hex: 0x05070C, opacity: 0.8)
    static let readPaper = Color(hex: 0xEFE6D0)
    /// The web's #746B5D measures 4.22:1 on the paper; lifted the minimum to 4.60:1.
    static let readMeta = Color(hex: 0x6E655A)
    static let readCue = Color(hex: 0x37322A)
    static let readFact = Color(hex: 0x4A443A)
    static let readRule = Color(hex: 0x211D17, opacity: 0.16)
    static let readRuling = Color(hex: 0x4A443A, opacity: 0.055)
    static let edgeHairline = Color(hex: 0xB9C6CC, opacity: 0.4)
    static let edgeRing = Color(hex: 0x09090B)
    static let edgeStack: [Color] = [Color(hex: 0x35383C), Color(hex: 0x101114), Color(hex: 0x42464B), Color(hex: 0x08090B)]
    // Ember 1/1 — .rfx-card.is-gold (index.css 1527-1605)
    static let emberName = Color(hex: 0xFFD9B8)
    static let emberOverline = Color(hex: 0xE8C9A6)
    static let emberFileLabel = Color(hex: 0x8A6A4C)
    static let emberPaper = Color(hex: 0xF1E4C8)
    static let emberMeta = Color(hex: 0x6B4318)
    static let emberCue = Color(hex: 0x33261A)
    static let emberFact = Color(hex: 0x3A2A16)
    static let emberRing = Color(hex: 0x813B01)
    static let emberField: [Color] = [Color(hex: 0x0F0A06), Color(hex: 0x090604), Color(hex: 0x040302)]
    // Card back — .v2-back, .rfx-scout (index.css 3384-3418, 1607-1640)
    static let backTop = Color(hex: 0x15120F)
    static let backBottom = Color(hex: 0x0A0908)
    static let chaseBackTop = Color(hex: 0x1A100A)
    static let chaseBackBorder = Color(hex: 0x823D05)
    static let flipFill = Color(hex: 0x0A0908, opacity: 0.82)
    // Wall mount and compare — .v2-mount (index.css 3302-3332), compare.css 2-8, archive.css 174
    static let mountTop = Color(hex: 0x141210)
    static let mountBottom = Color(hex: 0x0A0908)
    static let selectedOutline = Color(hex: 0xC8A35C)
    static let compareFill = Color(hex: 0x171511)
    static let compareInk = Color(hex: 0xD9CCB3)
    static let compareBorder = Color(hex: 0x89724E, opacity: 0.5)
    static let compareOnFill = Color(hex: 0xEFE1BF)
    static let compareOnInk = Color(hex: 0x201C15)
    // Plate and row — .rfx-plate, .rfx-entry (index.css 1930-2018)
    static let plateBase = Color(hex: 0x1A140C)
    static let plateHoverBase = Color(hex: 0x1D1610)
    static let plateEnd = Color(hex: 0x100C07)
    static let filedBone = Color(hex: 0xD8CFB8)
    static let filedInk = Color(hex: 0x14110A)
    static let thumbFill = Color(hex: 0x14100B)
    static let seamMarkDisc = Color(hex: 0x17120C)
    static let legendTeal = Color(hex: 0x1F97A2)
    // Binder — .binder-sheet, .pocket*, .pocket-slip (index.css 2395-2632)
    static let sheetTop = Color(hex: 0x33210F)
    static let sheetBottom = Color(hex: 0x221507)
    static let holeCenter = Color(hex: 0x0A0805)
    static let pocketInnerTop = Color(hex: 0x14110D)
    static let pocketInnerBottom = Color(hex: 0x0E0B08)
    static let pocketNameFill = Color(hex: 0x17120C)
    static let pocketNameInk = Color(hex: 0xF2ECDD)
    static let pocketStatus = Color(hex: 0x8A8576)
    static let pocketStatusEdge = Color(hex: 0xFF6B77)
    static let slipPaper = Color(hex: 0xEDE3CC)
    static let slipInk = Color(hex: 0x211D17)
    static let slipEdgeStatus = Color(hex: 0xA8232F)
    static let slipEdgeRing = Color(hex: 0xC8102E, opacity: 0.55)
}
```

`Surfaces.swift`:

```swift
import SwiftUI

/// `.rfx-panel`: press ground, bone .10 hairline, the raking catch (white .4 band
/// at 20%, screen, .55) and a 16% accent rim. No hover, no motion — the web has none.
struct PanelSurface: View {
    static let catchPeakOpacity = 0.4
    static let catchLayerOpacity = 0.55
    static let rimOpacity = 0.16
    var radius: CGFloat = PitchAtlasRadius.panel
    var accent: Color = PitchAtlasTheme.cyan

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape.fill(PitchAtlasTheme.press)
            .overlay {
                shape.fill(LinearGradient(stops: [
                    .init(color: .clear, location: 0.06),
                    .init(color: .white.opacity(Self.catchPeakOpacity), location: 0.20),
                    .init(color: .clear, location: 0.40)],
                    startPoint: PitchAtlasMaterials.cssEndpoints(angle: 101, aspect: 2).start,
                    endPoint: PitchAtlasMaterials.cssEndpoints(angle: 101, aspect: 2).end))
                .blendMode(.screen).opacity(Self.catchLayerOpacity)
            }
            .overlay { shape.strokeBorder(accent.opacity(Self.rimOpacity), lineWidth: 1) }
            .overlay { shape.strokeBorder(PitchAtlasTheme.bone.opacity(0.10), lineWidth: 1) }
            .accessibilityHidden(true).allowsHitTesting(false)
    }
}

extension View {
    /// `.rfx-panel-foil`: a 1px still foil edge around a press-2 interior.
    func panelFoil(radius: CGFloat = PitchAtlasRadius.panel) -> some View {
        background(RoundedRectangle(cornerRadius: radius - 1, style: .continuous).fill(PitchAtlasTheme.press2))
            .padding(1)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(PitchAtlasMaterials.foil(aspect: 2)))
    }
}

/// The web hairline: machined .20 fading out from 64%.
struct Hairline: View {
    var body: some View {
        Rectangle().fill(LinearGradient(stops: [
            .init(color: PitchAtlasTheme.machined, location: 0),
            .init(color: PitchAtlasTheme.machined, location: 0.64),
            .init(color: .clear, location: 1)], startPoint: .leading, endPoint: .trailing))
        .frame(height: 1).accessibilityHidden(true)
    }
}

/// The section kicker: Martian 500, 11, .2em, cyan, led by a 22×2 rule.
struct KickerLabel: View {
    static let ruleSize = CGSize(width: 22, height: 2)
    static let gap: CGFloat = 9
    static let trackingEm: CGFloat = 0.2
    let text: String
    var body: some View {
        HStack(spacing: Self.gap) {
            Rectangle().fill(PitchAtlasTheme.kicker).frame(width: Self.ruleSize.width, height: Self.ruleSize.height)
                .accessibilityHidden(true)
            Text(text.uppercased()).font(PitchAtlasType.kicker)
                .tracking(em: Self.trackingEm, size: 11)
                .foregroundStyle(PitchAtlasTheme.kicker)
        }
        .accessibilityElement(children: .combine).accessibilityAddTraits(.isHeader)
    }
}

/// The web stamp: mono 9, .14em, 4×9 padding, 1px currentColor, radius 3, −1°.
struct InkStamp: View {
    static let fontSize: CGFloat = 9
    static let padding = EdgeInsets(top: 4, leading: 9, bottom: 4, trailing: 9)
    static let rotation: Double = -1
    let text: String
    var color: Color = PitchAtlasTheme.bone2
    var body: some View {
        Text(text.uppercased())
            .font(PitchAtlasType.font(.martian400, size: Self.fontSize, relativeTo: .caption2))
            .tracking(em: 0.14, size: Self.fontSize)
            .foregroundStyle(color)
            .padding(Self.padding)
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(color, lineWidth: 1))
            .rotationEffect(.degrees(Self.rotation))
    }
}
```
If `PitchAtlasTheme.press2` does not exist yet, add `static let press2 = Color(web: WebTokens.Palette.press2)` to the theme (the token is generated). `LeatherPress` and `SpecimenCardFrame` change their background from `ArchiveCoverSurface(radius:)` to `PanelSurface(radius:)`. `HairlineDivider` body becomes `Hairline()`. `SectionLabel` keeps its API and `tracking(2)` becomes `.tracking(em: 0.18, size: size)` (`.mono-label`). Remove `InkStamp` from `CardBackPanel.swift`.

- [ ] **Step 4: Run** compile check, `scripts/check-no-color-literals.sh` (Expected: exit 0), CI. Expected: all tests pass.

- [ ] **Step 5: Commit** `feat(components): panel, foil panel, hairline, kicker and stamp from the web kit`

---

### Task 4: Buttons — chrome, ghost, wax seal, chapter, link; the rosin puff

**Files:**
- Create: `PitchAtlas/Components/Buttons.swift`
- Modify: `PitchAtlas/Features/Study/CompareSelection.swift` (`CompareButton` → web compare button)
- Test: `PitchAtlasTests/ComponentKitTests.swift`

**Interfaces:**
- Produces: `PitchButtonStyle(_ kind: PitchButtonKind)` where `enum PitchButtonKind { case chrome, ghost, waxSeal, chapter(fill: UInt32), link }`; `ButtonStyle` extension `.pitch(_:)`; `RosinPuff.grain(_ index: Int, at t: Double) -> RosinGrain?` (pure); `PitchButtonKind.minHitHeight == 44`; `CompareButton(slug:)` unchanged signature.

- [ ] **Step 1: Write the failing tests**

```swift
func testEveryButtonKeepsA44ptHitArea() {
    for kind: PitchButtonKind in [.chrome, .ghost, .waxSeal, .chapter(fill: 0xB9D4E5), .link] {
        XCTAssertGreaterThanOrEqual(kind.minHitHeight, 44)
    }
}
func testChapterButtonInkComesFromAccentButton() {
    XCTAssertEqual(PitchButtonKind.chapter(fill: 0x5B7F96).colors.fill, 0x63859B, "forkball lifts one 5% step")
    XCTAssertEqual(PitchButtonKind.chapter(fill: 0xBF5700).colors.ink, 0xFFFFFF)
    XCTAssertEqual(PitchButtonKind.chapter(fill: 0xB9D4E5).colors.ink, 0x06121B)
}
func testRosinGrainsFallAndFade() {
    let early = RosinPuff.grain(3, at: 0.05)!, late = RosinPuff.grain(3, at: 0.4)
    XCTAssertGreaterThan(early.alpha, late?.alpha ?? 0)
    XCTAssertNil(RosinPuff.grain(3, at: 0.9), "every grain is gone by 0.85s")
    XCTAssertEqual(RosinPuff.grainCount, 30)
    XCTAssertEqual(RosinPuff.duration, 0.8)
}
func testRosinPuffIsDeterministic() {
    XCTAssertEqual(RosinPuff.grain(7, at: 0.2), RosinPuff.grain(7, at: 0.2))
}
```

- [ ] **Step 2: Run** compile check. Expected: `cannot find 'PitchButtonKind' in scope`.

- [ ] **Step 3: Implement** `Buttons.swift`:

```swift
import SwiftUI

enum PitchButtonKind: Equatable {
    case chrome, ghost, waxSeal, chapter(fill: UInt32), link
    var minHitHeight: CGFloat { 44 }
    var colors: (fill: UInt32, ink: UInt32) {
        if case .chapter(let fill) = self {
            let pair = PitchAccents.accentButton(fill: fill)
            return (pair.background, pair.foreground)
        }
        return (0, 0)
    }
}

/// The web's button kinds (spec §1). Chrome is the one rosin-dusted primary per
/// view; ghost is its quiet partner; the wax seal is for About and Not Found only.
struct PitchButtonStyle: ButtonStyle {
    let kind: PitchButtonKind
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var puffs: [UUID] = []

    func makeBody(configuration: Configuration) -> some View {
        label(configuration)
            .frame(minHeight: kind.minHitHeight)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(PitchAtlasMotion.animation(PitchAtlasMotion.tiny, reduceMotion: reduceMotion), value: configuration.isPressed)
            .overlay {
                if kind == .chrome && !reduceMotion {
                    ZStack { ForEach(puffs, id: \.self) { _ in RosinPuffView() } }.allowsHitTesting(false)
                }
            }
            .onChange(of: configuration.isPressed) { _, pressed in
                guard pressed, kind == .chrome, !reduceMotion else { return }
                let id = UUID(); puffs.append(id)
                DispatchQueue.main.asyncAfter(deadline: .now() + RosinPuff.duration) { puffs.removeAll { $0 == id } }
            }
    }

    @ViewBuilder private func label(_ c: Configuration) -> some View {
        switch kind {
        case .chrome:
            c.label.font(PitchAtlasType.chromeCTA).tracking(em: 0.14, size: 11).textCase(.uppercase)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.horizontal, 20).padding(.vertical, 11)
                .background {
                    Capsule().fill(LinearGradient(colors: [ComponentInk.chromeFaceTop, ComponentInk.chromeFaceBottom],
                                                  startPoint: .top, endPoint: .bottom))
                        .overlay { Capsule().strokeBorder(PitchAtlasMaterials.foil(aspect: 4), lineWidth: 1) }
                        .overlay { Capsule().inset(by: 1).stroke(Color.white.opacity(0.16), lineWidth: 0.5).offset(y: 0.5).mask(Capsule()) }
                        .overlay { Capsule().fill(LinearGradient(stops: [.init(color: .clear, location: 0.1), .init(color: .white.opacity(0.45), location: 0.22), .init(color: .clear, location: 0.34)], startPoint: .leading, endPoint: .trailing)).blendMode(.screen).opacity(0.6) }
                        .shadow(color: .black.opacity(0.9), radius: 11, y: 8)
                        .shadow(color: PitchAtlasTheme.cyan.opacity(0.35), radius: 12)
                }
        case .ghost:
            c.label.font(PitchAtlasType.chromeCTA).tracking(em: 0.14, size: 11).textCase(.uppercase)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.horizontal, 20).padding(.vertical, 11)
                .background { Capsule().fill(ComponentInk.ghostFill).overlay { Capsule().strokeBorder(PitchAtlasTheme.bone.opacity(0.4), lineWidth: 1) } }
        case .waxSeal:
            c.label.font(PitchAtlasType.font(.anton400, size: 14, relativeTo: .callout)).tracking(em: 0.06, size: 14).textCase(.uppercase)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.horizontal, 22).padding(.vertical, 13)
                .background {
                    RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [ComponentInk.sealFaceTop, ComponentInk.sealFaceBottom], startPoint: .top, endPoint: .bottom))
                        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(ComponentInk.sealBorder, lineWidth: 1) }
                        .padding(-3).overlay { RoundedRectangle(cornerRadius: 13).strokeBorder(PitchAtlasTheme.bone, lineWidth: 3) }
                        .padding(-4).overlay { RoundedRectangle(cornerRadius: 17).strokeBorder(ComponentInk.sealHalo, lineWidth: 4) }
                }
        case .chapter(let fill):
            let pair = PitchAccents.accentButton(fill: fill)
            c.label.font(PitchAtlasType.font(.martian500, size: 14, relativeTo: .callout))
                .foregroundStyle(Color(rgb: pair.foreground))
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(rgb: pair.background)))
        case .link:
            c.label.font(PitchAtlasType.font(.martian600, size: 11, relativeTo: .caption)).tracking(em: 0.14, size: 11).textCase(.uppercase)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .opacity(c.isPressed ? 0.7 : 1)
        }
    }
}

extension ButtonStyle where Self == PitchButtonStyle {
    static func pitch(_ kind: PitchButtonKind) -> PitchButtonStyle { PitchButtonStyle(kind: kind) }
}

struct RosinGrain: Equatable { let x: Double; let y: Double; let radius: Double; let alpha: Double }

/// The web's rosin puff (spec Appendix C), with a fixed seed so it is repeatable.
enum RosinPuff {
    static let grainCount = 30
    static let duration = 0.8
    static let box: CGFloat = 180
    private static func unit(_ i: Int, _ salt: Int) -> Double {
        let v = sin(Double(i * 127 + salt * 311) * 12.9898) * 43758.5453
        return v - floor(v)
    }
    static func grain(_ i: Int, at t: Double) -> RosinGrain? {
        let a = unit(i, 1) * 2 * .pi, v = 28 + unit(i, 2) * 90
        let vx = cos(a) * v, vy = sin(a) * v * 0.6 - 38
        let r = 0.45 + unit(i, 3) * 1.15, life = 0.5 + unit(i, 4) * 0.35
        let u = t / life
        guard u < 1 else { return nil }
        let travel = (1 - exp(-3.2 * t)) / 3.2
        return RosinGrain(x: 90 + vx * travel, y: 90 + vy * travel + 46 * t * t, radius: r, alpha: 0.8 * (1 - u) * (1 - u))
    }
}

private struct RosinPuffView: View {
    @State private var start = Date()
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince(start)
            Canvas { ctx, _ in
                let k = min(t / RosinPuff.duration, 1)
                let cloud = Path(ellipseIn: CGRect(x: 90 - (10 + 40 * k), y: 80 - 10 * k, width: 2 * (10 + 40 * k), height: 2 * (10 + 40 * k)))
                ctx.fill(cloud, with: .radialGradient(Gradient(colors: [ComponentInk.rosin.opacity(0.2 * (1 - k)), .clear]),
                                                      center: CGPoint(x: 90, y: 90 - 10 * k), startRadius: 0, endRadius: 10 + 40 * k))
                for i in 0..<RosinPuff.grainCount {
                    guard let g = RosinPuff.grain(i, at: t) else { continue }
                    ctx.fill(Path(ellipseIn: CGRect(x: g.x - g.radius, y: g.y - g.radius, width: 2 * g.radius, height: 2 * g.radius)),
                             with: .color(PitchAtlasTheme.bone.opacity(g.alpha)))
                }
            }
            .frame(width: RosinPuff.box, height: RosinPuff.box)
        }
        .accessibilityHidden(true)
    }
}
```
`CompareButton` becomes the web compare button (36pt painted, 44pt hit, radius 6, Hanken 600 12; on = cream):

```swift
struct CompareButton: View {
    let slug: String
    @Environment(\.compareSelection) private var selection
    var body: some View {
        let on = selection.slugs.contains(slug)
        Button { selection.add(slug); Haptics.selection() } label: {
            Label(on ? "In comparison" : "Compare", systemImage: "square.split.2x1")
                .font(PitchAtlasType.font(.hanken600, size: 12, relativeTo: .caption))
                .foregroundStyle(on ? ComponentInk.compareOnInk : ComponentInk.compareInk)
                .padding(.horizontal, 12.8).frame(minHeight: 36)
                .background(RoundedRectangle(cornerRadius: 6).fill(on ? ComponentInk.compareOnFill : ComponentInk.compareFill))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(on ? ComponentInk.selectedOutline : ComponentInk.compareBorder, lineWidth: 1))
                .frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(on ? "In comparison" : "")
    }
}
```

- [ ] **Step 4: Run** compile check, literal gate, CI. Expected: all pass.

- [ ] **Step 5: Commit** `feat(components): the web's button kinds and the rosin puff`

---

### Task 5: Chips and toggles — tag chip, filter chip, ROWS/BINDER pill toggle, VIEW/HAND segment, Filter & sort pill

**Files:**
- Create: `PitchAtlas/Components/Controls.swift`
- Modify: `PitchAtlas/Features/Index/IndexView.swift` (delete private `FilterChip`, use `PitchChip(.filter)`)
- Test: `PitchAtlasTests/ComponentKitTests.swift`

**Interfaces:**
- Produces: `enum ChipKind { case tag, filter }`; `struct ChipAppearance { fill: Color?; ink: Color; border: Color; weight: PitchAtlasType.Face }` with `static func of(_ kind: ChipKind, selected: Bool) -> ChipAppearance`; `PitchChip(label:kind:selected:dot:action:)`; `PillToggle<Value: Hashable>(selection:options:)` where options are `[(value: Value, label: String, systemImage: String)]`; `SegmentToggle<Value: Hashable>(selection:options:)` with `[(value: Value, label: String)]`; `FilterSortPill(isOpen:activeCount:action:)`.

- [ ] **Step 1: Write the failing tests**

```swift
func testTagChipIsCyanWhenOnAndBoneWhenOff() {
    let on = ChipAppearance.of(.tag, selected: true), off = ChipAppearance.of(.tag, selected: false)
    XCTAssertEqual(on.fill, PitchAtlasTheme.cyan); XCTAssertEqual(on.ink, ComponentInk.onCyanInk); XCTAssertEqual(on.weight, .martian600)
    XCTAssertNil(off.fill); XCTAssertEqual(off.ink, PitchAtlasTheme.bone); XCTAssertEqual(off.border, PitchAtlasTheme.cyan.opacity(0.4))
}
func testFilterChipIsBurntWithWhiteInkWhenOn() {
    let on = ChipAppearance.of(.filter, selected: true)
    XCTAssertEqual(on.fill, Color(rgb: WebTokens.Accent.burnt)); XCTAssertEqual(on.ink, Color(rgb: WebTokens.Palette.white.rgb))
}
func testControlsKeep44ptHitAreas() {
    XCTAssertGreaterThanOrEqual(PitchChip.hitHeight, 44)
    XCTAssertGreaterThanOrEqual(PillToggle<Int>.hitHeight, 44)
    XCTAssertGreaterThanOrEqual(SegmentToggle<Int>.hitHeight, 44)
    XCTAssertGreaterThanOrEqual(FilterSortPill.hitHeight, 44)
}
func testFilterPillCountsActiveFilters() {
    XCTAssertEqual(FilterSortPill.title(activeCount: 0), "Filter & sort")
    XCTAssertEqual(FilterSortPill.title(activeCount: 2), "Filter & sort (2)")
}
```

- [ ] **Step 2: Run** compile check. Expected: `cannot find 'ChipAppearance' in scope`.

- [ ] **Step 3: Implement** `Controls.swift`:

```swift
import SwiftUI

enum ChipKind { case tag, filter }

/// `.rfx-chip` (tag: cyan) and the Index filter-panel chip (filter: burnt).
struct ChipAppearance {
    let fill: Color?
    let ink: Color
    let border: Color
    let weight: PitchAtlasType.Face
    static func of(_ kind: ChipKind, selected: Bool) -> ChipAppearance {
        switch (kind, selected) {
        case (.tag, true): ChipAppearance(fill: PitchAtlasTheme.cyan, ink: ComponentInk.onCyanInk, border: .clear, weight: .martian600)
        case (.tag, false): ChipAppearance(fill: nil, ink: PitchAtlasTheme.bone, border: PitchAtlasTheme.cyan.opacity(0.4), weight: .martian400)
        case (.filter, true): ChipAppearance(fill: Color(rgb: WebTokens.Accent.burnt), ink: Color(rgb: WebTokens.Palette.white.rgb), border: .clear, weight: .martian500)
        case (.filter, false): ChipAppearance(fill: nil, ink: PitchAtlasTheme.bone2, border: Color.white.opacity(0.14), weight: .martian400)
        }
    }
}

struct PitchChip: View {
    static let hitHeight: CGFloat = 44
    let label: String
    var kind: ChipKind = .tag
    let selected: Bool
    var dot: Color? = nil
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let look = ChipAppearance.of(kind, selected: selected)
        Button(action: action) {
            HStack(spacing: 6) {
                if let dot { FamilyDot(color: dot, size: 6) }
                Text(label.uppercased()).font(PitchAtlasType.font(look.weight, size: 9.5, relativeTo: .caption2)).tracking(em: 0.1, size: 9.5)
            }
            .foregroundStyle(look.ink)
            .padding(.horizontal, kind == .tag ? 13 : 12).padding(.vertical, kind == .tag ? 7 : 6)
            .frame(minHeight: kind == .filter ? 32 : nil)
            .background { if let f = look.fill { Capsule().fill(f) } }
            .overlay { Capsule().strokeBorder(look.border, lineWidth: 1) }
            .frame(minHeight: Self.hitHeight).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(PitchAtlasMotion.animation(PitchAtlasMotion.short, reduceMotion: reduceMotion), value: selected)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}

/// `.pi-toggle` — the Index ROWS/BINDER group. On = burnt with white ink.
struct PillToggle<Value: Hashable>: View {
    static var hitHeight: CGFloat { 44 }
    @Binding var selection: Value
    let options: [(value: Value, label: String, systemImage: String)]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { o in
                let on = o.value == selection
                Button { selection = o.value; Haptics.selection() } label: {
                    Label(o.label.uppercased(), systemImage: o.systemImage)
                        .font(PitchAtlasType.font(.martian500, size: 12, relativeTo: .caption)).tracking(em: 0.06, size: 12)
                        .foregroundStyle(on ? Color(rgb: WebTokens.Palette.white.rgb) : PitchAtlasTheme.bone)
                        .padding(.horizontal, 10).frame(height: 32)
                        .background { if on { Capsule().fill(Color(rgb: WebTokens.Accent.burnt)) } }
                        .frame(minHeight: Self.hitHeight).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.horizontal, 2)
        .background(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1).frame(height: 38))
    }
}

/// `.rfx-seg` — the specimen VIEW and HAND toggles. On = cyan, on-cyan ink, inset lip.
struct SegmentToggle<Value: Hashable>: View {
    static var hitHeight: CGFloat { 44 }
    @Binding var selection: Value
    let options: [(value: Value, label: String)]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { o in
                let on = o.value == selection
                Button { selection = o.value; Haptics.selection() } label: {
                    Text(o.label.uppercased())
                        .font(PitchAtlasType.segment).tracking(em: 0.06, size: 12)
                        .foregroundStyle(on ? ComponentInk.onCyanInk : PitchAtlasTheme.bone)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background { if on { RoundedRectangle(cornerRadius: 9).fill(PitchAtlasTheme.cyan)
                            .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.35)).frame(height: 1).padding(.horizontal, 4) } } }
                        .frame(minHeight: Self.hitHeight).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(PitchAtlasTheme.bone.opacity(0.25), lineWidth: 1).padding(.vertical, 4))
    }
}

/// The Index "Filter & sort" pill: 36pt painted, 44pt hit; burnt rim when open.
struct FilterSortPill: View {
    static let hitHeight: CGFloat = 44
    static func title(activeCount: Int) -> String { activeCount > 0 ? "Filter & sort (\(activeCount))" : "Filter & sort" }
    let isOpen: Bool
    let activeCount: Int
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(Self.title(activeCount: activeCount).uppercased(), systemImage: "slider.horizontal.3")
                .font(PitchAtlasType.chip).tracking(em: 0.1, size: 9.5)
                .foregroundStyle(isOpen ? PitchAtlasTheme.bone : PitchAtlasTheme.bone2)
                .padding(.horizontal, 14).frame(height: 36)
                .overlay(Capsule().strokeBorder(isOpen ? Color(rgb: WebTokens.Accent.burnt) : Color.white.opacity(0.14), lineWidth: 1))
                .frame(minHeight: Self.hitHeight).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOpen ? "Open" : "Closed")
    }
}
```
In `IndexView`, replace each `FilterChip(label:dot:selected:action:)` with `PitchChip(label:kind: .filter, selected:dot:action:)` and delete the private `FilterChip`. (Whether the Index chips sit inside a collapsed panel behind `FilterSortPill` is Plan 3's screen work.)

- [ ] **Step 4: Run** compile check, literal gate, CI. Expected: pass.

- [ ] **Step 5: Commit** `feat(components): tag and filter chips, pill and segment toggles, filter pill`

---

### Task 6: Fields, select, dialog, toast

**Files:**
- Create: `PitchAtlas/Components/Fields.swift`
- Modify: `PitchAtlas/Components/PitchAtlasUI.swift` (`PitchTextFieldSurface`, `PitchMenuField` visuals), `IndexView.swift:150-170`, `GripsView.swift:120-130`, `SourcesView.swift:180-200` (adopt `PitchSearchField`), `PitchAtlas/App/PitchAtlasApp.swift` (inject `ToastCenter`, add `ToastHost`)
- Test: `PitchAtlasTests/ComponentKitTests.swift`

**Interfaces:**
- Produces: `PitchSearchField(text:prompt:)`; `@Observable final class ToastCenter { var current: Toast?; func show(_ message: String, duration: TimeInterval = 4) }`, `struct Toast: Identifiable, Equatable { id; message }`; `ToastHost` overlay; `View.pitchDialog(isPresented:title:description:content:)`.

- [ ] **Step 1: Write the failing tests**

```swift
func testToastShowsThenClearsItself() async throws {
    let center = ToastCenter()
    center.show("Sent for review", duration: 0.05)
    XCTAssertEqual(center.current?.message, "Sent for review")
    try await Task.sleep(nanoseconds: 200_000_000)
    XCTAssertNil(center.current)
}
func testANewerToastIsNotClearedByAnOlderTimer() async throws {
    let center = ToastCenter()
    center.show("first", duration: 0.05); center.show("second", duration: 0.5)
    try await Task.sleep(nanoseconds: 150_000_000)
    XCTAssertEqual(center.current?.message, "second")
}
func testSearchFieldMetricsMatchTheWeb() {
    XCTAssertEqual(PitchSearchField.height, 44); XCTAssertEqual(PitchSearchField.radius, 14)
}
```

- [ ] **Step 2: Run** compile check. Expected: `cannot find 'ToastCenter' in scope`.

- [ ] **Step 3: Implement** `Fields.swift`:

```swift
import SwiftUI
import Observation

/// Search: 44pt, radius 14, cyan .40 rim, #1D1710 fill, Hanken 15, a 16pt icon,
/// clear button; focus adds a 3px cyan .5 ring.
struct PitchSearchField: View {
    static let height: CGFloat = 44
    static let radius: CGFloat = 14
    @Binding var text: String
    let prompt: String
    @FocusState private var focused: Bool
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.system(size: 16)).foregroundStyle(ComponentInk.searchIcon).accessibilityHidden(true)
            TextField("", text: $text, prompt: Text(prompt).foregroundStyle(PitchAtlasTheme.placeholder))
                .font(PitchAtlasType.body(size: 15)).foregroundStyle(PitchAtlasTheme.bone)
                .focused($focused).submitLabel(.search).autocorrectionDisabled()
                .accessibilityLabel(prompt)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 16)).foregroundStyle(ComponentInk.searchIcon)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, 14)
        .frame(minHeight: Self.height)
        .background(RoundedRectangle(cornerRadius: Self.radius, style: .continuous).fill(ComponentInk.searchFill))
        .overlay(RoundedRectangle(cornerRadius: Self.radius, style: .continuous).strokeBorder(PitchAtlasTheme.cyan.opacity(focused ? 1 : 0.4), lineWidth: 1))
        .overlay { if focused { RoundedRectangle(cornerRadius: Self.radius + 3, style: .continuous).strokeBorder(PitchAtlasTheme.cyan.opacity(0.5), lineWidth: 3).padding(-3) } }
        .tint(PitchAtlasTheme.cyan)
    }
}

struct Toast: Identifiable, Equatable { let id = UUID(); let message: String }

/// One toast at a time, bottom-center, 4s — spoken to VoiceOver and felt as the success haptic.
@Observable final class ToastCenter {
    private(set) var current: Toast?
    func show(_ message: String, duration: TimeInterval = 4) {
        let toast = Toast(message: message)
        current = toast
        UIAccessibility.post(notification: .announcement, argument: message)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if self?.current?.id == toast.id { self?.current = nil }
        }
    }
}

struct ToastHost: ViewModifier {
    @Environment(ToastCenter.self) private var center
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast = center.current {
                Text(toast.message).font(PitchAtlasType.body(size: 14)).foregroundStyle(PitchAtlasTheme.bone)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 10).fill(ComponentInk.dialogFill))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(PitchAtlasTheme.bone.opacity(0.12), lineWidth: 1))
                    .padding(.horizontal, 16).padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .id(toast.id)
                    .accessibilityHidden(true) // already announced
            }
        }
        .animation(PitchAtlasMotion.animation(PitchAtlasMotion.short, reduceMotion: reduceMotion), value: center.current)
    }
}

extension View {
    func toastHost() -> some View { modifier(ToastHost()) }

    /// The web dialog: #0E0B15, radius 14, bone .10 ring, Anton 16 title, Hanken 14 description.
    func pitchDialog<C: View>(isPresented: Binding<Bool>, title: String, description: String, @ViewBuilder content: @escaping () -> C) -> some View {
        sheet(isPresented: isPresented) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title.uppercased()).font(PitchAtlasType.font(.anton400, size: 16, relativeTo: .headline)).foregroundStyle(PitchAtlasTheme.bone)
                    .accessibilityAddTraits(.isHeader)
                Text(description).font(PitchAtlasType.body(size: 14)).foregroundStyle(PitchAtlasTheme.ink2)
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .presentationDetents([.medium])
            .presentationBackground(ComponentInk.dialogFill)
            .presentationCornerRadius(14)
        }
    }
}
```
`PitchTextFieldSurface`: radius `PitchAtlasRadius.input`, fill `ComponentInk.inputFill`, horizontal 16 / vertical 12, cyan .40 border. `PitchMenuField`: radius `PitchAtlasRadius.select`, fill `ComponentInk.inputFill`, label in `PitchAtlasType.font(.martian400, size: 13, relativeTo: .callout)`, padding leading 13 / trailing 34 / vertical 9, chevron `chevron.down` cyan, `minHeight: 44`. Swap the three hand-built search rows for `PitchSearchField(text: $query, prompt: <their existing prompt string>)`. In `PitchAtlasApp`, `@State private var toasts = ToastCenter()`, `.environment(toasts)` and `.toastHost()` on the root `TabView`.

- [ ] **Step 4: Run** compile check, literal gate, CI. Expected: pass.

- [ ] **Step 5: Commit** `feat(components): search field, input and select surfaces, dialog, toast`

---

### Task 7: Trust marks — ConfidenceDot, the approx pill, ScoutRow

**Files:**
- Modify: `PitchAtlas/Components/ProvenanceViews.swift` (`ProvenanceDot` body → `ConfidenceDot`; add `ApproxPill`, `ScoutRow`, `ScoutRows`)
- Test: `PitchAtlasTests/ComponentKitTests.swift`

**Interfaces:**
- Produces: `ConfidenceDot(confidence: ClaimConfidence, approximate: Bool = false)` (dot 8 + 9pt glow + mono 10 label in bone-2, gap 8); `ApproxPill()` ("≈ approx"); `ScoutRow(label:value:tier:approximate:)`; `ScoutRows(accent: Color) { rows }` — even rows tinted accent .14, 1px bone .06 between rows, radius 7, bone .08 border; `ConfidenceDot.accessibilityText(for:approximate:) -> String`.

- [ ] **Step 1: Write the failing tests**

```swift
func testConfidenceDotAlwaysSaysItsWords() {
    for c in ClaimConfidence.allCases {
        let text = ConfidenceDot.accessibilityText(for: c, approximate: false)
        XCTAssertTrue(text.contains(c.label), "\(c) must speak its label")
    }
    XCTAssertTrue(ConfidenceDot.accessibilityText(for: .unverified, approximate: true).hasSuffix("approximate"))
}
func testScoutRowsTintEvenRowsOnly() {
    XCTAssertFalse(ScoutRows<EmptyView>.isTinted(index: 0))
    XCTAssertTrue(ScoutRows<EmptyView>.isTinted(index: 1))
    XCTAssertEqual(ScoutRows<EmptyView>.tintOpacity, 0.14)
    XCTAssertEqual(ScoutRow.keyWidth, 56)
}
```
(If `ClaimConfidence` is not `CaseIterable`, add the conformance — the type has seven fixed cases.)

- [ ] **Step 2: Run** compile check. Expected: `cannot find 'ConfidenceDot' in scope`.

- [ ] **Step 3: Implement** (append to `ProvenanceViews.swift`):

```swift
/// The web ConfidenceDot: an 8pt tier dot with a 9pt glow, then the tier's words
/// in mono 10 at .1em, bone-2. The dot never stands alone.
struct ConfidenceDot: View {
    let confidence: ClaimConfidence
    var approximate = false
    static func accessibilityText(for c: ClaimConfidence, approximate: Bool) -> String {
        "Source: \(c.label)" + (approximate ? ", approximate" : "")
    }
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PitchAtlasTheme.color(forConfidence: confidence.rawValue)).frame(width: 8, height: 8)
                .shadow(color: PitchAtlasTheme.color(forConfidence: confidence.rawValue), radius: 4.5)
            Text(confidence.label.uppercased()).font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                .tracking(em: 0.1, size: 10).foregroundStyle(PitchAtlasTheme.text2)
            if approximate { ApproxPill() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityText(for: confidence, approximate: approximate))
    }
}

struct ApproxPill: View {
    var body: some View {
        Text("≈ approx").font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
            .foregroundStyle(PitchAtlasTheme.text2)
            .padding(.horizontal, 6).padding(.vertical, 1)
            .overlay(Capsule().strokeBorder(PitchAtlasTheme.text3, lineWidth: 1))
    }
}

/// One scout-file row: a 56pt mono key and the value; a tier, when given, prints as a ConfidenceDot.
struct ScoutRow: View {
    static let keyWidth: CGFloat = 56
    let label: String
    let value: String
    var tier: ClaimConfidence? = nil
    var approximate = false
    var accent: Color = PitchAtlasTheme.bone2
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text(label.uppercased()).font(PitchAtlasType.font(.martian400, size: 8, relativeTo: .caption2)).tracking(em: 0.12, size: 8)
                .foregroundStyle(accent).frame(width: Self.keyWidth, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(PitchAtlasType.body(size: 12)).foregroundStyle(PitchAtlasTheme.bone).lineLimit(3)
                if let tier {
                    HStack(spacing: 6) {
                        Circle().fill(PitchAtlasTheme.color(forConfidence: tier.rawValue)).frame(width: 6, height: 6)
                        Text(tier.label.uppercased() + (approximate ? " · approx" : ""))
                            .font(PitchAtlasType.font(.martian400, size: 8, relativeTo: .caption2)).tracking(em: 0.1, size: 8)
                            .foregroundStyle(PitchAtlasTheme.bone2)
                    }
                }
            }
        }
        .padding(.horizontal, 9).padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct ScoutRows<Content: View>: View {
    static var tintOpacity: Double { 0.14 }
    static func isTinted(index: Int) -> Bool { index % 2 == 1 }
    let accent: Color
    let rows: [AnyView]
    init(accent: Color, rows: [AnyView]) where Content == EmptyView { self.accent = accent; self.rows = rows }
    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { i in
                rows[i]
                    .background(Self.isTinted(index: i) ? accent.opacity(Self.tintOpacity) : .clear)
                    .overlay(alignment: .top) { if i > 0 { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.06)).frame(height: 1) } }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(PitchAtlasTheme.bone.opacity(0.08), lineWidth: 1))
    }
}
```
`ProvenanceDot`'s body becomes `ConfidenceDot(confidence:)` (callers keep compiling).

- [ ] **Step 4: Run** compile check, CI. Expected: pass.

- [ ] **Step 5: Commit** `feat(provenance): confidence dot with its words, approx pill, scout rows`

---

### Task 8: The card model — metrics, frame, content, lean, arched window

**Files:**
- Create: `PitchAtlas/Components/Cards/SpecimenCardModel.swift`
- Modify: `PitchAtlas/Core/Data/PitchStore.swift` (add `gripEntry(forSpecimen:)`)
- Test: `PitchAtlasTests/SpecimenCardModelTests.swift` (new)

**Interfaces:**
- Produces:
  - `struct SpecimenCardMetrics { init(width: CGFloat, frame: CardFrame); u, height, stockPadding, fieldPadding: EdgeInsets, headPadding: EdgeInsets, overlineSize, nameSize, numberSize, stageTopRX, stageTopRY, stageBottomR, chipSize, chipInset, readMarginTop, readPadding: EdgeInsets, readRadius, readGap, readRuleStep, readMetaSize, cueSize, factSize, dotSize, stripSize, stripTop }`
  - `enum CardFrame { case standard, ember, powder, teal; static func of(slug: String, grade: SpecimenGradeKey) -> CardFrame }`
  - `enum CardFace: Equatable { case film(GripFilm), photo(VisualReference), schematic }`
  - `struct SpecimenCardContent: Equatable { slug, name, vnum, family: PitchFamily, frame, triad: WebAccent, face: CardFace, chipLabel: String, chipIsAustin: Bool, cue: String, cueTier: ClaimConfidence, approximate: Bool; static func make(entry: PitchAtlasEntry, grip: GripEntry?) -> SpecimenCardContent; var accessibilityLabel: String }`
  - `enum CardLean { static func rest(index: Int) -> Double; static let hero: Double = -0.28 }`
  - `struct ArchedWindow: Shape { topRX, topRY, bottomR }`
  - `PitchStore.gripEntry(forSpecimen slug: String) -> GripEntry?`

- [ ] **Step 1: Write the failing tests**

```swift
import XCTest
import SwiftUI
@testable import PitchAtlas

final class SpecimenCardModelTests: XCTestCase {
    func testMetricsAt360MatchTheWebUnitTable() {
        let m = SpecimenCardMetrics(width: 360, frame: .standard)
        XCTAssertEqual(m.u, 3.6, accuracy: 1e-9)
        XCTAssertEqual(m.height, 504, accuracy: 1e-9)
        XCTAssertEqual(m.nameSize, 25.92, accuracy: 0.01)
        XCTAssertEqual(m.numberSize, 18.72, accuracy: 0.01)
        XCTAssertEqual(m.overlineSize, 7.2, accuracy: 0.01)
        XCTAssertEqual(m.cueSize, 14.04, accuracy: 0.01)
        XCTAssertEqual(m.stageTopRX, 78.01, accuracy: 0.01)
        XCTAssertEqual(m.stageTopRY, 82.8, accuracy: 0.01)
        XCTAssertEqual(m.stageBottomR, 14.0, accuracy: 0.01)
        XCTAssertEqual(m.readMetaSize, 7.38, accuracy: 0.01)
        XCTAssertEqual(m.stockPadding, 13)
        XCTAssertEqual(SpecimenCardMetrics(width: 360, frame: .ember).stockPadding, 16)
    }
    func testMicroTypeFloorsHoldOnSmallCards() {
        let m = SpecimenCardMetrics(width: 200, frame: .standard)   // u = 2
        XCTAssertEqual(m.overlineSize, 7); XCTAssertEqual(m.chipSize, 7)
        XCTAssertEqual(m.factSize, 8); XCTAssertEqual(m.stripSize, 8); XCTAssertEqual(m.readMetaSize, 7)
    }
    func testEmberSupersedesAThrowbackFinish() {
        XCTAssertEqual(CardFrame.of(slug: "four-seam", grade: .gold), .ember)
        XCTAssertEqual(CardFrame.of(slug: "twelve-six", grade: .inMotion), .powder)
        XCTAssertEqual(CardFrame.of(slug: "circle-change", grade: .firstParty), .teal)
        XCTAssertEqual(CardFrame.of(slug: "slider", grade: .reference), .standard)
    }
    func testRestLeanMatchesTheWebFormula() {
        XCTAssertEqual(CardLean.rest(index: 0), 0.38844, accuracy: 1e-4)
        XCTAssertEqual(CardLean.rest(index: 1), -0.39221, accuracy: 1e-4)
        XCTAssertEqual(CardLean.hero, -0.28)
    }
    func testContentForPitchWithAustinMediaUsesTheGripsShortCue() throws {
        let store = PitchStore()
        let entry = try XCTUnwrap(store.pitches.first { store.gripEntry(forSpecimen: $0.slug).map { $0.film != nil || !$0.photos.isEmpty } == true })
        let grip = try XCTUnwrap(store.gripEntry(forSpecimen: entry.slug))
        let c = SpecimenCardContent.make(entry: entry, grip: grip)
        XCTAssertEqual(c.cue, grip.shortCue)
        XCTAssertEqual(c.cueTier, grip.claimTier)
        XCTAssertTrue(c.chipIsAustin)
        XCTAssertEqual(c.chipLabel, grip.film != nil ? "Austin video" : "Austin photo")
        XCTAssertFalse(c.approximate)
    }
    func testContentForPitchWithoutAustinMediaUsesReferenceClaim() throws {
        let store = PitchStore()
        let entry = try XCTUnwrap(store.pitches.first { e in
            let g = store.gripEntry(forSpecimen: e.slug); return g == nil || (g!.film == nil && g!.photos.isEmpty) })
        let c = SpecimenCardContent.make(entry: entry, grip: store.gripEntry(forSpecimen: entry.slug))
        let reference = entry.canonical.gripDetails.first ?? entry.canonical.grip
        XCTAssertEqual(c.cue, reference.value)
        XCTAssertEqual(c.cueTier, reference.confidence)
        XCTAssertEqual(c.approximate, reference.approximate ?? false)
        XCTAssertEqual(c.chipLabel, "Reference schematic")
        XCTAssertEqual(c.face, .schematic)
    }
    func testAccessibilityLabelCarriesNameNumberCueAndTierWords() throws {
        let store = PitchStore()
        let e = try XCTUnwrap(store.pitch(slug: "four-seam"))
        let c = SpecimenCardContent.make(entry: e, grip: store.gripEntry(forSpecimen: e.slug))
        for part in [e.display.shortName, "No. 00", c.cue, c.cueTier.label] { XCTAssertTrue(c.accessibilityLabel.contains(part), part) }
    }
    func testArchedWindowFillsItsRect() {
        let rect = CGRect(x: 0, y: 0, width: 300, height: 270)
        let box = ArchedWindow(topRX: 65, topRY: 69, bottomR: 12).path(in: rect).boundingRect
        XCTAssertEqual(box.width, 300, accuracy: 0.5); XCTAssertEqual(box.height, 270, accuracy: 0.5)
        XCTAssertTrue(ArchedWindow(topRX: 65, topRY: 69, bottomR: 12).path(in: rect).contains(CGPoint(x: 150, y: 135)))
        XCTAssertFalse(ArchedWindow(topRX: 65, topRY: 69, bottomR: 12).path(in: rect).contains(CGPoint(x: 2, y: 2)), "the arch clears the corner")
    }
}
```
(`PitchStore()` loads the bundle synchronously, as `WingBundleTests` already uses it.)

- [ ] **Step 2: Run** compile check. Expected: `cannot find 'SpecimenCardMetrics' in scope`.

- [ ] **Step 3: Implement** `SpecimenCardModel.swift`:

```swift
import SwiftUI

/// Which stock a card is cut from. The ember 1/1 supersedes a throwback finish.
enum CardFrame: Equatable {
    case standard, ember, powder, teal
    static func of(slug: String, grade: SpecimenGradeKey) -> CardFrame {
        if grade == .gold { return .ember }
        switch PitchAccents.triad(for: slug).finish {
        case "powder": return .powder
        case "teal": return .teal
        default: return .standard
        }
    }
}

/// Every printed size on the card is N·u with u = width/100 (the web's --rfxu);
/// micro-type floors apply after scaling (spec Appendix F).
struct SpecimenCardMetrics: Equatable {
    let width: CGFloat
    let frame: CardFrame
    init(width: CGFloat, frame: CardFrame) { self.width = width; self.frame = frame }
    var u: CGFloat { width / 100 }
    var height: CGFloat { width * 7 / 5 }
    var stockPadding: CGFloat { frame == .ember ? 16 : 13 }
    var fieldPadding: EdgeInsets { EdgeInsets(top: 3.06 * u, leading: 3.06 * u, bottom: 2.5 * u, trailing: 3.06 * u) }
    var headPadding: EdgeInsets { EdgeInsets(top: 0.83 * u, leading: 0.83 * u, bottom: 2.22 * u, trailing: 0.83 * u) }
    var overlineSize: CGFloat { max(7, 2 * u) }
    var nameSize: CGFloat { 7.2 * u }
    var numberSize: CGFloat { 5.2 * u }
    var stageTopRX: CGFloat { 21.67 * u }
    var stageTopRY: CGFloat { 23 * u }
    var stageBottomR: CGFloat { 3.89 * u }
    var chipSize: CGFloat { max(7, 2.22 * u) }
    var chipInset: CGFloat { 2.5 * u }
    var readMarginTop: CGFloat { 2.5 * u }
    var readPadding: EdgeInsets { EdgeInsets(top: 2.5 * u, leading: 3.33 * u, bottom: 2.22 * u, trailing: 3.33 * u) }
    var readRadius: CGFloat { 2.22 * u }
    var readGap: CGFloat { 1.75 * u }
    var readRuleStep: CGFloat { 4.7 * u }
    var readMetaSize: CGFloat { max(7, 2.05 * u) }
    var cueSize: CGFloat { 3.9 * u }
    var factSize: CGFloat { max(8, 2.5 * u) }
    var dotSize: CGFloat { 2.22 * u }
    var stripSize: CGFloat { max(8, 2.5 * u) }
    var stripTop: CGFloat { 1.67 * u }
}

enum CardLean {
    /// `rotate: sin((i + 1) · 2.1) · 0.45deg` — every web card passes i = 0.
    static func rest(index: Int) -> Double { sin(Double(index + 1) * 2.1) * 0.45 }
    static let hero: Double = -0.28
}

enum CardFace: Equatable { case film(GripFilm), photo(VisualReference), schematic }

/// What the card prints, resolved like the web's specimenFace(): Austin's clip,
/// then his photo, then the schematic. The cue is his short cue when he filed
/// the grip, else the reference grip claim — never anything invented.
struct SpecimenCardContent: Equatable {
    let slug: String
    let name: String
    let vnum: String
    let family: PitchFamily
    let frame: CardFrame
    let triad: WebAccent
    let face: CardFace
    let chipLabel: String
    let chipIsAustin: Bool
    let cue: String
    let cueTier: ClaimConfidence
    let approximate: Bool

    static func make(entry: PitchAtlasEntry, grip: GripEntry?) -> SpecimenCardContent {
        let film = grip?.film
        let photo = grip?.photos.first
        let austin = film != nil || photo != nil
        let reference = entry.canonical.gripDetails.first ?? entry.canonical.grip
        let face: CardFace = film.map(CardFace.film) ?? photo.map(CardFace.photo) ?? .schematic
        return SpecimenCardContent(
            slug: entry.slug, name: entry.display.shortName, vnum: entry.display.specimenNo,
            family: entry.canonical.family,
            frame: CardFrame.of(slug: entry.slug, grade: entry.specimenGrade.key),
            triad: PitchAccents.triad(for: entry.slug), face: face,
            chipLabel: film != nil ? "Austin video" : photo != nil ? "Austin photo" : "Reference schematic",
            chipIsAustin: austin,
            cue: austin ? grip!.shortCue : reference.value,
            cueTier: austin ? grip!.claimTier : reference.confidence,
            approximate: austin ? false : (reference.approximate ?? false))
    }

    var accessibilityLabel: String {
        "\(name), filed specimen No. \(vnum). Grip tell: \(cue). Source: \(cueTier.label)\(approximate ? ", approximate" : ""). \(chipLabel)."
    }
}

/// The card window: elliptical top corners (21.67u × 23u), small bottom radius.
struct ArchedWindow: Shape {
    var topRX: CGFloat
    var topRY: CGFloat
    var bottomR: CGFloat
    func path(in r: CGRect) -> Path {
        let rx = min(topRX, r.width / 2), ry = min(topRY, r.height - bottomR), br = min(bottomR, r.width / 2, r.height / 2)
        let k: CGFloat = 0.5523
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY + ry))
        p.addCurve(to: CGPoint(x: r.minX + rx, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.minY + ry - k * ry), control2: CGPoint(x: r.minX + rx - k * rx, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - rx, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + ry),
                   control1: CGPoint(x: r.maxX - rx + k * rx, y: r.minY), control2: CGPoint(x: r.maxX, y: r.minY + ry - k * ry))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - br))
        p.addArc(center: CGPoint(x: r.maxX - br, y: r.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: r.minX + br, y: r.maxY))
        p.addArc(center: CGPoint(x: r.minX + br, y: r.maxY - br), radius: br, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.closeSubpath()
        return p
    }
}
```
`PitchStore`: `func gripEntry(forSpecimen slug: String) -> GripEntry? { grips.entries.first { $0.specimenSlug == slug } }`. Run `xcodegen generate` (new folder).

- [ ] **Step 4: Run** compile check, CI. Expected: all 8 new tests pass.

- [ ] **Step 5: Commit** `feat(cards): the specimen card's geometry, frame and printed content as tested data`

---

### Task 9: The 5:7 specimen card front — stock, field, head, window, read plate, strip; ember and throwbacks

**Files:**
- Create: `PitchAtlas/Components/Cards/SpecimenCard.swift`
- Modify: `PitchAtlas/Components/ContentCards.swift` (delete the old `PitchSpecimenCard` 207-357), `PitchAtlas/Features/Atlas/AtlasView.swift:104,167` (call shape kept)
- Test: `PitchAtlasTests/SpecimenCardModelTests.swift`

**Interfaces:**
- Consumes: Task 8 (`SpecimenCardMetrics`, `CardFrame`, `SpecimenCardContent`, `CardLean`, `ArchedWindow`), Task 3 (`ComponentInk`).
- Produces: `PitchSpecimenCard(entry:style:)` with `enum Style { case hero, rail, wall }` (hero = 320 max width, ember lean −0.28, film plays; rail = 268; wall = cell width, ≤360, chase ≤520); `SpecimenCardFront(content:metrics:playsFilm:)` (the face alone, used by the flip in Task 11); `CardWords(content:)` (scalable text twin shown at accessibility sizes).

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor
func testCardRendersAt5by7ForEveryFrame() throws {
    let store = PitchStore()
    for slug in ["four-seam", "twelve-six", "circle-change", "slider", "eephus"] {
        let e = try XCTUnwrap(store.pitch(slug: slug))
        let content = SpecimenCardContent.make(entry: e, grip: store.gripEntry(forSpecimen: slug))
        let metrics = SpecimenCardMetrics(width: 300, frame: content.frame)
        let r = ImageRenderer(content: SpecimenCardFront(content: content, metrics: metrics, playsFilm: false).environment(store))
        let img = try XCTUnwrap(r.uiImage, slug)
        XCTAssertEqual(img.size.height / img.size.width, 1.4, accuracy: 0.02, slug)
    }
}
@MainActor
func testCardWordsRepeatCueAndTierInScalableText() throws {
    let store = PitchStore()
    let e = try XCTUnwrap(store.pitch(slug: "slider"))
    let c = SpecimenCardContent.make(entry: e, grip: store.gripEntry(forSpecimen: "slider"))
    XCTAssertEqual(CardWords.lines(for: c), [c.cue, c.cueTier.label + (c.approximate ? " · approximate" : "")])
}
func testEmberPlateInksPassContrast() {
    XCTAssertGreaterThanOrEqual(PitchAccents.contrast(0x6E655A, 0xEFE6D0), 4.5, "read meta")
    XCTAssertGreaterThanOrEqual(PitchAccents.contrast(0x6B4318, 0xF1E4C8), 4.5, "ember meta")
    XCTAssertGreaterThanOrEqual(PitchAccents.contrast(0x9D927D, 0x0B0805), 4.5, "file label")
}
```

- [ ] **Step 2: Run** compile check. Expected: `cannot find 'SpecimenCardFront' in scope`.

- [ ] **Step 3: Implement** `SpecimenCard.swift`. Layers top-down follow spec §7.2–7.11:

```swift
import SwiftUI

/// The face of a filed specimen (spec §7): foil-rimmed stock, a warm-black field,
/// the head, the arched window, the cream read plate, the strip.
struct SpecimenCardFront: View {
    let content: SpecimenCardContent
    let metrics: SpecimenCardMetrics
    var playsFilm = false
    var light = UnitPoint(x: 0.5, y: 0.32)

    private var ember: Bool { content.frame == .ember }
    private var c2: Color { Color(rgb: content.triad.c2) }
    private var c3: Color { Color(rgb: content.triad.c3) }
    private var c3Ink: Color { PitchAccents.accentInk(content.triad.c3) }

    var body: some View {
        let m = metrics
        ZStack {
            stock
            field.padding(m.stockPadding)
        }
        .frame(width: m.width, height: m.height)
        .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.card, style: .continuous))
        .modifier(EdgeStack(ember: ember))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityLabel)
    }

    // Stock: the foil (or ember / throwback foil) at 300%, positioned by the light,
    // a 57° hatch at white .14 overlay, then the rim hairline and the 9pt black ring.
    private var stock: some View {
        let foil: LinearGradient = switch content.frame {
        case .ember: PitchAtlasMaterials.ember()
        case .powder: PitchAtlasMaterials.cardFoil(finish: "powder")
        case .teal: PitchAtlasMaterials.cardFoil(finish: "teal")
        case .standard: PitchAtlasMaterials.foil()
        }
        return RoundedRectangle(cornerRadius: PitchAtlasRadius.card, style: .continuous)
            .fill(foil)
            .scaleEffect(3, anchor: light)     // background-size 300%, position follows the light
            .overlay { Hatch(angle: 57, spacing: 9).stroke(Color.white.opacity(0.14), lineWidth: 1).blendMode(.overlay) }
            .overlay { RoundedRectangle(cornerRadius: PitchAtlasRadius.card).strokeBorder(ComponentInk.edgeHairline, lineWidth: 1) }
            .clipped()
            .accessibilityHidden(true)
    }

    private var field: some View {
        let m = metrics
        return VStack(spacing: 0) {
            head
            window
            readPlate.padding(.top, m.readMarginTop)
            Spacer(minLength: 0)
            strip
        }
        .padding(m.fieldPadding)
        .background {
            RoundedRectangle(cornerRadius: PitchAtlasRadius.cardField)
                .fill(ember ? LinearGradient(colors: ComponentInk.emberField, startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [c2.opacity(0.34), ComponentInk.fieldBase], startPoint: .top, endPoint: .bottom))
                .overlay { RoundedRectangle(cornerRadius: PitchAtlasRadius.cardField).strokeBorder(.black, lineWidth: 2) }
                .overlay { RoundedRectangle(cornerRadius: PitchAtlasRadius.cardField).inset(by: 2).strokeBorder((ember ? Color(rgb: WebTokens.Accent.burnt) : c3).opacity(0.42), lineWidth: 1) }
                .overlay { Hatch(angle: 45, spacing: 6).stroke(PitchAtlasTheme.bone, lineWidth: 0.5).opacity(0.075) }
                .overlay { RadialGradient(colors: [.white.opacity(0.3), .clear], center: light, startRadius: 0, endRadius: metrics.width * 0.6).blendMode(.screen) }
                .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.cardField))
        }
    }

    private var head: some View {
        let m = metrics
        return HStack(alignment: .bottom, spacing: 2.22 * m.u) {
            VStack(alignment: .leading, spacing: 0.83 * m.u) {
                Text("FILED SPECIMEN").font(PitchAtlasType.font(.martian400, size: m.overlineSize))
                    .tracking(em: ember ? 0.22 : 0.17, size: m.overlineSize)
                    .foregroundStyle(ember ? ComponentInk.emberOverline : c3Ink.mix(ComponentInk.cardStrip, 0.32))
                Text(content.name.uppercased()).font(PitchAtlasType.font(.anton400, size: m.nameSize))
                    .lineSpacing(0).lineLimit(2).minimumScaleFactor(0.7)
                    .foregroundStyle(ember ? ComponentInk.emberName : ComponentInk.cardName)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 1, y: 1)
                    .transformEffect(CGAffineTransform(a: 1, b: 0, c: tan(-5 * .pi / 180), d: 1, tx: 0, ty: 0))
            }
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 1.1 * m.u) {
                Text("FILE").font(PitchAtlasType.font(.martian400, size: m.overlineSize))
                    .foregroundStyle(ember ? ComponentInk.emberFileLabel : ComponentInk.cardFileLabel).padding(.bottom, 0.65 * m.u)
                Text(content.vnum).font(PitchAtlasType.font(.anton400, size: m.numberSize))
                    .foregroundStyle(ember ? ComponentInk.emberName : c3Ink.mix(PitchAtlasTheme.bone, 0.28))
                    .transformEffect(CGAffineTransform(a: 1, b: 0, c: tan(-6 * .pi / 180), d: 1, tx: 0, ty: 0))
            }
        }
        .padding(m.headPadding)
        .accessibilityHidden(true)
    }

    private var window: some View {
        let m = metrics
        let shape = ArchedWindow(topRX: m.stageTopRX, topRY: m.stageTopRY, bottomR: m.stageBottomR)
        return ZStack(alignment: .bottomLeading) {
            RadialGradient(colors: [c2.mix(.black, 0.52), ComponentInk.stageDeep], center: .init(x: 0.5, y: 0.24), startRadius: 0, endRadius: m.width * 0.78)
            HalftoneDots(spacing: 9, color: c3.opacity(0.7)).opacity(0.12)
            faceView
            chip.padding(m.chipInset)
        }
        .aspectRatio(10.0 / 9.0, contentMode: .fit)
        .clipShape(shape)
        .overlay { shape.stroke(c3.opacity(0.22), lineWidth: 1) }
    }

    @ViewBuilder private var faceView: some View {
        switch content.face {
        case .film(let film):
            if playsFilm { GripFilmCard(film: film, height: metrics.width * 0.82, offersMotionControl: false, showsCaption: false) }
            else { BundledImage(src: film.poster, alt: film.clip.alt, contentMode: .fill) }
        case .photo(let photo): BundledImage(src: photo.src, alt: photo.alt, contentMode: .fill)
        case .schematic: SchematicFace(slug: content.slug, size: metrics.width * 0.62)
        }
    }

    private var chip: some View {
        let m = metrics
        return HStack(spacing: 1.39 * m.u) {
            Circle().fill(content.chipIsAustin ? PitchAtlasTheme.cyan : PitchAtlasTheme.sandBright).frame(width: m.dotSize, height: m.dotSize)
            Text(content.chipLabel.uppercased()).font(PitchAtlasType.font(.martian400, size: m.chipSize)).tracking(em: 0.1, size: m.chipSize)
                .foregroundStyle(content.chipIsAustin ? PitchAtlasTheme.cyan : PitchAtlasTheme.sandBright)
        }
        .padding(.horizontal, 2.22 * m.u).padding(.vertical, 0.83 * m.u)
        .background(Capsule().fill(ComponentInk.gripChipFill))
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
    }

    private var readPlate: some View {
        let m = metrics
        let paper = ember ? ComponentInk.emberPaper : ComponentInk.readPaper
        return VStack(alignment: .leading, spacing: m.readGap) {
            HStack {
                Text("GRIP TELL"); Spacer(); Text("PA—\(content.vnum)")
            }
            .font(PitchAtlasType.font(.martian400, size: m.readMetaSize)).tracking(em: ember ? 0.24 : 0.15, size: m.readMetaSize)
            .foregroundStyle(ember ? ComponentInk.emberMeta : ComponentInk.readMeta)
            Text(content.cue).font(PitchAtlasType.cardCue(size: m.cueSize)).lineSpacing(m.cueSize * 0.32).lineLimit(2)
                .foregroundStyle(ember ? ComponentInk.emberCue : ComponentInk.readCue)
            HStack(spacing: 1.4 * m.u) {
                Circle().fill(PitchAtlasTheme.cardInk(forConfidence: content.cueTier.rawValue)).frame(width: m.dotSize, height: m.dotSize)
                    .shadow(color: PitchAtlasTheme.cardInk(forConfidence: content.cueTier.rawValue), radius: 4)
                Text(content.cueTier.label.uppercased()).font(PitchAtlasType.font(.martian400, size: m.factSize)).tracking(em: 0.07, size: m.factSize)
                    .foregroundStyle(ember ? ComponentInk.emberFact : ComponentInk.readFact).lineLimit(1)
                if content.approximate { Text("≈ APPROX").font(PitchAtlasType.font(.martian400, size: max(7, 2.58 * m.u))).foregroundStyle(ember ? ComponentInk.emberMeta : ComponentInk.readFact) }
            }
            .padding(.top, 1.67 * m.u)
            .overlay(alignment: .top) { Rectangle().fill(ComponentInk.readRule).frame(height: 1) }
        }
        .padding(m.readPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: m.readRadius).fill(paper)
                .overlay { RuledLines(step: m.readRuleStep).stroke(ComponentInk.readRuling, lineWidth: 0.2 * m.u) }
                .overlay { RadialGradient(colors: [.white.opacity(0.62), .clear], center: .top, startRadius: 0, endRadius: m.width * 0.5) }
                .clipShape(RoundedRectangle(cornerRadius: m.readRadius))
        }
        .accessibilityHidden(true)
    }

    private var strip: some View {
        let m = metrics
        return HStack(spacing: 2.22 * m.u) {
            Text("GRIP / RELEASE / SHAPE").font(PitchAtlasType.font(.martian400, size: m.stripSize * 0.86)).tracking(em: 0.1, size: m.stripSize * 0.86)
                .foregroundStyle(c3Ink.mix(ComponentInk.cardStrip, 0.42)).lineLimit(1)
            Spacer(minLength: 0)
            Text("OPEN SPECIMEN →").font(PitchAtlasType.font(.martian400, size: m.stripSize)).tracking(em: 0.08, size: m.stripSize)
                .foregroundStyle(ComponentInk.cardStrip)
        }
        .padding(.top, m.stripTop)
        .shadow(color: .black.opacity(0.85), radius: 1.5, y: 1)
        .accessibilityHidden(true)
    }
}
```
Plus the private helpers in the same file — `Hatch: Shape` (parallel lines at `angle`, `spacing`), `RuledLines: Shape` (horizontal lines every `step`), `HalftoneDots` (a `Canvas` drawing 1.4pt dots on a `spacing` grid, masked by a radial fade), `SchematicFace` (wraps `SeamBall(motion: store.pitch(slug:)!.motion, size:)` through `@Environment(PitchStore.self)`), `EdgeStack: ViewModifier` (the 10-layer edge: `.shadow` stack — 1pt `ComponentInk.edgeRing`, then `ComponentInk.edgeStack` offsets at y 3/5/7/9, then `.shadow(color: .black.opacity(0.55), radius: 14, y: 16)`; ember swaps layer 2 for `ComponentInk.emberRing` and adds a burnt `.shadow(color: Color(rgb: WebTokens.Accent.burnt).opacity(0.3), radius: 12)`), and a `Color.mix(_:_:)` helper in `Core/Theme/PitchAccents.swift` (sRGB linear interpolation: `self` weighted `1 − amount`, `other` weighted `amount`; Core/Theme so its `Color(red:)` stays inside the gate).

`CardWords`:

```swift
/// The card's print scales with the card, not with text size. At accessibility
/// sizes the same words also print here, in scalable type, under the card.
struct CardWords: View {
    static func lines(for c: SpecimenCardContent) -> [String] { [c.cue, c.cueTier.label + (c.approximate ? " · approximate" : "")] }
    let content: SpecimenCardContent
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(content.cue).font(PitchAtlasTheme.newsreaderItalic(17, relativeTo: .body)).foregroundStyle(PitchAtlasTheme.bone)
            ConfidenceDot(confidence: content.cueTier, approximate: content.approximate)
        }
        .accessibilityHidden(true)   // the card's own label already speaks these
    }
}
```

`PitchSpecimenCard(entry:style:)` wraps it: `GeometryReader`-free — it takes a fixed width per style (`.hero` 320, `.rail` 268; `.wall` `min(cellWidth, 360)` supplied by the caller via `.frame`), `.rotationEffect(.degrees(style == .hero && content.frame == .ember ? CardLean.hero : CardLean.rest(index: 0)))`, keeps today's `contextMenu`/`accessibilityAction(named: "Compare this pitch")`, and under `dynamicTypeSize.isAccessibilitySize` shows `CardWords` below the card. Delete the old `PitchSpecimenCard` and its `ArchiveCoverSurface(signature:)` use.

- [ ] **Step 4: Run** compile check, literal gate, CI. Expected: pass. Visual comparison with the live card is Plan 6's screenshot pass (ledger it).

- [ ] **Step 5: Commit** `feat(cards): the 5:7 specimen card — stock, window, read plate, ember, throwbacks`

---

### Task 10: Tilt, light and the rim rake

**Files:**
- Create: `PitchAtlas/Components/Cards/CardTilt.swift`
- Modify: `PitchAtlas/Components/Cards/SpecimenCard.swift` (`PitchSpecimenCard` applies `.cardTilt(...)`; `SpecimenCardFront` reads `light`)
- Test: `PitchAtlasTests/SpecimenCardModelTests.swift`

**Interfaces:**
- Produces: `struct CardTiltState: Equatable { rx, ry, mx, my; static let rest; static func drag(translation: CGSize, width: CGFloat) -> CardTiltState?; static func gyro(roll: Double, pitch: Double) -> CardTiltState; var light: UnitPoint }`; `View.cardTilt(useGyro: Bool) -> some View` (reads `MotionProvider` and Reduce Motion from the environment).

- [ ] **Step 1: Write the failing tests**

```swift
func testDragTiltFollowsTheWebFormulaAndClamps() throws {
    let t = try XCTUnwrap(CardTiltState.drag(translation: CGSize(width: 50, height: 0), width: 300))
    XCTAssertEqual(t.rx, 50.0 / 300 * 14 * 2.4, accuracy: 1e-9)       // 5.6°
    XCTAssertEqual(t.ry, t.rx * -0.22, accuracy: 1e-9)
    XCTAssertEqual(t.mx, 50 + t.rx / 14 * 42, accuracy: 1e-9)
    XCTAssertEqual(t.my, 32 + t.ry / 14 * 30, accuracy: 1e-9)
    XCTAssertEqual(CardTiltState.drag(translation: CGSize(width: 900, height: 0), width: 300)!.rx, 14)
}
func testVerticalDragDoesNotTilt() {
    XCTAssertNil(CardTiltState.drag(translation: CGSize(width: 6, height: 40), width: 300), "a scroll that starts on the card scrolls the page")
    XCTAssertNil(CardTiltState.drag(translation: CGSize(width: 5, height: 0), width: 300), "under the 8pt threshold nothing moves")
}
func testGyroTiltClampsAtTen() {
    let t = CardTiltState.gyro(roll: 1, pitch: -1)
    XCTAssertEqual(t.rx, 10); XCTAssertEqual(t.ry, 10)
    XCTAssertEqual(CardTiltState.gyro(roll: 0, pitch: 0), .rest)
}
func testRestLightSitsWhereTheWebRests() {
    XCTAssertEqual(CardTiltState.rest.light, UnitPoint(x: 0.5, y: 0.32))
}
```

- [ ] **Step 2: Run** compile check. Expected: `cannot find 'CardTiltState' in scope`.

- [ ] **Step 3: Implement** `CardTilt.swift`:

```swift
import SwiftUI

/// The web's useCardTilt (spec Appendix B): drag ≤14°, the gyroscope ≤10° on the
/// hero only, light follows the tilt, a spring of ω20 ζ0.7 carries it home.
struct CardTiltState: Equatable {
    var rx = 0.0, ry = 0.0, mx = 50.0, my = 32.0
    static let rest = CardTiltState()
    static let dragMax = 14.0, gyroMax = 10.0
    static let threshold: CGFloat = 8

    private static func clamp(_ v: Double, _ m: Double) -> Double { min(m, max(-m, v)) }
    private static func lit(rx: Double, ry: Double) -> CardTiltState {
        CardTiltState(rx: rx, ry: ry, mx: 50 + rx / dragMax * 42, my: 32 + ry / dragMax * 30)
    }
    /// Horizontal drags tilt; a mostly-vertical drag is a scroll and returns nil.
    static func drag(translation t: CGSize, width: CGFloat) -> CardTiltState? {
        guard abs(t.width) >= threshold, abs(t.width) > abs(t.height), width > 0 else { return nil }
        let rx = clamp(Double(t.width / width) * dragMax * 2.4, dragMax)
        return lit(rx: rx, ry: clamp(rx * -0.22, dragMax))
    }
    static func gyro(roll: Double, pitch: Double) -> CardTiltState {
        lit(rx: clamp(roll * gyroMax, gyroMax), ry: clamp(-pitch * gyroMax, gyroMax))
    }
    var light: UnitPoint { UnitPoint(x: mx / 100, y: my / 100) }
}

private struct CardTiltModifier: ViewModifier {
    let useGyro: Bool
    let width: CGFloat
    @Binding var light: UnitPoint
    @Environment(MotionProvider.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drag: CardTiltState?

    private var state: CardTiltState {
        if reduceMotion { return .rest }
        if let drag { return drag }
        return useGyro ? .gyro(roll: motion.roll, pitch: motion.pitch) : .rest
    }

    func body(content: Content) -> some View {
        let s = state
        content
            .rotation3DEffect(.degrees(s.rx), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            .rotation3DEffect(.degrees(s.ry), axis: (x: 1, y: 0, z: 0), perspective: 0.4)
            .overlay {   // the rim rake: a 190pt bone glint at the light, screen, on the frame ring only
                RadialGradient(colors: [.white.opacity(0.5), .clear], center: s.light, startRadius: 0, endRadius: 190)
                    .blendMode(.screen).opacity(0.46)
                    .mask(RoundedRectangle(cornerRadius: PitchAtlasRadius.card).strokeBorder(lineWidth: 13))
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
            .simultaneousGesture(reduceMotion ? nil : DragGesture(minimumDistance: CardTiltState.threshold)
                .onChanged { v in drag = CardTiltState.drag(translation: v.translation, width: width) }
                .onEnded { _ in drag = nil })
            .animation(PitchAtlasMotion.animation(PitchAtlasMotion.tiltSpring, reduceMotion: reduceMotion), value: s)
            .onChange(of: s.light) { _, l in light = l }
            .onAppear { if useGyro && !reduceMotion { motion.start() } }
            .onDisappear { if useGyro { motion.stop() } }
    }
}

extension View {
    func cardTilt(useGyro: Bool, width: CGFloat, light: Binding<UnitPoint>) -> some View {
        modifier(CardTiltModifier(useGyro: useGyro, width: width, light: light))
    }
}
```
`PitchSpecimenCard` holds `@State private var light = CardTiltState.rest.light`, passes it to `SpecimenCardFront(light:)`, and applies `.cardTilt(useGyro: style == .hero, width:, light: $light)`. If `MotionProvider.start/stop` are reference-counted elsewhere, call whatever the existing callers call (`SpecimenBallView`) and note it in the ledger. A drag never produces a tap (the system tap recognizer fails once the finger moves), so the web's click suppression is native.

- [ ] **Step 4: Run** compile check, CI. Expected: pass.

- [ ] **Step 5: Commit** `feat(cards): tilt by drag, gyroscope on the hero, light and rim rake follow`

---

### Task 11: The flip and the dark scout-file back

**Files:**
- Create: `PitchAtlas/Components/Cards/CardBack.swift`
- Delete: `PitchAtlas/Components/CardBackPanel.swift` (its `CardBackPanel` and `CardBackRules` move into `CardBack.swift`, restyled)
- Modify: `PitchAtlasTheme.swift` (`cardback*` retuned; delete `archiveStock`, `signatureStock`, `signatureEdge`, `signatureWear`, `signatureBevel`, `referenceEdge`), `PitchAtlasUI.swift` (delete `ArchiveCoverSurface`), `GripFilm.swift`, `CompareSelection.swift:91`, `PitchDetailView.swift`, `AtlasView.swift` (their `ArchiveCoverSurface` uses → `PanelSurface`)
- Test: `PitchAtlasTests/CardBackTests.swift` (new)

**Interfaces:**
- Consumes: Task 7 (`ScoutRow`, `ScoutRows`), Task 9 (`SpecimenCardFront`).
- Produces: `enum FlipFace { case front, back; static func visible(angle: Double) -> FlipFace }`; `struct ScoutFile { rows: [ScoutFile.Row]; sourceLinks: [(label: String, url: URL)]; static func make(entry: PitchAtlasEntry) -> ScoutFile }` with `Row { key, value, tier, approximate }`; `SpecimenCardBack(entry:metrics:isChase:)`; `FlippableSpecimen(entry:width:isChase:) ` (front + back + the action row with the flip button and `CompareButton`); `FlipButton.label(name:flipped:)`; `CardBackPanel { content }` (now `.v2-back`).

- [ ] **Step 1: Write the failing tests**

```swift
import XCTest
@testable import PitchAtlas

final class CardBackTests: XCTestCase {
    func testFlipFaceSwapsAtNinetyDegrees() {
        XCTAssertEqual(FlipFace.visible(angle: 0), .front)
        XCTAssertEqual(FlipFace.visible(angle: 89.9), .front)
        XCTAssertEqual(FlipFace.visible(angle: 90), .back)
        XCTAssertEqual(FlipFace.visible(angle: 180), .back)
    }
    func testFlipLabelsNameCardAndState() {
        XCTAssertEqual(FlipButton.label(name: "Slider", flipped: false), "Flip Slider to its sourced back")
        XCTAssertEqual(FlipButton.label(name: "Slider", flipped: true), "Flip Slider back to its card")
        XCTAssertEqual(FlipButton.title(flipped: false), "↺ Source")
        XCTAssertEqual(FlipButton.title(flipped: true), "↺ Card")
    }
    func testScoutRowsAreGripCueThenShapeFromTheRecord() throws {
        let store = PitchStore()
        let e = try XCTUnwrap(store.pitches.first { $0.canonical.physics.shape != nil })
        let file = ScoutFile.make(entry: e)
        let grip = e.canonical.gripDetails.first ?? e.canonical.grip
        XCTAssertEqual(file.rows.map(\.key), ["Grip cue", "Shape"])
        XCTAssertEqual(file.rows[0].value, grip.value); XCTAssertEqual(file.rows[0].tier, grip.confidence)
        XCTAssertEqual(file.rows[1].value, e.canonical.physics.shape!.value)
    }
    func testScoutRowsOmitMissingShape() throws {
        let store = PitchStore()
        guard let e = store.pitches.first(where: { $0.canonical.physics.shape == nil }) else { return }  // every record may carry one
        XCTAssertEqual(ScoutFile.make(entry: e).rows.map(\.key), ["Grip cue"])
    }
    func testBackHeadReadsNumberAndFamily() throws {
        let e = try XCTUnwrap(PitchStore().pitch(slug: "four-seam"))
        XCTAssertEqual(ScoutFile.headline(for: e), "No. 00 · Fastball")
    }
}
```

- [ ] **Step 2: Run** compile check. Expected: `cannot find 'FlipFace' in scope`.

- [ ] **Step 3: Implement** `CardBack.swift`:

```swift
import SwiftUI

enum FlipFace: Equatable {
    case front, back
    static func visible(angle: Double) -> FlipFace { angle.truncatingRemainder(dividingBy: 360) < 90 ? .front : .back }
}

/// The scout file on the back — only sourced or categorical facts (web ChromeWall).
struct ScoutFile {
    struct Row: Equatable { let key: String; let value: String; let tier: ClaimConfidence; let approximate: Bool }
    let rows: [Row]
    let sourceLinks: [(label: String, url: URL)]
    static func headline(for e: PitchAtlasEntry) -> String { "No. \(e.display.specimenNo) · \(e.canonical.family.label)" }
    static func make(entry e: PitchAtlasEntry) -> ScoutFile {
        let grip = e.canonical.gripDetails.first ?? e.canonical.grip
        var rows = [Row(key: "Grip cue", value: grip.value, tier: grip.confidence, approximate: grip.approximate ?? false)]
        var links: [(String, URL)] = []
        if let s = grip.source, let url = URL(string: s.url) { links.append(("Grip: \(s.label)", url)) }
        if let shape = e.canonical.physics.shape {
            rows.append(Row(key: "Shape", value: shape.value, tier: shape.confidence, approximate: shape.approximate ?? false))
            if let s = shape.source, let url = URL(string: s.url) { links.append(("Shape: \(s.label)", url)) }
        }
        return ScoutFile(rows: rows, sourceLinks: links)
    }
}

/// `.v2-back`: matte black stock, a wide dull wash; the chase back runs warm.
struct SpecimenCardBack: View {
    let entry: PitchAtlasEntry
    let metrics: SpecimenCardMetrics
    var isChase = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        let file = ScoutFile.make(entry: entry)
        let c3 = Color(rgb: PitchAccents.triad(for: entry.slug).c3)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(entry.display.shortName.uppercased()).font(PitchAtlasType.font(.anton400, size: 18, relativeTo: .title3))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .transformEffect(CGAffineTransform(a: 1, b: 0, c: tan(-5 * .pi / 180), d: 1, tx: 0, ty: 0))
                Spacer(minLength: 0)
                Text(ScoutFile.headline(for: entry).uppercased()).font(PitchAtlasType.font(.martian400, size: 9)).tracking(em: 0.14, size: 9)
                    .foregroundStyle(PitchAtlasTheme.bone2).lineLimit(1)
            }
            .padding(.bottom, 7)
            .overlay(alignment: .bottom) { Rectangle().fill(c3.opacity(0.47)).frame(height: 1) }
            ScoutRows(accent: c3, rows: file.rows.map { r in
                AnyView(ScoutRow(label: r.key, value: r.value, tier: r.tier, approximate: r.approximate,
                                 accent: PitchAccents.accentInk(PitchAccents.triad(for: entry.slug).c3).mix(PitchAtlasTheme.bone2, 0.4)))
            })
            .padding(.top, 9)
            Spacer(minLength: 10)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(file.sourceLinks, id: \.label) { link in
                    Button { openURL(link.url) } label: {
                        Text("\(link.label.uppercased()) ↗").font(PitchAtlasType.font(.martian400, size: 10)).tracking(em: 0.1, size: 10)
                            .underline(color: PitchAtlasTheme.bone2.opacity(0.4)).foregroundStyle(PitchAtlasTheme.bone2).lineLimit(1)
                            .frame(minHeight: 44, alignment: .leading).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
                NavigationLink(value: entry) {
                    Text("OPEN THE FULL FILE →").font(PitchAtlasType.font(.martian400, size: 10)).tracking(em: 0.14, size: 10)
                        .foregroundStyle(PitchAtlasTheme.bone).frame(minHeight: 44, alignment: .leading).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }
        .padding(15)
        .frame(width: metrics.width, height: metrics.height, alignment: .topLeading)
        .background { BackStock(isChase: isChase) }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .inkContext(.object)
    }
}

private struct BackStock: View {
    let isChase: Bool
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 8)
        shape.fill(RadialGradient(colors: [isChase ? ComponentInk.chaseBackTop : ComponentInk.backTop, ComponentInk.backBottom],
                                  center: .top, startRadius: 0, endRadius: isChase ? 420 : 520))
            .overlay {
                shape.fill(LinearGradient(stops: [.init(color: .clear, location: 0.14),
                                                  .init(color: isChase ? Color(rgb: WebTokens.Accent.burnt).opacity(0.28) : PitchAtlasTheme.bone.opacity(0.06), location: isChase ? 0.40 : 0.38),
                                                  .init(color: .clear, location: isChase ? 0.66 : 0.64)],
                                          startPoint: .leading, endPoint: .trailing))
                    .blendMode(.screen).opacity(isChase ? 0.4 : 0.35)
            }
            .overlay { shape.strokeBorder(isChase ? ComponentInk.chaseBackBorder : PitchAtlasTheme.bone.opacity(0.10), lineWidth: 1) }
            .shadow(color: isChase ? Color(rgb: WebTokens.Accent.burnt).opacity(0.5) : .clear, radius: 17)
            .accessibilityHidden(true)
    }
}

enum FlipButton {
    static func title(flipped: Bool) -> String { flipped ? "↺ Card" : "↺ Source" }
    static func label(name: String, flipped: Bool) -> String {
        flipped ? "Flip \(name) back to its card" : "Flip \(name) to its sourced back"
    }
}

/// A wall card: the front, the back, and the action row (flip + compare) outside the turning card.
struct FlippableSpecimen: View {
    let entry: PitchAtlasEntry
    let width: CGFloat
    var isChase = false
    @Environment(PitchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var angle: Double = 0
    @State private var light = CardTiltState.rest.light

    private var flipped: Bool { FlipFace.visible(angle: angle) == .back }

    var body: some View {
        let content = SpecimenCardContent.make(entry: entry, grip: store.gripEntry(forSpecimen: entry.slug))
        let metrics = SpecimenCardMetrics(width: width, frame: content.frame)
        VStack(spacing: 12) {
            ZStack {
                NavigationLink(value: entry) { SpecimenCardFront(content: content, metrics: metrics, light: light) }
                    .buttonStyle(.plain)
                    .opacity(flipped ? 0 : 1).accessibilityHidden(flipped)
                SpecimenCardBack(entry: entry, metrics: metrics, isChase: isChase)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .opacity(flipped ? 1 : 0).accessibilityHidden(!flipped)
            }
            .modifier(FlipAngle(angle: angle))
            .rotationEffect(.degrees(CardLean.rest(index: 0)))
            .accessibilityAction(named: "Flip card") { toggle() }
            HStack {
                Button(action: toggle) {
                    Text(FlipButton.title(flipped: flipped)).font(PitchAtlasType.font(.martian400, size: 9)).tracking(em: 0.12, size: 9)
                        .foregroundStyle(PitchAtlasTheme.bone).padding(.horizontal, 10).padding(.vertical, 7)
                        .background(Capsule().fill(ComponentInk.flipFill))
                        .overlay(Capsule().strokeBorder(Color(rgb: content.triad.c3).mix(PitchAtlasTheme.bone, 0.3).opacity(0.6), lineWidth: 1))
                        .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(FlipButton.label(name: entry.display.shortName, flipped: flipped))
                .accessibilityValue(flipped ? "Showing sources" : "Showing card")
                Spacer()
                CompareButton(slug: entry.slug)
            }
            .frame(width: width)
        }
    }

    private func toggle() {
        Haptics.selection()
        let target: Double = flipped ? 0 : 180
        if reduceMotion { angle = target } else { withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.4)) { angle = target } }
    }
}

/// Rotates about the vertical centre line; the opacity swap happens at 90° as the angle animates.
private struct FlipAngle: ViewModifier, Animatable {
    var angle: Double
    var animatableData: Double { get { angle } set { angle = newValue } }
    func body(content: Content) -> some View {
        content.rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.35)
    }
}
```
Note: the opacity swap reads `flipped`, which is computed from the final `angle` state, not the animating value. To swap at the visual 90°, move the two `.opacity` modifiers inside `FlipAngle` (it receives the animating `angle`): give `FlipAngle` two closures `front`/`back` and let it render `ZStack { front().opacity(FlipFace.visible(angle: angle) == .front ? 1 : 0); back().opacity(... == .back ? 1 : 0) }`. Implement it that way; the snippet above shows the parts.

`CardBackPanel` (used by Atlas's grading-scale panel and PitchDetail) is re-implemented as content padded 15 over `BackStock(isChase: false)` with `.inkContext(.object)`. `CardBackRules` keeps its API with Anton 15 bone and bone hairlines. Retune `cardbackInk` → `bone`, `cardbackInk2` → `bone2`, `cardbackInk3` → `bone3`, `cardbackLine` → `bone.opacity(0.10)`, `cardbackNavy` → `kicker`, `cardbackBurgundy` → `seamBright` (so the three existing screens keep legible light inks on dark stock — never the dead cream `cb-*` inks). Delete `ArchiveCoverSurface` and its stock tokens after swapping its remaining callers to `PanelSurface` (`grep -rn ArchiveCoverSurface PitchAtlas` → Expected: no output).

- [ ] **Step 4: Run** compile check, literal gate, CI. Expected: pass.

- [ ] **Step 5: Commit** `feat(cards): flip to the dark scout-file back; card-back panel and stocks follow the web`

---

### Task 12: The wall mount and the binder

**Files:**
- Create: `PitchAtlas/Components/Cards/WallAndBinder.swift`
- Test: `PitchAtlasTests/CardBackTests.swift`

**Interfaces:**
- Consumes: Task 11 (`FlippableSpecimen`), Task 8 (`SpecimenCardContent`).
- Produces: `WallMount { content }` with `isChase`, `isSelected`; `WallSpecimen(entry:isChase:)` (mount + `FlippableSpecimen`); `enum BinderLayout { static func columns(width: CGFloat) -> Int; static func foilPosition(index: Int) -> UnitPoint; static func rotation(index: Int) -> Double }`; `BinderSheet(title:entries:onOpen:)` where entries are `[RepertoireEntry]`; `PocketCard`, `PocketSlip`.

- [ ] **Step 1: Write the failing tests**

```swift
func testBinderColumnsByWidth() {
    XCTAssertEqual(BinderLayout.columns(width: 390), 2)
    XCTAssertEqual(BinderLayout.columns(width: 639), 2)
    XCTAssertEqual(BinderLayout.columns(width: 640), 3)
}
func testPocketsCatchTheLightAtDifferentAngles() {
    // nth-child is 1-based on the web: index 0 is child 1.
    XCTAssertEqual(BinderLayout.foilPosition(index: 0), UnitPoint(x: 0.30, y: 0.25))
    XCTAssertEqual(BinderLayout.foilPosition(index: 1), UnitPoint(x: 0.12, y: 0.80))   // 3n+2
    XCTAssertEqual(BinderLayout.foilPosition(index: 2), UnitPoint(x: 0.78, y: 0.60))   // 3n
    XCTAssertEqual(BinderLayout.rotation(index: 0), -0.5)                              // 4n+1
    XCTAssertEqual(BinderLayout.rotation(index: 2), 0.45)                              // 5n+3
    XCTAssertEqual(BinderLayout.rotation(index: 1), 0)
}
```

- [ ] **Step 2: Run** compile check. Expected: `cannot find 'BinderLayout' in scope`.

- [ ] **Step 3: Implement** `WallAndBinder.swift`:

```swift
import SwiftUI

enum BinderLayout {
    static func columns(width: CGFloat) -> Int { width < 640 ? 2 : 3 }
    static func foilPosition(index: Int) -> UnitPoint {
        let n = index + 1
        if n % 3 == 0 { return UnitPoint(x: 0.78, y: 0.60) }
        if n % 3 == 2 { return UnitPoint(x: 0.12, y: 0.80) }
        return UnitPoint(x: 0.30, y: 0.25)
    }
    static func rotation(index: Int) -> Double {
        let n = index + 1
        if n % 4 == 1 { return -0.5 }
        if n % 5 == 3 { return 0.45 }
        return 0
    }
}

/// `.v2-mount`: the matte cell a wall card sits in; the chase cell runs ember.
struct WallMount<Content: View>: View {
    var isChase = false
    var isSelected = false
    @ViewBuilder var content: Content
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 8)
        content
            .padding(10)
            .background {
                shape.fill(LinearGradient(colors: [ComponentInk.mountTop, ComponentInk.mountBottom], startPoint: .top, endPoint: .bottom))
                    .overlay { shape.strokeBorder(isChase ? Color(rgb: WebTokens.Accent.burnt).opacity(0.4) : Color.black.opacity(0.4), lineWidth: 1) }
                    .overlay { if isChase { shape.inset(by: 1).strokeBorder(Color(rgb: WebTokens.Accent.burnt).opacity(0.2), lineWidth: 1) } }
                    .shadow(color: .black, radius: 13, y: 10)
                    .shadow(color: isChase ? Color(rgb: WebTokens.Accent.burnt).opacity(0.55) : .clear, radius: 20)
            }
            .overlay { if isSelected { RoundedRectangle(cornerRadius: 12).strokeBorder(ComponentInk.selectedOutline, lineWidth: 1).padding(-5) } }
    }
}

struct WallSpecimen: View {
    let entry: PitchAtlasEntry
    var isChase = false
    let width: CGFloat
    @Environment(\.compareSelection) private var selection
    var body: some View {
        WallMount(isChase: isChase, isSelected: selection.slugs.contains(entry.slug)) {
            FlippableSpecimen(entry: entry, width: min(width - 22, isChase ? 520 : 360), isChase: isChase)
        }
    }
}

/// The Index binder: a saddle-leather sheet punched for rings, pockets two or three across.
struct BinderSheet: View {
    let title: String
    let entries: [RepertoireEntry]
    let onOpen: (RepertoireEntry) -> Void
    var body: some View {
        GeometryReader { geo in
            let cols = BinderLayout.columns(width: geo.size.width)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: cols), spacing: 12) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { i, e in
                    Pocket { pocketFace(e, index: i) }
                }
            }
            .padding(.vertical, 14).padding(.trailing, 14).padding(.leading, 36)
        }
        .background {
            RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [ComponentInk.sheetTop, ComponentInk.sheetBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Color.black.opacity(0.6), lineWidth: 1) }
                .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3])).foregroundStyle(PitchAtlasTheme.bone.opacity(0.22)).padding(8) }
                .overlay(alignment: .leading) { RingHoles().padding(.leading, 11) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) family, binder sheet")
    }
    @ViewBuilder private func pocketFace(_ e: RepertoireEntry, index: Int) -> some View {
        Button { onOpen(e) } label: {
            if e.hasFace { PocketCard(entry: e, index: index) } else { PocketSlip(entry: e) }
        }.buttonStyle(.plain)
    }
}
```
plus `Pocket` (sleeve: radius 10, padding 5–9, `bone .025` fill, inset `bone .10` ring, the 118° gloss band; a press lifts the card 12pt and turns it −0.6° except under Reduce Motion), `RingHoles` (three 14pt holes, `ComponentInk.holeCenter`→black radial, spaced top 6%/bottom 6%), `PocketCard` (5:7, radius 9, 2pt foil frame at 240% positioned by `BinderLayout.foilPosition`, rotated by `BinderLayout.rotation`, inner gradient `pocketInnerTop→Bottom`, the photo or `SeamBall`, filed number in Anton with a black stroke top-left, name strip in Anton uppercase on `pocketNameFill` with a `bone .22` top rule and the status in Martian 7.5 `pocketStatus` / `pocketStatusEdge`), and `PocketSlip` (5:7 cream `slipPaper`, `slipInk`, status 8pt mono, name Anton, "No image filed", "Basic file →", ruled lower 26%, edge statuses ringed `slipEdgeRing`). `RepertoireEntry.hasFace` = it has a filed specimen or a grip photo; add it as an extension in this file using the store's grip entries if the entry itself does not carry photos (resolve with `PitchStore` through the environment if needed — record the choice in the ledger). Navigation: screens push a `PitchAtlasEntry` value (Atlas `navigationDestination(for: PitchAtlasEntry.self)`); the Index pushes through its own `navigationDestination(item:)` binding. The binder takes an `onOpen: (RepertoireEntry) -> Void` closure and the Index passes the same action its rows use — read `IndexView` around line 122 before wiring it.

- [ ] **Step 4: Run** compile check, literal gate, CI. Expected: pass.

- [ ] **Step 5: Commit** `feat(cards): the wall mount and the Index binder`

---

### Task 13: Plates and index rows — Tier B and Tier C; craftsman and lost-pitch plates

**Files:**
- Create: `PitchAtlas/Components/Cards/PlateAndRow.swift`
- Modify: `PitchAtlas/Components/ContentCards.swift` (delete `RepertoireRow`; `CraftsmanCard` and `LostPitchCard` bodies → `Plate`), `PitchAtlas/Features/Index/IndexView.swift:325` (`RepertoireRow(entry:)` → `IndexRow(entry:)`, compare button under filed rows)
- Test: `PitchAtlasTests/PlateAndRowTests.swift` (new)

**Interfaces:**
- Produces: `enum PlateVariant { case standard, filed, edge, dashed, edgeDashed }`; `Plate<Content>(accent: Color, variant:) { content }` with `Plate.edgeColor(accent:variant:) -> Color`; `IndexRow(entry: RepertoireEntry)`; `IndexRowStyle.statusInk(_ status: RepertoireStatus) -> AnyShapeStyle`; `IndexSeamMark(id:tint:)`; `func restFor(_ id: String) -> Double`.

- [ ] **Step 1: Write the failing tests**

```swift
import XCTest
import SwiftUI
@testable import PitchAtlas

final class PlateAndRowTests: XCTestCase {
    func testRestForMatchesTheWebHash() {
        XCTAssertEqual(restFor("four-seam"), 0.951036, accuracy: 1e-5)
        XCTAssertEqual(restFor("eephus"), -0.714876, accuracy: 1e-5)
        XCTAssertEqual(restFor("gyroball"), 0.773891, accuracy: 1e-5)
    }
    func testPlateLipByVariant() {
        let burnt = Color(rgb: WebTokens.Accent.burnt)
        XCTAssertEqual(Plate<EmptyView>.edgeColor(accent: burnt, variant: .standard), burnt.opacity(0.78))
        XCTAssertEqual(Plate<EmptyView>.edgeColor(accent: burnt, variant: .edge), PitchAtlasTheme.seamBright.opacity(0.82))
        XCTAssertEqual(Plate<EmptyView>.edgeColor(accent: burnt, variant: .filed), ComponentInk.filedBone.opacity(0.82))
    }
    func testStatusInkIsSeamForBannedAndQuietForTheEdgeCases() {
        XCTAssertEqual(IndexRowStyle.statusTone(.banned), .seam)
        for s: RepertoireStatus in [.alias, .illusion, .notAPitch] { XCTAssertEqual(IndexRowStyle.statusTone(s), .quiet) }
        for s: RepertoireStatus in [.standard, .niche, .rare, .nearExtinct] { XCTAssertEqual(IndexRowStyle.statusTone(s), .bone2) }
    }
    func testFiledRowsWearTheAccentTopRuleAndSquareTopCorners() {
        XCTAssertEqual(IndexRowStyle.topRule(filed: true), 2); XCTAssertEqual(IndexRowStyle.topRule(filed: false), 0)
        XCTAssertEqual(IndexRowStyle.topRadius(filed: true), 0); XCTAssertEqual(IndexRowStyle.topRadius(filed: false), 14)
    }
    @MainActor func testRowsAndPlatesRender() throws {
        let store = PitchStore()
        for e in store.repertoire.entries.prefix(4) {
            XCTAssertNotNil(ImageRenderer(content: IndexRow(entry: e).frame(width: 340).environment(store)).uiImage, e.id)
        }
        XCTAssertNotNil(ImageRenderer(content: CraftsmanCard(craftsman: store.craftsmen[0]).frame(width: 340)).uiImage)
        XCTAssertNotNil(ImageRenderer(content: LostPitchCard(pitch: store.lostPitches.entries[0]).frame(width: 340)).uiImage)
    }
}
```

- [ ] **Step 2: Run** compile check. Expected: `cannot find 'restFor' in scope`.

- [ ] **Step 3: Implement** `PlateAndRow.swift`:

```swift
import SwiftUI

/// The web's clock-free lean for an id: h = (h·31 + code) mod 1000, rest = sin(h).
func restFor(_ id: String) -> Double {
    var h = 0
    for scalar in id.unicodeScalars { h = (h * 31 + Int(scalar.value)) % 1000 }
    return sin(Double(h))
}

enum PlateVariant { case standard, filed, edge, dashed, edgeDashed }

/// Tier B `.rfx-plate`: matte field, a 3px accent lip on top, corner ticks, the raking catch.
struct Plate<Content: View>: View {
    static func edgeColor(accent: Color, variant: PlateVariant) -> Color {
        switch variant {
        case .filed: ComponentInk.filedBone.opacity(0.82)
        case .edge, .edgeDashed: PitchAtlasTheme.seamBright.opacity(0.82)
        case .standard, .dashed: accent.opacity(0.78)
        }
    }
    let accent: Color
    var variant: PlateVariant = .standard
    @ViewBuilder var content: Content
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: PitchAtlasRadius.plate, style: .continuous)
        let dashed = variant == .dashed || variant == .edgeDashed
        VStack(alignment: .leading, spacing: 14) { content }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                shape.fill(variant == .filed
                           ? LinearGradient(colors: [ComponentInk.filedBone.opacity(0.10), PitchAtlasTheme.press], startPoint: .topLeading, endPoint: .bottomTrailing)
                           : LinearGradient(colors: [accent.mix(ComponentInk.plateBase, 0.92), ComponentInk.plateEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(alignment: .top) { Rectangle().fill(Self.edgeColor(accent: accent, variant: variant)).frame(height: 3) }
                    .overlay { shape.fill(LinearGradient(stops: [.init(color: .clear, location: 0.06), .init(color: PitchAtlasTheme.bone.opacity(0.16), location: 0.2), .init(color: .clear, location: 0.4)], startPoint: .leading, endPoint: .trailing)).blendMode(.screen).opacity(0.55) }
                    .overlay { shape.strokeBorder(accent.opacity(0.16), lineWidth: 1) }
                    .overlay { shape.strokeBorder(Color.black.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: dashed ? [4, 3] : [])) }
                    .overlay(alignment: .topLeading) { CornerTick().padding(11) }
                    .overlay(alignment: .topTrailing) { CornerTick().scaleEffect(x: -1).padding(11) }
                    .clipShape(shape)
                    .shadow(color: .black.opacity(0.8), radius: 15, y: 16)
            }
            .inkContext(.object)
    }
}

private struct CornerTick: View {
    var body: some View {
        Path { p in p.move(to: CGPoint(x: 0, y: 12)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: 12, y: 0)) }
            .stroke(Color.white.opacity(0.15), lineWidth: 1).frame(width: 12, height: 12).accessibilityHidden(true)
    }
}

enum IndexRowStyle {
    enum Tone: Equatable { case seam, quiet, bone2 }
    static func statusTone(_ s: RepertoireStatus) -> Tone {
        switch s { case .banned: .seam; case .alias, .illusion, .notAPitch: .quiet; default: .bone2 }
    }
    static func statusInk(_ s: RepertoireStatus) -> AnyShapeStyle {
        switch statusTone(s) {
        case .seam: AnyShapeStyle(PitchAtlasTheme.seamBright)
        case .quiet: AnyShapeStyle(PitchAtlasTheme.text3)      // ink-3 re-scoped inside the object: #969080
        case .bone2: AnyShapeStyle(PitchAtlasTheme.text2)
        }
    }
    static func topRule(filed: Bool) -> CGFloat { filed ? 2 : 0 }
    static func topRadius(filed: Bool) -> CGFloat { filed ? 0 : PitchAtlasRadius.indexRow }
}

/// Tier C `.rfx-entry`: warm charcoal, an accent glow at top-left, the woven hatch at .13;
/// filed rows wear a 2px accent top rule with square top corners.
struct IndexRow: View {
    let entry: RepertoireEntry
    var body: some View {
        let filed = entry.filedSlug != nil
        let gc = entry.family.accent
        let shape = UnevenRoundedRectangle(topLeadingRadius: IndexRowStyle.topRadius(filed: filed), bottomLeadingRadius: PitchAtlasRadius.indexRow,
                                           bottomTrailingRadius: PitchAtlasRadius.indexRow, topTrailingRadius: IndexRowStyle.topRadius(filed: filed), style: .continuous)
        HStack(alignment: .top, spacing: 13) {
            IndexSeamMark(id: entry.id, tint: filed ? Color(rgb: PitchAccents.triad(for: entry.filedSlug!).c3) : gc)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text(entry.name).font(PitchAtlasType.font(.hanken700, size: 15, relativeTo: .headline)).foregroundStyle(PitchAtlasTheme.bone)
                    if filed {
                        Text("FILED").font(PitchAtlasType.font(.martian400, size: 10)).tracking(em: 0.1, size: 10)
                            .foregroundStyle(ComponentInk.filedInk).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(ComponentInk.filedBone))
                    }
                }
                .padding(.trailing, 80)
                if let aka = entry.aka, !aka.isEmpty {
                    Text(aka.joined(separator: " · ")).font(PitchAtlasType.body(size: 11.5)).foregroundStyle(PitchAtlasTheme.text3).padding(.top, 4)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            Text(entry.status.displayLabel.uppercased()).font(PitchAtlasType.font(.martian400, size: 9.5)).tracking(em: 0.08, size: 9.5)
                .foregroundStyle(IndexRowStyle.statusInk(entry.status))
                .padding(.horizontal, 8).padding(.vertical, 2)
                .overlay(Capsule().strokeBorder(IndexRowStyle.statusInk(entry.status), lineWidth: 1))
                .padding(14)
        }
        .background {
            shape.fill(filed
                ? LinearGradient(colors: [ComponentInk.filedBone.opacity(0.13), PitchAtlasTheme.press], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [gc.mix(PitchAtlasTheme.press, 0.9), PitchAtlasTheme.press], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay { shape.fill(RadialGradient(colors: [gc.opacity(filed ? 0.16 : 0.18), .clear], center: .topLeading, startRadius: 0, endRadius: 180)) }
                .overlay { WovenHatch(accent: gc).opacity(0.13).blendMode(.screen).clipShape(shape) }
                .overlay { shape.strokeBorder(filed ? ComponentInk.filedBone.opacity(0.42) : Color.white.opacity(0.09), lineWidth: 1) }
                .overlay(alignment: .top) { if filed { Rectangle().fill(gc).frame(height: IndexRowStyle.topRule(filed: true)) } }
                .shadow(color: .black.opacity(0.82), radius: 14, y: 16)
        }
        .inkContext(.object)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(([entry.name, entry.family.label, filed ? "Filed specimen" : "Basic file", entry.status.displayLabel]
                             + (entry.aka.map { $0.isEmpty ? [] : ["also known as \($0.joined(separator: ", "))"] } ?? [])).joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
    }
}
```
plus `WovenHatch` (two `Hatch`-style line sets: 45° bone .75 every 8pt and −45° accent .6 every 18pt, from Task 9's helper — move `Hatch` to an internal type so both files share it) and `IndexSeamMark` (40×40: a 13.8pt-radius `seamMarkDisc` circle, a 1pt tint ring at .38, and a seam arc rotated `restFor(id) * 48` degrees, drawn with the existing `SeamArc` shape at stroke 1.5 / opacity .9). The row keeps the a.k.a. accessibility promise of the old `RepertoireRow`.

`CraftsmanCard` → `Plate(accent: <signature pitch accent c3, else cyan; legend → ComponentInk.legendTeal>, variant: legend ? .dashed : .standard)` with: mono-label row (`"Master · C-01"` / `"Legend · …"` left, era right in `text3`), name in Anton 24 bone (unskewed — `.rfx-platetitle` has no skew), signature pitch mono-label in `text2`, tagline Hanken 14 `text2`, and a footer rule (`white .10`) with "Open the file →" in cyan. `LostPitchCard` → `Plate(accent: PitchAtlasTheme.sandBright, variant: legend ? .edgeDashed : .standard)` with the same anatomy (tier on the label row via `StatusPill`). In `IndexView`, the row becomes `IndexRow(entry:)`, and for filed rows a `CompareButton(slug:)` sits below it, outside the row's `NavigationLink`, indented 64pt.

- [ ] **Step 4: Run** compile check, literal gate, CI. Expected: pass; then `grep -rn "RepertoireRow\|ArchiveCoverSurface\|signatureStock" PitchAtlas` → no output.

- [ ] **Step 5: Commit** `feat(cards): Tier B plates and Tier C index rows; craftsman and lost-pitch plates`

---

## Self-review notes

- **Spec coverage:** buttons (T4), kicker/hairline/stamp/panel (T3), chips/toggles/filter pill (T5), search/select/dialog/toast (T6), trust marks/scout rows (T7), the 5:7 card with ember, throwbacks, tilt and flip to the dark back (T8–T11), wall and binder (T12), plate/row/craftsman/lost pitch (T13), Blaze removal with the scroll tracker kept (T2), PR #35 follow-ups (T1). Screen layouts (Atlas sections, Index panel, specimen rail) are Plan 3. The hero foil shader (Metal `layerEffect`) is deferred to Plan 3 with the hero, where it is measured against battery (spec Risks).
- **Deferred on purpose and ledgered at execution:** button adoption across screens (Plan 3 does it screen by screen); the 3D grip model inside wall cards (native cards use the schematic — three live SceneKit views in one scroll is the battery risk the spec names); perspective values (0.35/0.4) are tuned against the live site in Plan 6's screenshot pairs.
- **Type consistency:** `SpecimenCardContent.make(entry:grip:)`, `SpecimenCardMetrics(width:frame:)`, `CardFrame.of(slug:grade:)`, `CardTiltState.drag(translation:width:)`, `FlipFace.visible(angle:)`, `ScoutFile.make(entry:)`, `BinderLayout.columns(width:)`, `restFor(_:)` are used with these exact signatures in every later task.
