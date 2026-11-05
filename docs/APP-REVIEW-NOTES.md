# App Review Notes — candidate 1.2.0 (14)

Status: remediation candidate for the November 2 rejection of submission `0b7dce83-8e94-415f-9d89-404ba3c941ab`. Build 14 upload, native acceptance testing, and resubmission are pending. Do not treat the build-13 test record as proof for this candidate.

## Reviewer notes

Pitch Atlas is a native SwiftUI iPhone field manual for how baseball pitches are gripped and thrown. The bundled reference manual works without an account. Community contributions require acceptance of the Community Terms and EULA and confirmation that the contributor is 18 or older. The first write creates an anonymous contributor record; Apple or email sign-in can claim it for use across devices. Still-image uploads require a claimed account.

### Find community posting

1. Launch on Atlas and tap `Study this grip →` to open Four-seam.
2. Scroll past the grip, lessons, and history to `Field notes from the bullpen.` and `Log a field note`.
3. Tap `Write a note →`. Accept `I accept the Community Terms and EULA` and `I confirm I am 18 or older`. Enter a handle in `Submitted by` and a grip cue in `The tweak`, then tap `File field note →`. Field notes remain private until approved.
4. Continue to `Discussion · Talk through the four-seam` and open the drawer. Accept the same terms and age confirmation if needed, enter a handle in `Your name`, enter a comment, and tap `File post`.
5. The same consent applies to replies and suggestions submitted from `Know a pitching post that belongs here?`. Suggestions remain private until reviewed and approved.
6. Image attachment requires a claimed account, the same 18+ consent, and the image upload terms. Submitted images remain private until approved.

These steps describe the implemented candidate. Their execution on build 14 is still pending, as recorded below.

### Safety controls

- The Community Terms and EULA state that objectionable content and abusive users are not tolerated and link to Apple's Standard EULA. The new consent keys require existing users to accept the updated terms and 18+ confirmation again.
- Open a post, reply, field-note, or attached-media menu to Hide or Report. Hide removes the item immediately on the device, including offline, and persists after relaunch. Report also hides it immediately before attempting delivery.
- If a report cannot send, it is retained on the device. Retry from that screen or from `Account > Safety > Unsent reports`. The app confirms delivery only after the server accepts it.
- Block another contributor from their content menu. Blocking filters content in both directions and prevents direct replies across the blocked connection. Manage the private blocked list in `Account > Safety`.
- Production text filtering and pending-image restrictions run on the server. Submitted images cannot be publicly read or signed for playback before approval.
- Automated safeguards remove reported content from public view and restrict the contributor within 24 hours. Confirmed violations result in permanent content removal and contributor ejection. This is not a claim that a staffed human review occurs within 24 hours.
- Open `Account > Safety > Contact developer` or `Support > Contact developer`. The form identifies Austin Humphrey and accepts a private message and optional reply email without requiring an existing post or claimed account. A successful server receipt produces `Message sent`; failure preserves the text for retry.
- Account deletion is available for both anonymous and claimed accounts.

### Sign in with Apple

Open Account from the account button on Atlas. An anonymous contributor can use `Claim this record` to claim the existing record with Apple or email. A reader without a contributor record can also sign in from Account.

The production Apple provider is now enabled and its public Auth settings endpoint returns HTTP 200 with `external.apple=true`. This verifies backend configuration only. The complete native Apple authorization, token exchange, and anonymous-account claim flows remain pending build-14 acceptance checks.

### Media and privacy

The app accepts still images through PhotosPicker. It does not upload video or GIFs, capture camera media, track users, or include advertising or analytics SDKs.

Credited teaching clips use TikTok's official player in a poster-gated WKWebView. No player request occurs until the reader taps the poster. The original post remains available through an outbound link. The app does not download or rehost these clips.

Contact developer sends the submitted message, optional reply email, and contributor ID, including anonymous IDs, for private customer support and safety. Opening the form sends nothing. Account deletion removes the sender-ID link from support records; the private message and optional reply email remain unless separately deleted. The privacy manifest declares Customer Support, Email Address, User ID, Other User Content, and Photos or Videos as linked to the user, used for App Functionality, and not used for tracking.

## Candidate evidence and remaining gates

Evidence snapshot: 2026-11-05 UTC (November 4 in America/Chicago).

| Check | Evidence/status |
| --- | --- |
| Candidate identity | Version 1.2.0, build 14, bundle `com.pitchatlas.app`; not yet claimed uploaded or submitted. |
| Native source checks | Changed Swift files parse; `git diff --check` and privacy plist validation passed. |
| Unit tests | 11 safety tests added for consent upgrade, hiding, report persistence/retry, and contact validation. Runtime execution for the final candidate is pending. |
| Apple provider | Production enabled; HTTP 200 settings readback reports `external.apple=true`. Native sign-in and claim completion pending. |
| Moderation backend | `app_review_community_moderation` deployed; explicit post, note, and media report fixtures passed local and hosted rollback checks. Automated sweep `pitch-atlas-community-review-deadlines` runs every 10 minutes for unresolved reports aged 22 hours; a real run succeeded at 2026-11-05 04:20:00 UTC. |
| Developer contact backend | Production RPC accepted a message with an optional reply email, returned a UUID receipt, returned the same receipt for a duplicate retry, enforced the hourly limit, and accepted an existing restricted identity. Native form acceptance pending. |
| Media backend | Pending-image public reads/signing are denied before approval. Native upload and review-state UI acceptance pending. |
| Native acceptance | Fresh install, upgrade from old consent, offline hide/report retry, post/reply/note/media menus, contact, block/unblock, and account deletion pending on the final candidate. |
| Distribution | Signed archive, upload/processing, build-14 attachment, privacy readback, requested 18+ App Store rating override/readback, final review reply, and resubmission pending. |

Backend evidence and the operator runbook are saved in the investigation outputs as `backend-moderation-verification.md` and `moderation-operator-runbook.md`. Do not convert a pending row to passed without its own result.

## Build and listing

- Version: `1.2.0`
- Candidate build: `14`
- Bundle ID: `com.pitchatlas.app`
- Privacy: https://pitch-atlas.com/privacy
- Support: https://pitch-atlas.com/support

Build 13 was the rejected submission, not the current candidate. Its October 30 archive, tests, and submission remain historical evidence in `docs/review-evidence/2026-10-30-build-13-submitted.md`. The corresponding build-12 and July build-11 evidence is also historical and does not certify build 14.
