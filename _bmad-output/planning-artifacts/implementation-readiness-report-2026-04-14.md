# Implementation Readiness Assessment Report

**Date:** 2026-04-14
**Project:** prijavko

---

## Document Inventory

| Document Type | File | Status |
|---|---|---|
| PRD | `prd.md` | ✅ Found |
| Architecture | `architecture.md` | ✅ Found |
| UX Design | `ux-design-specification.md` | ✅ Found |
| Epics & Stories | — | ⏳ Not yet created |

**Supporting Documents:**
- `product-brief-prijavko.md`
- `product-brief-prijavko-distillate.md`
- `research/market-mobile-evisitor-guest-check-in-hr-research-2026-04-13.md`
- `research/technical-android-evisitor-mrz-queue-evisitor-api-research-2026-04-13.md`
- `ux-design-directions.html`

**Note:** Epics & Stories not yet created — this is a pre-epic validation run.

---

## PRD Analysis

### Functional Requirements (39 total)

**Document Capture & Recognition (FR1–FR5)**
- FR1: Host can capture a guest's identity document using the device camera
- FR2: System can extract guest data from the MRZ zone with checksum validation (TD1, TD2, TD3)
- FR3: System can fall back to OCR text extraction when MRZ parsing fails or MRZ is absent
- FR4: Host can manually enter or correct all guest data fields when automated extraction is insufficient
- FR5: System can determine the capture method used (MRZ, OCR, manual) and carry it as metadata

**Guest Data Review & Editing (FR6–FR10)**
- FR6: Host can review extracted guest data on a read-only confirmation card before submission
- FR7: Host can switch a review card to editable mode to correct any field
- FR8: Host can add data not extractable from documents (arrival date, departure date, facility assignment)
- FR9: System can validate guest data against eVisitor field requirements before allowing submission
- FR10: Host can delete a guest from the queue before submission

**Facility Management (FR11–FR15)**
- FR11: Host can add a facility profile with credentials and per-facility defaults (TTPaymentCategory, ArrivalOrganisation, OfferedServiceType, default stay duration)
- FR12: Host can manage multiple facility profiles (edit, delete)
- FR13: Host can select a session-scoped active facility that applies to all subsequent captures
- FR14: Host can change the active facility between capture sessions
- FR15: System can store facility credentials and defaults encrypted on-device using hardware-backed keystore

**Guest Queue & Batch Workflow (FR16–FR22)**
- FR16: System can maintain a local queue of captured guests associated with the active facility
- FR17: Host can view all guests in the current queue
- FR18: Host can submit all ready guests in a single batch action
- FR19: Host can submit an individual guest from the queue
- FR20: System can track each guest's status through a defined state lifecycle (captured → confirmed → ready → sending → sent / failed)
- FR21: Host can retry submission for failed guests
- FR22: System can automatically purge unsent queue items older than 7 days

**eVisitor API Integration (FR23–FR29)**
- FR23: System can authenticate with the eVisitor API using host credentials (ASP.NET Forms Auth with cookie session)
- FR24: System can submit guest check-in data to eVisitor (CheckInTourist or ImportTourists endpoint)
- FR25: System can generate a unique GUID per guest submission and persist it locally for idempotency/checkout/cancellation
- FR26: System can detect session expiry or authentication failure and re-authenticate transparently
- FR27: System can parse eVisitor API error responses and present them as human-readable Croatian messages
- FR28: System can handle eVisitor API unavailability without losing queued guest data
- FR29: System can require BorderCrossing and PassageDate fields for non-EU guests before submission

**Submission History (FR30–FR32)**
- FR30: Host can view a history of submitted guests for the past 30 days
- FR31: Host can see the submission status and timestamp for each historical entry
- FR32: System can automatically purge history entries older than 30 days

**Consent & Monetization (FR33–FR35)**
- FR33: System can display ads within the app (AdMob integration)
- FR34: System can present a consent dialog for ad personalization compliant with EEA/UK requirements (UMP/CMP)
- FR35: Host can manage their ad consent preferences

**Onboarding (FR36)**
- FR36: System can detect first launch and guide the host through initial facility profile setup before scanning

**Feedback & Error Communication (FR37–FR39)**
- FR37: System can provide audible and/or haptic feedback on successful capture events
- FR38: System can display field-level validation errors in Croatian before submission
- FR39: System can warn the host when a duplicate guest scan is detected within 24 hours

### Non-Functional Requirements (31 total)

**Performance (NFR1a–NFR8)**
- NFR1a: MRZ capture-to-parsed-data display ≤ 3 seconds on mid-range Android devices
- NFR1b: OCR fallback capture-to-parsed-data display ≤ 5 seconds on same device class
- NFR2: Time-to-first-feedback after capture under 1 second
- NFR3: Guest queue list rendering smooth with up to 50 guests
- NFR4: App cold start to camera-ready ≤ 5 seconds on mid-range devices
- NFR5: Warm resume to camera-ready ≤ 2 seconds
- NFR6: eVisitor API submission per guest: 15-second client-side timeout with progress indicator
- NFR7: Review card field editing with no perceptible input lag
- NFR8: App responsive during background API submission — UI thread never blocked

**Security (NFR9–NFR18)**
- NFR9: Facility credentials encrypted at rest using Android Keystore hardware-backed keys
- NFR10: Guest identity data not accessible to other apps (app-private storage)
- NFR11: Android Auto Backup disabled or scoped to exclude credential and guest data
- NFR12: eVisitor API communication HTTPS exclusively
- NFR13: Captured document images not persisted after data extraction
- NFR14: Local guest history automatically purged after 30 days
- NFR15: Credential entry fields must not allow system keyboard autocomplete/suggestions
- NFR16: Credential and guest identity screens must use FLAG_SECURE
- NFR17: App must comply with Google Play data safety declaration requirements
- NFR18: Observability must never capture MRZ data, document images, guest names, or credentials in logs/crash reports

**Integration (NFR19–NFR24)**
- NFR19: eVisitor API session management must handle cookie expiry transparently
- NFR20: eVisitor API failures must never result in loss of queued guest data
- NFR21: eVisitor API retry policy must use exponential backoff with jitter on 429/503/timeout
- NFR22: App must gracefully degrade when eVisitor API is unreachable — capture/review/queue remain operational offline
- NFR23: ML Kit text recognition must function without network connectivity (on-device bundled model)
- NFR24: AdMob must not block or delay core functionality — no full-screen interstitials during capture or submission

**Reliability (NFR25–NFR29)**
- NFR25: Crash-free session rate ≥ 99.5% over trailing 28 days
- NFR26: Guest state machine recoverable after process death — no guest stuck in transient state
- NFR27: After crash/process death, app must restore session context (active facility, queue position)
- NFR28: Queue data must survive app updates without data loss
- NFR29: Duplicate submission prevention — no double-submit even after crash recovery or retry

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

**Verdict:** PRD is **solid and implementation-ready**. No blocking gaps. The minor state-machine naming difference should be reconciled in the architecture document.

---

## Epic Coverage Validation

**Status:** ⏳ Skipped — Epics & Stories not yet created. This section will be completed when epics are available.

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

**Issue 2 (Medium): `paused_auth` state not in architecture enum**
- UX explicitly defines `paused_auth` as a queue row state (with its own `ThemeExtension` color token and specific `BatchSendSummary` state)
- Architecture mentions `paused_auth` in retry policy prose ("If re-auth fails → `paused_auth` state on all pending guests")
- BUT: Architecture's `guest_state.dart` enum only lists: `captured, confirmed, ready, sending, sent, failed`
- **Impact:** Medium. UX expects a distinct visual state for auth-paused guests. Without it in the enum, implementation will either add it ad-hoc or handle it inconsistently.
- **Recommendation:** Add `pausedAuth` to the `GuestState` enum in architecture. Add state machine transition: `sending → pausedAuth` (on re-auth failure) and `pausedAuth → ready` (on successful re-auth). Update the state machine events table.

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

**Status:** ⏳ Skipped — Epics & Stories not yet created.

---

## Summary and Recommendations

### Overall Readiness Status

**READY (for epic creation) — PRD, Architecture, and UX are well-aligned and implementation-grade**

All three documents are thorough, internally consistent, and cross-reference each other's decisions correctly. The BMAD workflow has been followed correctly up to this point. You are in good shape to proceed to epic and story creation.

### Critical Issues Requiring Immediate Action

**None.** No blocking issues found across the three assessed documents.

### Issues to Address Before or During Epic Creation

| # | Severity | Issue | Recommended Fix |
|---|---|---|---|
| 1 | **Medium** | `paused_auth` state missing from architecture's `GuestState` enum despite UX and architecture prose both referencing it | Add `pausedAuth` to the enum and add transitions in the state machine table |
| 2 | **Minor** | Component naming: UX says `GuestSubmissionSnapshotCard`, architecture says `guest_review_card.dart` | Align on one name — prefer UX's "submission snapshot" framing |
| 3 | **Minor** | UX distinguishes `failed-retryable` vs `failed-terminal` visually; architecture has single `failed` state | Document in architecture that the distinction is derived from `Failure` type at render time |
| 4 | **Minor** | Architecture says "29 NFRs" but actual count is 31 (NFR1a + NFR1b counted separately) | Correct the count in architecture doc header |

### Document Quality Scores

| Document | Completeness | Internal Consistency | Cross-Document Alignment | Grade |
|---|---|---|---|---|
| **PRD** | Excellent — 39 FRs, 31 NFRs, 4 journeys, risk matrix, scoping | Strong — one minor state naming ambiguity in Implementation Considerations vs FR20 | N/A (source of truth) | **A** |
| **Architecture** | Excellent — full project structure, patterns, validation, gap analysis | Strong — all FRs and NFRs explicitly mapped to file locations | Very strong PRD alignment; 3 minor issues vs UX | **A-** |
| **UX Design** | Excellent — journeys, components, design system, accessibility, responsive | Strong — consistent with chosen Direction A | Very strong PRD and architecture alignment | **A** |

### Recommended Next Steps

1. **Fix the `paused_auth` enum gap** in `architecture.md` before creating epics — it affects state machine story breakdown
2. **Create epics and stories** using the `bmad-create-epics-and-stories` skill — all three input documents are ready
3. **Re-run this readiness check** after epics are created to validate FR coverage and story quality (steps 3 and 5 that were skipped)

### BMAD Workflow Compliance

You have correctly followed the BMAD workflow:
- ✅ Product Brief created
- ✅ Research (market + technical) completed
- ✅ Brainstorming session conducted
- ✅ PRD created through guided workflow (all steps completed)
- ✅ UX Design Specification created through guided workflow (14 steps completed)
- ✅ Architecture Decision Document created through guided workflow (8 steps completed)
- ⏳ **Next:** Epics & Stories creation

### Final Note

This assessment validated 3 documents across 4 analysis categories (PRD completeness, UX↔PRD alignment, UX↔Architecture alignment, Architecture↔PRD alignment). **4 issues found** — 1 medium, 3 minor. None are blocking. The planning artifacts are at a high quality level and ready to drive epic/story creation and subsequent implementation.

---

<!--stepsCompleted: [step-01-document-discovery, step-02-prd-analysis, step-03-epic-coverage-skipped, step-04-ux-alignment, step-05-epic-quality-skipped, step-06-final-assessment]-->
