# Pitch Atlas iOS Compliance Contract

This document describes candidate `1.2.0 (14)` and separates implemented behavior from release evidence. The candidate has not yet been established as uploaded or resubmitted.

## Scope and identity

Pitch Atlas is a native SwiftUI iPhone app with a bundled reference manual and a Supabase-backed community layer.

- Reading needs no account and does not create one.
- Posting field notes, discussion posts, replies, and public-post suggestions requires the versioned Community Terms and EULA plus confirmation that the contributor is 18 or older. Old consent does not satisfy the new gate.
- The first write creates an anonymous contributor record through `AuthSessionStore.ensureSessionForWrite()`. Apple or email sign-in can claim that record. Reporting, blocking, and contacting the developer do not require contribution consent or a claimed account.
- Image uploads require a claimed account, contribution consent, and image upload terms. The backend enforces claimed-account upload access. Images remain private until approved.
- Public-post suggestions are private review submissions and do not publish automatically. The suggestion form now includes the same terms and 18+ gate.
- Account deletion works for anonymous and claimed accounts through the JWT-protected `delete-account` Edge Function.
- Use production Supabase project `cloeoulvrrfcbitrjpso`; `ahump20/Pitch-Atlas` owns its migration and function source.
- iOS uploads are still images from PhotosPicker. No camera capture, video/GIF upload, push notifications, Firebase, Appwrite, or CloudKit is present.
- Teaching clips use TikTok's official player behind a poster tap in the app's single WKWebView, with credit and an outbound original-post link. They are not bundled, downloaded, or rehosted.

## Community safety

The candidate implements these Guideline 1.2 controls:

- Explicit zero tolerance for objectionable content and abusive users in the Community Terms and EULA, linked to Apple's Standard EULA.
- Versioned consent and 18+ confirmation before every contribution path.
- Server-side banned-term filtering for submitted text and approval before image publication.
- Hide and Report on posts, replies, field notes, and attached media. Hide is immediate and persisted locally, independent of authentication or network availability.
- Report hides first and saves a pending report before network delivery. Failed reports survive navigation and relaunch; Account > Safety exposes retries. Only confirmed server acceptance clears a pending report.
- Contributor block/unblock, bidirectional content filtering, and restrictions on direct replies across blocked connections.
- Contact developer in Account > Safety, Support, and the Community Terms. The form identifies Austin Humphrey, accepts an optional reply address, and shows success only after a server receipt. Restricted existing identities may still contact the developer.
- Automated moderation safeguards remove reported content from public view and restrict contributors before the 24-hour deadline. Moderator-confirmed violations lead to permanent removal and ejection. No staffed human-review guarantee is claimed.

Production migration `app_review_community_moderation` (source timestamp `20261105032000`) is deployed. The `pitch-atlas-community-review-deadlines` cron runs every 10 minutes, processing unresolved reports aged 22 hours. An actual scheduled run succeeded at `2026-11-05 04:20:00 UTC`. That proves a successful execution; continuing operation must still be monitored.

## Privacy

App Store privacy labels must not say Data Not Collected.

| Data | Purpose and handling |
| --- | --- |
| Email Address | Account access and an optional reply address submitted through Contact developer. |
| User ID | Contributor identity, including anonymous IDs used for community safety and support. |
| Other User Content | Field notes, discussion posts, replies, suggestions, and reports. |
| Customer Support | Private messages submitted to the developer for support and safety. |
| Photos or Videos | Still images selected by the user; no native video upload. |

All are linked to the user and used for App Functionality. None is used for tracking. There is no ATT prompt, advertising SDK, or analytics SDK. Contact information is sent only when the user submits the form. Account deletion clears the support sender's contributor-ID link, but the private message and optional reply email remain; there is no automatic contact-retention deadline or deletion job. The privacy policy discloses this and directs access/deletion requests to Contact developer.

`PrivacyInfo.xcprivacy` includes Customer Support and the UserDefaults required-reason declaration. UserDefaults stores versioned consent, device-local hidden-content preferences, and unsent reports retained for retry. The draft privacy policy is `docs/PRIVACY-POLICY.md`; production publication and App Store Connect label readback require separate evidence.

## Verified backend evidence

As of 2026-11-05 UTC:

- Production Apple provider is enabled; its public settings endpoint returned HTTP 200 with `external.apple=true`.
- Production moderation migration deployed; explicit post, note, and media report fixtures passed local and hosted rollback checks, and a real cron execution succeeded as recorded above.
- `submit_safety_contact(p_message, p_reply_email)` accepted a private message, returned a UUID receipt, deduplicated an identical retry within 10 minutes, enforced the five-messages-per-hour limit, and allowed an existing restricted sender.
- Pending images cannot be publicly read or signed for playback before approval.

Evidence: investigation outputs `backend-moderation-verification.md` and `moderation-operator-runbook.md`. Backend checks do not prove native interaction or Apple authorization completion.

## Remaining release gates

These remain pending until separately verified on the final candidate:

- Native Apple sign-in and anonymous-record claim, including failure/cancellation handling.
- Runtime unit tests and fresh-install/upgrade UI checks.
- New 18+ consent on notes, posts, replies, suggestions, and image uploads.
- Offline hide/report behavior and retry after navigation/relaunch from Account > Safety.
- Native contact success, failure, optional reply email, and restricted-account access.
- Native image upload, pending state, and approved-media readback.
- Posting/replying, block/unblock, and anonymous/claimed account deletion.
- Signed archive, App Store Connect processing/validity, and attached build identity.
- Current privacy labels, age questionnaire/override, support/privacy pages, review notes, and submission status read back from App Store Connect.

## App Store metadata

- Bundle ID: `com.pitchatlas.app`
- Display name: `Pitch Atlas`
- Candidate version/build: `1.2.0 (14)`
- Privacy URL: https://pitch-atlas.com/privacy
- Support URL: https://pitch-atlas.com/support
- Screenshots: 6.9-inch iPhone target
- Community contribution age: 18+. Apple also requested an App Store age-rating override of 18+; verify its saved readback separately from the in-app gate.
