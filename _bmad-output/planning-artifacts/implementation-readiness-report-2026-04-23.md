---
date: 2026-04-23
project: prijavko
stepsCompleted:
  - step-01-document-discovery
  - step-02-prd-analysis
  - step-03-epic-coverage-validation
  - step-04-ux-alignment
  - step-05-epic-quality-review
  - step-06-final-assessment
inputs:
  prd: _bmad-output/planning-artifacts/prd.md
  architecture: _bmad-output/planning-artifacts/architecture.md
  epics: _bmad-output/planning-artifacts/epics.md
  ux: _bmad-output/planning-artifacts/ux-design-specification.md
  ux_supplements:
    - _bmad-output/planning-artifacts/figma-code-contract.md
    - _bmad-output/planning-artifacts/ux-design-directions.html
  supporting:
    - _bmad-output/planning-artifacts/product-brief-prijavko-distillate.md
    - _bmad-output/planning-artifacts/research/technical-evisitor-auth-lifecycle-research-2026-04-22.md
---

# Implementation Readiness Assessment Report

**Date:** 2026-04-23
**Project:** prijavko

## Step 1 — Document Inventory

**PRD (whole):** `_bmad-output/planning-artifacts/prd.md` (82 KB, 2026-04-23 16:49)
**Architecture (whole):** `_bmad-output/planning-artifacts/architecture.md` (60 KB, 2026-04-23 09:51)
**Epics & Stories (whole):** `_bmad-output/planning-artifacts/epics.md` (248 KB, 2026-04-23 22:56)
**UX (whole):** `_bmad-output/planning-artifacts/ux-design-specification.md` (76 KB, 2026-04-23 11:08)

**UX supplements:** `figma-code-contract.md`, `ux-design-directions.html`
**Supporting context:** product brief + distillate, eVisitor auth lifecycle research

**Duplicates:** none detected.
**Missing required docs:** none.
**Notes:** Prior readiness report at the same path (00:41) is stale — epics.md is now 22:56, so a fresh pass is warranted. This file overwrites it.

## Step 2 — PRD Analysis

### Functional Requirements

**Onboarding & Consent**
- FR1: Host can launch the app and be guided through first-run consent, permissions, and credential capture in a single linear flow.
- FR2: App can present an EU-consent surface for ad personalization before any ads are requested.
- FR3: App can present a sensitive-data disclosure explaining passport/MRZ processing, 3-day retention, and a link to the Privacy Policy before camera permission is requested.
- FR4: Host can grant or deny camera permission; manual entry remains fully functional if camera is denied.
- FR5: Host can enter and store eVisitor credentials (username, password, apikey) for subsequent sessions without re-entering.
- FR6: App can verify eVisitor credentials by performing a live login against the eVisitor authentication endpoint during onboarding.
- FR7: Host can replace or re-enter credentials at any time from the Settings surface.

**Authentication & Session Lifecycle**
- FR8: App can maintain an eVisitor session across process restarts, device reboots, and periods of background inactivity.
- FR9: App can detect an expired or invalid session from eVisitor responses (regardless of HTTP status code) and classify the cause (session-dead, lockout, credentials-invalid, network, or server error).
- FR10: App can re-authenticate automatically using stored credentials when a dead session is detected, without duplicate concurrent login attempts.
- FR11: App can surface a non-blocking credential banner to the host when session-dead or credentials-invalid is detected, with a single-tap recovery action.
- FR12: App can refuse further login attempts after a configurable threshold of consecutive failures within a rolling window, and communicate the remaining wait to the host in Croatian.
- FR13: App can perform an opportunistic authentication check on app foregrounding without blocking the UI.
- FR14: Host can view current session state (authenticated, reauth-needed, locked-out) at a glance in the Settings surface.
- FR14.5: App can detect missing credentials on launch (Keystore returns no value for an existing facility profile) and surface a non-blocking "credentials missing — re-enter to continue" state with facility names pre-populated, without losing facility context or forcing full re-onboarding.

**Facility Management**
- FR15: App can fetch and cache the list of facilities available to the host's eVisitor account on first successful login.
- FR16: Host can select exactly one facility at the start of each registration session.
- FR17: App can surface the last-used facility as a hint during facility selection, but not pre-select it as a default.
- FR18: Host can see the currently active facility on the home surface during an active registration session.
- FR19: App can refresh the facility list when the host explicitly requests it, without forcing a full re-login.

**Guest Capture**
- FR20: Host can capture guest identity data by holding a passport/ID in front of the camera; the app detects and parses a valid MRZ automatically.
- FR21: Host can tap a static capture control to capture a document image when live MRZ detection does not succeed within a bounded time.
- FR22: Host can enter guest data manually as a fallback when neither live nor static capture succeeds.
- FR23: App can validate captured or entered guest data against semantic sanity rules (date plausibility, document expiry, valid country codes, realistic birth years) before accepting it into the queue.
- FR24: Host can review and correct captured guest data before it is committed to the queue.
- FR25: App can reject a capture or entry inline with a Croatian-language explanation when sanity validation fails, without committing it to the queue.
- FR26: App can support future fields required by the May-2026 apartment registration-number mandate, gated by a feature flag, without breaking the existing capture flow.

**Queue & Local Persistence**
- FR27: App can persist every captured guest to encrypted local storage with a client-generated unique identifier, synchronously, before surfacing any success indication to the host.
- FR28: App can preserve unsent guests across app kills, device reboots, and offline periods indefinitely until either submission succeeds or the host deletes them.
- FR29: Host can view the unsent queue with a per-guest status and initiate per-guest edit or delete actions.
- FR30: App can automatically delete successfully submitted guests after a 3-day soft-undo retention window, regardless of host action.
- FR31: Host can manually delete individual unsent or recently-submitted guests from the queue at any time.
- FR31.5: Host can replace the active OIB from the Settings surface via a destructive, typed-OIB-guarded confirmation that wipes all facility profiles, queue entries, credentials, and cookie jar, then re-launches onboarding.

**Submission (Send All)**
- FR32: Host can trigger a batch submission of all unsent guests for the active facility via an explicit action (no automatic submission, no background retry).
- FR33: App can perform a pre-flight check for authentication and network reachability immediately before submitting and block the submission with a clear message if either check fails.
- FR34: App can submit guests individually to eVisitor such that a rejection of one guest does not cause rejection of other guests in the same batch.
- FR35: App can report per-guest success or failure outcomes to the host after a submission batch completes.
- FR36: Host can edit a failed guest inline and retry only the failed guests without re-submitting already-successful ones.
- FR36.5: App can distinguish a rate-limited response (HTTP 429 or equivalent eVisitor throttling) from a submission failure and surface a non-blocking "eVisitor is busy — retrying..." message with exponential backoff, without counting the rate-limit as a per-guest failure outcome.
- FR36.6: App can track an `in_flight` queue state between `ready-to-send` and `accepted/rejected`; on app resume after process kill or crash, any `in_flight` entries are re-queried against eVisitor before any retry is attempted (or held for host review if a lookup endpoint is unavailable) — preventing silent double-submits.

**Post-Submission Closure**
- FR37: App can present a closure summary after every submission batch, containing the facility name, number of guests registered, and the local submission timestamp — and containing no guest names, document numbers, or other PII.
- FR38: Host can share or screenshot the closure summary for their own records.

**Privacy & Data Lifecycle**
- FR39: Host can view a "Your Data" surface listing what is currently stored on the device (unsent queue count, recently-submitted count within retention), with links to the Privacy Policy and Terms of Service.
- FR40: Host can trigger a complete wipe of all local data (queue, cached facilities, cookie jar, credentials) in a single action.

**Observability & Compliance Signals**
- FR41: App can emit zero-PII telemetry events that allow the operator to measure submission success rate, session-dead-recovery rate, queue-stuck-over-24h count, and crash-free session rate — without transmitting any guest or credential data.
- FR42: App can present a forced-update banner when a remote minimum-supported-version signal indicates the current client is incompatible with eVisitor, and block submissions while the banner is active.

**Total FRs: 46** (FR1–FR42 = 42, plus inserts FR14.5, FR31.5, FR36.5, FR36.6 = 4)

### Non-Functional Requirements

**Performance (10)**
- NFR-P1: Live MRZ auto-shutter fires within 1.5s (p95) on a well-lit, flat, in-date MRZ.
- NFR-P2: Static-tap fallback surfaces no later than 3s of failed live detection.
- NFR-P3: Scanned guest persisted + reflected in unsent-row UI within 300ms (p95); synchronous DB commit before success haptic.
- NFR-P4: Semantic sanity validation completes within 50ms (p95) of capture submission.
- NFR-P5: Send All pre-flight (auth + network) completes within 1s (p95).
- NFR-P6: Per-guest submission UI progress updates within 200ms of each eVisitor response.
- NFR-P7: Post-submit closure summary renders within 200ms of last guest's response.
- NFR-P8: Cold start ≤ 2.5s (p95) on mid-range Android 2023+.
- NFR-P9: Warm resume + opportunistic auth check ≤ 1s (p95), non-blocking.
- NFR-P10: Capable of holding ≥ 40 unsent guests in one session without UI degradation (60fps scroll, 200ms edit/delete). Integration-test verified.

**Security (11)**
- NFR-S1: HTTPS with TLS 1.2+; cleartext rejected at platform level (`network_security_config.xml`).
- NFR-S2: SHA-256 cert pinning to `www.evisitor.hr` (leaf + intermediate); pin mismatch aborts without retry.
- NFR-S3: Credentials in flutter_secure_storage with Keystore-backed AES/GCM; hardware-backed keys where available.
- NFR-S4: Cookie jar (`authentication`, `affinity`, `language`) AES-GCM-encrypted at rest; key in flutter_secure_storage.
- NFR-S5: Drift queue guest-identifying fields AES-GCM-encrypted at column level.
- NFR-S6: `allowBackup="false"` and `fullBackupContent="false"` — no cloud backup path.
- NFR-S7: Zero PII in logs/telemetry. Enforced at two layers: (a) PII types override `toString()` to `[REDACTED]`, (b) build-blocking CI grep guard.
- NFR-S8: Crashlytics carries only counts, facility IDs, error codes — no free-text guest data.
- NFR-S9: OWASP MASVS L1 self-audit pre-submission (documented checklist).
- NFR-S10: 3-day auto-purge enforced regardless of host action or app state; documented in Privacy Policy + in-app "Your Data" surface.
- NFR-S11: Release builds disable verbose Dio logging; Crashlytics custom-key allowlist; transitive-dependency logging reviewed pre-submission; staging acceptance test intentionally crashes a PII-carrying path and Firebase Console inspected for leakage.

**Reliability (9)**
- NFR-R1: Crash-free session rate ≥ 99.5% (Crashlytics).
- NFR-R2: `scan_to_submit` first-time success ≥ 90% without field corrections.
- NFR-R3: Silent-failure rate (auth-classifier false negatives) = 0 during 2026-06-01 → 2026-09-30 peak.
- NFR-R4: Queue-stuck count (unsent > 24h) = 0 at every app open (telemetry fires when non-zero).
- NFR-R5: No submission lost to process kill, device reboot, network drop, or storage pressure — queue always pending or submitted, never "gone."
- NFR-R6: Auto-recovery from expired session on next action without re-entering credentials (unless credentials themselves invalid).
- NFR-R7: Concurrent auth-triggering requests produce exactly one login call (QueuedInterceptor).
- NFR-R8: Client-side circuit breaker opens at 3 consecutive login failures for 6 minutes (more conservative than Rhetos 5/5).
- NFR-R9: Offline-capable for capture/queue/facility-picker; only Send All + opportunistic auth check require network.

**Integration (7)**
- NFR-I1: JSON everywhere; `ImportTourists` is XML-as-string inside JSON body; dates `/Date(ms+offset)/`.
- NFR-I2: Error classifier correctly identifies session-dead across HTTP 401/403, HTTP 400-with-`SystemMessage`, and HTTP 200-with-error-envelope on non-Login endpoints.
- NFR-I3: Classifier matches Croatian text (`locked|zaključan`, `invalid|nevažeć|neispra`, `session|prijava|auth`) and English; regex refined in Week-1 spike.
- NFR-I4: Permanent in-repo Dio fake on every CI build + nightly real testApi canary.
- NFR-I5: Drift between fake and real eVisitor fails CI; resolved before merging.
- NFR-I6: Zero guest PII transmitted to AdMob/Crashlytics/Firebase/Google Play/any third party — only to eVisitor.
- NFR-I7: Forced-update mechanism: `prijavko.hr/min-version.json` polled on cold start; below min → banner blocks Send All.

**Compatibility (5)**
- NFR-C1: Android 7.0 (API 24) minimum; target SDK per latest Play Store mandate at submission.
- NFR-C2: arm64-v8a + armeabi-v7a; no x86.
- NFR-C3: Phone portrait 4.7"–6.9" fully designed; landscape + tablet portrait non-breaking but not design-optimized.
- NFR-C4: Camera works on CameraX-capable API-24+ devices with rear camera.
- NFR-C5: No Google Play Services beyond ML Kit MRZ (on-device) + Firebase Crashlytics.

**Localization (4)**
- NFR-L1: Croatian primary, English secondary; active language follows Android system locale, Croatian fallback for unsupported locales.
- NFR-L2: Date/time/number formats follow active locale.
- NFR-L3: Host-facing errors include Croatian eVisitor `UserMessage` (when present) + prijavko-provided Croatian explanation safe for UI.
- NFR-L4: No English-only user-facing strings; missing translations block release.

**Accessibility (4)**
- NFR-A1: Minimum 48×48 dp touch target (note: project design-system rule requires 56 dp — stricter).
- NFR-A2: WCAG 2.1 AA contrast (≥4.5:1 body, ≥3:1 large text) in light + dark.
- NFR-A3: Every actionable control exposes TalkBack content description; scan/Send All/credential banner/closure summary fully screen-reader navigable.
- NFR-A4: Manual-entry flows respect system font scaling up to 200% without layout breakage.

**Maintainability (8)**
- NFR-M1: `dart analyze --fatal-warnings --fatal-infos` on CI; zero warnings in merged code.
- NFR-M2: No production `dynamic` except boundary deserialization that immediately coerces to typed models.
- NFR-M3: Public classes/functions carry doc comments explaining *why*, not *what*.
- NFR-M4: Commit messages explain *why*; atomic preferred over batched.
- NFR-M5: Coverage measured not gated; capability contract (FRs) + integration harness (NFR-I4) must cover every MVP capability; meaningful coverage ≥ 70% on auth + queue + classifier.
- NFR-M6: Pre-peak code freeze 2026-06-15; post-freeze merges are bugs only until 2026-09-30 kill-criteria checkpoint.
- NFR-M7: PRD + brief + distillate + auth research are authoritative context; scope change updates PRD first, then code.
- NFR-M8: AI coverage review + security scan at end of every epic (Weeks 1–4); remediated same week; Week 5 reserved for Play Store prep with zero open technical dependencies.

**Total NFRs: 58** (10+11+9+7+5+4+4+8)

### Additional Requirements & Constraints

**Compliance & regulatory (domain):**
- Host is **sole legal data controller** under Croatian tourism law; prijavko is a transient processor/courier. ToS must disclaim liability for fines from app failure.
- 24-hour registration window is legally mandatory. The queue-stuck-over-24h metric (NFR-R4) is the observable form of this.
- May-2026 apartment registration-number mandate is a **Week-1 spike blocker**; payload shape TBD against testApi.
- GDPR Art. 6(1)(c) legal-obligation basis (not consent) for guest flow. Data-minimization, storage limitation (3 days), right-to-erasure via zero-retention, in-app "Your Data" surface.
- Play Store **sensitive-data manual review** expected 1–3 weeks; Data Safety declaration + privacy policy + ToS must all be live before upload (target 2026-05-27).

**Technical constraints:**
- No refresh token against Rhetos — re-auth is always full re-login with stored credentials.
- Rhetos server-side 5-failure / 5-minute lockout; client circuit breaker opens at 3 / 6 minutes.
- Stack lock-in (per architecture): Flutter 3.x, Dart 3.x, Riverpod 3, Drift, Dio 5.x, flutter_secure_storage, dio_cookie_manager + PersistCookieJar, Firebase Crashlytics, UMP/CMP.
- No push, no FCM, no foreground service, no geolocation, no background auto-retry.
- Permanent in-repo Dio fake is a **first-class repo artifact** (not a dev-only fixture).

**Visual contract:**
- Figma file + `figma-code-contract.md` + `tools/figma-scripts/` are authoritative for UI-fidelity questions (PRD §Visual Contract). Not duplicated in PRD.

**Slip protocol (explicit):**
1. Hybrid live-first capture → static-only
2. Opportunistic auth banner → login-on-send
3. Replace-Active-OIB setting (schema-ready) → UI deferred
4. Shareable closure-summary screenshot → textual only
Below the irreducible floor (scan → queue → Send All → success + six-state auth + zero-PII + Play Store compliance): **slip the date, not the scope.**

**Kill criteria (2026-09-30):** <1,000 installs OR <3.5 Play Store rating OR <10% month-3 retention → planned sunset.

### PRD Completeness Assessment

**Strengths:**
- Requirements are behaviour-outcome shaped, not implementation-shaped — leaves architectural freedom while still being testable.
- Every FR is traced to at least one journey; every capability in Step 4's Journey Requirements table has a corresponding FR.
- NFRs are numeric and measurable (p95 latencies, error rates, touch-target sizes, contrast ratios). Few mushy clauses.
- Observability-as-MVP posture forces the reliability promise to be falsifiable from day one (NFR-I4 + NFR-R1–R4 + FR41).
- Slip protocol + irreducible floor clearly separates negotiable from non-negotiable scope.
- Innovation moat (zero-retention, classifier, Neutral App, type-level PII, Dio fake) is called out and validation-tied.

**Gaps / things to watch in later steps:**
- **NFR-A1 vs design-system rule:** PRD says 48×48 dp minimum; `.claude/rules/design-system.md` §5 and UX spec require 56 dp. Epics must reflect the stricter 56 dp (not the PRD minimum) to avoid drift.
- **May-2026 mandate field (FR26):** entire enforcement depends on a Week-1 spike. An epic must own the spike and the feature flag; if missing, readiness fails.
- **FR36.6 `in_flight` dedup:** requires an eVisitor lookup endpoint for pre-retry reconciliation; fallback is "hold for host review." Epics must pick one of the two paths and have stories for both the lookup and the human-review UX.
- **FR14.5 credential-missing (non-destructive recovery) vs FR31.5 destructive OIB-replace:** two separate flows. Epics must not conflate them.
- **Forced-update mechanism (FR42 + NFR-I7):** depends on a static JSON at `prijavko.hr/min-version.json` — a deployment artifact outside the Flutter build. Epics should own its setup.
- **NFR-S11 staging PII-leak acceptance test:** process-level test. Should be a story, not a handwave.
- **NFR-M8 per-epic AI coverage + security review:** a schedule commitment; readiness check should confirm epics surface this as an exit gate, not a footnote.

The PRD is coherent, internally traceable, and measurement-grounded. No structural defects blocking coverage validation — proceed.

## Step 3 — Epic Coverage Validation

### Epics Overview

The epics document defines **10 epics and 59 stories**, with an explicit Requirements Inventory (FR/NFR/UX-DR), an FR Coverage Map, a Story-to-Requirements matrix, an FR-to-Story inverse map, a UX-DR inverse map, and a selected NFR coverage section.

| Epic | Title | Stories | Declared FRs |
|---|---|---|---|
| 1 | First-Run Onboarding & Credential Trust | 9 | FR1–FR8 |
| 2 | Resilient Auth Lifecycle (No Door Surprises) | 9 | FR9–FR14, FR14.5 |
| 3 | Facility Choice (Neutral App Pattern) | 6 | FR15–FR19 |
| 4 | Confident Capture Pipeline | 9 | FR20–FR26 |
| 5 | Zero-Loss Encrypted Queue | 8 | FR27–FR31, FR31.5 |
| 6 | Explicit Send All with Per-Guest Isolation | 8 | FR32–FR36, FR36.5, FR36.6 |
| 7 | Closure Summary | 3 | FR37, FR38 |
| 8 | Privacy Transparency & Data Wipe | 2 | FR39, FR40 |
| 9 | Observability & Forced-Update Safety Net | 5 | FR41, FR42 |
| 10 | Monetization & Launch Readiness | 8 | — (NFR-S9, NFR-I6, Play Store compliance) |

### FR Coverage Matrix (PRD ↔ Epics ↔ Story)

| FR | PRD? | Epic | Story(ies) | Status |
|---|---|---|---|---|
| FR1 | ✓ | 1 | 1.4, 1.5, 1.6, 1.7 (compose linear flow) | ✓ Covered |
| FR2 | ✓ | 1 | 1.4 | ✓ Covered |
| FR3 | ✓ | 1 | 1.5 | ✓ Covered |
| FR4 | ✓ | 1 | 1.6 | ✓ Covered |
| FR5 | ✓ | 1 | 1.7 | ✓ Covered |
| FR6 | ✓ | 1 | 1.7 | ✓ Covered |
| FR7 | ✓ | 1 | 1.9 | ✓ Covered |
| FR8 | ✓ | 1 | 1.8 | ✓ Covered |
| FR9 | ✓ | 2 | 2.2 | ✓ Covered |
| FR10 | ✓ | 2 | 2.3, 2.4 | ✓ Covered |
| FR11 | ✓ | 2 | 2.7 | ✓ Covered |
| FR12 | ✓ | 2 | 2.5 | ✓ Covered |
| FR13 | ✓ | 2 | 2.6 | ✓ Covered |
| FR14 | ✓ | 2 | 2.9 | ✓ Covered |
| FR14.5 | ✓ | 2 | 2.8 | ✓ Covered |
| FR15 | ✓ | 3 | 3.2 | ✓ Covered |
| FR16 | ✓ | 3 | 3.4 | ✓ Covered |
| FR17 | ✓ | 3 | 3.4 | ✓ Covered |
| FR18 | ✓ | 3 | 3.5 | ✓ Covered |
| FR19 | ✓ | 3 | 3.6 | ✓ Covered |
| FR20 | ✓ | 4 | 4.2 | ✓ Covered |
| FR21 | ✓ | 4 | 4.5 | ✓ Covered |
| FR22 | ✓ | 4 | 4.6 | ✓ Covered |
| FR23 | ✓ | 4 | 4.1 | ✓ Covered |
| FR24 | ✓ | 4 | 4.8 | ✓ Covered |
| FR25 | ✓ | 4 | 4.7 | ✓ Covered |
| FR26 | ✓ | 4 | 4.9 | ✓ Covered |
| FR27 | ✓ | 5 | 5.2 | ✓ Covered |
| FR28 | ✓ | 5 | 5.5 (visible on Home) + persistence in 5.1+5.2 | ✓ Covered |
| FR29 | ✓ | 5 | 5.6 | ✓ Covered |
| FR30 | ✓ | 5 | 5.7 | ✓ Covered |
| FR31 | ✓ | 5 | 5.6 | ✓ Covered |
| FR31.5 | ✓ | 5 | 5.8 | ✓ Covered |
| FR32 | ✓ | 6 | 6.4 | ✓ Covered |
| FR33 | ✓ | 6 | 6.4 | ✓ Covered |
| FR34 | ✓ | 6 | 6.5 | ✓ Covered |
| FR35 | ✓ | 6 | 6.5 | ✓ Covered |
| FR36 | ✓ | 6 | 6.7 | ✓ Covered |
| FR36.5 | ✓ | 6 | 6.6 | ✓ Covered |
| FR36.6 | ✓ | 6 | 6.8 | ✓ Covered |
| FR37 | ✓ | 7 | 7.1, 7.3 | ✓ Covered |
| FR38 | ✓ | 7 | 7.2 | ✓ Covered |
| FR39 | ✓ | 8 | 8.1 | ✓ Covered |
| FR40 | ✓ | 8 | 8.2 | ✓ Covered |
| FR41 | ✓ | 9 | 9.2, 9.3 | ✓ Covered |
| FR42 | ✓ | 9, 10 | 9.4 (client) + 10.5 (server-side JSON publish) | ✓ Covered |

### Missing FR Coverage

**None.** All 46 PRD FRs map to at least one story with acceptance criteria.

### Drift / Discrepancies (epics vs. PRD)

Not missing, but worth flagging for later steps:

- **NFR-M8 missing from epics Requirements Inventory.** PRD defines NFR-M8 (AI coverage review + security scan at end of every epic, remediated same week; Week 5 reserved for Play Store prep with zero open technical dependencies). Epics list NFR-M1 through NFR-M7 only — NFR-M8 is dropped. Given it is an epic-exit-gate commitment, this is a notable omission to address in Step 5 (epic quality). Remediation: either add as a per-epic exit gate, or cite it explicitly in Story 10.8 / Week-5 sequence.
- **NFR-P8 (cold start ≤2.5s p95) not mapped to any story.** The NFR-to-Story table is labelled "selected high-criticality NFRs" and lists P1–P7, P9, P10 but omits P8. Worth assigning to Story 1.1 (bootstrap) or Story 10.8 (production submission) as an acceptance gate.
- **Epic 10 declares no FRs directly** — correct per the epic description (monetization/launch readiness), but note that FR42 has its operational half (publishing `min-version.json`) owned by Story 10.5. This is already reflected in the inverse map and is fine.
- **Epics total count declared as "46 FRs"** at line 3668 — matches PRD inventory exactly (including the four `.5`/`.6` inserts).

### Coverage Statistics

- **Total PRD FRs:** 46
- **FRs covered by ≥1 story:** 46
- **Coverage percentage:** **100%**
- **UX-DR coverage:** 33 / 33 (from inverse map, verified by sampling)
- **NFR coverage:** 56 / 58 explicitly mapped (NFR-P8, NFR-M8 unmapped; flagged above)

**Result:** Functional coverage is complete. Two NFR gaps (P8, M8) warrant a note but are non-blocking — both are operational/process concerns that can be owned via Story-10 / per-epic checkpoints. Proceed to UX alignment.

## Step 4 — UX Alignment

### UX Document Status

**Found — primary spec + two supplements:**
- `ux-design-specification.md` (1628 lines) — authoritative spec: vision, personas, journeys, experience principles, design system foundation (tokens, color, typography, spacing, accessibility), custom components (10 widgets), UX consistency patterns, responsive/accessibility, screen implementation roadmap.
- `figma-code-contract.md` (171 lines) — authoritative Figma-node → Flutter-widget mapping (PRD §Visual Contract names it so).
- `ux-design-directions.html` (53 KB) — exploration asset (28 mockups across 3 directions); Adriatic Teal chosen; included for provenance.

### UX ↔ PRD Alignment

Verified:

- **All 5 user journeys align 1:1.** UX spec §User Journey Flows (lines 829–1045) mirrors PRD §User Journeys — same personas (Ana / Marko / Ivana / Tomislav), same door-side scenes, same capabilities surfaced. No divergence.
- **Experience Principles map to PRD Success Criteria.** UX's "calm under pressure," "no door surprises," "zero-PII closure" match PRD's user-success guarantees 1:1.
- **Accessibility tiers are reconciled correctly.**
  - PRD NFR-A1 = **48×48 dp** minimum (Android guideline).
  - UX-DR26 = "Touch target minimum 48×48 dp everywhere; primary button min-height **56 dp** (one-handed night-shift)."
  - Project rule `.claude/rules/design-system.md` §5 = 56 dp tap-target minimum (stricter than PRD).
  - These are a tiered rule, not a contradiction: 48 dp is the floor, 56 dp is mandated on primary CTAs. Epics honour both (UX-DR26 wording reused in FilledButton component theme + design-system rule). **Non-blocking**, but stories 1.2 and 3.3 should make the tier explicit in acceptance criteria wording.
- **Innovation moats have a UX surface.** Zero-retention → "Your Data" screen (FR39 / UX-DR22). Error classifier → `CredentialBanner` (FR11 / UX-DR10). Neutral App → `FacilityPickerSheet` (FR16 / UX-DR11). Type-level PII → propagated throughout UX via document-number masking (UX-DR8, UX-DR14). Permanent Dio fake → not UX-visible (correct).
- **Closure Summary emotional-payoff language is consistent** across PRD (signature moment, shareable, zero-PII) and UX (Adriatic gold `closureAccent` used **only** on this screen; native ShareSheet with text-only payload).

### UX ↔ Architecture Alignment

Verified:

- Architecture selects Flutter 3.x + Material 3 + Riverpod 3 + Freezed + go_router v14+ + Drift + `cryptography_flutter` — matches the UX stack requirements (Material 3 primitives, theming via `ThemeData` extensions, `AsyncValue.when()` for state rendering).
- `SystemChrome.setPreferredOrientations` for portrait-lock on scan + closure — not an architectural concern (widget-level); stories 4.3, 4.5, 7.2 own it. **OK.**
- `ShellRoute` overlay for `ForceUpdateBanner` (UX-DR32 modal/overlay priority) — architecture mentions go_router `redirect` but does **not** explicitly name `ShellRoute`. Story 9.4 description names it correctly (`ShellRoute overlay`). **Minor gap:** architecture.md §App Architecture should be cross-referenced when Story 9.4 is implemented; not a readiness blocker because the story itself is specific.
- Component theme slots (FilledButton min height 56 dp, Card radius 16 dp, button radius 12 dp) live in UX spec + `.claude/rules/design-system.md` + story 1.2. Architecture is silent on theming — **intentional separation of concerns**, but worth noting.
- Haptic-before-render (UX-DR13/UX-DR29) as a poka-yoke signal — architectural support is implicit (synchronous Drift commit in story 5.2 feeds the haptic firing in story 4.4). **No gap.**
- 200% font-scale clamp (UX-DR28) — architecture neutral; widget responsibility. **OK.**
- `AppLocalizations` / ARB files + `GlobalMaterialLocalizations.delegate` (UX-DR24) — architecture does not explicitly list localization delegates; project rule `.claude/rules/design-system.md` §6 does; story 1.5 baseline owns it. **Minor gap** (architecture addendum opportunity, but non-blocking).

### Alignment Issues (internal)

1. **UX-spec internal inconsistency:** early §Implementation Approach (line 371) says "~5 custom widgets" — later authoritative §Custom Components (line 1089) lists 10 widgets. Epics list 10. **Tiny editorial drift in the UX spec** — not a readiness blocker, but worth cleaning up in the spec itself (the "~5" passage is pre-decision prose that was not updated when the final 10-widget list was committed).
2. **Architecture does not enumerate design-system responsibilities.** Theming, typography, and iconography live exclusively in UX spec + `figma-code-contract.md` + `.claude/rules/design-system.md`. This is a deliberate separation (consistent with PRD §Visual Contract: "those three artifacts are authoritative for any UI-fidelity question"), but a first-time reader of architecture.md may look for a "UI Architecture" section and not find it. **Non-blocking.** Could add a 2-line cross-reference in architecture.md §3 pointing to the three authoritative UI artifacts.
3. **Architecture lacks explicit l10n setup note.** `GlobalMaterialLocalizations.delegate` + ARB build is implicit; story 1.5 covers it per the UX-DR24 baseline. **Non-blocking.**

### Warnings

- None that block readiness. The UX spec is comprehensive, aligns with the PRD on journeys/principles/accessibility, and its 10-widget component contract is mirrored in the epics' UX-DR inverse map.
- The two minor cross-reference nits (architecture ↔ UX and UX-spec internal "~5 widgets" prose) are documentation hygiene, not planning defects.

**Conclusion:** UX alignment is sound. PRD, UX spec, figma-code-contract, project design-system rule, and epics tell a consistent story at every layer. Proceed.

## Step 5 — Epic Quality Review

Validation scope: user-value framing, epic independence, story sizing, acceptance-criteria structure, within-epic dependency flow, cross-epic dependency flow, database/entity JIT creation, starter-template discipline. Findings are categorized by severity.

### Epic User-Value Framing

| Epic | Title | User-outcome framed? | Notes |
|---|---|---|---|
| 1 | First-Run Onboarding & Credential Trust | ✅ | "First-ever host lands on Home in <90s with persistent credentials" |
| 2 | Resilient Auth Lifecycle (No Door Surprises) | ✅ | "Session-dead caught hours before the door; one-tap restore" |
| 3 | Facility Choice (Neutral App Pattern) | ✅ | "No wrong-facility submissions" |
| 4 | Confident Capture Pipeline | ✅ | "3-tier capture with inline Croatian sanity rejection" |
| 5 | Zero-Loss Encrypted Queue | ✅ | "Queue survives kills/reboots; 3-day soft-undo" |
| 6 | Explicit Send All with Per-Guest Isolation | ✅ | "One-tap submission; per-guest ✓/✗; no silent double-submit" |
| 7 | Closure Summary (The Signature Moment) | ✅ | "Emotional payoff, shareable, zero-PII" |
| 8 | Privacy Transparency & Data Wipe | ✅ | "Host sees what's stored + one-action wipe" |
| 9 | Observability & Forced-Update Safety Net | ✅ | "Reliability thesis measured in production; contract-break block" |
| 10 | Monetization & Launch Readiness | ⚠️ Borderline | Ad-supported free tier on Play Store — user outcome framed, but still a compliance/release epic. Acceptable per Step 5 §5B (greenfield needs release epic). |

**Verdict:** No "Setup Database" / "API Development" / "Infrastructure Setup" anti-patterns. Epic 10 is the only one that leans toward release management; its user-outcome framing ("host installs a Play-Store-listed v1.0") is defensible.

### Starter-Template Discipline

- Architecture §2 mandates `flutter create --org hr.prijavko --project-name prijavko --platforms=android --empty -a kotlin .` with no third-party starter.
- **Story 1.1** implements this exact command in acceptance criteria (line 450, verified). ✅
- `--dart-define=EVISITOR_ENV=<prod|test|fake>` wiring tested per AC (line 470). ✅

### Database/Entity JIT Creation

- `FacilitiesTable` → Story 3.1 (first story that needs facilities). ✅
- `GuestEntriesTable` → Story 5.1 (first story that needs the queue). ✅
- `AppDatabase` is **not** created in Story 1.1 with all tables upfront. ✅
- Epics' own validation results (line 3739) call this out explicitly. ✅

### Story Quality Assessment (sampled)

Sampled Stories 1.1, 1.2, 1.3, 2.2, 2.3, 6.8, 7.1, 9.3, 10.8. Across the sample:

- **User story format (As a / I want / So that):** present on every sampled story with a specific persona and a rationale. ✅
- **Given/When/Then BDD structure:** every AC block uses the G/W/T form correctly. No vague "user can login" phrasing found. ✅
- **Specificity & testability:** ACs name file paths, classes, method signatures, Croatian copy strings, exact regex patterns, exact latency targets, mocked assertion counts (e.g., Story 2.3 AC: "an integration test dispatches 10 concurrent requests and asserts exactly one `POST /Login` call"). ✅
- **Story size:** sampled stories run 30–90 lines with 5–10 G/W/T blocks; each sized for a single-dev-session per project constraints. ✅
- **Error/edge-case coverage:** Story 2.2 covers every `EvisitorErrorClass` enum variant exhaustively via a sealed-enum switch that fails compilation if a variant is unhandled — textbook Poka-yoke. ✅
- **Traceability:** every story in the Story-to-Requirements matrix names the FR(s)/NFR(s)/UX-DR(s) it delivers (confirmed for 100% of the 59 stories via the matrix at lines 3547–3616). ✅
- **"Why" doc comments** called out in story ACs (e.g., Story 7.1 AC: "the file has a top-of-file `why` doc comment explaining the emotional-payoff constraint") — aligns with project craftsmanship rules. ✅

### Dependency Analysis

**Within-epic flow** (sampled linearly):
- Epic 1: 1.1 (bootstrap) → 1.2 (design) → 1.3 (security) → 1.4 (consent) → 1.5 (welcome) → 1.6 (camera) → 1.7 (login) → 1.8 (persist) → 1.9 (re-enter). Forward-only. ✅
- Epic 2: 2.1 (state skeleton) → 2.2 (classifier pure) → 2.3 (interceptor) → 2.4 (re-auth) → 2.5 (breaker) → 2.6 (opportunistic) → 2.7 (banner) → 2.8 (missing-creds) → 2.9 (settings). Forward-only. ✅
- Epic 6: 6.1 (date codec) → 6.2 (XML builder) → 6.3 (API client) → 6.4 (notifier + pre-flight) → 6.5 (per-guest loop) → 6.6 (throttle) → 6.7 (review UI) → 6.8 (reconciler). Forward-only. ✅

**Cross-epic flow:**
- Epic 1 → 2 → 3 → 4 → 5 → 6 → 7 for the core flow. Epics 8, 9, 10 layer on top. ✅
- **Story 9.3 (telemetry call-site wiring across Epics 1–8)** is the **only intentional retroactive dependency**. The story itself declares "this is a retroactive wiring sweep across prior epics — no new product features are introduced." The epics' own Validation Results (line 3745) calls it out as "by design, not a violation." ✅ **Accepted as deliberate Jidoka-style late wiring.**
- No circular dependencies detected.
- FR42 is split across Story 9.4 (client-side `MinVersionChecker` + `ForceUpdateBanner`) and Story 10.5 (server-side `prijavko.hr/min-version.json` publish). These are parallel, not a forward dependency. ✅

### Compliance Checklist

| Rule | Status |
|---|---|
| Epics deliver user value | ✅ (Epic 10 borderline but acceptable) |
| Epics function independently (once Epic-N dependencies satisfied) | ✅ |
| Stories appropriately sized | ✅ (single-dev-session) |
| No forward dependencies within epics | ✅ |
| Cross-epic forward dependencies only via explicit retroactive sweep (9.3) | ✅ by design |
| Database tables created when needed (JIT) | ✅ |
| Acceptance criteria in G/W/T, testable, specific | ✅ |
| Every FR / UX-DR traceable to ≥1 story | ✅ |
| Starter template command captured in Story 1.1 | ✅ |
| CI/CD pipeline scaffolded in Story 1.1 (greenfield) | ✅ |

### Findings by Severity

#### 🔴 Critical Violations

None found.

#### 🟠 Major Issues

None found.

#### 🟡 Minor Concerns

1. **NFR-M8 (per-epic AI coverage review + security scan) is not an epic-exit acceptance criterion anywhere.** PRD commits to "AI coverage review + security scan at end of every epic (Weeks 1–4); findings remediated the same week they are discovered; Week 5 reserved for Play Store prep with zero open technical dependencies." This NFR is missing from epics.md's own Requirements Inventory (inventory stops at NFR-M7) and is not surfaced as an exit gate on Epics 1–9. **Remediation:** add a single "Epic Exit Gate" AC at the last story of each epic — e.g., "Given the epic is claimed complete, When the AI coverage review + security scan completes, Then findings are remediated within the same week, and the epic is not considered closed until remediated." Low effort, high audit value.
2. **NFR-P8 (cold start ≤ 2.5s p95) unassigned.** The NFR-to-Story table is labeled "selected high-criticality NFRs" and omits P8. **Remediation:** add P8 to Story 1.1 or Story 10.8 acceptance criteria (cold-start latency probed via an integration test + staging-acceptance gate at rollout).
3. **Epic 10's declared "FRs covered: none" is slightly inaccurate.** Story 10.5 owns the operational half of FR42 (publishing `min-version.json`). Epic 10 description line 430 says "none"; the FR-to-Story inverse map correctly shows "FR42: 9.4, 10.5." **Remediation:** update Epic 10's epic-header line to "FRs covered: FR42 (operational half, paired with 9.4)." Purely cosmetic.
4. **UX spec internal drift — "~5 custom widgets" (line 371) vs. later authoritative "10 custom widgets" (line 1089).** Editorial. **Remediation:** remove/update the "~5 widgets" sentence in the early §Implementation Approach to cross-reference the authoritative §Custom Components section. Documentation hygiene.
5. **Architecture lacks explicit cross-reference to UX/design-system artifacts.** Arch is silent on theming; UX spec + figma-code-contract + `.claude/rules/design-system.md` are the authoritative stack. **Remediation:** add a 2-line note in architecture.md §3 pointing to those three artifacts so a first-time reader is not confused.
6. **`ShellRoute` for `ForceUpdateBanner` overlay is implied, not named in architecture.md.** Story 9.4's acceptance criteria name it correctly, so this is more of a documentation completeness observation than a defect.

### Summary

**Epic quality is high.** The epics document is unusually rigorous: 59 stories, every FR traced to ≥1 story, every UX-DR traced to ≥1 story, Given/When/Then structure throughout, exhaustive enum coverage in test ACs, explicit JIT database creation, forward-only dependency flow with a single documented retroactive sweep (9.3) that is itself called out as deliberate. The six minor concerns are all either editorial cleanup or missing exit-gate acceptance — none of them block Phase 4 start. Proceed to final assessment.

## Step 6 — Final Assessment

### Overall Readiness Status

**✅ READY for Phase 4 implementation**, conditional on two Week-1 spikes which are already identified as blockers in the epics document and do not affect Phase 4 *start* (Epic 1 does not depend on them).

- No 🔴 Critical violations.
- No 🟠 Major issues.
- 6 🟡 Minor concerns, all documentation or exit-gate polish — none block Phase 4 start.

### Scorecard

| Dimension | Status | Notes |
|---|---|---|
| Document inventory complete (PRD, Architecture, Epics, UX) | ✅ | No duplicates, no missing required docs |
| PRD requirements extracted (FR + NFR) | ✅ | 46 FRs + 58 NFRs |
| FR coverage by epics/stories | ✅ | 100% (46/46) |
| NFR coverage by stories | ⚠️ | 56/58 explicitly mapped; NFR-P8, NFR-M8 unassigned |
| UX-DR coverage by stories | ✅ | 33/33 |
| UX ↔ PRD alignment | ✅ | Journeys, principles, a11y reconciled |
| UX ↔ Architecture alignment | ✅ | No contradictions; 2 minor cross-ref gaps |
| Epic user-value framing | ✅ | Epic 10 borderline but defensible |
| Epic independence | ✅ | Retroactive wiring (9.3) is deliberate |
| Story sizing | ✅ | Single-dev-session sized |
| AC structure (Given/When/Then) | ✅ | Consistent across sample |
| Database JIT creation | ✅ | FacilitiesTable in 3.1, GuestEntriesTable in 5.1 |
| Starter template discipline | ✅ | `flutter create --empty` enforced in 1.1 |
| Forward dependencies | ✅ | None found; only retroactive 9.3 is deliberate |

### Critical Issues Requiring Immediate Action

**None.** Phase 4 can begin on Epic 1.

### Recommended Next Steps

Ordered by value and sequencing. **None are readiness blockers**; all can be addressed during or between sprints.

1. **Add NFR-M8 epic-exit acceptance gate** to the last story of each epic (1–9). Pattern: "Given the epic is claimed complete, When the AI coverage review + security scan completes, Then findings are remediated within the same week, and the epic is not closed until remediated." This closes the most material gap between PRD commitment and story enforcement.
2. **Assign NFR-P8 (cold start ≤ 2.5s p95)** to either Story 1.1 (startup integration test) or Story 10.8 (production rollout gate). Pick one and make it a G/W/T acceptance criterion.
3. **Run the Week-1 spikes immediately** — all four are already captured in the epics document (lines 241–245):
   - FR26 May-2026 apartment registration-number payload shape (blocker for Story 4.9 / FR26).
   - eVisitor idempotency key support (affects UUID use in ImportTourists).
   - FR36.6 lookup-by-client-UUID endpoint existence → determines `InFlightReconciler` Path A vs. Path B (Story 6.8).
   - eVisitor API-key scope (vendor-wide vs. per-account) → affects Login UI shape (Story 1.7).
   These do not block the start of Epic 1, but Epic 4 (Story 4.9) and Epic 6 (Story 6.8) depend on them. Front-loading them keeps the 5-week solo-dev timeline safe.
4. **Documentation hygiene sweep (30-min pass):**
   - UX spec line 371: replace "~5 custom widgets" with a cross-reference to §Custom Components (10 widgets).
   - Architecture §3: add a 2-line cross-reference pointing to UX spec + figma-code-contract.md + `.claude/rules/design-system.md` as the UI-fidelity authorities.
   - Architecture: name `ShellRoute` for the force-update overlay to match Story 9.4 language.
   - Epic 10 header: change "FRs covered: none" → "FRs covered: FR42 (operational half, paired with 9.4)".
5. **Reconcile NFR-A1 wording across docs** (non-breaking but cleaner): make explicit that 48 dp is the universal touch-target floor and 56 dp is the primary-CTA minimum. UX-DR26 already phrases this correctly; mirror the exact wording into PRD NFR-A1 + design-system rule for zero ambiguity.
6. **Consider adding an Epic 0 "ceremonies" note** (non-blocking) — this is a solo-dev engagement, so "Epic 0" could simply be a README/Runbook pointer. Not required; just a Hansei-style aid for future-you.

### Week-1 Implementation Start Plan

On the basis of this readiness assessment, Phase 4 can begin with:

- **Day 1:** Story 1.1 (Project Bootstrap & CI Foundation) — unblocks every subsequent story.
- **Day 1 (parallel):** Begin the four Week-1 spikes against the eVisitor testApi. These run alongside, not in front of, Story 1.1.
- **Day 2–3:** Stories 1.2 (Design System Foundation) + 1.3 (Security Primitives, Dio & Cert Pinning). Tokens + theme needed before any UI; Dio + Keystore wiring needed before 1.4/1.7.
- **Day 4–5:** Story 1.4 (UMP/CMP) + 1.5 (Welcome + sensitive-data disclosure).

### Summary Note

This assessment identified **6 minor concerns across 3 categories** (NFR coverage polish, documentation hygiene, epic-exit gating). Zero critical or major defects. The planning artifacts — PRD, Architecture, UX spec, Epics — are internally consistent, numerically traceable, and measurement-grounded. The reliability thesis that the product positioning hinges on is observable in production from day 1 (NFR-I4 permanent Dio fake + Crashlytics `scan_to_submit`). The solo-dev slip protocol and kill criteria are explicit.

**Recommendation: begin Phase 4 on Epic 1 Story 1.1, run the four Week-1 spikes in parallel, and fold the six minor concerns into the same week as cleanup commits.**

---

**Assessor:** Claude (bmad-check-implementation-readiness)
**Date:** 2026-04-23
**Input artifacts:** PRD (916 lines), Architecture (1011 lines), Epics (3749 lines, 10 epics / 59 stories), UX Spec (1628 lines) + Figma Code Contract (171 lines)




