# Pitch Atlas iOS Production Ship Plan

## Summary
- Ship a new production `com.pitchatlas.app` build to App Store Connect, TestFlight, and App Review.
- Work from the isolated release worktree on `codex/ios-release-hardening-20260622`.
- Treat production Supabase, simulator proof, App Store metadata, screenshots, and critique as release gates.
- Executed on 2026-06-24: build `1.0.1 (8)` supersedes the earlier build `6` review binary and build `7` visual-pass upload.

## Tasks
1. Completed: verified App Store Connect, TestFlight, branch, and build-number state before upload.
2. Completed: repaired production Supabase so the iOS block/unblock RPC contract exists live.
3. Completed: finished release-critical community validation, account safety copy, and App Store build guards.
4. Completed: added Pitch Atlas collectible-card polish without copying the supplied reference cards.
5. Completed: refreshed build number, release docs, App Review notes, privacy posture, and screenshot requirements.
6. Completed: ran MacBook iOS-runtime tests, simulator launch proof, screenshots, and annotated design critique.
7. Completed: uploaded build `8`, distributed it to internal TestFlight, attached it to app version `1.0.1`, and submitted it for App Review.

## Gates
- No fake pitch metrics, fake freshness, fake posts, or third-party marks.
- Production data-destructive operations require a stop-and-confirm gate.
- Screenshot proof is incomplete until rendered proof and annotated design/UX critique are both complete.
