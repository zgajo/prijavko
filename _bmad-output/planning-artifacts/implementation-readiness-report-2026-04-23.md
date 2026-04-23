---
project: prijavko
date: 2026-04-23
stepsCompleted:
  - step-01-document-discovery
  - step-02-prd-analysis
  - step-03-epic-coverage-validation
  - step-04-ux-alignment
  - step-05-epic-quality-review
  - step-06-final-assessment
filesIncluded:
  prd: _bmad-output/planning-artifacts/prd.md
  architecture: null
  epics: null
  stories: null
  ux: null
supportingDocs:
  - _bmad-output/planning-artifacts/product-brief-prijavko-distillate.md
  - _bmad-output/planning-artifacts/product-brief-prijavko.md
  - _bmad-output/planning-artifacts/research/technical-evisitor-auth-lifecycle-research-2026-04-22.md
---

# Implementation Readiness Assessment Report

**Date:** 2026-04-23
**Project:** prijavko

## Step 1 — Document Discovery

### Inventory

**PRD Files Found**
- Whole: `_bmad-output/planning-artifacts/prd.md` (83 KB, modified 2026-04-23)
- Sharded: none

**Architecture Files Found**
- Whole: none
- Sharded: none

**Epics & Stories Files Found**
- Whole: none
- Sharded: none

**UX Design Files Found**
- Whole: none
- Sharded: none

**Supporting (non-canonical) Documents**
- `product-brief-prijavko-distillate.md` (LLM-optimized distillate — authoritative per memory)
- `product-brief-prijavko.md` (original brief)
- `research/technical-evisitor-auth-lifecycle-research-2026-04-22.md`

### Issues

- ⚠️ **WARNING — Architecture document not found.** Required for readiness assessment.
- ⚠️ **WARNING — Epics & Stories document(s) not found.** Required; without these, the readiness check cannot validate requirements traceability or implementation sequencing.
- ⚠️ **WARNING — UX Design document not found.** Impact depends on scope; PRD may cover UX inline.
- ✅ **No duplicate formats detected** (no sharded vs. whole conflicts).

### Selected Files for Assessment
- PRD: `prd.md`
- Architecture: *missing*
- Epics/Stories: *missing*
- UX: *missing*

## Step 2 — PRD Analysis

### Functional Requirements

**Onboarding & Consent**
- **FR1** — Host can launch the app and be guided through first-run consent, permissions, and credential capture in a single linear flow.
- **FR2** — App can present an EU-consent surface for ad personalization before any ads are requested.
- **FR3** — App can present a sensitive-data disclosure explaining passport/MRZ processing, 3-day retention, and a link to the Privacy Policy before camera permission is requested.
- **FR4** — Host can grant or deny camera permission; manual entry remains fully functional if camera is denied.
- **FR5** — Host can enter and store eVisitor credentials (username, password, apikey) for subsequent sessions without re-entering.
- **FR6** — App can verify eVisitor credentials by performing a live login against the eVisitor authentication endpoint during onboarding.
- **FR7** — Host can replace or re-enter credentials at any time from the Settings surface.

**Authentication & Session Lifecycle**
- **FR8** — App can maintain an eVisitor session across process restarts, device reboots, and periods of background inactivity.
- **FR9** — App can detect an expired or invalid session from eVisitor responses (regardless of HTTP status code) and classify the cause (session-dead, lockout, credentials-invalid, network, or server error).
- **FR10** — App can re-authenticate automatically using stored credentials when a dead session is detected, without duplicate concurrent login attempts.
- **FR11** — App can surface a non-blocking credential banner to the host when session-dead or credentials-invalid is detected, with a single-tap recovery action.
- **FR12** — App can refuse further login attempts after a configurable threshold of consecutive failures within a rolling window, and communicate the remaining wait to the host in Croatian.
- **FR13** — App can perform an opportunistic authentication check on app foregrounding without blocking the UI.
- **FR14** — Host can view current session state (authenticated, reauth-needed, locked-out) at a glance in the Settings surface.
- **FR14.5** — App can detect missing credentials on launch (Keystore returns no value for an existing facility profile) and surface a non-blocking "credentials missing — re-enter to continue" state with facility names pre-populated, without losing facility context or forcing full re-onboarding.

**Facility Management**
- **FR15** — App can fetch and cache the list of facilities available to the host's eVisitor account on first successful login.
- **FR16** — Host can select exactly one facility at the start of each registration session.
- **FR17** — App can surface the last-used facility as a hint during facility selection, but not pre-select it as a default.
- **FR18** — Host can see the currently active facility on the home surface during an active registration session.
- **FR19** — App can refresh the facility list when the host explicitly requests it, without forcing a full re-login.

**Guest Capture**
- **FR20** — Host can capture guest identity data by holding a passport or ID card in front of the camera; the app detects and parses a valid MRZ automatically.
- **FR21** — Host can tap a static capture control to capture a document image when live MRZ detection does not succeed within a bounded time.
- **FR22** — Host can enter guest data manually as a fallback when neither live nor static capture succeeds.
- **FR23** — App can validate captured or entered guest data against semantic sanity rules (date plausibility, document expiry, valid country codes, realistic birth years) before accepting it into the queue.
- **FR24** — Host can review and correct captured guest data before it is committed to the queue.
- **FR25** — App can reject a capture or entry inline with a Croatian-language explanation when sanity validation fails, without committing it to the queue.
- **FR26** — App can support future fields required by the May-2026 apartment registration-number mandate, gated by a feature flag, without breaking the existing capture flow.

**Queue & Local Persistence**
- **FR27** — App can persist every captured guest to encrypted local storage with a client-generated unique identifier, synchronously, before surfacing any success indication to the host.
- **FR28** — App can preserve unsent guests across app kills, device reboots, and offline periods indefinitely until either submission succeeds or the host deletes them.
- **FR29** — Host can view the unsent queue with a per-guest status and initiate per-guest edit or delete actions.
- **FR30** — App can automatically delete successfully submitted guests after a 3-day soft-undo retention window, regardless of host action.
- **FR31** — Host can manually delete individual unsent or recently-submitted guests from the queue at any time.
- **FR31.5** — Host can replace the active OIB from the Settings surface via a destructive, typed-OIB-guarded confirmation that wipes all facility profiles, queue entries, credentials, and cookie jar, then re-launches onboarding.

**Submission (Send All)**
- **FR32** — Host can trigger a batch submission of all unsent guests for the active facility via an explicit action (no automatic submission, no background retry).
- **FR33** — App can perform a pre-flight check for authentication and network reachability immediately before submitting and block the submission with a clear message if either check fails.
- **FR34** — App can submit guests individually to eVisitor such that a rejection of one guest does not cause rejection of other guests in the same batch.
- **FR35** — App can report per-guest success or failure outcomes to the host after a submission batch completes.
- **FR36** — Host can edit a failed guest inline and retry only the failed guests without re-submitting already-successful ones.
- **FR36.5** — App can distinguish a rate-limited response (HTTP 429 or equivalent eVisitor throttling) from a submission failure and surface a non-blocking "eVisitor is busy — retrying..." message with exponential backoff, without counting the rate-limit as a per-guest failure outcome.
- **FR36.6** — App can track an `in_flight` queue state between `ready-to-send` and `accepted/rejected`; on app resume after process kill or crash, any `in_flight` entries are re-queried against eVisitor before any retry is attempted (or held for host review if a lookup endpoint is unavailable) — preventing silent double-submits.

**Post-Submission Closure**
- **FR37** — App can present a closure summary after every submission batch, containing the facility name, number of guests registered, and the local submission timestamp — and containing no guest names, document numbers, or other PII.
- **FR38** — Host can share or screenshot the closure summary for their own records.

**Privacy & Data Lifecycle**
- **FR39** — Host can view a "Your Data" surface listing what is currently stored on the device (unsent queue count, recently-submitted count within retention), with links to the Privacy Policy and Terms of Service.
- **FR40** — Host can trigger a complete wipe of all local data (queue, cached facilities, cookie jar, credentials) in a single action.

**Observability & Compliance Signals**
- **FR41** — App can emit zero-PII telemetry events that allow the operator to measure submission success rate, session-dead-recovery rate, queue-stuck-over-24h count, and crash-free session rate — without transmitting any guest or credential data.
- **FR42** — App can present a forced-update banner when a remote minimum-supported-version signal indicates the current client is incompatible with eVisitor, and block submissions while the banner is active.

**Total FRs: 46** (FR1–FR42 + FR14.5, FR31.5, FR36.5, FR36.6)

### Non-Functional Requirements

**Performance (NFR-P1 → NFR-P10)**
- **NFR-P1** — Live MRZ auto-shutter fires within 1.5s (p95) on well-lit in-date MRD.
- **NFR-P2** — Static-tap fallback surfaces no later than 3s of failed live detection.
- **NFR-P3** — Scanned guest persisted to encrypted queue + reflected in unsent-row UI within 300ms (p95), synchronous DB commit before haptic.
- **NFR-P4** — Semantic sanity validation completes within 50ms (p95).
- **NFR-P5** — Send All pre-flight (auth + network) completes within 1s (p95).
- **NFR-P6** — Per-guest progress indicator updates within 200ms of each eVisitor response.
- **NFR-P7** — Post-submit closure summary renders within 200ms of last guest's response.
- **NFR-P8** — Cold start → home ready within 2.5s (p95) on mid-range 2023+ hardware.
- **NFR-P9** — Warm resume + opportunistic auth check within 1s (p95), non-blocking.
- **NFR-P10** — Holds ≥40 unsent guests in a session without UI degradation (60fps scroll, 200ms edit/delete); verified by integration test.

**Security (NFR-S1 → NFR-S11)**
- **NFR-S1** — HTTPS TLS 1.2+ only; cleartext rejected at platform level.
- **NFR-S2** — SHA-256 cert pinning to `www.evisitor.hr` (leaf + intermediate); pin mismatch aborts without retry.
- **NFR-S3** — Credentials in flutter_secure_storage with Keystore-backed AES/GCM, hardware-backed where available.
- **NFR-S4** — Cookie jar AES-GCM-encrypted at rest; key in flutter_secure_storage.
- **NFR-S5** — Drift queue AES-GCM-encrypts PII columns.
- **NFR-S6** — Android `allowBackup="false"` and `fullBackupContent="false"`.
- **NFR-S7** — Zero PII in logs/telemetry: (a) PII-bearing types override `toString() → [REDACTED]`, (b) CI grep guard build-blocking.
- **NFR-S8** — Crashlytics traces symbolicated, zero free-text from guest records; custom events carry counts/IDs/codes only.
- **NFR-S9** — OWASP MASVS L1 self-audit pre-submission.
- **NFR-S10** — 3-day auto-purge enforced regardless of host action/app state.
- **NFR-S11** — Release builds disable verbose Dio logging; Crashlytics custom-key allowlist; transitive-dep log review; staging crash-in-PII-path test inspecting Firebase Console output.

**Reliability (NFR-R1 → NFR-R9)**
- **NFR-R1** — Crash-free session rate ≥ 99.5%.
- **NFR-R2** — `scan_to_submit` first-time success ≥ 90% without corrections.
- **NFR-R3** — Silent-failure rate = 0 confirmed cases during peak season (2026-06-01 → 2026-09-30).
- **NFR-R4** — Queue-stuck count (>24h) = 0 at every app open; telemetry on non-zero.
- **NFR-R5** — No submission loss from process kill, reboot, network drop, or storage pressure.
- **NFR-R6** — Auto-recover from expired session on next action without re-credential entry (unless credentials invalid).
- **NFR-R7** — Exactly ONE login call under concurrent auth-triggering requests (QueuedInterceptor serialization).
- **NFR-R8** — Client-side circuit breaker: 3 consecutive login failures → 6 minutes open (strictly more conservative than Rhetos 5/5).
- **NFR-R9** — Offline for all capture/queue/facility flows; only Send All + opportunistic auth need network.

**Integration (NFR-I1 → NFR-I7)**
- **NFR-I1** — JSON envelopes everywhere; `ImportTourists` XML-as-string-in-JSON; dates `/Date(ms+offset)/`.
- **NFR-I2** — Classifier handles 401, 403, 400+SystemMessage, 200+error-envelope-at-non-Login.
- **NFR-I3** — Classifier matches Croatian text (`locked|zaključan`, `invalid|nevažeć|neispra`, `session|prijava|auth`) + English; refined in Week-1 spike.
- **NFR-I4** — Permanent in-repo Dio fake on every CI build + nightly CI against real testApi with minimal-data canary.
- **NFR-I5** — Fake-to-real drift triggers CI failure; drift resolved before merging.
- **NFR-I6** — No guest PII to AdMob/Crashlytics/Firebase/Play/any third party — only to eVisitor.
- **NFR-I7** — Forced-update via static `prijavko.hr/min-version.json` check on cold start; blocks Send All when active.

**Compatibility (NFR-C1 → NFR-C5)**
- **NFR-C1** — Android 7.0 (API 24)+; target SDK per Play mandate at submission.
- **NFR-C2** — arm64-v8a + armeabi-v7a; no x86.
- **NFR-C3** — Phone portrait 4.7"–6.9"; landscape/tablet portrait render without breakage (not optimized).
- **NFR-C4** — CameraX-compatible devices (effectively all API-24+ with rear camera).
- **NFR-C5** — No Google Play Services beyond ML Kit MRZ (on-device) + Firebase Crashlytics.

**Localization (NFR-L1 → NFR-L4)**
- **NFR-L1** — Croatian primary, English secondary; follows Android system locale, Croatian fallback.
- **NFR-L2** — Date/time/number formats follow active locale.
- **NFR-L3** — Error messages include Croatian eVisitor `UserMessage` (when present) + prijavko Croatian explanation safe for UI.
- **NFR-L4** — No English-only user-facing strings; missing translations block release.

**Accessibility (NFR-A1 → NFR-A4)** — *good-stewardship baselines, not legal minimums*
- **NFR-A1** — 48×48 dp minimum touch targets.
- **NFR-A2** — WCAG 2.1 AA contrast (4.5:1 body, 3:1 large) in light + dark.
- **NFR-A3** — Content descriptions for TalkBack on every actionable control; scan/Send All/banner/closure fully navigable.
- **NFR-A4** — Manual-entry respects system font scaling up to 200% without layout breakage.

**Maintainability (NFR-M1 → NFR-M8)**
- **NFR-M1** — `dart analyze --fatal-warnings --fatal-infos` on CI; zero warnings merged.
- **NFR-M2** — No `dynamic` in production paths except at deserialization boundaries.
- **NFR-M3** — Public classes/functions carry WHY doc comments (not WHAT).
- **NFR-M4** — Atomic commits, WHY-focused messages.
- **NFR-M5** — Coverage measured, not percentage-gated; capability contract + integration harness cover every MVP capability; ≥70% meaningful on auth + queue + classifier.
- **NFR-M6** — Pre-peak code freeze 2026-06-15; post-freeze = bugs only until 2026-09-30 kill-criteria checkpoint.
- **NFR-M7** — PRD + brief + distillate + eVisitor research are authoritative context; scope changes update PRD first.
- **NFR-M8** — AI coverage review + security scan at end of every epic (Weeks 1–4); findings remediated same week; Week 5 = Play Store prep only.

**Total NFRs: 47** (10 Performance + 11 Security + 9 Reliability + 7 Integration + 5 Compatibility + 4 Localization + 4 Accessibility + 8 Maintainability. Wait — recount: 10+11+9+7+5+4+4+8 = 58. Corrected total: **58 NFRs**.)

### Additional Requirements (constraints, commitments, dated milestones)

**Compliance deadlines (hard-dated, pre-launch 2026-05-27):**
- Play Store Data Safety declaration submitted and sensitive-data manual-review accepted
- Privacy Policy URL live (`prijavko.hr/privacy`)
- ToS with liability disclaimer live (`prijavko.hr/terms`) — host is sole legal data controller
- AdMob + UMP/CMP EU consent surface
- May-2026 registration-number mandate payload support (blocker — depends on Week-1 spike)

**Scope commitments (non-negotiable signed-off list):**
- v1.0 MUST NOT include: iOS, web/PWA host surface, multi-OIB UI, NFC, guest self-scan, reported-history view, CSV/PDF export, compliance receipt, auto-retry, push notifications, geolocation, widgets, iCal import, tax computation, boravišna-pristojba filing, social/community features.
- No feature survives into v1.0 without an observable success metric.

**Slip protocol (defer order if 5-week timeline compresses):**
1. Hybrid live-first capture → static-only
2. Opportunistic auth banner → login-on-send (manual refresh only)
3. Replace-Active-OIB setting (schema-ready, UI deferred)
4. Shareable closure-summary screenshot → textual only

**Irreducible launch floor (below this, slip the date not the scope):**
- Scan → queue → manual Send All → successful submission against real eVisitor
- Six-state auth machine with classifier handling HTTP 400 + SystemMessage
- Zero-PII log guarantee at type level + CI grep guard
- Play Store Data Safety + privacy policy + ToS accepted

**Operational constraints:**
- Solo-dev, ~12 effective working days between 2026-04-23 and 2026-05-27
- Pre-peak code freeze 2026-06-15 (bugs-only June–Aug)
- Kill-criteria checkpoint 2026-09-30 (<1000 installs OR <3.5★ OR <10% M3 retention → planned sunset)
- Budget sub-€500 out-of-pocket
- 5 host interviews are a **pre-build blocker** (validates top-pain hypothesis)

**Measurable outcomes dashboard (Crashlytics + Play Console):**
1. Crash-free session rate ≥ 99.5%
2. `scan_to_submit` success ≥ 90% without corrections
3. Auth-recovery latency p50 < 30s
4. Queue-stuck-count >24h = 0
5. Play Store rating ≥ 4.5
6. Weekly active hosts ≥500 by July 2026

**Risk mitigations flagged as requirement-bearing:**
- Production-canary ping account against testApi (nightly CI)
- In-app forced-update banner on contract break (NFR-I7)
- Feature-flagged May-2026 mandate field (FR26)

### PRD Completeness Assessment

**Strengths:**
- Requirements are **numbered, traceable, and verb-prefixed** ("Host can…" / "App can…") — clean testability surface.
- Every capability in the Journey Requirements Summary table maps to at least one FR.
- Technical-success metrics in Step 3 are tied directly to NFRs (crash-free → NFR-R1; scan_to_submit → NFR-R2; silent-failure → NFR-R3; queue-stuck → NFR-R4).
- NFRs cover the full ISO-25010-ish spread: performance, security, reliability, integration, compatibility, localization, accessibility, maintainability.
- Slip protocol + irreducible floor give epic planners an explicit priority gradient.
- Compliance + dated milestones are first-class; no hand-waving "GDPR-compliant" — every claim is actionable (AES-GCM, 3-day purge, CI grep guard, UMP/CMP).

**Gaps & concerns:**
- **No architecture document exists.** Several FRs/NFRs imply architectural decisions (six-state auth machine, QueuedInterceptor, Drift schema with `in_flight` state per FR36.6, certificate pin set management, feature-flag infrastructure for FR26) that an implementation agent cannot execute from the PRD alone.
- **No epics/stories exist.** The capability contract is ready to be decomposed into epics, but no decomposition has been performed.
- **No UX design document exists.** The PRD describes journeys narratively but contains no wireframes, surface inventory, component-level interaction specs, Croatian-language microcopy, or screen-by-screen layouts. Several FRs (e.g., FR11 non-blocking credential banner, FR35 per-guest outcomes, FR37 closure summary) will need UX specificity before a developer can implement them consistently.
- **FR26 depends on a Week-1 spike** that has not yet been performed — spec is intentionally deferred, but epics must plan for this as a gated blocker.
- **FR36.6 `in_flight` state** introduces a state machine requirement on top of the basic queue; needs either architecture or story-level design to nail down the "lookup endpoint unavailable" fallback path.
- Minor internal inconsistency flagged during extraction: the earlier text references a "six-state" auth machine; the distillate should be checked to ensure the PRD's Settings-visible states (authenticated, reauth-needed, locked-out) are consistent with the six states. Not a blocker, but a story-level clarification will be needed.

**Verdict:** PRD is complete and high-quality as a requirements artifact. It is **not** sufficient on its own to begin implementation — architecture + epics/stories + UX spec remain prerequisites.

## Step 3 — Epic Coverage Validation

### Epics Document Status

🛑 **No epics document found** in `_bmad-output/planning-artifacts/`. Search pattern `*epic*.md` returned zero results — neither a whole-file nor a sharded `epics/index.md` structure exists.

### Coverage Matrix

| FR | PRD Requirement (summary) | Epic Coverage | Status |
|---|---|---|---|
| FR1 | First-run linear flow (consent → perms → creds) | **NOT FOUND** | ❌ MISSING |
| FR2 | UMP/CMP EU consent before ads | **NOT FOUND** | ❌ MISSING |
| FR3 | Sensitive-data disclosure + 3-day retention + Privacy link | **NOT FOUND** | ❌ MISSING |
| FR4 | Camera permission grant/deny; manual-entry always works | **NOT FOUND** | ❌ MISSING |
| FR5 | Enter + store eVisitor credentials | **NOT FOUND** | ❌ MISSING |
| FR6 | Verify credentials via live login at onboarding | **NOT FOUND** | ❌ MISSING |
| FR7 | Replace/re-enter credentials from Settings | **NOT FOUND** | ❌ MISSING |
| FR8 | Maintain session across restarts/reboots/inactivity | **NOT FOUND** | ❌ MISSING |
| FR9 | Detect + classify session state from eVisitor responses | **NOT FOUND** | ❌ MISSING |
| FR10 | Auto re-auth with stored creds, no duplicate concurrent logins | **NOT FOUND** | ❌ MISSING |
| FR11 | Non-blocking credential banner, single-tap recovery | **NOT FOUND** | ❌ MISSING |
| FR12 | Circuit breaker after N consecutive failures, Croatian wait message | **NOT FOUND** | ❌ MISSING |
| FR13 | Opportunistic auth check on foregrounding, non-blocking | **NOT FOUND** | ❌ MISSING |
| FR14 | Session state visible in Settings | **NOT FOUND** | ❌ MISSING |
| FR14.5 | Missing-credentials state with facility-preserved re-entry | **NOT FOUND** | ❌ MISSING |
| FR15 | Fetch + cache facility list on first login | **NOT FOUND** | ❌ MISSING |
| FR16 | Explicit per-session facility choice | **NOT FOUND** | ❌ MISSING |
| FR17 | Last-used facility as hint, not default | **NOT FOUND** | ❌ MISSING |
| FR18 | Active facility visible on home | **NOT FOUND** | ❌ MISSING |
| FR19 | Explicit facility-list refresh without re-login | **NOT FOUND** | ❌ MISSING |
| FR20 | Live MRZ detection + parse | **NOT FOUND** | ❌ MISSING |
| FR21 | Static-tap capture fallback after bounded time | **NOT FOUND** | ❌ MISSING |
| FR22 | Manual-entry fallback | **NOT FOUND** | ❌ MISSING |
| FR23 | Semantic sanity validation (date/expiry/ISO/birth year) | **NOT FOUND** | ❌ MISSING |
| FR24 | Review + correct before queue commit | **NOT FOUND** | ❌ MISSING |
| FR25 | Inline rejection with Croatian explanation | **NOT FOUND** | ❌ MISSING |
| FR26 | Feature-flagged May-2026 mandate fields | **NOT FOUND** | ❌ MISSING |
| FR27 | Synchronous encrypted persist + UUID before success | **NOT FOUND** | ❌ MISSING |
| FR28 | Unsent queue persists across kills/reboots/offline | **NOT FOUND** | ❌ MISSING |
| FR29 | View unsent queue; per-guest edit/delete | **NOT FOUND** | ❌ MISSING |
| FR30 | 3-day auto-purge of submitted guests | **NOT FOUND** | ❌ MISSING |
| FR31 | Manual delete of individual queue entries | **NOT FOUND** | ❌ MISSING |
| FR31.5 | Destructive Replace-Active-OIB with typed confirmation | **NOT FOUND** | ❌ MISSING |
| FR32 | Explicit Send All, no auto-retry | **NOT FOUND** | ❌ MISSING |
| FR33 | Pre-flight auth + network check before send | **NOT FOUND** | ❌ MISSING |
| FR34 | Per-guest submission (one rejection does not kill batch) | **NOT FOUND** | ❌ MISSING |
| FR35 | Per-guest success/failure reporting | **NOT FOUND** | ❌ MISSING |
| FR36 | Edit failed inline + retry-failed-only | **NOT FOUND** | ❌ MISSING |
| FR36.5 | 429/throttle distinguished from failure; exponential backoff | **NOT FOUND** | ❌ MISSING |
| FR36.6 | `in_flight` state + resume reconciliation to prevent double-submit | **NOT FOUND** | ❌ MISSING |
| FR37 | Zero-PII closure summary (facility + count + time) | **NOT FOUND** | ❌ MISSING |
| FR38 | Share/screenshot closure summary | **NOT FOUND** | ❌ MISSING |
| FR39 | "Your Data" surface with counts + policy links | **NOT FOUND** | ❌ MISSING |
| FR40 | Single-action complete local-data wipe | **NOT FOUND** | ❌ MISSING |
| FR41 | Zero-PII telemetry: submission/recovery/stuck/crash-free | **NOT FOUND** | ❌ MISSING |
| FR42 | Forced-update banner from min-version signal, blocks Send All | **NOT FOUND** | ❌ MISSING |

### Missing Requirements — all 46

Every FR in the PRD is uncovered. No prioritization by subgroup is useful at this stage because the epics decomposition simply hasn't been attempted yet.

**Recommendation:** run `bmad-create-epics-and-stories` to generate the epic structure. Based on the PRD's capability groupings, a natural decomposition is:

- **Epic 1 — Onboarding, Consent & Credentials** (FR1–FR7, FR14.5) — gates camera + login path
- **Epic 2 — Auth Lifecycle & Classifier** (FR8–FR14) — six-state machine, QueuedInterceptor, circuit breaker; the reliability headline promise
- **Epic 3 — Facility Management (Neutral App)** (FR15–FR19)
- **Epic 4 — Capture Pipeline** (FR20–FR26) — MRZ + static-tap + manual + sanity layer + mandate feature flag
- **Epic 5 — Queue & Drift Persistence** (FR27–FR31.5) — encrypted synchronous persist, 3-day auto-purge, OIB replace
- **Epic 6 — Send All & Submission** (FR32–FR36.6) — pre-flight, per-guest isolation, `in_flight` reconciliation, throttling
- **Epic 7 — Closure, Privacy Surface & Data Wipe** (FR37–FR40)
- **Epic 8 — Observability, Forced-Update & Compliance Readiness** (FR41–FR42 + NFR cross-cuts: CI grep guard, permanent Dio fake, nightly testApi canary, Play Store submission package)

### Coverage Statistics

- **Total PRD FRs:** 46
- **FRs covered in epics:** 0
- **Coverage percentage:** **0%**

### Verdict

Epic coverage validation cannot produce a meaningful gap analysis against an artifact that doesn't exist. The gap **is** the artifact. This is the biggest single blocker to implementation readiness.

## Step 4 — UX Alignment Assessment

### UX Document Status

**Not Found.** Search patterns `*ux*.md` and `*ux*/index.md` returned zero results in `_bmad-output/planning-artifacts/`. No wireframes, surface inventory, component spec, Croatian microcopy catalog, or screen-by-screen layout document exists.

### Is UX Implied by the PRD?

**Yes — strongly.** Prijavko is a user-facing Android mobile app whose entire thesis depends on interaction quality at the door. The PRD itself describes multiple UX artifacts that must exist before implementation:

- **5 narrative journeys** (onboarding, 4-guest happy path, session death + Wi-Fi drop, one-bad-passport, multi-facility) — each implies screens, transitions, microcopy
- **Capability contract specifies UI affordances** — non-blocking credential banner (FR11), inline Croatian rejection messages (FR25), per-guest success/failure rendering (FR35), edit-and-retry-failed-only affordance (FR36), closure summary shareable (FR38), "Your Data" surface (FR39), forced-update banner (FR42)
- **Neutral App facility pattern** (FR16–FR18) — explicit UX inversion requiring careful visual treatment; last-used as hint-not-default is a design decision that needs a wireframe, not prose
- **Localization NFRs** — all strings need to exist in Croatian (primary) + English (secondary); a microcopy catalog is effectively prerequisite

### Alignment Issues

| Concern | Impact |
|---|---|
| No UX ↔ PRD traceability possible (no UX document to cross-check) | Cannot confirm that the journey narratives decompose into concrete screens covering every FR. A dev agent will invent UX per-story, producing inconsistent treatment of core patterns (banners, inline errors, progress indicators). |
| No UX ↔ Architecture alignment possible (neither document exists) | Cannot check that performance NFRs (NFR-P1 live MRZ 1.5s, NFR-P3 300ms queue reflect, NFR-P6 200ms per-guest progress, NFR-P7 200ms closure render) are architecturally achievable through planned UI rendering strategy. |
| No Croatian microcopy catalog | FR25 (inline Croatian explanation), NFR-L3 (Croatian UserMessage + prijavko explanation), FR12 ("Previše neuspješnih pokušaja — pričekajte 6 minuta") all require exact phrasing that beta hosts will react to. Without a catalog, each story will bikeshed its own microcopy. |
| Screen inventory absent | Unclear which screens exist, what their state variants are (empty queue, offline banner, auth-dead banner, in-flight submission progress), or how navigation connects them. |
| Interaction specification gaps for the innovation bets | The five declared novelty patterns (zero-retention framing, classifier-as-feature, Neutral App, type-level zero-PII, permanent Dio fake) include two UX-facing ones (zero-retention framing surfaces, Neutral App facility picker) that need concrete design to land in beta testing. |

### Warnings

- ⚠️ **UX is implied but missing.** This is a blocker-class gap for a consumer mobile app with explicit user-experience differentiation as part of its value proposition.
- ⚠️ Closed beta starts 2026-05-13 (11 working days from today). Without a UX spec, beta feedback will reflect inconsistent UX choices made story-by-story, not a coherent design.
- ⚠️ Play Store listing requires 6 Croatian-language screenshots — cannot be produced without a screen inventory and a stable UI.

## Step 5 — Epic Quality Review

### Reviewable Artifact Status

**No epics or stories exist to review.** Quality assessment against `bmad-create-epics-and-stories` standards requires an artifact to critique. Since the artifact does not exist, this step cannot be executed in its standard form.

### What Can Still Be Checked — Quality Preconditions

Although there are no epics to score, several preconditions for epic *creation* can be examined so that when epics are generated, the common anti-patterns are headed off. Below is a forward-looking quality checklist derived from the PRD, flagged by risk.

#### 🔴 Critical preconditions (must hold before epics exist)

| Precondition | Current State | Risk if Ignored |
|---|---|---|
| Architecture document with starter-template decision | **Missing** | Epic 1 Story 1 normally is "set up project from starter template." Without architecture, there is no template choice; implementation cannot begin. |
| FR → Epic mapping is stable | **Not started** | The recommended 8-epic decomposition in Step 3 is a suggestion, not a committed structure. |
| Database/entity creation timing is understood | **Partially** | PRD specifies Drift for queue + facility cache, flutter_secure_storage for credentials, encrypted file for cookie jar — but which story creates which Drift tables is not decomposed. Anti-pattern to avoid: "Epic 1 Story 1 creates all tables." |
| Week-1 spike (May-2026 mandate + reported-history endpoint) is identifiable as a gated story | **Not yet in any epic** | PRD names these as blockers. If epics are generated without explicit spike stories at the top of Epic 4 and Epic 8, those blockers will be rediscovered mid-build. |

#### 🟠 Major anti-patterns to avoid when epics are created

Based on common BMAD epic-quality failures + this project's shape:

- **❌ "Auth System" as a single epic.** Auth is user-value-deliverable only when paired with onboarding + classifier surfacing. A story like "set up Dio + cookie jar" has no user-observable outcome. Instead: Epic 1 delivers "host logs in and sees home screen," which internally covers the first slice of auth infrastructure; Epic 2 then delivers "session survives inactivity and surfaces banner when dead" on top of Epic 1's plumbing. This preserves user-value framing.
- **❌ Technical-milestone epics.** "Epic X — Set up CI/CD," "Epic Y — Dio Fake Harness," "Epic Z — Crashlytics wiring" all fail the user-value test. These must be absorbed into epics 1–8 as stories or cross-cutting work.
- **❌ Forward dependencies.** Example trap: Epic 6 (Send All) stories assuming Epic 8 (forced-update banner) exists. The two must be independently completable.
- **❌ Epic-sized stories.** "Build the classifier" is an epic, not a story. A correct story is "classifier returns session-dead verdict on HTTP 400 + Croatian SystemMessage matching `session|prijava|auth`" — testable, shippable, small.
- **❌ Upfront schema creation.** A common BMAD failure is "Epic 1 Story 1 creates full Drift schema." Correct pattern: each story creates only the tables it needs at the time it needs them (queue row type in Epic 5; facility row type in Epic 3; `in_flight` state column in Epic 6).

#### 🟡 Minor concerns worth pre-empting

- Observability FRs (FR41) + NFR-M8 (per-epic AI coverage + security review) imply a cross-cutting rhythm, not a single epic. Without explicit guidance, epic 8 risks becoming a dumping ground.
- PRD uses sub-numbered FRs (FR14.5, FR31.5, FR36.5, FR36.6) — these are refinements added after the main numbering. Story creators should treat them with equal weight to integer-numbered FRs.
- The slip protocol (hybrid-live → static-only, etc.) implies **every deferred capability must be a separately slippable story**, not threaded through a must-have story. E.g., "hybrid live-first capture" must be a story distinct from "static-tap capture" so that the former can slip while the latter stays.

### Dependency Analysis (proposed epic structure)

Using the Step 3 proposed epic decomposition and testing for independence:

| Epic | Stands Alone? | Dependencies |
|---|---|---|
| Epic 1 — Onboarding/Consent/Credentials | ✅ Yes (delivers first-launch working home screen) | Architecture + UX prerequisite |
| Epic 2 — Auth Lifecycle & Classifier | ✅ Yes (requires Epic 1's credentials) | Epic 1 only |
| Epic 3 — Facility Management | ✅ Yes (requires Epic 2's live session) | Epics 1–2 |
| Epic 4 — Capture Pipeline | ✅ Yes (can dry-commit to in-memory queue for demo; but most natural after Epic 5) | Epics 1–3; *best paired with Epic 5* |
| Epic 5 — Queue & Drift Persistence | ⚠️ Partially — queue exists for no reason without capture (Epic 4) or submit (Epic 6) | Epics 1–3 |
| Epic 6 — Send All | ✅ Yes (requires Epics 4+5 for guests to send) | Epics 1–5 |
| Epic 7 — Closure/Privacy/Wipe | ✅ Yes (closure requires Epic 6; wipe + "Your Data" stand on Epic 5) | Epics 5–6 |
| Epic 8 — Observability/Forced-Update/Compliance | ✅ Yes (cross-cutting; can ship last) | Epics 1–7 |

**Note:** Epics 4 and 5 are tightly coupled — they should probably be a single combined "Capture & Queue" epic, or the boundary must be carefully designed so that Epic 5's persistence story delivers a user-observable outcome (e.g., "unsent queue survives app kill" as a demonstrable acceptance criterion) rather than being hidden plumbing.

### Verdict

No epics exist, so no quality violations exist in the traditional sense — but the absence of the artifact is itself the dominant finding. When epics are created, apply the above anti-pattern list verbatim. The proposed decomposition is a starting point, not a ruling.

## Step 6 — Summary and Recommendations

### Overall Readiness Status

🔴 **NOT READY** — implementation cannot safely begin from the current artifact set.

Only 1 of 4 required planning artifacts exists. The existing artifact (PRD) is high-quality, but it is the *requirements* input — it does not substitute for architecture, epic decomposition, or UX specification. Beginning implementation now means a dev agent would invent architecture per-story, invent UX per-story, and invent epic boundaries per-story — producing the exact incoherence the Japanese-craftsmanship principles and NFR-M3/M4/M7 exist to prevent.

### Artifact Scorecard

| Artifact | Status | Readiness Signal |
|---|---|---|
| PRD | ✅ Complete, high quality | 46 FRs + 58 NFRs, traceable, observable-metrics-backed |
| Architecture | ❌ Missing | Cannot execute six-state machine, QueuedInterceptor, Drift schema, `in_flight` state, cert-pin set, feature-flag infrastructure without it |
| Epics & Stories | ❌ Missing | 0% FR coverage in epics |
| UX Design | ❌ Missing | No screen inventory, no Croatian microcopy catalog, no wireframes for banners / inline errors / per-guest progress / closure summary |

### Critical Issues Requiring Immediate Action

1. **🔴 Create the architecture document.** Blocker for every FR that implies a design decision (the six-state auth machine, QueuedInterceptor, Drift schema including FR36.6 `in_flight` reconciliation, encrypted cookie jar scheme, cert-pin management, forced-update mechanism, feature flag for FR26). Run `bmad-create-architecture`. Starter-template decision at minimum is required before Epic 1 Story 1 can exist.

2. **🔴 Create epics and stories.** Run `bmad-create-epics-and-stories` after architecture is in place. Apply the anti-pattern checklist from Step 5 (no technical-milestone epics, no forward dependencies, no upfront-schema creation, no epic-sized stories). Suggested 8-epic decomposition (from Step 3) is a starting point only.

3. **🔴 Produce UX design.** Run `bmad-create-ux-design`. Minimum viable artifact for this project: a screen inventory (12–15 screens), Croatian microcopy catalog for the banner / inline error / closure-summary surfaces, wireframes for the Neutral App facility picker and per-guest send-progress UI, and a design treatment of the "zero-retention" framing as it appears in-app.

4. **🟠 Schedule the Week-1 spike as a gated story.** FR26 (May-2026 mandate payload shape) + the v1.1 Pro feature gate (reported-history endpoint) are both named blockers in the PRD. When epics are generated, both must appear as explicit spike stories at the top of their respective epics so they cannot be accidentally deprioritized.

5. **🟠 Lock in the 5 host interviews as a pre-build gate.** The PRD flags this as a blocker. Do not let epic/architecture creation substitute for validation of the top-pain hypothesis.

6. **🟡 Reconcile the "six-state" auth machine with PRD's three Settings-visible states.** Internal inconsistency flagged in Step 2. Either the architecture or a story acceptance criterion needs to specify the exact state set.

7. **🟡 Consider whether Epics 4 (Capture) and 5 (Queue) should merge.** They are tightly coupled; separating them risks Epic 5 becoming user-value-free plumbing.

### Recommended Next Steps (in order)

1. **Today (2026-04-23) — 30 min:** Confirm (a) whether the PRD passed the `bmad-validate-prd` check already or needs that pass before continuing; (b) whether the 5 host interviews are scheduled/done. If the interviews change the top-pain hypothesis, PRD scope shifts first — *before* architecture.
2. **Day 1–2:** Run `bmad-create-architecture`. Treat the eVisitor auth-lifecycle research document as a first-class input alongside the PRD.
3. **Day 2–3:** Run `bmad-create-ux-design` (can overlap with architecture — both block epics, neither blocks the other).
4. **Day 3–4:** Run `bmad-create-epics-and-stories`. Validate against the anti-pattern checklist in Step 5 of this report.
5. **Day 4:** Re-run `bmad-check-implementation-readiness` (this workflow) against the full artifact set. The output should flip to ✅ READY with a real coverage percentage, not 0%.
6. **Day 5+:** Begin Epic 1 story execution via `bmad-dev-story`.

**Timeline reality check:** 11 working days remain to 2026-05-13 closed beta start and 22 working days to 2026-05-27 submission. Days 1–4 above are planning, leaving ~7 working days for Epic 1–3 implementation before beta (aggressive), ~18 working days before submission (feasible against slip protocol). This is why the slip protocol exists.

### Final Note

This assessment identified **one dominant blocker** (three of the four required planning artifacts do not exist) and **seven secondary concerns** covering validation gating, internal consistency, and epic-boundary design. The critical path is unambiguous: architecture → UX → epics → implementation. The PRD is ready to serve as the requirements input to each of those steps — it is good enough that no PRD rework is on the critical path.

Findings can be used to drive the next three BMAD workflows, or to document accepted risk if the user chooses to proceed as-is. Proceeding as-is is strongly discouraged: Japanese-craftsmanship rules (`/Users/darko/Documents/Projects/private/prijavko/.claude/rules/japanese-craftsmanship.md`) + NFR-M3/M4/M7 require that architecture and design precede implementation. Skipping them now buys days against the 2026-05-27 deadline at the cost of *exactly* the discipline the project's differentiation is built on.

---

**Assessor:** prijavko implementation-readiness check (bmad-check-implementation-readiness)
**Date:** 2026-04-23
**Artifacts scanned:** PRD (`prd.md`, 915 lines), planning-artifacts directory, docs directory
**Issues found:** 1 critical (3 missing artifacts), 7 secondary





