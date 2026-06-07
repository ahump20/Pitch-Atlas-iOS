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

**The one web view, and why it's there:** each pitch's *interactive 3D specimen* (a seam-true ball you can drag to spin, with a live spin-axis vector and a physics-derived movement model) is rendered by a bundled, offline WebGL component inside a single card on the otherwise-native Pitch Detail screen. It is one feature on one card — not the app — and it ships **inside the binary** (no remote code, no remote fetch). If WebGL is unavailable, the screen falls back to a native 2D seam schematic.

**To verify offline behavior:** enable Airplane Mode and launch the app — every tab, the index, the grip library, the craftsmen hall, and the sources browser load with full content. The 3D specimen renders from the bundled assets.

**Content rights:** the grip photography is the developer's own first-party work. The visual subject throughout is an original seam specimen or first-party photography. No third-party player photos, team/league marks, or re-hosted footage are included.

---

_Update before submission: confirm the exact tab names, the WebGL fallback wording, and add a one-line "what changed" for the build under review._
