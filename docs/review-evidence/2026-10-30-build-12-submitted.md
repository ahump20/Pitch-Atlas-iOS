# 2026-10-30 Build 12 Submitted

Purpose: record the App Store Connect state after `1.2.0 (12)`, the web-parity
release, went to App Review. Every value below was read back from the App Store
Connect API on 2026-10-30, not copied from notes.

## Result

- Source: `main` at `ac72447` ("Pitch Atlas iOS 1.2.0: web parity (#36)"),
  also `release/1.2.0`. Archived locally from a clean clone of `release/1.2.0`
  and uploaded with `xcodebuild -exportArchive` (Xcode Cloud's workflow has no
  TestFlight audience, so it does not deliver builds).
- Xcode Cloud run 39 on `ac72447`: `SUCCEEDED` (run 38 on 2026-10-05 had failed
  on the missing package pin fixed in `d3932db`).
- `1.2.0` App Store version: `79432a3b-8a70-486c-8dc2-ddc2ad6107fe`,
  release type `AFTER_APPROVAL`.
- Attached build: `12` (`e80fd68a-16a7-48e2-be2e-210fb37897f7`), `VALID`,
  `APP_STORE_ELIGIBLE`, uploaded `2026-10-30T08:57:03-07:00`, min OS `17.0`,
  `usesNonExemptEncryption=false`.
- Review submission: `5fe9bf01-253c-40c9-986e-28aa98d445a1`, submitted
  `2026-10-30T16:28:48.708Z`, state `WAITING_FOR_REVIEW`.

## Store Metadata Readback (en-US)

- Description: `1862` characters.
- What's New: `941` characters.
- Promotional text: `138` characters.
- Keywords: `98` characters.
- App Review notes: `2689` characters (`docs/APP-REVIEW-NOTES.md`).
- Demo account required: `false` (contribution is anonymous-first).

## Media

- `APP_IPHONE_67` screenshots, 1320 × 2868, all `COMPLETE`, in this order:
  Atlas, four-seam specimen, grip bench (four-seam and slider), Flight Lab,
  softball wing, compare, Pitch Index, Grips, Greg Maddux, lost pitches. The five
  1.1.0 screenshots the draft inherited were removed from the 1.2.0 set only.
- `IPHONE_67` app preview, the first one this app has had:
  `pitch-atlas-preview.mp4`, 886 × 1920, 30 fps, H.264 with a silent stereo AAC
  track, 28.3 s, `COMPLETE`. Filmed from the running app by
  `AppPreviewUITests.testPreviewTour` (`PA_SHOTS=preview`) under
  `simctl io recordVideo`, then cut at the test's printed timestamps: Atlas →
  four-seam specimen → compare → Pitch Index → softball wing → Flight Lab, ending
  on a lob landing in the zone drawing. No overlays, no added footage.

## Age Rating

Apple's questionnaire gained required questions. Answered on 2026-10-30 to match
`docs/APP-STORE-CONNECT.md` § Age Rating:

- User-Generated Content: Yes (the form had shown No; the documented posture is yes).
- Social Media: No — discussion is per-pitch threads, no feed that spreads posts.
- Social Media Disabled for Users Under 13: No — the app does not call the
  Declared Age Range API, and has no social-media feature to disable.
- Messaging and Chat, Advertising, Unrestricted Web Access, Parental Controls,
  Age Assurance: No. All content steps unchanged (profanity Infrequent, the rest None).
- Calculated rating: 9+ (unchanged), no override.

## Privacy Labels

Unchanged and still accurate for 1.2.0: Email Address, Photos or Videos, Other
User Content, User ID — all App Functionality, linked to the user. The typed
discussion handle and the pitching-post suggestion are Other User Content. The
only package is supabase-swift and its dependencies (`ci_scripts/Package.resolved`).
