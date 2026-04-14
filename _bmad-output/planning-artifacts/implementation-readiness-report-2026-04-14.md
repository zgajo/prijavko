---
workflow: bmad-check-implementation-readiness
assessmentDate: "2026-04-14"
assessor: "BMAD implementation-readiness workflow (automated run)"
artifactsAssessed:
  prd: "_bmad-output/planning-artifacts/prd.md"
  architecture: "_bmad-output/planning-artifacts/architecture.md"
  epics: "_bmad-output/planning-artifacts/epics.md"
  ux: "_bmad-output/planning-artifacts/ux-design-specification.md"
stepsCompleted:
  - step-01-document-discovery
  - step-02-prd-analysis
  - step-03-epic-coverage-validation
  - step-04-ux-alignment
  - step-05-epic-quality-review
  - step-06-final-assessment
---

# Implementation Readiness Assessment Report

**Date:** 2026-04-14
**Project:** prijavko

---

## Step 1: Document Discovery

Beginning **Document Discovery** to inventory all project files under `_bmad-output/planning-artifacts/`.

### PRD Documents

**Whole Documents:**

- `prd.md` (37,390 bytes, modified 2026-04-14 14:03)

**Sharded Documents:** none (`*prd*/index.md` not present)

### Architecture Documents

**Whole Documents:**

- `architecture.md` (59,512 bytes, modified 2026-04-14 14:03)

**Sharded Documents:** none

### Epics & Stories Documents

**Whole Documents:**

- `epics.md` (61,436 bytes, modified 2026-04-14 15:04)

**Sharded Documents:** none

### UX Design Documents

**Whole Documents:**

- `ux-design-specification.md` (42,816 bytes, modified 2026-04-14 13:48)
- `ux-design-directions.html` (17,689 bytes, modified 2026-04-14 13:48) — supplementary HTML artifact alongside the MD spec

**Sharded Documents:** none

### Critical issues

- **Duplicates (whole vs sharded):** none — no competing `index.md` trees for PRD, architecture, epics, or UX.
- **Missing required types:** none for PRD, Architecture, Epics (whole), UX (whole).

### Additional artifacts in `planning-artifacts/` (not part of the four core patterns)

- `product-brief-prijavko.md`
- `product-brief-prijavko-distillate.md`
- `research/market-mobile-evisitor-guest-check-in-hr-research-2026-04-13.md`
- `research/technical-android-evisitor-mrz-queue-evisitor-api-research-2026-04-13.md`

---

## PRD Analysis

Source: `prd.md` — Functional Requirements, Non-Functional Requirements, and related constraints (read completely for this step).

### Functional Requirements

**Total FRs: 39** — verbatim requirement statements from the PRD:

- **FR1:** Host can capture a guest's identity document using the device camera
- **FR2:** System can extract guest data from the MRZ zone of a captured document with checksum validation (TD1, TD2, TD3 formats)
- **FR3:** System can fall back to OCR text extraction when MRZ parsing fails or MRZ is absent
- **FR4:** Host can manually enter or correct all guest data fields when automated extraction is insufficient
- **FR5:** System can determine the capture method used (MRZ, OCR, manual) and carry it as metadata
- **FR6:** Host can review extracted guest data on a read-only confirmation card before submission
- **FR7:** Host can switch a review card to editable mode to correct any field
- **FR8:** Host can add data not extractable from documents (e.g., arrival date, departure date, facility assignment)
- **FR9:** System can validate guest data against eVisitor field requirements before allowing submission
- **FR10:** Host can delete a guest from the queue before submission
- **FR11:** Host can add a facility profile with credentials (eVisitor username, password, facility ID) and per-facility defaults (TTPaymentCategory, ArrivalOrganisation, OfferedServiceType, default stay duration)
- **FR12:** Host can manage multiple facility profiles (edit, delete)
- **FR13:** Host can select a session-scoped active facility that applies to all subsequent captures
- **FR14:** Host can change the active facility between capture sessions
- **FR15:** System can store facility credentials and defaults encrypted on-device using hardware-backed keystore
- **FR16:** System can maintain a local queue of captured guests associated with the active facility
- **FR17:** Host can view all guests in the current queue
- **FR18:** Host can submit all ready guests in a single batch action
- **FR19:** Host can submit an individual guest from the queue
- **FR20:** System can track each guest's status through a defined state lifecycle (captured → confirmed → ready → sending → sent / failed)
- **FR21:** Host can retry submission for failed guests
- **FR22:** System can automatically purge unsent queue items older than 7 days to prevent stale data accumulation
- **FR23:** System can authenticate with the eVisitor API using host credentials (ASP.NET Forms Authentication with cookie session)
- **FR24:** System can submit guest check-in data to eVisitor (CheckInTourist or ImportTourists endpoint)
- **FR25:** System can generate a unique GUID per guest submission and persist it locally for idempotency, future checkout, and cancellation
- **FR26:** System can detect session expiry or authentication failure and re-authenticate transparently
- **FR27:** System can parse eVisitor API error responses and present them as human-readable Croatian messages
- **FR28:** System can handle eVisitor API unavailability without losing queued guest data
- **FR29:** System can require BorderCrossing and PassageDate fields for non-EU guests before submission (conditional mandatory fields per eVisitor API rules)
- **FR30:** Host can view a history of submitted guests for the past 30 days
- **FR31:** Host can see the submission status and timestamp for each historical entry
- **FR32:** System can automatically purge history entries older than 30 days
- **FR33:** System can display ads within the app (AdMob integration)
- **FR34:** System can present a consent dialog for ad personalization compliant with EEA/UK requirements (UMP/CMP)
- **FR35:** Host can manage their ad consent preferences
- **FR36:** System can detect first launch and guide the host through initial facility profile setup before scanning
- **FR37:** System can provide audible and/or haptic feedback on successful capture events
- **FR38:** System can display field-level validation errors in Croatian before submission
- **FR39:** System can warn the host when a duplicate guest scan is detected within 24 hours

### Non-Functional Requirements

**Total NFRs: 31** (NFR1 split into NFR1a and NFR1b per PRD) — verbatim:

**Performance**

- **NFR1a:** MRZ capture-to-parsed-data display must complete within 3 seconds on mid-range Android devices (Snapdragon 600-series or equivalent, 2022+, release build)
- **NFR1b:** OCR fallback capture-to-parsed-data display must complete within 5 seconds on the same device class
- **NFR2:** Time-to-first-feedback after capture (e.g., "Reading document…") must be under 1 second — perceived progress reduces wait anxiety
- **NFR3:** Guest queue list rendering must remain smooth (no sustained jank) with up to 50 guests in a single session
- **NFR4:** App cold start to camera-ready state must complete within 5 seconds on mid-range devices (release build, subsequent launches — first install may be slower)
- **NFR5:** Warm resume (app backgrounded → foregrounded) to camera-ready must complete within 2 seconds
- **NFR6:** eVisitor API submission per guest: client-side timeout of 15 seconds; user-visible progress indicator during submission; retry available immediately on timeout
- **NFR7:** Review card field editing must have no perceptible input lag relative to system keyboard
- **NFR8:** App must remain responsive during background API submission — UI thread never blocked by network operations

**Security**

- **NFR9:** Facility credentials must be encrypted at rest using Android Keystore hardware-backed keys
- **NFR10:** Guest identity data stored locally must not be accessible to other apps (app-private storage, no external storage)
- **NFR11:** Android Auto Backup must be disabled or scoped to exclude credential and guest data — no restoration of sensitive data to another device
- **NFR12:** eVisitor API communication must use HTTPS exclusively — no fallback to HTTP
- **NFR13:** Captured document images must not be persisted after data extraction — only extracted text fields are stored
- **NFR14:** Local guest history must be automatically purged after 30 days (device-local clock, UTC-normalized) with no manual recovery possible
- **NFR15:** Credential entry fields must not allow system keyboard autocomplete/suggestions to prevent credential leakage
- **NFR16:** Credential and guest identity screens must use FLAG_SECURE to prevent capture in screenshots and recent app thumbnails
- **NFR17:** App must comply with Google Play data safety declaration requirements (no data shared with third parties except ad networks per consent)
- **NFR18:** Observability (Crashlytics, analytics) must never capture MRZ data, document images, guest names, or credential values in logs or crash reports — anonymized funnel events and crash stacks only

**Integration**

- **NFR19:** eVisitor API session management must handle cookie expiry (401, redirect-to-login, empty session) transparently — re-authenticate and replay failed request without user intervention or data loss
- **NFR20:** eVisitor API failures must never result in loss of queued guest data — queue persists through API errors, app crashes, and process death (SQLite/Drift with WAL)
- **NFR21:** eVisitor API retry policy must use exponential backoff with jitter on 429/503/timeout responses — no retry storms
- **NFR22:** App must gracefully degrade when eVisitor API is unreachable — all capture, review, and queue functions remain operational offline
- **NFR23:** ML Kit text recognition must function without network connectivity (on-device bundled model, no cloud API dependency)
- **NFR24:** AdMob integration must not block or delay core app functionality — ads load asynchronously, never interrupt capture or submission flows, and no full-screen interstitials during capture or submission sequences

**Reliability**

- **NFR25:** Crash-free session rate must be ≥ 99.5% as measured by Firebase Crashlytics over trailing 28 days (target applies after first public release stabilization)
- **NFR26:** Guest state machine must be recoverable after process death — no guest stuck in transient state (sending) after app restart; resume or roll back to last stable state
- **NFR27:** After crash or process death, app must restore the user's session context (active facility, queue position) — not just data survival but continuity of workflow
- **NFR28:** Queue data must survive app updates without data loss
- **NFR29:** Duplicate submission prevention — system must not submit the same guest twice to eVisitor even after crash recovery or retry (idempotency key or server-side dedup check)

### Additional Requirements & Constraints

- **eVisitor API constraints:** Cookie-based auth (ASP.NET Forms), XML payloads for batch, JSON wrapper, GUID required per submission since 2017-06-01
- **MRZ/ICAO constraints:** TD1 (3×30), TD2, TD3 (2×44) formats; fields NOT available from MRZ: city of birth, city of residence, residence address
- **eVisitor field limits:** Document number ≤ 16, name/surname ≤ 64, city of birth/residence ≤ 64
- **Duplicate detection key:** Same facility + DateOfBirth + DocumentType + DocumentNumber + CountryOfResidence + not checked out + not cancelled
- **Max stay:** 90 days (MUP constraint)
- **Platform:** Flutter (Dart), Android-only v1, min API 24+, target API 35
- **No permissions beyond:** Camera, Internet
- **Test environment:** `https://www.evisitor.hr/testApi` available
- **Revenue model:** Ad-supported, free, CMP/UMP required for EEA

### PRD Completeness Assessment

**Strengths:**
- Comprehensive and well-structured — all standard PRD sections present
- User journeys are excellent: 4 realistic scenarios covering happy path, edge cases, onboarding, and multi-facility
- FRs and NFRs are numbered, specific, and measurable
- Domain constraints thoroughly documented (eVisitor API surface, MRZ/ICAO, GDPR)
- Clear MVP vs post-MVP separation with rationale
- Risk mitigation table with likelihood/impact/mitigation triads
- Success criteria with measurable targets

**Observations:**
1. Camera guide overlay for document alignment is mentioned in "Implementation Considerations" but has no numbered FR — appears intentional (UX detail, not requirement)
2. Torch toggle listed as nice-to-have — consistent with scoping
3. The state machine lifecycle in FR20 lists 5 states (`captured → confirmed → ready → sending → sent / failed`) while Implementation Considerations lists 6 states (`captured → fields_confirmed → facility_assigned → ready → sending → sent / failed`). Minor naming inconsistency — architecture should resolve this
4. eVisitor API has two check-in paths (CheckInTourist JSON vs ImportTourists XML) — FR24 says "or" but architecture should specify which is primary for v1
5. No explicit FR for the camera guide overlay or capture UX (viewfinder) — these are implementation details, not functional requirements, so this is acceptable

**Verdict:** PRD is **solid and implementation-ready**. No blocking gaps. The minor state-machine naming difference between FR20 and the older "Implementation Considerations" bullet in the PRD should be treated as superseded by FR20; `epics.md` and `architecture.md` align with FR20 and extend with `pausedAuth` where needed.

---

## Epic Coverage Validation

Beginning **Epic Coverage Validation** against `epics.md` (whole document read; FR Coverage Map and epic headers used for traceability).

### Epic FR coverage extracted

Every PRD FR1–FR39 is listed in `epics.md` **FR Coverage Map** with a target epic:

| FR | Epic (from epics.md) | Coverage note |
|----|----------------------|---------------|
| FR1–FR9, FR37–FR38 | Epic 3 | Capture + review + validation |
| FR10, FR16–FR17, FR20, FR22, FR39 | Epic 4 | Queue, lifecycle, purge, duplicate warning |
| FR11–FR15, FR36 | Epic 2 | Facility + onboarding |
| FR18–FR19, FR21, FR23–FR29 | Epic 5 | Auth + submit + errors |
| FR30–FR32 | Epic 6 | History |
| FR33–FR35 | Epic 7 | Ads + consent |

**FRs in epics but not in PRD:** none — the epics document only lists FR1–FR39 from the PRD.

### FR coverage matrix (summary)

| FR | Epic | Status |
|----|------|--------|
| FR1–FR39 | See map above | Covered |

Full per-FR text is in **PRD Analysis** above; epic/story detail is in `epics.md`.

### Missing FR coverage

**Critical / high-priority gaps:** none — **39/39** FRs mapped.

### Coverage statistics

- **Total PRD FRs:** 39
- **FRs with at least one epic reference:** 39
- **Coverage percentage:** 100%

### NFR note (out of step 3 scope but useful)

`epics.md` also distributes **NFR1a–NFR29** across epics and stories with acceptance-criteria hooks — no separate “NFR coverage gap” analysis was required by step 3; spot-check shows performance, security, integration, and reliability NFRs referenced in story ACs.

---

## UX Alignment Assessment

### UX Document Status

✅ Found: `ux-design-specification.md` (624 lines, workflow complete through step 14)

### UX ↔ PRD Alignment

**Journey Coverage: ✅ All 4 PRD journeys fully mapped**

| PRD Journey | UX Coverage | Notes |
|---|---|---|
| Journey 1 (Peak arrivals, MRZ happy path) | ✅ Flowchart + screen mechanics | Facility anchor, queue rows, batch send all represented |
| Journey 2 (OCR fallback + eVisitor error) | ✅ Flowchart + degraded path design | Croatian error mapping, field focus, retry flow |
| Journey 3 (First-time setup) | ✅ Flowchart + onboarding design | Keystore credentials, consent, first round-trip |
| Journey 4 (Multi-facility Saturday) | ✅ Flowchart + neutral app design | Session reset, mixed-facility queue, batch across facilities |

**FR Coverage: ✅ All 39 FRs have corresponding UX surface**

- FR1–FR5 (Capture): `DocumentCameraView` component, tier badge, capture flow
- FR6–FR10 (Review): `GuestSubmissionSnapshotCard` with read-only/editable states, validation
- FR11–FR15 (Facility): `FacilitySessionBar`, `facility_picker_sheet`, credential entry
- FR16–FR22 (Queue): `QueueGuestRow`, batch send, state lifecycle in UI
- FR23–FR29 (eVisitor): Auth prompt dialog, Croatian error panel, re-auth surface
- FR30–FR32 (History): History screen with 30-day retention
- FR33–FR35 (Ads): Ad placement rules (non-blocking, no interstitials on capture/send)
- FR36 (Onboarding): First-launch flow
- FR37–FR39 (Feedback): Sound/haptic hooks, inline validation, duplicate warning

### UX ↔ Architecture Alignment

**Component Mapping: ✅ All 6 custom UX components have architecture file locations**

| UX Component | Architecture File | Status |
|---|---|---|
| `FacilitySessionBar` | `features/facility/presentation/widgets/facility_session_bar.dart` | ✅ Aligned |
| `DocumentCameraView` | `features/capture/presentation/widgets/document_camera_view.dart` | ✅ Aligned |
| `GuestSubmissionSnapshotCard` | `features/capture/presentation/widgets/guest_review_card.dart` | ⚠️ Name difference (see below) |
| `QueueGuestRow` | `features/queue/presentation/widgets/queue_guest_row.dart` | ✅ Aligned |
| `BatchSendSummary` | `features/queue/presentation/widgets/batch_send_summary.dart` | ✅ Aligned |
| `EVisitorMessagePanel` | `features/send/presentation/widgets/evisitor_message_panel.dart` | ✅ Aligned |

**Design System: ✅ Full agreement**
- Both specify Material 3 with `ColorScheme.fromSeed` (teal class)
- Both specify `ThemeExtension` for queue state semantics
- Both specify light + dark theme from same seed
- Both specify Croatian l10n as primary

**Navigation: ✅ Aligned**
- Both specify bottom navigation: Home, Queue, History, Settings
- Both use go_router with shell route
- Both support predictive back gesture

**Security UX: ✅ Aligned**
- FLAG_SECURE on credential and PII screens — both documents agree
- No autocomplete on credential fields — both documents agree
- No interstitial ads on capture/review/send — both documents agree

### Alignment Issues Found

**Issue 1 (Minor): Component naming inconsistency**
- UX calls it `GuestSubmissionSnapshotCard` (emphasizing "what will be sent")
- Architecture calls it `guest_review_card.dart` (emphasizing the action of reviewing)
- **Impact:** Low. Same widget, different name. Could cause confusion during implementation if devs read only one document.
- **Recommendation:** Pick one name. UX's "submission snapshot" language is more precise to the product intent — consider renaming the architecture file to `guest_submission_snapshot_card.dart`.

**Issue 2 (Resolved): `pausedAuth` in architecture and epics**
- UX defines `paused-auth` as a queue row / batch-summary state.
- `architecture.md` documents `guest_state.dart` as including **`pausedAuth`**, with transitions `sending → pausedAuth` and `pausedAuth → ready` in the state machine section.
- `epics.md` Story 1.2 acceptance criteria explicitly list `GuestState` values: `captured`, `confirmed`, `ready`, `sending`, `sent`, `failed`, **`pausedAuth`**.
- **Residual nit:** Executive summary prose in `architecture.md` still describes the lifecycle as `sent/failed` without naming `pausedAuth` in that one sentence — cosmetic consistency only.

**Issue 3 (Minor): Retryable vs terminal failure distinction**
- UX defines separate tokens for `failed-retryable` and `failed-terminal` states
- Architecture has a single `failed` state with `errorMessage`
- Architecture's retry policy distinguishes retryable (429/503/timeout) from non-retryable (400/404) but this distinction lives in code logic, not in the persisted state
- **Impact:** Low. Can be handled at presentation layer by inspecting error type from the `Failure` object. But UX expects visually distinct treatment.
- **Recommendation:** Either (a) add a `isTerminal` boolean on the `failed` state, or (b) document that the distinction is derived from the `Failure` type at UI render time. Option (b) is simpler and sufficient for v1.

**Issue 4 (Observation): State machine naming across documents**
- PRD FR20: `captured → confirmed → ready → sending → sent / failed`
- PRD Implementation Considerations: `captured → fields_confirmed → facility_assigned → ready → sending → sent / failed`
- Architecture state machine: `captured → confirmed → ready → sending → sent / failed` (matches FR20)
- UX display states: `queued / sending / failed / paused-auth / sent`
- **Impact:** None. Architecture correctly adopted FR20's naming. UX uses presentation-level labels (e.g., "queued" is the display name for any pre-sending state). PRD's Implementation Considerations section appears to be early brainstorming that was superseded by the FR20 definition.
- **Status:** Resolved by architecture — no action needed.

### Warnings

- None. UX document is comprehensive and well-aligned with both PRD and Architecture.

---

## Epic Quality Review

Beginning **Epic Quality Review** against `epics.md` and create-epics-and-stories expectations (user value, independence, dependencies, AC quality).

### Epic structure — user value

| Epic | Title | Assessment |
|------|-------|------------|
| 1 | Project Foundation & App Shell | Acceptable for **greenfield**: delivers runnable app shell + infra; Stories 1.1–1.2 are developer-role stories (explicit in ACs), Story 1.3 is host-facing navigation — not a pure "technical milestone" epic because outcome is a usable themed shell. |
| 2–7 | Facility → Capture → Queue → Send → History → Ads | All **user-outcome** oriented; no epics named as bare "API layer" or "DB only". |

### Epic independence

- **Ordering:** Epic 2+ assume Epic 1's codebase, DB, and router exist — **sequential dependency**, not a forward reference to unfinished later epics.
- **No Epic N → Epic N+1 reverse dependency** detected in epic descriptions.

### Story dependencies (spot-check)

- **Backward-only references:** Story 1.2 says "Given the project from Story 1.1"; Story 3.x references prior capture steps; no "depends on Story 5.x" patterns found in grep.
- **Within-epic order:** Logical (e.g., 3.1 camera → 3.2 MRZ → 3.3 OCR → 3.4 review/queue).

### Acceptance criteria quality

- Stories use **Given / When / Then** (BDD-style) with concrete checks (packages, tables, timeouts, NFR citations).
- Error and offline paths appear in Epic 4–5 stories (retry, backoff, persistence).

### Findings by severity

**Critical violations:** none (no technical-only epics with zero user-visible outcome; Epic 1 justified as foundation).

**Major issues:** none identified — database is introduced in Epic 1 Story 1.2 as foundation for all features; aligns with architecture's single-schema approach (acceptable trade for solo greenfield).

**Minor concerns:**

1. **Developer-facing stories in Epic 1** — Stories 1.1 and 1.2 use "As a developer"; acceptable if the team treats Epic 1 as explicit platform setup (matches architecture starter template).
2. **Widget filename vs UX label** — Same as UX Issue 1 (`guest_review_card.dart` vs `GuestSubmissionSnapshotCard`); fix by renaming file or documenting alias in architecture.
3. **Optional polish** — Torch toggle and duplicate-scan warning are scoped in PRD as nice-to-have / guardrail; stories still implement where listed — no conflict.

---

## Summary and Recommendations

### Overall Readiness Status

**READY —** PRD, Architecture, UX, and **Epics & Stories** are aligned for Phase 4 implementation. FR coverage is complete; epic/story structure meets quality bar with only minor naming/documentation nits.

### Critical Issues Requiring Immediate Action

**None.**

### Issues to Track (non-blocking)

| # | Severity | Issue | Recommended fix |
|---|----------|--------|-----------------|
| 1 | Minor | UX component name vs architecture file: `GuestSubmissionSnapshotCard` vs `guest_review_card.dart` | Rename file or add one-line cross-reference in architecture |
| 2 | Minor | UX retryable vs terminal failure | Already mitigated in `epics.md` via `isTerminalFailure` + ThemeExtension mapping — ensure implementation follows Story 1.2 / UX-DR2 |
| 3 | Cosmetic | Architecture intro sentence for queue lifecycle omits `pausedAuth` | Optional one-line edit in `architecture.md` summary for consistency |
| 4 | Cosmetic | Architecture doc NFR count wording (29 vs 31) | Align header text with PRD (31 NFR lines) if still present |

### Document quality scores (updated)

| Document | Notes | Grade |
|----------|--------|-------|
| **PRD** | 39 FRs, 31 NFRs; journeys and risks complete | **A** |
| **Architecture** | Matches PRD; `pausedAuth` in file map and transitions | **A** |
| **UX** | Full journey + component coverage | **A** |
| **Epics** | 100% FR map; BDD ACs; 7 epics, 2–4 stories each | **A** |

### Recommended next steps

1. **Start implementation** from Epic 1 Story 1.1 per sprint plan — artifacts are sufficient to drive dev without replanning FR coverage.
2. **Resolve widget filename** vs UX component name early in capture feature to avoid import drift.
3. Use **`bmad-help`** if you want the next BMAD skill suggestion after implementation kickoff.

### Final note

This run completed all six workflow steps. The assessment found **no critical gaps**; remaining items are **minor naming/documentation** only. You may proceed to implementation as-is.

---
