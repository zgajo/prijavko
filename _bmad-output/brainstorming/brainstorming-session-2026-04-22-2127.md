---
stepsCompleted: [1, 2, 3, 4]
inputDocuments: []
session_topic: 'prijavko v1.0 — stress-test and expand the locked plan for an Android MRZ/OCR eVisitor batch-submission app (5-week solo Flutter build, target 2026-05-27)'
session_goals: 'All outcome types: surface hidden feature ideas, edge cases, differentiators, risks, and novel angles the locked plan may have missed. Push past the obvious into truly divergent territory before converging.'
selected_approach: 'ai-recommended'
techniques_used: ['Assumption Reversal', 'Chaos Engineering (Pre-Mortem)', 'SCAMPER Method']
ideas_generated: 45
context_file: ''
workflow_completed: true
---

# Brainstorming Session Results

**Facilitator:** Darko
**Date:** 2026-04-22

## Session Overview

**Topic:** prijavko v1.0 — stress-test and expand the locked plan for an Android MRZ/OCR eVisitor batch-submission app. Solo developer, part-time, 5 weeks to Play Store submission (target 2026-05-27). Flutter, no backend, Android-only, host-only, single-OIB, free with AdMob.

**Goals:** All outcome types — feature ideas, solutions, differentiators vs. PrijaviTuriste/mVisitor, edge cases to handle, adversarial angles on the locked scope, and novel directions not yet considered.

### Session Setup

The incoming document is remarkably locked: positioning, capture pipeline, queue semantics, error handling, non-negotiables, conflicts resolved, timeline, success metrics, and non-goals are all named. The brainstorm therefore flips from "generate scope" to "stress-test and expand" mode — find what the locked plan misses before it becomes PRD-permanent.

## Technique Selection

**Approach:** AI-Recommended Techniques
**Analysis Context:** Locked-scope Flutter MVP, solo part-time dev, 5-week deadline, Android-only, no backend, eVisitor single dependency. Best served by adversarial + generative pass.

**Recommended Techniques:**

- **Assumption Reversal** *(deep)* — Flip each of the ~23 locked decisions to find which are conclusions and which are hidden bets. Phase 1 — opens the widest aperture.
- **Chaos Engineering / Pre-Mortem** *(wild)* — Jump to 2026-05-27 and walk backwards through every failure mode. Phase 2 — turns flipped assumptions into concrete risks.
- **SCAMPER Method** *(structured)* — Seven-lens systematic pass for differentiation vs. PrijaviTuriste/mVisitor and v1.1+ ideas. Phase 3 — forces convergence toward actionable angles.

**AI Rationale:** Locked plans fail on unchecked assumptions and unimagined failure modes, not on missing features. Techniques ordered to open → stress → structure, divergent before convergent, target 100+ raw ideas before organizing.

---

## Phase 1 — Assumption Reversal

### Flip #1 — "Host-only. No guest self-check-in."

**Verdict:** v1.0 position **confirmed** (host-only stays). Guest-side flows filed as **v1.1+ Future Vision**.

**The tension surfaced:** Self-scan saves host time but does not shift legal responsibility — the host remains the data controller under Croatian tourism law, and eVisitor validation is format-only, not identity-proofing. Design problem for any future guest-side flow is therefore *"decouple capture effort from the host's legal verification obligation."*

#### Future Vision (v1.1+) — captured for later

**[Positioning #1]: Pre-Queue Inbox**
*Concept*: Guest self-scan lands in a "Pending" inbox on host's device, separate from the outgoing queue. Host approves with one tap at the door; data moves to real queue. Host never types but still legally signs off.
*Novelty*: Separates *who captured the bytes* from *who attested to the identity*. eVisitor only sees host submission, so legal chain intact.

**[Positioning #2]: Pre-Arrival Self-Scan + Door-Side Liveness**
*Concept*: Guest pre-scans before arrival via SMS/browser link. Self-scan captures document + selfie; on-device face-match attaches similarity score to the Pending entry. Host at door does the physical match in 5 seconds.
*Novelty*: Moves check-in work off the critical door-moment path entirely.

**[Positioning #3]: Proof-of-Possession Self-Scan**
*Concept*: Self-scan requires two captures — document alone + document held in hand. Raises fraud cost without biometric regulatory burden.
*Novelty*: Uses physics as verification, not ML. Copy-paste-a-passport-JPEG fraud becomes "need a real person holding a fake document on camera," massively harder.

**[Architecture #2]: Two-Queue State Machine**
*Concept*: `pending_entries` table + `submission_queue` table; host approval is a state transition. Generalizes beyond self-scan — OCR-path entries could also land in Pending for deliberate second review.
*Novelty*: Turns OCR from "interrupt-flow-to-edit" into "defer-to-batch-review" — better happy-path UX even in host-only mode.

**[UX #1]: Pending Badge on Session List**
*Concept*: Session list shows "3 scanned, 2 pending review" with one-tap filter. Visible unresolved state beats invisible technical debt.
*Novelty*: Solves a *current* v1.0 UX problem: OCR-path guests the host meant to revisit and forgot.

**[UX #2]: Pre-Check-In Link via Native SMS Intent**
*Concept*: Host pastes guest phone number, app opens native SMS app with pre-filled link. Host's phone bills the SMS. Zero backend, zero Twilio, GDPR-clean.
*Novelty*: Moves effort from 23:40 stressful moment to calm morning prep.

**[Architecture #4]: Stateless Signed Link (GitHub Pages + Firebase)**
*Concept*: Pre-check-in URL is a static GitHub Pages + HMAC-signed token. Guest scan data encrypted client-side, lands in Firestore doc with 24h TTL, host decrypts on device. Firebase already in-scope for Crashlytics.
*Novelty*: Zero app server, minimal backend surface.

**[ML #1]: On-Device Face-Match (speculative)**
*Concept*: TF Lite MobileFaceNet or similar for selfie↔document face similarity. Informational, non-blocking.
*Novelty*: [Flagged speculative — ML Kit Face Detection alone is only detection/landmarks. True face-match needs heavier models and Play data-safety disclosure. Likely v1.5.]

**[Anti-fraud #1]: Two-Shot Composition Requirement**
*Concept*: Self-scan validates that shot #2 (document-in-hand) differs significantly from shot #1 (document alone). Client-side pixel delta + presence-of-person check.
*Novelty*: Blocks 80% of trivial fraud without biometric regulatory burden.

**[Marketing #1]: "The only Croatian check-in app that verifies the document is in the guest's hand."**
*Concept*: Proof-of-possession as Play Store listing headline for v1.1. PrijaviTuriste and mVisitor don't do this.
*Novelty*: Markets on *accountability* (what a regulator-conscious host cares about) instead of *convenience* — different emotional register, different reviewer base.

**[Edge case #1]: Group / Family Bookings**
*Concept*: Parent as "custodian" scans all children's docs with their own face/document in-frame. ~30% of Croatian tourism check-ins are families; self-scan without family semantics is DOA.
*Novelty*: Per-family custodian model handles a class of users most KYC flows ignore.

**[Legal #1]: GDPR Minimization — Delete Liveness Artifacts on Approval**
*Concept*: Proof-of-possession photos never leave device and auto-delete the moment the Pending entry transitions to `submission_queue`. No biometric artifact lives past review.
*Novelty*: Radical minimization — most KYC products retain liveness artifacts for audit; you can delete because the verifier is the host present at the door, not a future auditor.

#### v1.0 Architecture Hooks (cheap now, expensive later) — **REJECTED for v1.0**

User verdict: these are premature for v1.0 scope. Revisit when v1.1 roadmap is actually being planned, not now. Named here for the record:

- Drift `entry_source` enum column
- Graph-shaped queue state machine with `awaiting_host_confirmation` future state
- OIB + facility ID as a signable unit in profile storage

**Rationale for rejection:** violates JIT principle. v1.0 doesn't need them, and adding them "just in case" is the exact kind of speculative engineering the locked decisions guard against. If v1.1 is ever built, a Drift migration to add the column then is cheap enough.

---

### Flip #2 — "Android-only for v1.0. No iOS build."

**Verdict:** v1.0 position **confirmed**. Flutter Web / PWA alternative explicitly rejected by user — not even as v1.1+ direction. Android-native remains the single delivery surface. iOS deferred to post-launch consideration (separate native build, not cross-platform shortcut).

Load-bearing reasons: (1) MRZ read quality on mobile browsers is unacceptable — ML Kit does not run in browser, and Tesseract.js / WASM MRZ parsers are meaningfully slower with lower read rates; (2) Play Store discoverability is load-bearing for solo-dev distribution — Croatian hosts search "eVisitor" in Play Store, not in Google; (3) Sound + haptic on iOS Safari PWA is restricted, and those are core UX affordances, not niceties.

---

### Flip #3 — "Single OIB per user session. Multi-OIB means install twice."

**Verdict:** v1.0 position **flipped** — install-twice pattern is rejected as poor UX (Play Store flags duplicate installs; users get confused with identical icons). Multi-OIB support confirmed as **planned v1.1 feature**.

**Decisions:**

**[Architecture #5]: OIB as First-Class Schema Axis (single-OIB UI in v1.0)** — **ADOPTED**
*Concept*: Drift schema has `oib` on every facility profile from v1.0. App enforces single-OIB at the UI layer only (profile picker filtered to the active OIB). v1.1 unlocks multi-OIB via UI change; zero data migration needed.
*Novelty*: Honest "constraint in UI, not in data model" — because the data model doesn't benefit from the constraint. JIT-compliant because multi-OIB is a committed v1.1 feature, not speculative.

**[Alternative #2]: "Replace Active OIB" Setting** — **ADOPTED as v1.0 scope**
*Concept*: Settings entry that wipes all facility profiles, credentials, queue, and history, then re-launches onboarding. Guarded by destructive-action confirmation (OIB re-entry required).
*Novelty*: Pressure valve for OIB *transitions* (sold one rental business, bought another under a new legal entity) without requiring multi-OIB switcher UI in v1.0.
*Scope impact*: Adds ~half-day of work — Settings entry, confirmation dialog with typed-OIB guard, wipe-then-re-onboard flow. Non-threatening to 5-week timeline.

**Open question (low priority):** Multi-OIB frequency in the Croatian small-host market is unknown. Worth a post-launch signal — add a "how many OIBs do you operate under?" question to the in-app feedback form in v1.0 so Week 6+ data informs the v1.1 multi-OIB UX.

---

### Flip #4 — "MRZ-first, OCR-second, manual-third."

**Verdict:** v1.0 three-tier cascade **confirmed**. User declined to adopt any of the four captured provocations for v1.0. All four filed as v1.1+ candidates — worth revisiting when first-month real-world scan data is available.

#### Future Vision (v1.1+) — Capture pipeline refinements

**[Capture #1]: Diagnostic Retry Screen before Manual Fallback**
*Concept*: On MRZ+OCR failure, show the user what the camera actually captured (cropped MRZ strip + parsed attempt) alongside Retry and Type-manually CTAs.
*Novelty*: Shifts user-blame attribution from "the app is broken" to "the photo was blurry" by surfacing camera output. Reduces 1-star reviews that come from opaque failures.

**[Capture #2]: Document-Type-Split Pipeline**
*Concept*: Passport path = MRZ-or-manual (skip OCR entirely since ICAO 9303 MRZ is reliable on passports). ID Card path keeps OCR fallback (older Croatian IDs benefit).
*Novelty*: Uses the host's existing Passport/ID button press as a pipeline selector, not just a UI hint. Reduces test surface by ~40%.

**[Capture #3]: OCR-as-Verification (Parallel Cross-Check)**
*Concept*: Run MRZ and OCR in parallel. Flag disagreements in the review card (e.g., MRZ says document #X, OCR reads #Y). Disagreement is rare but indicates one source is wrong.
*Novelty*: Catches a class of bugs where MRZ is technically valid (checksum passes) but belongs to a different document (reused test data, cloned doc). Cheap extra poka-yoke layer on top of existing parsing.

**[Capture #4]: Drop OCR Entirely (Contrarian Minimalism)**
*Concept*: MRZ + a very good manual form, no ML Kit dependency. ~5MB smaller APK, simpler Play Store data-safety disclosure, no long-tail OCR bugs. Accept ~5% of older ID cards as manual-entry cases.
*Novelty*: Contrarian positioning in a market adding more ML. "Small, fast, works offline, no hidden AI."

---

### Flip #5 — "Static capture only. No live MRZ scanning, no auto-shutter."

**Verdict:** v1.0 position **flipped** — Hybrid Live-First with Static Fallback adopted for v1.0.

**[Capture #5]: Hybrid Live-First, Static-Fallback** — **ADOPTED for v1.0**
*Concept*: Default to live MRZ detection with auto-shutter when a valid MRZ appears in frame. If no detection after ~3s, UI falls back to tap-to-capture button. Matches competitor muscle memory (PrijaviTuriste / mVisitor do live scanning) while keeping low-end reliability intact via the static fallback path.
*Novelty*: Uses *timeout-to-manual-capture* as the degradation path instead of *format-to-manual-entry*. Preserves industry-standard fast-path without sacrificing low-end reliability.
*Scope impact*: ~1–2 extra days in Week 2 — camera preview UI, live MRZ detection loop (ML Kit Text Recognition live mode or `mobile_scanner`-style continuous feed), auto-shutter trigger, 3s timeout→static fallback state machine. Fits the 5-week plan.

**Week 2 risk to monitor:** live MRZ detection on API 24+ low-end devices can run hot / drain battery. Integration test harness must include a low-end profile (e.g., throttled CPU via ADB) or acceptance on real mid-range 2020 device before declaring the week done.

---

### Flip #6 — "Host picks Passport or ID Card manually before capture."

**Verdict:** v1.0 position **confirmed** (two-button selector stays). Auto-type-detection via MRZ parser output rejected.

Rationale captured: even though MRZ parser output includes document type as a free byproduct, keeping the pre-capture type selector gives the user an explicit, reviewable commitment before the camera fires. Also simplifies the manual-entry path (type is already known) and gives the camera screen a clearer "Passport scan" vs. "ID Card scan" affordance.

---

### Flip #7 — "Binary MRZ pass/fail. No per-field confidence UI."

**Verdict:** v1.0 position **extended** — binary pass/fail UX stays, but a **semantic sanity layer** is added on top of MRZ checksum validation.

**[Capture #7]: Semantic Sanity Layer on Top of MRZ Checksum** — **ADOPTED for v1.0**
*Concept*: Even on MRZ checksum pass, run post-parse sanity checks: birth date in plausible range (e.g., 1900–today), document expiry not in the past, nationality is a real ISO 3166 code, issuing country matches expected encoding. Any failure downgrades the review card to editable state with the suspicious field visually flagged.
*Novelty*: Checksum validates *encoding*, not *meaning*. Sanity layer is cheap (~20 lines of Dart) and catches a real gap — a document with a clean MRZ checksum can still contain semantically garbage data if source MRZ has damage that doesn't affect checksum digits.
*Scope impact*: ~2–4 hours. Integration tests must cover each sanity rule with fixture MRZ strings. Fits cleanly into Week 2 MRZ pipeline work.

**Hansei note:** This flip exposed a real gap in the locked plan. The "host is the confidence model" principle is sound for *ambiguous* cases, but *impossible* cases (date 1899-02-30) should never reach the host at all — poka-yoke says catch at the source. Good catch from the flip exercise.

---

### Flip #8 — "Neutral App pattern. No persistent facility toggle."

**Verdict:** v1.0 neutral-app principle **confirmed and strengthened** with a last-facility shortcut.

**[UX #4]: Last-Facility Shortcut on Start Scanning** — **ADOPTED for v1.0**
*Concept*: Start Scanning screen presents the most-recently-used facility as a primary button ("Continue at Apartment A") alongside the full facility picker, both equally visible. One-tap for the 80% repeat-case; picker visible to prevent autopilot mis-taps.
*Novelty*: Preserves the no-persistent-toggle safety — every session still makes an explicit facility choice — while eliminating pick-from-list friction. Solves speed concern without weakening poka-yoke.
*Scope impact*: ~2–3 hours in Week 3 session-flow work.

---

### Flip #9 — "No background auto-retry. Host taps Send manually."

**Verdict:** v1.0 passive-queue principle **confirmed and strengthened** by closing two gaps around partial-batch failures. Neither is a new feature — both are details the locked decision depends on to be safe.

**[Queue #1]: Idempotency via Client-Side Guest UUID** — **ADOPTED for v1.0**
*Concept*: Every queued guest gets a client-generated UUID at scan time, persisted in Drift. If eVisitor's `ImportTourists` supports an idempotency key, use it. If not, rely on eVisitor's natural duplicate-detection on `document_number + date_of_birth + date_of_entry`.
*Novelty*: Handles "network dropped mid-submit" deterministically — on retry, eVisitor either accepts (never saw it) or rejects as duplicate (already landed). Either outcome is safe for the host.
*Scope impact*: minimal — UUIDs already standard. Load-bearing work is the **Week 1 spike** verifying eVisitor's duplicate-detection behavior against real credentials or fake.

**[Queue #2]: Explicit `in_flight` Queue State** — **ADOPTED for v1.0**
*Concept*: Queue state machine has an `in_flight` state between `ready_to_send` and `accepted`/`rejected`. On app resume after crash or kill, any `in_flight` entries are re-queried against eVisitor before retrying.
*Novelty*: No silent double-submits. Makes the no-background-retry decision *safer*, not weaker. Directly supports process-death survival already required by Week 3 gate.
*Scope impact*: ~half day in Week 3 queue-state-machine work. Needs a `GetTourists`-style read endpoint on the eVisitor side, or acceptance that `in_flight` entries on resume require host review/decision if lookup unsupported.

---

### Flip #10 — "Deferred eVisitor auth. Login happens on first Send All."

**Verdict:** v1.0 deferred-auth principle **confirmed and strengthened** by decoupling auth health from submission UX.

**[Auth #1]: Opportunistic Silent Auth + Non-Blocking Credential Banner** — **ADOPTED for v1.0**
*Concept*: Silent `/auth` attempt when app opens and network is available. Success caches `.ASPXAUTH` cookie until expiry. Failure shows a persistent but non-modal banner on the session list: "eVisitor login needs attention." Tapping routes to credential edit. Scanning path never blocks on auth.
*Novelty*: Host finds out about credential problems *hours before* Send All matters, not at the tired-and-want-to-finish moment. Decouples auth health from scanning UX.
*Scope impact*: ~1 day in Week 4 auth/error-handling work. Needs a credential-health state in Drift, a banner widget, and a background auth check coordinator.

**[Auth #2]: Send All Pre-Flight Credential Check** — **ADOPTED for v1.0**
*Concept*: On Send All tap, app performs auth check (up to ~3s) before submission loop begins. Auth failure surfaces as "fix login first" instead of "20 submission errors."
*Novelty*: Distinguishes "auth failed" from "submission failed" in the error UX. Host gets one clear next action instead of a wall of identical-looking rejections.
*Scope impact*: ~half day, folded into existing Send All flow.

---

## 📊 Cumulative v1.0 Scope Addition Audit

**So far, this brainstorm has added to v1.0 scope:**

| ID | Addition | Est. Effort | Week |
|----|----------|-------------|------|
| Alternative #2 | "Replace Active OIB" Setting | ~½ day | Week 3 |
| Architecture #5 | OIB schema column (single-OIB UI) | ~1 hr | Week 1 |
| Capture #5 | Hybrid Live-First, Static-Fallback | ~1–2 days | Week 2 |
| Capture #7 | Semantic Sanity Layer on MRZ | ~2–4 hrs | Week 2 |
| UX #4 | Last-Facility Shortcut | ~2–3 hrs | Week 3 |
| Queue #1 | Idempotency UUID | ~minimal + spike | Week 1 |
| Queue #2 | `in_flight` Queue State | ~½ day | Week 3 |
| Auth #1 | Opportunistic Auth + Banner | ~1 day | Week 4 |
| Auth #2 | Send All Pre-Flight Check | ~½ day | Week 4 |

**Total estimate: ~4–5 additional working days across Weeks 1–4.**

With ~25 working days in a 5-week plan (and solo-part-time that realistically halves), this is meaningful. **Flag for consideration:**

- Week 2 is now heaviest-loaded (Hybrid capture + sanity layer + core MRZ/OCR pipeline).
- Queue #1 idempotency depends on Week 1 spike outcome — if eVisitor has no idempotency key AND weak duplicate detection, Queue #2 in_flight state becomes the *only* safety mechanism and Week 3 work expands.
- None of the additions threaten the Play Store 2026-05-27 target *individually*, but cumulatively they erode the buffer.

**Recommendation at Hansei checkpoint (end of this brainstorm):** review whether any additions should actually be v1.1 to preserve schedule headroom. Candidates to defer if pressure appears: Capture #5 (Hybrid live — defer to v1.1, ship static-only first), Auth #1 (Opportunistic banner — keep only Auth #2 pre-flight check).

---

### Flip #11 — "Free with AdMob. 'Coffee money' monetization."

**Verdict:** v1.0 position **confirmed**; v1.1 path planned.

**[Business #2]: Free-with-Ads in v1.0, Remove-Ads IAP in v1.1** — **ADOPTED (v1.1 plan)**
*Concept*: Ship v1.0 as locked. v1.1 adds Play Billing IAP (~€4.99 one-time) bundled with the reported-guests history view, branded as "prijavko Pro." Uses 60 days of real install/rating data as validation before committing to payment infrastructure.
*Novelty*: Decouples adoption validation from monetization validation. v1.1 "Pro" framing (history view + ad-free) is clearer to users than a standalone "remove ads" IAP.

---

### Flip #12 — "30-day local history. Auto-purge after 30 days."

**Verdict:** v1.0 position **flipped**. Retention policy extended and export added. ⚠️ One number (1 year default) needs legal verification before PRD.

**[Business #4]: Retention = 1 Year Default, User-Configurable** — **ADOPTED for v1.0 (number pending verification)**
*Concept*: Change default retention from 30 days to **1 year** (matches estimated Croatian tourism audit window — needs actual legal research). Settings offers 30 days / 90 days / 1 year / Forever. Drift size impact is trivial (~5KB × hundreds of guests = <1MB).
*Novelty*: Aligns retention with the host's legal record-keeping reality, not an arbitrary app-hygiene number.
*⚠️ Open research task for PRD author*: Verify actual Croatian audit window — could be 3 or 5 years. If so, update default accordingly.

**[Business #3]: Export to CSV/PDF** — **ADOPTED for v1.0**
*Concept*: Settings entry: "Export all records" → CSV (for accountant) or PDF (for inspector). Host can archive to Drive, email to self, etc.
*Novelty*: Decouples app retention from host record-keeping obligation without taking on cloud storage risk.
*Scope impact*: ~½ day in Week 5.

---

### Flip #13 — "Zero PII in logs or Crashlytics."

**Verdict:** v1.0 principle **strengthened** with type-level + build-level enforcement.

**[Security #1]: Type-Level PII Guard via `toString()` Redaction** — **ADOPTED for v1.0**
*Concept*: Types holding PII (`GuestDocument`, `Credentials`, `MrzData`, `GuestRecord`, etc.) override `toString()` to return `"[REDACTED]"`. Makes accidental PII logging via string interpolation impossible at the type level.
*Novelty*: Error-proofing by design — "can't accidentally log what can't be stringified." Burden of "remember not to log this" moves from developer memory to type system.
*Scope impact*: ~2–3 hours spread across Weeks 1–3 as PII types are defined.

**[Security #2]: CI Grep Guard on Forbidden Log Patterns** — **ADOPTED for v1.0**
*Concept*: CI step (GitHub Actions) or pre-commit hook greps for `log.` / `print(` / `debugPrint(` calls that reference PII-holding types. Build fails if matches found.
*Novelty*: Turns "don't log PII" from a policy into a build-time guarantee. Catches future-you when context has faded.
*Scope impact*: ~1 hour in Week 1 tooling setup.

---

## Phase 1 Summary — Assumption Reversal Complete

**13 flips processed. ~30 ideas captured. v1.0 scope adjusted as documented above.**

Updated cumulative v1.0 scope additions (incorporating Flips #11–13):

| ID | Addition | Est. Effort | Week |
|----|----------|-------------|------|
| Alternative #2 | "Replace Active OIB" Setting | ~½ day | Week 3 |
| Architecture #5 | OIB schema column | ~1 hr | Week 1 |
| Capture #5 | Hybrid Live-First Scanning | ~1–2 days | Week 2 |
| Capture #7 | Semantic Sanity Layer | ~2–4 hrs | Week 2 |
| UX #4 | Last-Facility Shortcut | ~2–3 hrs | Week 3 |
| Queue #1 | Idempotency UUID | minimal + spike | Week 1 |
| Queue #2 | `in_flight` Queue State | ~½ day | Week 3 |
| Auth #1 | Opportunistic Auth + Banner | ~1 day | Week 4 |
| Auth #2 | Send All Pre-Flight Check | ~½ day | Week 4 |
| Business #4 | 1-year retention (configurable) | ~1 hr | Week 3 |
| Business #3 | Export CSV/PDF | ~½ day | Week 5 |
| Security #1 | Type-Level PII Guard | ~2–3 hrs | Weeks 1–3 |
| Security #2 | CI Grep Guard | ~1 hr | Week 1 |

**Total: ~5–6 extra working days across Weeks 1–5.** Tight but feasible; tight enough that Phase 2 pre-mortem should flag which v1.0 adds are at real risk if schedule slips.

**Deferred to v1.1+ (filed as Future Vision above):** All 10 guest-self-scan ideas, 2 Flutter Web ideas *(user-rejected even as future vision — remove if editing again)*, 4 capture-pipeline refinements, 1 monetization IAP plan.

⚠️ **Research task for PRD author:** Verify Croatian tourism audit/retention legal window. Current 1-year default in [Business #4] is a placeholder estimate.

---

## Phase 2 — Pre-Mortem / Chaos Engineering

**Frame:** Standing on 2026-05-27 and walking backwards through 20 failure modes that could derail the Play Store launch or the first post-launch month. Each tagged **A** (adopt mitigation), **R** (accept risk), or **X** (not a real risk).

### Adopted Mitigations (v1.0 scope additions)

**[F2] `.ASPXAUTH` Cookie Edge Cases — ADOPTED**
*Mitigation:* Dio interceptor with explicit `401`/`302`→re-auth→retry-once logic. Integration tests that simulate mid-batch cookie expiry.
*Scope impact:* ~half day in Week 4 auth/error-handling work.

**[F3] eVisitor Rate-Limiting at Peak Hours — ADOPTED**
*Mitigation:* Exponential backoff on `429`, user-visible "eVisitor is busy, retrying..." message. Don't fight the API — surface the delay.
*Scope impact:* ~2–3 hours in Week 4.

**[F6] First 10 Reviews = 1-Star from Capture Failures — ADOPTED**
*Mitigation:* Soft launch via Play Console "Internal Test" or "Closed Beta" for 1–2 weeks before public listing. Invite 10 real Croatian hosts through existing channels. Fix obvious issues under cover before public Play Store ranking is exposed.
*Scope impact:* Process change, not code — adds ~1–2 weeks to real launch date if 5-week build already done, or pulls launch-date messaging apart from Play-Store-visibility-date.

**[F8] Keystore Credential Loss on Device Migration — ADOPTED**
*Mitigation:* Onboarding explicitly warns "your eVisitor logins live on this device only." On app launch if Keystore returns no value for an existing facility profile, show a non-blocking "credentials missing — re-enter to continue" state with facility names pre-populated from Drift. Softens the device-migration blow.
*Scope impact:* ~2–3 hours in Week 3.

**[F10] Data Safety Form Rejection — ADOPTED**
*Mitigation:* Start Play Console Data Safety form in **Week 3**, not Week 5. File pre-submission review if available. Over-disclose rather than under-disclose. Any Week 4 app behavior change must flag "does this need a Data Safety form update?"
*Scope impact:* Process change. Moves a Week 5 activity earlier; net time roughly the same, risk buffer much larger.

**[F14] Third-Party SDK Silently Logs PII to Crashlytics — ADOPTED**
*Mitigation:* Beyond Security #1 + #2 from Flip #13: disable Dio logging entirely in release builds, configure Crashlytics `setCustomKey` allowlist, explicit review of every transitive dependency's default logging. Staging acceptance test: trigger an intentional crash in a PII path, inspect Firebase Console, verify no guest/credential data present.
*Scope impact:* ~3–4 hours in Week 4, staging test part of Week 5 security review.

**[F18] Competitor Ships Free Version First — ADOPTED**
*Mitigation:* Can't prevent, only differentiate. Lean on the 1-year retention + CSV/PDF export ([Business #3] + [Business #4]) and opportunistic auth banner ([Auth #1]) as listing differentiators competitors won't replicate in 5 weeks.
*Scope impact:* Play Store listing copy — Week 5 task.

**[F19] Solo Dev Burnout / Illness / Life Event — ADOPTED**
*Mitigation:* Define explicit **slip protocol** — ordered feature drop list if any week goes sideways. Current ordered candidates to defer from v1.0 if schedule pressure hits: Capture #5 Hybrid Live → Business #3 Export → Auth #1 Opportunistic Banner → Alternative #2 Replace-OIB Setting. Weekly Hansei checkpoint (not monthly). Accept 5 weeks = ~5 weeks of *real work*, not 5 calendar weeks.
*Scope impact:* Process discipline, not code.

**[F20] Week 5 AI Review + Integration Test Remediation Blowout — ADOPTED (extended)**
*Mitigation:* Run AI coverage review **AND** security scan at the end of *every* epic (Weeks 1, 2, 3, 4), not only Week 5. Findings remediated in the same week they're discovered. Week 5 reserved exclusively for Play Store prep with zero open technical dependencies. User-added: security scan must also run after each epic, not only Week 5.
*Scope impact:* ~half day per epic (4 epics = 2 days) folded into each epic's definition-of-done.

### Accepted Risks (conscious, documented)

**[F9] Drift Performance at 40+ Guests/Session — ACCEPTED**
*Rationale:* Riverpod + Drift + paginated list defaults are likely sufficient. Revisit only if real-world peak-season reveals UI lag. Not worth preemptive optimization in v1.0.

**[F16] Wrong-Facility Submission Despite Neutral-App — ACCEPTED**
*Rationale:* User explicitly accepts residual risk. Locked Neutral App pattern + last-facility shortcut + facility-name banner on scanner screen are judged sufficient. If post-launch data surfaces this as a real failure pattern, tighten with session auto-expiry (Flip #8 Provocation A) in v1.1.
*⚠️ Note for PRD author:* This risk has regulatory-consequence potential — worth mentioning in the risk register with explicit user acknowledgement.

### Dismissed — Not a Real Risk

**[F4] MRZ Read Rate <70%** — dismissed. Existing OCR fallback + manual entry + adopted Semantic Sanity Layer ([Capture #7]) judged sufficient.

**[F5] Hybrid Live MRZ Battery Drain** — dismissed. Will surface in Week 2 real-device testing; no preemptive mitigation warranted.

**[F11] AdMob Account Suspension** — dismissed. User plan: internal-tester distribution with friends first, AdMob not live until confidence established — removes cold-launch AdMob-review risk.

**[F12] Privacy Policy Fails Review** — dismissed. User takes responsibility for policy content quality.

**[F13] Dedicated Google Account Flagged** — dismissed. User has sufficient account hygiene.

**[F15] UMP/CMP Consent Flow Broken** — dismissed. User confident Google's UMP SDK is well-trodden.

**[F17] Onboarding Drop-Off at First Credential Entry** — dismissed. Deferred-auth principle already in locked plan handles this — credentials prompted at first Send All, not in onboarding.

### Modified Mitigation — User Alternative

**[F1] Week 1 API Spike Fails — USER-PREFERRED MITIGATION**
*User rationale:* Doesn't want to block 5-week plan on upstream test-credential availability. Original mitigation ("book Week 1 for spike, reach out for credentials in advance") rejected.
*Adopted instead:* Proceed with **in-repo Dio fake** seeded with realistic test data, mirroring the documented eVisitor contract. Build the full v1.0 pipeline against the fake. When real test credentials eventually arrive (before launch or post-launch), flip to real API with minimal code surface change. The fake remains the permanent integration-test harness.
*⚠️ Residual risk:* If the real eVisitor contract diverges materially from documented behavior, a post-fake integration phase may surface surprises. Mitigation: keep the Dio fake's contract conservative/spec-strict so surprises fail the real-API test immediately rather than silently.

### [F7] Process Death Loses In-Flight Data — ADOPTED for v1.0

*Mitigation:* Every guest-confirm tap performs a synchronous Drift `transaction { ... }` with explicit `await` to commit before the success haptic + sound fires. UI success signal is the handshake proving durable persistence. If write fails (process killed, SQLite error), user hears no ding and will naturally re-scan → safe behavior by design.
*Scope impact:* ~2–4 hours in Week 3 queue-state-machine work. Add integration test that simulates process kill mid-write and verifies persistence.
*Rationale:* Adopted on delegation — cheap, and the failure mode produces the exact kind of silent-corruption bug that destroys trust in a regulatory tool. Poka-yoke says never accept an uncommitted write.

---

## Phase 3 — SCAMPER

**Frame:** Seven-lens systematic pass for differentiation angles and v1.1+ roadmap seeds. 14 ideas generated, tagged V1 / V1.1 / KILL.

### Adopted for v1.0

**[A2]: Post-Submit Closure Summary** — **ADOPTED for v1.0**
*Concept:* After Send All succeeds, show "Summary: N guests registered at Facility X, M at Facility Y. All confirmed by eVisitor at HH:MM." Shareable as a screenshot for host's own records.
*Novelty:* Provides emotional closure plus doubles as proof-of-submission artifact. Screenshot is a lightweight "receipt" replacing any need for a dedicated export on the happy path.
*Scope impact:* ~2–3 hours in Week 4, folded into Send All success flow.

### v1.1 Roadmap (ordered approximately by impact × cost)

**[S1]: NFC Chip Read for Modern Passports** 🔥 — **v1.1 headline feature**
*Concept:* Read ICAO 9303 NFC chip on modern passports via `flutter_nfc_kit`. Sub-second, signed, zero OCR errors. Host taps passport against phone.
*Novelty:* **Genuine differentiator** — PrijaviTuriste and mVisitor do not do this. Marketing line: "Tap the passport. Done." Technically smaller than camera+MRZ+OCR path.
*Prerequisite:* Android NFC is mature; no real blocker. Passport coverage is ~80% of modern-issued documents but zero for older passports and all ID cards, so NFC is *additive* to the existing scan pipeline, not a replacement.

**[A1]: Revolut-Style Scan Rhythm UX** — v1.1
*Concept:* Adopt the animated "processing document..." micro-interaction pattern from banking KYC flows. Small haptic on capture, animated scan line, tick on success.
*Novelty:* Cheap polish that signals "professional" to hosts who use banking apps daily. Defer from v1.0 to avoid Week 2 scope creep.

**[E1]: Drop AdMob, Paid-Once €4.99 App** — **v1.1 business model pivot candidate**
*Concept:* Post-v1.0, evaluate replacing free+ads with a one-time €4.99 paid app. No AdMob SDK, no UMP/CMP, no Firebase ads analytics. Cleanest privacy story possible.
*Novelty:* Inverts Flip #11's v1.1 IAP plan. Instead of "free + Pro IAP," go "paid-only, no ads ever."
*⚠️ Tension with Flip #11:* Flip #11 v1.1 plan was "free + Remove-Ads IAP" (keeps free funnel, monetizes opt-in). E1 is "paid from install" (no free funnel, monetizes at first contact). These are competing bets — Darko should decide between them when v1.0 install/review data exists. Capturing both is fine for now.

**[P1]: Small-Boat Tourism / Charter Yachts** — v1.1
*Concept:* Boat captains register day-guests under an OIB using the same eVisitor API. Marketing/positioning expansion, zero code.
*Novelty:* Adjacent segment with identical tech fit. Play Store listing keyword expansion.

**[P2]: Small Hostel / Agritourism Segments** — v1.1
*Concept:* Same as P1 — adjacent regulated segments with slightly different operational rhythms.
*Novelty:* Expands TAM without expanding code scope.

### Killed — Explicit Dismissals

- **[S2]: Sentry Self-Hosted** — KILL. Firebase Crashlytics is fine for solo-dev v1.0; self-hosting Sentry is over-engineering.
- **[C1]: iCal Booking Import** — KILL. User rejected despite being a potentially strong differentiator. (Noted here in case revisit ever justifies.)
- **[C2]: Tourist Tax Calculator** — KILL. Reconfirms existing v1.0 non-goal on tax calculation.
- **[M1]: Implicit Session Auto-Close on Idle** — KILL. Redundant with accepted [F16] risk.
- **[M2]: 30-Second Onboarding** — KILL. Existing onboarding plan is sufficient.
- **[E2]: Home-Screen "Scan Guest" Widget** — KILL. Not valuable enough vs. dev cost.
- **[R1]: Geolocation-Based Facility Auto-Suggest** — KILL. Location handling adds permissions + privacy-policy surface disproportionate to the time savings.
- **[R2]: Tourist Board Sponsorship** — KILL. Long-shot outreach not worth pursuing at this stage.

---

## Session Complete — Ready for Organization

**Total ideas captured: ~45.**

**Phase 1 (Assumption Reversal):** 13 flips, ~30 ideas, v1.0 scope adjusted with 13 adopted additions.
**Phase 2 (Pre-Mortem):** 20 failure modes, 9 mitigations adopted into v1.0, 1 user-preferred alternate, 2 accepted residual risks, 7 dismissed.
**Phase 3 (SCAMPER):** 14 ideas, 1 adopted into v1.0 ([A2] Post-Submit Summary), 5 queued for v1.1, 8 killed.

**Final cumulative v1.0 scope additions from this brainstorm:** ~14 items, estimated ~6–7 additional working days across Weeks 1–5. Tight but feasible. See consolidated scope summary below (next step).

---

# 📋 Consolidated Session Output

## Theme 1 — Capture Pipeline (v1.0 additions)

| ID | Item | Week | Effort |
|----|------|------|--------|
| Capture #5 | **Hybrid Live-First, Static-Fallback scanning** — live MRZ detection with 3s timeout→static tap-to-capture | 2 | 1–2 days |
| Capture #7 | **Semantic Sanity Layer** on top of MRZ checksum — reject impossible dates, invalid ISO codes, expired docs | 2 | 2–4 hrs |

*Theme insight:* Week 2 becomes the heaviest week. These additions are the most at-risk if pace slips — Capture #5 is the first defer-to-v1.1 candidate in the [F19] slip protocol.

## Theme 2 — Queue, State, and Idempotency (v1.0 additions)

| ID | Item | Week | Effort |
|----|------|------|--------|
| Queue #1 | **Client-side guest UUID** for idempotent retries (pairs with Week 1 eVisitor dup-detection spike) | 1 | minimal + spike |
| Queue #2 | **`in_flight` queue state** with post-crash reconciliation lookup | 3 | ~½ day |
| F7 | **Synchronous Drift write before success signal** — haptic/sound only after durable persistence | 3 | 2–4 hrs |

*Theme insight:* These close three gaps in the locked "passive queue, no auto-retry" decision. Together they make the existing locked plan *safe*, not just simple.

## Theme 3 — Auth & Network Resilience (v1.0 additions)

| ID | Item | Week | Effort |
|----|------|------|--------|
| Auth #1 | **Opportunistic silent auth + non-blocking credential banner** | 4 | ~1 day |
| Auth #2 | **Send All pre-flight credential check** | 4 | ~½ day |
| F2 | **Dio interceptor: 401/302 → re-auth → retry-once** with integration test for mid-batch expiry | 4 | ~½ day |
| F3 | **Exponential backoff + "eVisitor is busy" surfacing** on HTTP 429 | 4 | 2–3 hrs |

*Theme insight:* Week 4 auth work is bigger than the locked plan implied. Auth #1 Opportunistic Banner is the second defer-to-v1.1 candidate in the slip protocol.

## Theme 4 — Security & Privacy Enforcement (v1.0 additions)

| ID | Item | Week | Effort |
|----|------|------|--------|
| Security #1 | **Type-level PII guard** — PII-holding types override `toString()` to `[REDACTED]` | 1–3 | 2–3 hrs |
| Security #2 | **CI grep guard** on forbidden log patterns (fail build on `log.` calls referencing PII types) | 1 | ~1 hr |
| F14 | **Release-build Dio logging disabled + Crashlytics allowlist + staged PII-crash test** | 4–5 | 3–4 hrs |

*Theme insight:* Locked "zero PII in logs" becomes a build-enforced guarantee rather than a hope. Non-negotiable.

## Theme 5 — Data, Retention, and Schema (v1.0 additions)

| ID | Item | Week | Effort |
|----|------|------|--------|
| Architecture #5 | **OIB as first-class Drift schema column** (single-OIB UI in v1.0) | 1 | ~1 hr |
| Alternative #2 | **"Replace Active OIB" Setting** with typed-OIB confirmation and wipe+re-onboard | 3 | ~½ day |
| Business #4 | **1-year default retention** (configurable 30 days / 90 days / 1 year / Forever) — ⚠️ 1y needs legal verification | 3 | ~1 hr |
| Business #3 | **Export all records to CSV/PDF** from Settings | 5 | ~½ day |
| F8 | **Keystore loss onboarding warning + missing-credentials recovery UI** | 3 | 2–3 hrs |

*Theme insight:* The locked plan underinvested in the host's real record-keeping reality. 1-year retention + export replaces 30-day auto-purge.

## Theme 6 — UX Polish (v1.0 additions)

| ID | Item | Week | Effort |
|----|------|------|--------|
| UX #4 | **Last-Facility Shortcut** on Start Scanning (preserves explicit choice) | 3 | 2–3 hrs |
| A2 | **Post-Submit Closure Summary** (shareable as screenshot) | 4 | 2–3 hrs |

*Theme insight:* Cheap wins. Could both defer to v1.1 if Week 3/4 tightens, but losing them makes the app feel less finished.

## Theme 7 — Operational / Launch Strategy (process, not code)

| ID | Item | When |
|----|------|------|
| F10 | **Start Play Console Data Safety form in Week 3**, not Week 5. Over-disclose. |
| F20 | **AI coverage + security scan at end of each epic** (Weeks 1, 2, 3, 4), not only Week 5. Week 5 = Play Store prep only. |
| F6 | **Soft launch via Play Console Closed Beta** with ~10 real Croatian hosts before public listing |
| F19 | **Slip protocol** — ordered defer list if any week slides: Capture #5 → Business #3 → Auth #1 → Alternative #2 |
| F18 | **Play Store listing differentiation** — lean on 1-year retention + export + auth banner; competitors can't match in 5 weeks |
| F1 | **In-repo Dio fake** as permanent integration-test harness; flip to real eVisitor when credentials arrive |

## Theme 8 — v1.1+ Roadmap Seeds (prioritized)

**Headline features:**
- **[S1] NFC passport chip read** 🔥 — genuine differentiator via `flutter_nfc_kit`
- **Guest self-check-in with Pre-Queue Inbox + Proof-of-Possession** — the full 10-idea cluster from Flip #1 (reported-guests view is already on v1.1 from locked plan — pair it with this)
- **[Capture #5 extension] Diagnostic Retry Screen** before manual fallback — if Week 2 data shows capture failures are opaque

**Polish:**
- **[A1] Revolut-style scan animation**
- **[R1-class] geolocation facility suggest** (killed from SCAMPER but worth revisit if wrong-facility [F16] materializes)

**Capture pipeline refinements:**
- Document-type-split pipeline (passport: MRZ-or-manual; ID: keep OCR fallback)
- OCR-as-verification cross-check
- Drop OCR entirely (contrarian minimalism — only if real-world MRZ rate validates it)

**Market expansion:**
- **[P1] Small-boat tourism charter** — same tech, listing copy only
- **[P2] Hostel / agritourism segments**

**Monetization fork (decision point post-v1.0):**
- **Fork A (Flip #11):** Keep free+ads, add Remove-Ads IAP + history-view bundled as "Pro"
- **Fork B (E1):** Drop AdMob, paid-once €4.99, pure privacy positioning
- **Fork C (R2):** Croatian Tourist Board sponsorship (long-shot)
- Decide at month 3 with real install/review data

## Theme 9 — Residual Risks Accepted (for risk register)

- **[F9] Drift performance at 40+ guests/session** — revisit only on real-world signal
- **[F16] Wrong-facility submission despite Neutral App pattern** — regulatory-consequence potential. Darko explicitly accepts; escalate to mitigation (session auto-expiry) in v1.1 if real-world data shows occurrence
- **Keystore credential loss on device migration** — partially mitigated by F8 recovery UX; no cloud backup in v1.0 by design

## Theme 10 — Open Research Questions (blockers for PRD author)

1. **Croatian tourism retention/audit legal window.** Current Business #4 default (1 year) is a placeholder. Confirm actual legal requirement (could be 3 or 5 years).
2. **eVisitor duplicate-detection behavior and idempotency support.** Week 1 spike must verify; shapes whether Queue #1 UUID is primary or secondary safety mechanism.
3. **Multi-OIB frequency in Croatian small-host market.** Post-launch signal via in-app feedback question. Drives v1.1 multi-OIB UX investment.

---

## 🎯 Top-Priority Actions (This Week)

1. **Update PRD v1.0 scope** with the 14 additions from Themes 1–6 (~6–7 extra working days, integrated into existing weekly plan).
2. **Revise the Engineering Sequence table** to reflect the new Week 2/3/4 loads and declare the slip protocol explicitly.
3. **Start outreach for eVisitor test credentials** now — even if Week 1 proceeds with Dio fake, real credentials arriving mid-build is the single biggest de-risking event available.
4. **Research Croatian retention legal window** (1-hour task, likely settles in 10 min with a tourism-board call or lawyer's email).
5. **Apply for AdMob account Week 1** to warm it up for Week 4 integration and Week 5 submission.
6. **Start Privacy Policy draft in Week 3** (GitHub Pages), tuning to match final app behavior so Week 5 Data Safety form is verified-match, not aspirational.

---

## 📝 Session Reflection (Hansei)

**What worked in the brainstorm:**
- Pre-loaded scope document turned the session from "generate" to "stress-test and expand," which matched Darko's senior-dev context far better than open-ended ideation would have.
- Compressed Phase 2 (one-shot 20 failure modes, batch tag) was a good adaptation to fatigue — preserved signal without extending the session.
- Explicit "v1.0 / v1.1+ / killed" tagging per idea kept scope discipline visible.

**What to do differently next time:**
- The Pattern #1 deep-dive on guest self-scan was valuable but extensive; maybe the "future vision" capture should be a sibling workflow to brainstorm rather than mixed in, so v1.0 discussions stay cleaner.
- Surface cumulative scope impact earlier (I did after Flip #10, could have been after Flip #6).

**Breakthrough moments:**
- **Flip #3 flip** — install-twice for multi-OIB was a genuinely weak locked decision; redesigning as v1.0-schema-ready + v1.1-UI-unlock preserved scope while fixing the UX.
- **Flip #7** — semantic sanity layer caught a hole in the "binary pass/fail" MRZ decision that could have produced rejected-by-eVisitor-after-host-said-OK bugs.
- **[S1] NFC chip** — the single cleanest v1.1 differentiator surfaced, and it's technically *smaller* than the camera pipeline it replaces.

**User creative style observed:** Fast, decisive, low tolerance for over-explanation. Prefers terse batched decisions. Trusts recommendations when fatigued but remains skeptical when a flip adds real cost. Strong instinct for protecting the 5-week timeline while still willing to adopt real poka-yoke improvements.


