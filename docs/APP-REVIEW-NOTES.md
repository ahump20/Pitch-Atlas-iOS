# App Review — Notes for the Reviewer (draft)

Drafted at scope-lock (not at submission) because the Guideline 4.2 native-value argument is the actual rebuttal to the single highest-probability rejection, and it should exist before the build is finished. Paste the final version into App Store Connect → App Review Information → Notes.

---

**What Pitch Atlas is:** a native, offline reference for how baseball pitches are gripped and thrown. Every fact carries a visible source and a confidence tier ("Sourced, not corrected").

**No account is required or offered.** The entire app is usable on first launch with no sign-in, no network connection, and no data collection. There is no login screen. (App Privacy: Data Not Collected.)

**Native functionality (why this is an app, not a website — Guideline 4.2):**

- A native tab bar and per-tab navigation (Atlas, Index, Grips, Craftsmen, Sources).
- A **native, searchable pitch index** with family filters and honest status labels — fully native SwiftUI, no web view.
- A **native offline grip library** of first-party grip photography with a pitcher's own notes — bundled in the app, works in airplane mode.
- A **native sources/provenance browser** — every claim's citation, rendered natively.
- All reference content (pitches, craftsmen, lost pitches, sources) is **bundled in the binary and works fully offline on first launch** — no server, no loading states for content.

**The pitch specimen is fully native — there is no web view in this build.** Each pitch's specimen (the baseball with its seam drawn from the real closed-form figure-eight seam equation, oriented to the pitch's spin axis, with a physics-derived break indicator) is rendered natively in SwiftUI. As the phone tilts, a holographic foil rakes across the specimen card (CoreMotion). No WebGL, no remote code, no network — the app contains no `WKWebView` and makes no network requests at all.

**To verify offline behavior:** enable Airplane Mode and launch the app — every tab, the index, the grip library, the craftsmen hall, and the sources browser load with full content. The native specimen renders instantly from bundled data. Nothing in the app requires a network connection.

**Content rights:** the grip photography is the developer's own first-party work. The visual subject throughout is an original seam specimen or first-party photography. No third-party player photos, team/league marks, or re-hosted footage are included.

---

_Update before submission: confirm the exact tab names and add a one-line "what changed" for the build under review. (The interactive WebGL 3D specimen is a planned v1.1 enhancement; v1 ships the native specimen described above.)_
