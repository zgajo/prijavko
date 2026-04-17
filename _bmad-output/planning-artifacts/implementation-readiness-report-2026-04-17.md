---
stepsCompleted: ["step-01-document-discovery", "step-02-prd-analysis", "step-03-epic-coverage-validation", "step-04-ux-alignment", "step-05-epic-quality-review", "step-06-final-assessment"]
documentsIncluded:
  prd: "_bmad-output/planning-artifacts/prd.md"
  architecture: "_bmad-output/planning-artifacts/architecture.md"
  epics: "_bmad-output/planning-artifacts/epics.md"
  ux: "_bmad-output/planning-artifacts/ux-design-specification.md"
---

# Implementation Readiness Assessment Report

**Date:** 2026-04-17
**Project:** prijavko

---

## PRD Analysis

### Functional Requirements

**Document Capture & Recognition**

- FR1: Host can capture a guest's identity document using the device camera
- FR2: System can extract guest data from the MRZ zone of a captured document with checksum validation (TD1, TD2, TD3 formats)
- FR3: System can fall back to OCR text extraction when MRZ parsing fails or MRZ is absent
- FR4: Host can manually enter or correct all guest data fields when automated extraction is insufficient
- FR5: System can determine the capture method used (MRZ, OCR, manual) and carry it as metadata

**Guest Data Review & Editing**

- FR6: Host can review extracted guest data on a read-only confirmation card before submission
- FR7: Host can switch a review card to editable mode to correct any field
- FR8: Host can add data not extractable from documents (e.g., arrival date, departure date, facility assignment)
- FR9: System can validate guest data against eVisitor field requirements before allowing submission
- FR10: Host can delete a guest from the queue before submission

**Facility Management**

- FR11: Host can add a facility profile with credentials (eVisitor username, password, facility ID) and per-facility defaults (TTPaymentCategory, ArrivalOrganisation, OfferedServiceType, default stay duration)
- FR12: Host can manage multiple facility profiles (edit, delete)
- FR13: Host can select a session-scoped active facility that applies to all subsequent captures
- FR14: Host can change the active facility between capture sessions
- FR15: System can store facility credentials and defaults encrypted on-device using hardware-backed keystore

**Guest Queue & Batch Workflow**

- FR16: System can maintain a local queue of captured guests associated with the active facility
- FR17: Host can view all guests in the current queue
- FR18: Host can submit all ready guests in a single batch action
- FR19: Host can submit an individual guest from the queue
- FR20: System can track each guest's status through a defined state lifecycle (captured → confirmed → ready → sending → sent / failed)
- FR21: Host can retry submission for failed guests
- FR22: System can automatically purge unsent queue items older than 7 days to prevent stale data accumulation

**eVisitor API Integration**

- FR23: System can authenticate with the eVisitor API using host credentials (ASP.NET Forms Authentication with cookie session)
- FR24: System can submit guest check-in data to eVisitor (CheckInTourist or ImportTourists endpoint)
- FR25: System can generate a unique GUID per guest submission and persist it locally for idempotency, future checkout, and cancellation
- FR26: System can detect session expiry or authentication failure and re-authenticate transparently
- FR27: System can parse eVisitor API error responses and present them as human-readable Croatian messages
- FR28: System can handle eVisitor API unavailability without losing queued guest data
- FR29: System can require BorderCrossing and PassageDate fields for non-EU guests before submission (conditional mandatory fields per eVisitor API rules)

**Submission History**

- FR30: Host can view a history of submitted guests for the past 30 days
- FR31: Host can see the submission status and timestamp for each historical entry
- FR32: System can automatically purge history entries older than 30 days

**Consent & Monetization**

- FR33: System can display ads within the app (AdMob integration)
- FR34: System can present a consent dialog for ad personalization compliant with EEA/UK requirements (UMP/CMP)
- FR35: Host can manage their ad consent preferences

**Onboarding**

- FR36: System can detect first launch and guide the host through initial facility profile setup before scanning

**Feedback & Error Communication**

- FR37: System can provide audible and/or haptic feedback on successful capture events
- FR38: System can display field-level validation errors in Croatian before submission
- FR39: System can warn the host when a duplicate guest scan is detected within 24 hours

**Total FRs: 39**

---

### Non-Functional Requirements

**Performance**

- NFR1a: MRZ capture-to-parsed-data display must complete within 3 seconds on mid-range Android devices (Snapdragon 600-series or equivalent, 2022+, release build)
- NFR1b: OCR fallback capture-to-parsed-data display must complete within 5 seconds on the same device class
- NFR2: Time-to-first-feedback after capture must be under 1 second
- NFR3: Guest queue list rendering must remain smooth with up to 50 guests in a single session
- NFR4: App cold start to camera-ready state must complete within 5 seconds on mid-range devices (release build)
- NFR5: Warm resume (app backgrounded → foregrounded) to camera-ready must complete within 2 seconds
- NFR6: eVisitor API submission per guest: client-side timeout of 15 seconds; retry available immediately on timeout
- NFR7: Review card field editing must have no perceptible input lag relative to system keyboard
- NFR8: App must remain responsive during background API submission — UI thread never blocked by network operations

**Security**

- NFR9: Facility credentials must be encrypted at rest using Android Keystore hardware-backed keys
- NFR10: Guest identity data stored locally must not be accessible to other apps (app-private storage)
- NFR11: Android Auto Backup must be disabled or scoped to exclude credential and guest data
- NFR12: eVisitor API communication must use HTTPS exclusively
- NFR13: Captured document images must not be persisted after data extraction
- NFR14: Local guest history must be automatically purged after 30 days (no manual recovery)
- NFR15: Credential entry fields must not allow system keyboard autocomplete/suggestions
- NFR16: Credential and guest identity screens must use FLAG_SECURE
- NFR17: App must comply with Google Play data safety declaration requirements
- NFR18: Observability must never capture MRZ data, document images, guest names, or credential values

**Integration**

- NFR19: eVisitor API session management must handle cookie expiry transparently (re-authenticate and replay)
- NFR20: eVisitor API failures must never result in loss of queued guest data
- NFR21: eVisitor API retry policy must use exponential backoff with jitter on 429/503/timeout responses
- NFR22: App must gracefully degrade when eVisitor API is unreachable — all capture, review, and queue functions remain operational offline
- NFR23: ML Kit text recognition must function without network connectivity (on-device bundled model)
- NFR24: AdMob integration must not block or delay core app functionality

**Reliability**

- NFR25: Crash-free session rate must be ≥ 99.5% (Firebase Crashlytics, trailing 28 days)
- NFR26: Guest state machine must be recoverable after process death
- NFR27: After crash or process death, app must restore session context (active facility, queue position)
- NFR28: Queue data must survive app updates without data loss
- NFR29: Duplicate submission prevention — must not submit same guest twice even after crash recovery or retry

**Total NFRs: 30 (NFR1a + NFR1b counted separately)**

---

### Additional Requirements & Constraints

**eVisitor API Specifics:**
- Auth: Cookie-based ASP.NET Forms Authentication; cookie persistence across process death required
- Required fields for check-in: facility code, StayFrom, ForeseenStayUntil, DocumentType, DocumentNumber, TouristName, TouristSurname, Gender, CountryOfBirth, CityOfBirth, DateOfBirth, Citizenship, CountryOfResidence, CityOfResidence, TTPaymentCategory, ArrivalOrganisation, OfferedServiceType, GUID ID
- Non-EU conditional fields: BorderCrossing, PassageDate
- Date format: YYYYMMDD; field length limits enforced (doc number ≤16, name ≤64)
- Max stay: 90 days

**Technical Constraints:**
- Android-only (Flutter), min API 24+, target API 35
- Mock eVisitor backend (Fastify + TypeScript) for CI/integration tests
- Patrol for E2E tests on headless Android emulator
- No real eVisitor API calls in CI

**Regulatory Constraints:**
- GDPR: on-device only, 30-day retention, document images discarded post-extraction
- Play Store: UMP/CMP required for EEA ad consent; data safety form required
- Privacy policy required disclosing: camera, local data, credentials, ad SDK

**Scope Boundaries (explicit out-of-scope for v1):**
- iOS support
- Tablet optimization
- Guest self-check-in flows
- Cloud sync
- Gallery import
- CheckOutTourist (post-MVP)
- BiometricPrompt for credentials
- Background retry (nice-to-have, deferrable)

---

### PRD Completeness Assessment

The PRD is thorough and well-structured. Key strengths:
- 39 FRs with clear grouping by capability domain
- 30 NFRs with measurable targets (timings, thresholds, rates)
- 4 detailed user journeys covering happy path, edge cases, onboarding, and multi-facility
- Explicit scoping with must-have vs. deferrable list
- eVisitor API fields and constraints precisely documented
- Testing strategy defined to 4 tiers with CI pipeline specifics

One area to monitor during epic coverage validation: FR8 (adding arrival/departure dates and facility assignment) spans both capture and queue workflows — ensure epics don't fragment its coverage. FR29 (non-EU conditional fields) is a non-trivial validation branch that needs explicit story coverage.

---

## Epic Coverage Validation

### Coverage Matrix

| FR | PRD Requirement (summary) | Epic | Story | Status |
|----|--------------------------|------|-------|--------|
| FR1 | Camera document capture | Epic 4 | Story 4.1 | ✓ Covered |
| FR2 | MRZ extraction + checksum (TD1/TD2/TD3) | Epic 4 | Story 4.2 | ✓ Covered |
| FR3 | OCR fallback when MRZ fails/absent | Epic 4 | Story 4.3 | ✓ Covered |
| FR4 | Manual entry/correction of all fields | Epic 4 | Story 4.3 + 4.4 | ✓ Covered |
| FR5 | Capture tier metadata (MRZ/OCR/manual) | Epic 4 | Story 4.2 + 4.3 | ✓ Covered |
| FR6 | Read-only review card | Epic 4 | Story 4.4 | ✓ Covered |
| FR7 | Switch review card to editable mode | Epic 4 | Story 4.4 | ✓ Covered |
| FR8 | Add non-document fields (dates, facility) | Epic 4 | Story 4.4 | ✓ Covered |
| FR9 | Client-side field validation vs eVisitor rules | Epic 4 | Story 4.4 | ✓ Covered |
| FR10 | Delete guest from queue before submission | Epic 5 | Story 5.2 | ✓ Covered |
| FR11 | Add facility profile + credentials + defaults | Epic 3 | Story 3.1 + 3.4 | ✓ Covered |
| FR12 | Manage multiple facility profiles (edit, delete) | Epic 3 | Story 3.1 | ✓ Covered |
| FR13 | Session-scoped active facility selection | Epic 3 | Story 3.2 | ✓ Covered |
| FR14 | Change active facility between sessions | Epic 3 | Story 3.2 | ✓ Covered |
| FR15 | Encrypted on-device credential storage (Keystore) | Epic 3 | Story 3.1 | ✓ Covered |
| FR16 | Local queue with facility association | Epic 5 | Story 4.4 + 5.1 | ✓ Covered |
| FR17 | View all guests in queue | Epic 5 | Story 5.1 | ✓ Covered |
| FR18 | Batch submit all ready guests | Epic 6 | Story 6.2 | ✓ Covered |
| FR19 | Individual guest submit | Epic 6 | Story 6.2 | ✓ Covered |
| FR20 | Guest state lifecycle tracking | Epic 5 | Story 5.1 + 5.3 + 6.2 | ✓ Covered |
| FR21 | Retry failed guests | Epic 6 | Story 6.3 | ✓ Covered |
| FR22 | Auto-purge unsent queue items >7 days | Epic 5 | Story 5.3 | ✓ Covered |
| FR23 | eVisitor authentication (cookie session) | Epic 6 | Story 6.1 | ✓ Covered |
| FR24 | Guest check-in submission (CheckInTourist/ImportTourists) | Epic 6 | Story 6.2 | ✓ Covered |
| FR25 | GUID generation + local persistence | Epic 6 | Story 4.4 + 6.2 | ✓ Covered |
| FR26 | Session expiry detection + transparent re-auth | Epic 6 | Story 6.1 | ✓ Covered |
| FR27 | Croatian error mapping from eVisitor UserMessage | Epic 6 | Story 6.3 | ✓ Covered |
| FR28 | API unavailability resilience (no data loss) | Epic 6 | Story 6.4 | ✓ Covered |
| FR29 | Non-EU conditional fields (BorderCrossing, PassageDate) | Epic 6 | Story 4.4 + 6.2 | ✓ Covered |
| FR30 | 30-day submission history view | Epic 7 | Story 7.1 | ✓ Covered |
| FR31 | Status + timestamp per history entry | Epic 7 | Story 7.1 | ✓ Covered |
| FR32 | Auto-purge history entries >30 days | Epic 7 | Story 7.2 | ✓ Covered |
| FR33 | AdMob banner display | Epic 8 | Story 8.2 | ✓ Covered |
| FR34 | UMP/CMP consent dialog (EEA/UK) | Epic 8 | Story 8.1 | ✓ Covered |
| FR35 | Ad consent preference management | Epic 8 | Story 8.1 | ✓ Covered |
| FR36 | First-launch onboarding to facility setup | Epic 3 | Story 3.3 | ✓ Covered |
| FR37 | Audio/haptic feedback on capture success | Epic 4 | Story 4.1 | ✓ Covered |
| FR38 | Croatian field-level validation errors | Epic 4 | Story 4.4 | ✓ Covered |
| FR39 | Duplicate scan warning (24h window) | Epic 5 | Story 5.2 | ✓ Covered |

### Missing Requirements

**None.** All 39 PRD Functional Requirements have explicit story-level coverage in the epics document.

### Coverage Statistics

- **Total PRD FRs:** 39
- **FRs covered in epics:** 39
- **Coverage percentage: 100%**

**Notable observations:**
- FR8 is correctly covered in Story 4.4 (review card handles both dates and facility assignment)
- FR29 (non-EU fields) is split across Story 4.4 (progressive disclosure UI) and Story 6.2 (payload inclusion) — appropriate split
- FR25 (GUID) is also split across Story 4.4 (generate on confirm) and Story 6.2 (include in submission) — correct
- Epic 1 and Epic 2 explicitly cover no FRs directly (infrastructure + quality) — intentional and correct design

---

## UX Alignment Assessment

### UX Document Status

**Found:** `_bmad-output/planning-artifacts/ux-design-specification.md` (42K, authored 2026-04-14)

The UX spec is comprehensive and mature — covering design system, all 4 user journey flows, 6 custom components, emotional design principles, accessibility strategy, form patterns, navigation patterns, and a responsive design strategy. All 20 UX-DR requirements are defined and traced into epics.

### UX ↔ PRD Alignment

| PRD Element | UX Coverage | Status |
|-------------|-------------|--------|
| Journey 1 (MRZ happy path) | Journey 1 flowchart + Component roadmap Phase 1 | ✓ Aligned |
| Journey 2 (OCR + error handling) | Journey 2 flowchart + EVisitorMessagePanel | ✓ Aligned |
| Journey 3 (first-time setup) | Journey 3 flowchart + Phase 3 onboarding | ✓ Aligned |
| Journey 4 (multi-facility) | Journey 4 flowchart + FacilitySessionBar design | ✓ Aligned |
| Scan-to-confirmed ≤10s target | "Door-speed default" principle + MRZ single-digit seconds bar | ✓ Aligned |
| Session-scoped facility (poka-yoke) | Explicitly called "neutral app" + FacilitySessionBar always-visible | ✓ Aligned |
| Croatian error mapping (FR27/FR38) | Croatian-first principle + EVisitorMessagePanel + ARB forms | ✓ Aligned |
| FLAG_SECURE (NFR16) | Credential + PII screens hardened, UX notes TalkBack+contrast still required | ✓ Aligned |
| Ads: never during capture/review/send (NFR24) | Compliance chrome never hijacks capture — design principle | ✓ Aligned |
| 30-day history purge | Empty history explains "30-day retention + privacy in one line" | ✓ Aligned |
| Duplicate scan warning (soft, not hard block) | Documented in anti-patterns-to-avoid section | ✓ Aligned |

**UX requirements in PRD but not in UX spec:** None. All PRD FRs with UX implications have corresponding UX treatment.

**UX requirements noted in UX spec but not explicitly in PRD FRs:**
- UX adds "Back: predictive back friendly; camera and review on stack" — implementation guidance not in PRD, but consistent with Android 14+ `enableOnBackInvokedCallback` mentioned in Story 1.5
- UX adds "Foldables: continuity — queue state survives fold/unfold" — not in PRD, but consistent with NFR26/27 process-death recovery

### UX ↔ Architecture Alignment

| Architecture Decision | UX Requirement | Status |
|----------------------|----------------|--------|
| Drift 7-state machine (captured/confirmed/ready/sending/sent/failed/pausedAuth) | AppQueueTheme ThemeExtension with 6 semantic tokens (queued/sending/failed-retryable/failed-terminal/paused-auth/sent) | ✓ Aligned — "queued" covers both captured+confirmed+ready pre-send states |
| go_router shell + route guard | Bottom NavigationBar + onboarding redirect | ✓ Aligned |
| Result<T, Failure> sealed class | UX failure surfaces per failure type (NetworkFailure → banner, AuthFailure → modal, ApiFailure → EVisitorMessagePanel) | ✓ Aligned |
| PersistCookieJar (process-death safe) | "Queue as explicit contract — paused-auth predictable; after re-auth, clear which items need resend" | ✓ Aligned |
| Exponential backoff 1s/2s/4s max 3 attempts | Per-row retry UX (no infinite retry loop in UX spec) | ✓ Aligned |
| CameraX + ML Kit on-device | DocumentCameraView states: permission-denied/initializing/ready/capturing/processing | ✓ Aligned |
| connectivity_plus package | ConnectivityBanner widget + "offline = safe to close" principle | ✓ Aligned |
| AdMob + AD_ENABLED dev flavor flag | Ads disabled in dev; neutral containers never on capture/review/send | ✓ Aligned |

### Warnings

1. **Minor: UX spec authored before architecture finalisation** — UX was dated 2026-04-14; architecture was last edited 2026-04-17. The UX spec does NOT list `architecture.md` as an input document. However, all architecture-driven UX requirements were successfully re-integrated into the epics (20 UX-DRs), and no UX ↔ architecture conflicts were identified. Risk: **Low**.

2. **Minor: UX component roadmap phase ordering differs from epic sequence** — UX Phase 3 ("onboarding + history + monetization") is listed after Phase 2 ("send + failure"), but epics sequence Epic 3 (facility/onboarding) *before* Epic 4 (capture). This is a known and intentional design choice in epics (facility profiles must exist before capture). Risk: **Low** — no implementation conflict.

3. **Note: 7-state machine vs 6 UX tokens** — Drift uses 7 states (`captured`, `confirmed`, `ready`, `sending`, `sent`, `failed`, `pausedAuth`). UX AppQueueTheme has 6 tokens (queued, sending, failed-retryable, failed-terminal, paused-auth, sent). The three pre-send states (captured/confirmed/ready) all map to "queued" visually — this is the correct design, as the host doesn't need to distinguish these internally. Story 1.3 and UX-DR2 confirm the `isTerminalFailure` flag drives the failed-retryable vs failed-terminal token split. Risk: **None**.

---

## Epic Quality Review

Beginning **Epic Quality Review** against create-epics-and-stories standards. Validating user value, independence, story dependencies, acceptance criteria quality, and implementation readiness.

---

### Best Practices Compliance by Epic

#### Epic 1: Project Foundation & App Shell

| Check | Result |
|-------|--------|
| Epic delivers user value | ⚠️ Partial — Stories 1.3-1.5 deliver a runnable themed shell with navigation; Stories 1.1-1.2 are pure developer infrastructure |
| Epic can function independently | ✓ First epic — no dependencies |
| Stories appropriately sized | ✓ Each story delivers a discrete, verifiable outcome |
| No forward dependencies | ✓ Each story builds on prior only |
| Database tables created when needed | ⚠️ See Major Issue #1 below |
| Clear acceptance criteria | ✓ All GWT format with specific commands and file paths |
| FR traceability | ✓ NFR4/10/11/12 explicit; infrastructure enabling all FRs |

**Observation:** Epic 1 title is technical-sounding but is acceptable for a greenfield project. The progression from Story 1.1→1.5 ends with a user-visible runnable app shell, which is legitimate user value for an MVP baseline.

---

#### Epic 2: Test Infrastructure & Deployment Quality

| Check | Result |
|-------|--------|
| Epic delivers user value | 🔴 No direct user value — CI pipeline, test containers, QA reports, AI log |
| Epic can function independently | 🔴 Story 2.3 explicitly requires Epics 3–7 complete before it can start |
| Stories appropriately sized | ✓ Each story is well scoped |
| No forward dependencies | 🔴 Story 2.3 forward-depends on Epics 3-7; Stories 2.4-2.6 depend on all feature epics |
| Database tables created when needed | N/A |
| Clear acceptance criteria | ✓ Docker compose commands, test counts, artifact paths all specific |
| FR traceability | ✓ Enables quality of all FRs (no direct FR coverage is expected and documented) |

**See Critical Issues #1 and #2 below.**

---

#### Epic 3: Facility Management & Onboarding

| Check | Result |
|-------|--------|
| Epic delivers user value | ✓ Host can add/manage facilities and get onboarded — clear capability gate |
| Epic can function independently | ✓ Depends on Epic 1 only |
| Stories appropriately sized | ✓ 4 stories, each delivering a distinct user capability |
| No forward dependencies | ✓ 3.1→3.2→3.3→3.4 are cleanly sequential by necessity |
| Database tables created when needed | ✓ Story 3.1 uses `facilities` and `credentials` tables (defined in Story 1.2) |
| Clear acceptance criteria | ✓ Well structured; FLAG_SECURE and keyboard autocomplete explicitly verified |
| FR traceability | ✓ FR11-15, FR36 all covered |

**Good:** Story 3.2's "even single facility shows picker" AC explicitly addresses the poka-yoke rationale. Story 3.4's progressive disclosure for defaults is correctly deferred to a separate story.

---

#### Epic 4: Document Capture & Guest Review

| Check | Result |
|-------|--------|
| Epic delivers user value | ✓ Core value proposition of the app |
| Epic can function independently | ✓ Depends on Epics 1 + 3 only |
| Stories appropriately sized | ✓ Clear separation: camera (4.1) → MRZ (4.2) → OCR (4.3) → review+queue (4.4) |
| No forward dependencies | ✓ Sequential but each story builds on completed prior |
| Database tables created when needed | ✓ Story 4.4 uses `guests` and `scan_sessions` (both defined in Story 1.2) |
| Clear acceptance criteria | ✓ NFR timings explicitly verified in ACs |
| FR traceability | ✓ FR1-9, FR37, FR38 all covered |

**See Minor Issue #3 below (Story 4.2 typo).**

---

#### Epic 5: Guest Queue & Local Workflow

| Check | Result |
|-------|--------|
| Epic delivers user value | ✓ Queue management is central host workflow |
| Epic can function independently | ✓ Depends on Epics 1 + 3 + 4 only |
| Stories appropriately sized | ✓ 3 stories covering view, manage, and durability |
| No forward dependencies | ✓ Clean — all dependencies are backward |
| Database tables created when needed | ✓ Uses `guests` table from Story 1.2 |
| Clear acceptance criteria | ✓ Drift stream reactivity, state recovery, purge timing all specific |
| FR traceability | ✓ FR10, FR16-17, FR20, FR22, FR39 all covered |

**Good:** Story 5.3 correctly addresses both data survival AND session context restore (NFR26 vs NFR27 distinction). The 7-day stale purge trigger ("on app launch, not continuous background process") is a good pragmatic choice.

---

#### Epic 6: eVisitor Submission & Error Handling

| Check | Result |
|-------|--------|
| Epic delivers user value | ✓ Core legal obligation — registers guests in eVisitor |
| Epic can function independently | ✓ Depends on Epics 1, 3, 4, 5 only |
| Stories appropriately sized | ✓ 4 stories: auth (6.1), submission+payload (6.2), error mapping (6.3), batch UI (6.4) |
| No forward dependencies | ✓ 6.1→6.2→6.3→6.4 are sequential and clean |
| Database tables created when needed | ✓ Uses existing `guests` + `credentials` tables |
| Clear acceptance criteria | ✓ Retry backoff values explicit (1s/2s/4s + 0-500ms jitter) |
| FR traceability | ✓ FR18-19, FR21, FR23-29 all covered |

**Good:** `isTerminalFailure` split (400/404 → terminal vs 429/503/timeout → retryable) is clearly defined in Story 6.2 and consistently used in Story 6.3 retry logic. GUID duplicate prevention (NFR29) explicitly handled in Story 6.2 AC.

---

#### Epic 7: Submission History

| Check | Result |
|-------|--------|
| Epic delivers user value | ✓ Proof-of-submission = compliance confidence |
| Epic can function independently | ✓ Depends on Epic 6 for data |
| Stories appropriately sized | ✓ 2 stories: view (7.1) and purge (7.2) — correct separation |
| No forward dependencies | ✓ Clean |
| Database tables created when needed | ✓ Uses existing `guests` table |
| Clear acceptance criteria | ✓ UTC-normalized clock handling for purge explicitly addressed |
| FR traceability | ✓ FR30-32 all covered |

**Good:** Story 7.2 addresses the "extreme clock manipulation" edge case and explicitly scopes responsibility ("documented, not defended against").

---

#### Epic 8: Ads & Consent Management

| Check | Result |
|-------|--------|
| Epic delivers user value | ✓ Consent management is user-facing; ads enable free app for hosts |
| Epic can function independently | ✓ Depends on Epic 1 (flavor config + AD_ENABLED flag) |
| Stories appropriately sized | ✓ 2 stories: consent (8.1) and ad display (8.2) |
| No forward dependencies | ✓ Clean — consent flows don't reference future features |
| Database tables created when needed | N/A — no DB changes |
| Clear acceptance criteria | ✓ "Ad collapses gracefully on failure" and "no interstitials" explicitly verified |
| FR traceability | ✓ FR33-35 all covered |

---

### 🔴 Critical Violations

**Critical Issue #1: Epic 2 is a technical milestone with no user value**
- Epic 2 title: "Test Infrastructure & Deployment Quality"
- All stories (2.1-2.6) are developer and QA tools: Docker compose pipeline, GitHub Actions CI, Patrol test suite, coverage reports, accessibility report, AI integration log
- No user-facing capability is delivered
- **Context/Rationale:** This is a training course deliverable epic — the Patrol E2E minimum 5 tests and AI Integration Log are explicit project requirements. Epic 2 exists to satisfy training deliverables, not user stories. As a result, the "user value" standard does not cleanly apply.
- **Recommendation:** Accept as-is given course requirements, but document that Epic 2 is an "engineering quality epic" explicitly exempted from the user-value standard in the epics document. The current description already hints at this — make it explicit.

**Critical Issue #2: Epic 2 has documented forward dependencies on Epics 3–7**
- Story 2.3 (Patrol E2E) explicitly states: "Start when: After 2.1 + Epics 3–7 complete, **before Epic 8**"
- Stories 2.4-2.6 (QA reports, AI log) also require all feature epics complete
- This breaks epic independence — Epic 2 cannot be completed without future epics
- **Context/Rationale:** This is an intentional architectural decision: end-to-end tests must test completed features. The execution sequencing table in the epics document makes this fully explicit.
- **Impact:** Low — the forward dependency is documented and understood. It would only be a problem if a team tried to complete Epic 2 as a unit before starting other epics.
- **Recommendation:** Rename the sequencing note in epics to be explicit: "Epic 2 is a continuous quality epic, not sequentially completable." Consider splitting Story 2.1+2.2 (pipeline setup, can be done after Epic 1) from Stories 2.3-2.6 (require feature completion). The current execution sequencing table already captures this intent.

---

### 🟠 Major Issues

**Major Issue #1: Database schema created upfront in Story 1.2 (all 4 tables)**
- Story 1.2 creates ALL 4 tables (`facilities`, `credentials`, `guests`, `scan_sessions`) in Epic 1
- Best practice: each story creates the tables it needs
- **Rationale for current approach:** Drift requires all database table definitions to coexist in a single `@DriftDatabase` class. Foreign key relationships (guests → facilities → credentials, scan_sessions → facilities) mean the tables cannot be defined independently without Drift schema migrations for every epic addition. On a greenfield 6-week project, having migrations from Epic 3 → Epic 4 → Epic 5 would add fragility without benefit.
- **Assessment:** Acceptable deviation — Drift's architectural constraint makes upfront schema definition the pragmatic choice. The story correctly creates all tables as an explicit decision, not an oversight.
- **Recommendation:** No change needed, but add a one-sentence rationale to Story 1.2's technical notes explaining this is a Drift-specific decision.

---

### 🟡 Minor Concerns

**Minor Issue #1: Story 4.2 contains a wrong story number reference in AC**
- Story 4.2 AC: "Given MRZ checksum fails... Then the system proceeds to OCR fallback (Story 3.3)"
- Story 3.3 is the onboarding flow. OCR fallback is Story 4.3.
- **Impact:** Could confuse a developer implementing Story 4.2 who looks up "Story 3.3" and finds onboarding logic
- **Recommendation:** Fix reference: "proceeds to OCR fallback (Story 4.3)"

**Minor Issue #2: Epic 1 and Epic 2 titles are technical-sounding**
- "Project Foundation & App Shell" and "Test Infrastructure & Deployment Quality" read as technical milestones, not user capabilities
- This is acceptable for a greenfield project and an explicit quality/training epic respectively
- **Recommendation:** No change needed — context makes intent clear

**Minor Issue #3: Story 1.3 AC forward reference**
- Story 1.3 AC: "Given Stories 1.4–1.5 are not yet implemented When the app runs Then the root remains a minimal placeholder"
- This is a future-context note, not a forward dependency. Story 1.3 can be completed standalone.
- **Assessment:** Acceptable documentation note, not a violation.

---

### Best Practices Compliance Summary

| Epic | User Value | Independence | Story Quality | ACs | Verdict |
|------|-----------|--------------|---------------|-----|---------|
| Epic 1 | ⚠️ Partial (infra → runnable shell) | ✓ | ✓ | ✓ | Accept |
| Epic 2 | 🔴 Technical milestone | 🔴 Forward deps on 3-7 | ✓ | ✓ | Accept with note |
| Epic 3 | ✓ | ✓ | ✓ | ✓ | **Ready** |
| Epic 4 | ✓ | ✓ | ✓ | ⚠️ Story 4.2 typo | Fix typo |
| Epic 5 | ✓ | ✓ | ✓ | ✓ | **Ready** |
| Epic 6 | ✓ | ✓ | ✓ | ✓ | **Ready** |
| Epic 7 | ✓ | ✓ | ✓ | ✓ | **Ready** |
| Epic 8 | ✓ | ✓ | ✓ | ✓ | **Ready** |

---

## Summary and Recommendations

### Overall Readiness Status

## ✅ READY — with 1 minor fix required before development starts

The Prijavko planning artifacts are implementation-ready. The PRD, Architecture, UX, and Epics form a coherent, well-traced specification. All requirements are covered, all journeys are mapped to stories, and all dependencies are understood. The one fix required (Story 4.2 AC typo) is trivial.

---

### Issues by Category

| # | Severity | Issue | Action Required |
|---|----------|-------|-----------------|
| 1 | 🔴 Critical (Intentional) | Epic 2 has no direct user value — it is a training deliverable epic | **Accept as-is.** Add explicit "engineering quality epic" note to Epic 2 description. |
| 2 | 🔴 Critical (Intentional) | Epic 2 Stories 2.3–2.6 forward-depend on Epics 3–7 completion | **Accept as-is.** Already documented in execution sequencing table. No change needed. |
| 3 | 🟠 Major (Intentional) | All 4 DB tables created upfront in Story 1.2 rather than per-feature | **Accept as-is.** Required by Drift FK constraints. Add one-sentence rationale to Story 1.2 technical notes. |
| 4 | 🟡 Minor | Story 4.2 AC references "Story 3.3" instead of "Story 4.3" for OCR fallback | **Fix before starting Epic 4.** Single-line correction in epics.md. |
| 5 | 🟡 Minor (Informational) | UX spec authored before architecture finalisation (2026-04-14 vs 2026-04-17) | **No action.** UX-DRs successfully re-integrated into epics. No conflicts found. |
| 6 | 🟡 Minor (Informational) | UX component roadmap phase order differs from epic execution order | **No action.** Epics sequence is correct; UX roadmap is guidance only. |

**Total: 6 issues — 2 critical (intentional, accepted), 1 major (intentional, accepted), 1 actionable minor fix, 2 informational**

---

### Critical Issues Requiring Immediate Action

**Only one issue requires action before development starts:**

**Fix Story 4.2 AC typo** — In `epics.md`, Story 4.2, the Acceptance Criterion that reads "the system proceeds to OCR fallback (Story 3.3)" must be corrected to "(Story 4.3)". A developer starting Epic 4 who looks up Story 3.3 will find the onboarding flow, not OCR logic.

---

### Recommended Next Steps

1. **Fix Story 4.2 AC reference** — Edit `_bmad-output/planning-artifacts/epics.md`, find "Story 3.3" in Story 4.2's acceptance criteria, change to "Story 4.3". Takes 2 minutes.

2. **Add rationale note to Story 1.2** — Add one sentence to Story 1.2 technical notes explaining that all 4 Drift tables are defined upfront due to FK constraints, not as a design choice. Prevents future confusion in code review.

3. **Add "engineering quality epic" label to Epic 2** — One sentence in the Epic 2 overview acknowledging that this epic serves training deliverables (Patrol E2E, AI Integration Log) and is intentionally exempt from the user-value standard.

4. **Proceed to implementation** — Start with Epic 1, Story 1.1 (flutter create) and Story 1.6 (mock eVisitor server) in parallel as specified.

---

### Positive Findings

The following aspects of the planning artifacts are notably strong and should be preserved through implementation:

- **39/39 FR coverage at story level** — every requirement has a named story
- **isTerminalFailure flag design** — consistently carried through Stories 6.2 and 6.3, ensuring retryable vs terminal failure UX is unambiguous
- **Non-EU conditional fields (FR29)** — explicitly handled in both Story 4.4 (UI progressive disclosure) and Story 6.2 (payload inclusion), covering both the UX and API dimensions
- **Process-death recovery split** — NFR26 (state machine recovery) and NFR27 (session context continuity) are correctly differentiated in Story 5.3
- **Mock eVisitor server scoped to CI/local only** — Story 1.6 is clear that the mock never ships in the app binary, eliminating a common test-code-in-prod risk
- **7-day queue stale purge + 30-day history purge** — both purges trigger on app launch (not background process), avoiding Android background execution complexity

---

### Final Note

This assessment identified **6 issues** across **3 categories** (structural/intentional × 2, Drift architectural trade-off × 1, documentation × 1, informational × 2). The two "critical" findings are intentional design decisions for a training course context, not planning failures. The single actionable fix (Story 4.2 reference typo) takes minutes to resolve.

**The project is ready to begin implementation.** The artifacts are coherent, traceable, and sufficiently detailed for a solo developer to execute without ambiguity.

---

**Assessment completed:** 2026-04-17
**Assessor:** Implementation Readiness Validator (BMAD)
**Report file:** `_bmad-output/planning-artifacts/implementation-readiness-report-2026-04-17.md`

