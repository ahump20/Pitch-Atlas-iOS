# Pitch Atlas App Store Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the native Pitch Atlas iOS app review-ready, separately branded from Blaze Sports Intel, and ready for App Store Connect submission.

**Architecture:** Keep v1 as a native SwiftUI, offline reference app. No login, no Supabase/Appwrite client, no WebView, no user-generated content, and no data collection. The App Store package is proven by simulator build/test, source audit, screenshot proof, and App Store Connect/Xcode signing checks.

**Tech Stack:** SwiftUI, XcodeGen, XcodeBuildMCP, Xcode/App Store Connect, bundled JSON content, first-party grip images.

---

### Task 1: Align The Repo Story With The v1 Binary

**Files:**
- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `PitchAtlas/Features/PitchDetail/PitchDetailView.swift`
- Modify: `PitchAtlas/Features/PitchDetail/SeamBall.swift`

- [ ] **Step 1: Confirm the current binary has no WebView code**

Run:

```bash
rg -n "WKWebView|WebKit|URLSession|Supabase|Firebase|Appwrite|signIn|Sign in|login|auth" PitchAtlas PitchAtlasTests docs README.md CLAUDE.md project.yml
```

Expected: no hits in `PitchAtlas/` for WebKit, network writes, auth, Supabase, Firebase, or Appwrite. Hits in docs must be scoped to compliance notes or v2/v1.1 plans.

- [ ] **Step 2: Replace stale WebView language**

Patch `README.md` so the architecture section says the v1 specimen is native SwiftUI and the WebView island is a later v1.1 plan.

- [ ] **Step 3: Replace stale repo guidance**

Patch `CLAUDE.md` so the architecture and pattern sections match the shipped v1: native SwiftUI specimen, no WebView, no web bundle, no network.

- [ ] **Step 4: Clean source comments that imply WebView is in v1**

Patch `PitchDetailView.swift` and `SeamBall.swift` comments so they describe the current native specimen and v1.1 target without implying WebView is shipped.

- [ ] **Step 5: Re-run the source audit**

Run:

```bash
rg -n "WKWebView|WebKit|URLSession|Supabase|Firebase|Appwrite|signIn|Sign in|login|auth" PitchAtlas PitchAtlasTests docs README.md CLAUDE.md project.yml
```

Expected: only compliance docs, v2/v1.1 planning docs, and source URLs/content references remain.

### Task 2: Prove The Native App Surface

**Files:**
- Inspect: `PitchAtlas/App/PitchAtlasApp.swift`
- Inspect: `PitchAtlas/Features/Atlas/AtlasView.swift`
- Inspect: `PitchAtlas/Features/Index/IndexView.swift`
- Inspect: `PitchAtlas/Features/Grips/GripsView.swift`
- Inspect: `PitchAtlas/Features/Sources/SourcesView.swift`

- [ ] **Step 1: Build and launch on simulator**

Run through XcodeBuildMCP with project `/Users/AustinHumphrey/code/Pitch-Atlas-iOS/PitchAtlas.xcodeproj`, scheme `PitchAtlas`, bundle id `com.pitchatlas.app`, and simulator `iPhone 17 Pro`.

Expected: build succeeds, app launches, and runtime logs are captured.

- [ ] **Step 2: Capture screenshot proof**

Run the XcodeBuildMCP screenshot tool after launch.

Expected: screenshot shows the Pitch Atlas app, not a blank shell or BSI surface.

- [ ] **Step 3: Run tests**

Run:

```bash
./scripts/build.sh test
```

Expected: the command exits successfully after the test run. If the script masks failures, fix the script first so failing tests fail the command.

### Task 3: Fix The Test Wrapper If It Masks Failures

**Files:**
- Modify: `scripts/build.sh`

- [ ] **Step 1: Inspect the test command**

Run:

```bash
sed -n '1,180p' scripts/build.sh
```

Expected: the `test` case should preserve the real `xcodebuild test` exit code.

- [ ] **Step 2: Patch the test branch**

Replace the masked pipeline with a `set -o pipefail`-safe branch:

```bash
    if command -v xcpretty >/dev/null 2>&1; then
      xcodebuild test \
        -scheme "$SCHEME" -sdk iphonesimulator \
        -destination "$TEST_DEST" -derivedDataPath "$DERIVED" \
        | xcpretty
    else
      xcodebuild test \
        -scheme "$SCHEME" -sdk iphonesimulator \
        -destination "$TEST_DEST" -derivedDataPath "$DERIVED"
    fi
```

Expected: a real test failure returns a failing process status.

- [ ] **Step 3: Run tests again**

Run:

```bash
./scripts/build.sh test
```

Expected: the command passes only if tests pass.

### Task 4: Prepare App Store Connect Copy

**Files:**
- Create: `docs/APP-STORE-CONNECT.md`
- Inspect: `docs/APP-REVIEW-NOTES.md`
- Inspect: `docs/PRIVACY-POLICY.md`

- [ ] **Step 1: Create store metadata doc**

Add copy for app name, subtitle, promotional text, description, keywords, support URL, marketing URL, privacy URL, review notes, screenshot checklist, privacy label, age rating, and export compliance.

- [ ] **Step 2: Keep the privacy claim exact**

The document must state `Data Not Collected` only for the iOS v1 binary. It must not describe the web community/Supabase layer as part of v1.

- [ ] **Step 3: Keep Pitch Atlas separate from BSI**

The document must not mention Blaze Sports Intel except in an internal warning that Pitch Atlas is separate and must not use BSI branding.

### Task 5: Xcode And App Store Connect Submission Lane

**Files:**
- Inspect: `project.yml`
- Inspect: `docs/CI.md`
- Inspect: `docs/APP-STORE-CONNECT.md`

- [ ] **Step 1: Verify signing state in Xcode**

Open `/Users/AustinHumphrey/code/Pitch-Atlas-iOS/PitchAtlas.xcodeproj` in Xcode. In Signing & Capabilities, set the Apple Developer team for `com.pitchatlas.app`. Do not commit `DEVELOPMENT_TEAM`.

- [ ] **Step 2: Create or verify the App Store Connect app record**

In App Store Connect, verify an app named `Pitch Atlas` exists with bundle id `com.pitchatlas.app`. If missing, create it as iOS, free, iPhone-only.

- [ ] **Step 3: Archive from Xcode**

Use Product -> Archive with scheme `PitchAtlas` and a Generic iOS Device destination.

Expected: archive succeeds and opens in Organizer.

- [ ] **Step 4: Distribute to App Store Connect**

Use Organizer -> Distribute App -> App Store Connect -> Upload.

Expected: upload succeeds, processing starts in App Store Connect, and the build appears under TestFlight/app version after Apple processing.

- [ ] **Step 5: Fill the App Store version**

Use `docs/APP-STORE-CONNECT.md` for metadata and `docs/APP-REVIEW-NOTES.md` for review notes. Set App Privacy to `Data Not Collected`, age rating to the truthful education/reference answers, and export compliance to no non-exempt encryption.

- [ ] **Step 6: Submit for review**

Submit only after the uploaded build is selectable, screenshots are attached, privacy/export/age rating are complete, and Apple agreements/tax/banking have no blocking banner.

### Self-Review

- Spec coverage: the plan covers native repo selection, brand separation, review-readiness docs, no-WebView/no-auth/no-data compliance, build/test proof, screenshot proof, and App Store Connect submission.
- Placeholder scan: no `TBD`, no empty edge-case step, no generic "add validation" task.
- Type consistency: no new Swift types are introduced by the plan; the only code patch target is the shell test wrapper.
