---
stepsCompleted:
  - "step-01-init"
  - "step-02-discovery"
  - "step-02b-vision"
  - "step-02c-executive-summary"
  - "step-03-success"
  - "step-04-journeys"
  - "step-05-domain"
  - "step-06-innovation-skipped"
  - "step-07-project-type"
  - "step-08-scoping"
  - "step-09-functional"
  - "step-10-nonfunctional"
  - "step-11-polish"
  - "step-e-01-discovery"
  - "step-e-02-review"
  - "step-e-03-edit"
lastEdited: "2026-04-17"
editHistory:
  - date: "2026-04-17"
    changes: "Added mock eVisitor backend (Fastify + TypeScript) to Technical Constraints and Integration Requirements; added Patrol to Integration Requirements; rewrote Testing Strategy to specify unit/widget/integration/E2E tiers with Patrol on headless Android emulator and mock eVisitor server as CI dependency."
timeline: "6 weeks to Play Store (target: ~end of May 2026)"
visionNotes:
  capturePipeline: "MRZ-first → OCR fallback → manual entry (changed from brainstorm S1 which eliminated OCR)"
  primaryPain: "Manual typing of foreign names/doc numbers AND wrong-facility submissions (equal weight)"
  dogfooding: "Darko is first user — owns apartment, registers guests personally"
  pitch: "Scan. Review. Send. Done."
  northStar: "First-time submission success rate"
classification:
  projectType: "Mobile App (Android, Flutter)"
  domain: "Tourism Regulatory Compliance"
  complexity: "Medium-High"
  projectContext: "Greenfield"
inputDocuments:
  - "product-brief-prijavko.md"
  - "product-brief-prijavko-distillate.md"
  - "research/technical-android-evisitor-mrz-queue-evisitor-api-research-2026-04-13.md"
  - "research/market-mobile-evisitor-guest-check-in-hr-research-2026-04-13.md"
  - "brainstorming/brainstorming-session-2026-04-13-212114.md"
  - "eVisitor Web API wiki (https://www.evisitor.hr/eVisitorWiki/Javno.Web-API.ashx)"
  - "eVisitor API integration guide PDF"
documentCounts:
  briefs: 2
  research: 2
  brainstorming: 1
  projectDocs: 0
  apiDocs: 2
workflowType: 'prd'
---

# Product Requirements Document — Prijavko

**Author:** Darko
**Date:** 2026-04-14

## Executive Summary

**Prijavko** is an Android app (Flutter) that replaces manual data entry in Croatia's national eVisitor guest registration system. The host points a camera at a passport or ID card, the app extracts guest data via MRZ parsing (with OCR fallback when MRZ is absent or unreadable), the host reviews and confirms fields, then submits to eVisitor — individually or in batch from a local queue.

The product targets Croatian tourism hosts who register guests themselves. The immediate value is **speed and accuracy**: scan instead of type foreign names, document numbers, and dates. The structural value is **compliance safety**: session-scoped facility selection prevents wrong-object submissions, and a local queue decouples door-side capture from admin send.

**v1 is ad-supported and free** — maximize reach, learn stability, avoid payment friction. Revenue expectation is hobby-scale (seasonal niche utility), not salary replacement.

The builder is the first user — an apartment host who registers guests via eVisitor and wants a tool that works at the door in peak season.

### What Makes This Special

**Capture pipeline:** MRZ-first with ICAO checksum validation → OCR fallback for documents without readable MRZ → manual entry as last resort. Each tier minimizes typing; the MRZ checksum catches garbage before it reaches eVisitor.

**Session-scoped facility:** The app starts "neutral" — no persistent facility toggle. The host picks a facility when starting a scan session. This is a structural guardrail (poka-yoke) against wrong-object submissions, the most painful error for multi-facility hosts.

**Queue + batch send:** Capture happens at the door; submission happens when the host is ready. Deferred eVisitor login (credentials stored encrypted via Android Keystore) means the app is useful before the host even logs in.

**Host-only, on-device:** No guest self-check-in flows, no cloud sync, no gallery import. Clearer GDPR posture, smaller attack surface, focused scope.

**North star metric:** First-time submission success rate — the share of guests where the first end-to-end attempt (capture → eVisitor accept) succeeds without manual field correction or repeated cycles.

## Project Classification

| Dimension | Value |
|-----------|-------|
| **Project Type** | Mobile App — Android-only, Flutter, camera + local DB + REST integration |
| **Domain** | Tourism Regulatory Compliance — mandatory guest registration via government API (eVisitor), identity document processing, GDPR |
| **Complexity** | Medium-High — government API with cookie auth + XML payloads, MRZ/OCR accuracy on real documents, EEA ad consent (UMP/CMP), legal compliance framing |
| **Project Context** | Greenfield — new product, no existing codebase |

## Success Criteria

### User Success

- **Scan-to-confirmed under 10 seconds** per guest (MRZ happy path). Manual eVisitor web entry is slower — the app must be noticeably faster at the door.
- **First-time submission success** — guest data captured, validated, and accepted by eVisitor on the first attempt without manual field correction or repeated capture cycles.
- **Zero wrong-facility submissions** — session-scoped facility picker structurally prevents this. If a guest is sent to the wrong object, it's a product failure.
- **Understandable failures** — when eVisitor rejects a submission, the host sees a human-readable Croatian message, not a system error code. The host knows what to fix.

### Business Success

- **v1 (6-week bar):** Published on Play Store within 1.5 months (~end of May 2026). Ready for summer season.
- **v1 (3-month bar):** Darko uses the app for all guest registrations during summer season without falling back to the eVisitor web interface. The app is the primary tool.
- **v1 (6-month bar):** Organic installs from Croatian hosts. Ad revenue covers at minimum store/infra costs (coffee money).
- **Support burden:** Near-zero. A solo dev can't run a support desk — the app must be self-explanatory and errors must be self-recoverable.

### Technical Success

- **MRZ checksum pass rate ≥ 90%** on real passports under normal conditions (indoor/outdoor, no extreme glare). Remaining 10% hit OCR fallback or manual entry — not a dead end.
- **eVisitor API round-trip reliability:** Login + submit succeeds on first attempt when network and eVisitor are available. Cookie session persists across process death.
- **Crash-free sessions ≥ 99.5%** — camera, MRZ parsing, and queue state must survive app kill, rotation, and low-memory conditions.
- **Queue durability:** Guest data persists across app kill and device reboot. Zero data loss on captured-but-unsent guests.

### Measurable Outcomes

| Metric | Target | How Measured |
|--------|--------|-------------|
| **First-time submission success rate** | Track from day 1; improve iteratively | Capture → eVisitor accept without field edits or retry |
| **Scan-to-confirmed time** | ≤ 10s (MRZ path) | In-app timer from capture to confirm tap |
| **MRZ checksum pass rate** | ≥ 90% | Parser pass/fail by document type |
| **Edit rate after capture** | Track by tier (MRZ / OCR / manual) | Fields modified before confirm |
| **Submit success rate** | Track; target near 100% after edits | eVisitor API response codes |
| **Crash-free sessions** | ≥ 99.5% | Firebase Crashlytics (trailing 28 days) |

## User Journeys

### Journey 1: Darko — Friday Evening Check-In (Happy Path)

**Persona:** Darko, apartment host in a coastal town. One apartment on eVisitor. Registers guests himself at the door.

**Opening Scene:** It's Friday at 6 PM. Two families are arriving within 30 minutes of each other — a German couple with a child and an Austrian family of four. Darko meets them at the apartment. Bags are in the hallway. Everyone's tired from driving. He needs to register 6 guests in eVisitor before he can hand over the keys and go home.

**Rising Action:** Darko opens Prijavko. Taps "Start Scanning," selects his apartment. Picks "Passport" and holds the camera over the German father's passport. The MRZ is detected, checksum passes — a confirmation beep plays. The review card appears read-only with extracted fields: name, date of birth, document number, citizenship, all correct. He taps Confirm. 8 seconds. Next guest — same flow. The child's passport works too. Three guests confirmed in under a minute.

The Austrian family arrives. Same flow — four more passports, four more beeps. The queue now shows 7 guests, all tagged to his apartment.

**Climax:** Darko taps "Send All." The app prompts for eVisitor login (first send of the session). He enters credentials (or they're already stored). The app submits all 7 guests in batch. Green checkmarks appear one by one. All accepted. Total time from first scan to all-sent: under 3 minutes.

**Resolution:** Darko hands over the keys. No laptop opened, no eVisitor web form, no typing foreign names from memory. He has a local record of what was sent. He's done for the evening.

**Requirements revealed:** MRZ capture pipeline, review card (read-only state), queue, batch send, deferred auth, sound/haptic feedback, local history.

---

### Journey 2: Darko — Old ID Card, OCR Fallback, eVisitor Error (Edge Case)

**Opening Scene:** A Croatian guest arrives with an old osobna iskaznica (national ID card). The MRZ zone is scratched and partially illegible. Darko opens the app, picks "ID Card," and captures a photo.

**Rising Action:** The MRZ parser fails checksum validation. An error tone plays. The review card appears in editable mode with fields partially pre-filled from OCR fallback — surname and given name are extracted but the document number has two garbled characters. Date of birth came through correctly from the OCR text region.

Darko glances at the physical card, corrects the two wrong characters in the document number, verifies the other fields, and taps Confirm. The guest is added to the queue.

He taps "Send All." The app submits to eVisitor. The response comes back with an error on this guest: *"Kategorija boravišne pristojbe mora biti dozvoljena za odabrani objekt."* — the tourist tax payment category doesn't match the facility type. The error is displayed in Croatian, human-readable. Darko taps the guest in the failed list, sees the dropdown for payment category, picks the correct one, and taps Retry. This time it succeeds.

**Climax:** The guest is registered despite two failures (MRZ and wrong category). The app caught the MRZ problem early (OCR fallback) and surfaced the eVisitor business rule clearly (Croatian error). No data was lost. No confusion.

**Resolution:** Darko knows exactly what happened and why. The 30-day history shows the attempt, the failure reason, and the successful retry. If an inspector ever asks, he has proof.

**Requirements revealed:** OCR fallback pipeline, editable review card, Croatian error mapping, per-guest retry, payment category selection, field validation, 30-day history with failure reasons.

---

### Journey 3: Darko — First-Time Setup (Onboarding)

**Opening Scene:** Darko just installed the app from the Play Store. He's never used it before. It's May, season hasn't started yet, and he wants to test it with his own passport before guests arrive.

**Rising Action:** The app opens to a neutral state — no facility, no session. A brief onboarding flow explains: "Add your eVisitor facility first." Darko goes to settings/profiles, taps "Add Facility." He enters the facility code (from his eVisitor account), his eVisitor username (OIB) and password. The app encrypts and stores credentials locally via Android Keystore. He names it "Apartment Sunset."

Back on the home screen, he taps "Start Scanning." The facility picker shows "Apartment Sunset" — he selects it. He picks "Passport," scans his own passport. MRZ passes. Review card looks correct. He confirms.

He's curious — taps "Send All." The app logs in to eVisitor with his stored credentials. It submits his own data. eVisitor returns: *"Turist je već prijavljen u navedenom objektu."* — he's already registered there (obviously — it's his own address). The error appears in Croatian. He understands what happened. Test complete.

**Climax:** Darko now trusts the pipeline. He saw the camera work, the MRZ parse, the eVisitor round-trip, and a real error message in his language. The tool is ready for season.

**Resolution:** He deletes his own test entry from the queue. The app is configured and waiting. When the first guest arrives in June, it's one tap to start.

**Requirements revealed:** Facility profile CRUD, credential encryption, onboarding flow, facility picker, eVisitor login round-trip, Croatian error display, queue management (delete entries).

---

### Journey 4: Marina — Multi-Facility Check-In Day (Structural Differentiator)

**Persona:** Marina, 45, manages three apartments under one OIB in Split — "Marina View," "Old Town Studio," and "Garden Suite." Different addresses, different facility codes in eVisitor.

**Opening Scene:** It's Saturday turnover day. All three apartments have guests arriving between 2 PM and 5 PM. Last summer, Marina submitted two guests to "Old Town Studio" when they were actually staying in "Garden Suite" — she had to call the TZ to fix it. She dreads peak Saturdays.

**Rising Action:** Marina opens Prijavko. The app is neutral — no facility selected. She drives to Marina View first. Taps "Start Scanning," picks "Marina View" from her three saved profiles. Scans two German passports — beep, beep. Confirms both. Taps "Finish Session."

She drives to Old Town Studio. Taps "Start Scanning" again — the app is neutral again, no lingering context. She picks "Old Town Studio." Scans a French passport and a Belgian passport. Confirms. Finish Session.

Finally, Garden Suite. Same flow — picks "Garden Suite," scans an Italian family of three. All confirmed.

Now she's home with coffee. The queue shows 7 guests across three facilities. She glances at each — the facility tag is visible per guest. Everything correct. She taps "Send All." The app logs in once, submits all 7 to the correct facilities. All green.

**Climax:** No wrong-facility submission. The "neutral app" design meant Marina never had to remember which profile was active. She chose it fresh each time at the door — matching her physical location to the digital context. The poka-yoke worked.

**Resolution:** Marina's Saturday took 15 minutes of admin instead of 45. No TZ calls. No corrections. She texts her neighbor host about the app.

**Requirements revealed:** Multi-facility profiles, neutral app state between sessions, per-guest facility tagging, facility re-assign before send, batch send across facilities, credential switching per facility on send.

---

### Journey Requirements Summary

| Capability | Journeys |
|------------|----------|
| MRZ capture + checksum validation | 1, 2, 3 |
| OCR fallback pipeline | 2 |
| Manual entry (last resort) | implied by 2 |
| Review card (read-only / editable states) | 1, 2, 3 |
| Sound + haptic feedback | 1, 2 |
| Queue with facility tags | 1, 4 |
| Batch send | 1, 4 |
| Deferred eVisitor auth | 1, 3 |
| Encrypted credential storage | 3, 4 |
| Facility profile CRUD | 3, 4 |
| Session-scoped facility picker | 1, 4 |
| Per-guest facility re-assign | 4 |
| Croatian error mapping | 2, 3 |
| Per-guest retry on failure | 2 |
| Payment category selection | 2 |
| Duplicate scan warning | implied |
| 30-day local history | 2 |
| Onboarding flow | 3 |
| Queue entry deletion | 3 |

## Domain-Specific Requirements

### Compliance & Regulatory

**Croatian guest registration law:**
- Hosts are legally required to register guests in eVisitor. Fines range €132–€2,654 for non-compliance (Rentlio/industry sources — verify with primary legal text for app copy).
- The app is an **operational aid** — it does not replace the host's statutory obligation. This must be stated in-app and on the Play Store listing.
- Registration deadlines are the host's responsibility. The app does not enforce deadlines but reduces friction in meeting them.

**GDPR / data privacy:**
- Identity documents (passports, ID cards) contain sensitive personal data. Processing must be minimized and justified.
- **On-device only** — no cloud upload of document images or guest data in v1. Simplest GDPR posture.
- Document images discarded after MRZ/OCR extraction. Only structured fields persisted in local queue.
- **30-day retention** on local history — automatic cleanup of older records.
- Privacy policy required for Play Store. Must disclose: camera use, local storage of guest data, eVisitor credential storage, ad SDK data collection.

**Google Play compliance:**
- Data safety form must declare: camera permission, local storage of identity data, encrypted credential storage, ad network data collection.
- Ad monetization requires **UMP/CMP** (User Messaging Platform / Consent Management Platform) for EEA/UK users — Google policy mandates certified CMP for personalization/measurement consent.
- No Play Integrity required for v1; consider for abuse reduction later.

### Technical Constraints

**eVisitor API surface (from official wiki + PDF):**
- **Auth:** `POST Resources/AspNetFormsAuth/Authentication/Login` — `(UserName, Password, apikey)` → bool + cookies (`.ASPXAUTH`, affinity, language). All subsequent calls must include these cookies.
- **Test environment:** `https://www.evisitor.hr/testApi` — separate credentials, snapshot data. Not used in CI or local dev — replaced by the project-owned mock server (`config/local.json` → `http://10.0.2.2:8080`; `config/test.json` → `http://mock-evisitor:8080` in compose).
- **Guest registration:** Two paths available:
  - `CheckInTourist` (action) — per-guest, JSON body, newer API
  - `ImportTourists` (action) — XML body, batch, legacy but still supported
- **Guest checkout:** `CheckOutTourist` (action) — post-MVP
- **Date format:** `YYYYMMDD` (e.g. `20260413`). Time format: `hh:mm`.
- **Field length limits (MUP):** Document number ≤ 16 chars, name ≤ 64, surname ≤ 64, city of birth ≤ 64, city of residence ≤ 64.
- **Required fields for check-in:** Facility code, StayFrom (date+time), ForeseenStayUntil (date+time), DocumentType, DocumentNumber, TouristName, TouristSurname, Gender, CountryOfBirth, CityOfBirth, DateOfBirth, Citizenship, CountryOfResidence, CityOfResidence, TTPaymentCategory, ArrivalOrganisation, OfferedServiceType. Optional: ResidenceAddress, TouristEmail, TouristTelephone, AccommodationUnitType, TouristMiddleName.
- **Duplicate detection key:** Same facility + DateOfBirth + DocumentType + DocumentNumber + CountryOfResidence + not checked out + not cancelled.
- **Max stay:** 90 days (MUP constraint).
- **Non-EU guests:** BorderCrossing and PassageDate are mandatory.
- **Error responses:** JSON `{SystemMessage, UserMessage}` — `UserMessage` is the Croatian human-readable string to display.
- **ID requirement:** Every submission requires a GUID `ID` parameter (mandatory since 2017-06-01). App must generate and track these for later checkout/cancellation.

**MRZ / ICAO 9303:**
- TD1 (ID cards — 3 lines × 30 chars), TD3 (passports — 2 lines × 44 chars). TD2 also exists but less common.
- Checksum validation per ICAO spec — composite check digit must pass.
- Fields extractable from MRZ: surname, given names, document number, nationality, date of birth, sex, expiry date, personal number (optional).
- MRZ does **not** contain: city of birth, city of residence, residence address — these must come from OCR or manual entry.

**Android Keystore:**
- Credential blobs encrypted with Keystore-backed keys. Jetpack `security-crypto` is moving toward deprecation — use direct Keystore + cipher.
- BiometricPrompt optional gate for credential access (post-MVP).

**Mock eVisitor backend server:**
- Project-owned mock server (Fastify + TypeScript) mirroring the eVisitor REST surface (`Login`, `CheckInTourist`, `ImportTourists`, session cookies, error envelope) with scripted responses: success, validation failure, duplicate detection, 401/session expiry, 503/unavailable.
- Purpose: deterministic target for integration and E2E tests — decouples the test suite from the real eVisitor test environment, which is rate-limited and snapshot-scheduled.
- Runs locally for development and as a CI test dependency. Not shipped in the app binary.

### Integration Requirements

| System | Integration | Protocol |
|--------|-------------|----------|
| **eVisitor** | Guest check-in/out, facility lookup | REST + cookies, JSON wrapper, XML payloads |
| **Mock eVisitor server** | E2E/integration test target mirroring eVisitor API contract | Fastify + TypeScript, local HTTP, scripted responses |
| **ML Kit** | Text Recognition v2 (MRZ + OCR regions) | On-device, no network |
| **MRZ parser** | ICAO TD1/TD2/TD3 checksum validation | Local library (mrz_parser or equivalent) |
| **Patrol** | E2E test framework on headless Android emulator | Dart test runner + native driver (ADB, UiAutomator) |
| **AdMob** | Ad display + revenue | Google Mobile Ads SDK |
| **UMP** | EEA consent management | Google UMP SDK |
| **Firebase Crashlytics** | Crash reporting (PII scrubbing required) | Firebase SDK |

## Mobile App Specific Requirements

### Platform Requirements

| Requirement | Decision |
|-------------|----------|
| **Framework** | Flutter (Dart) — cross-platform codebase, Android-only deployment for v1 |
| **Min Android API** | TBD during spike — target API 24+ (Android 7.0) for broad device coverage while supporting modern Keystore and CameraX APIs |
| **Target Android API** | Latest stable (API 35 / Android 15 at time of writing) |
| **iOS** | Explicitly out of v1. Flutter codebase enables future port after Android PMF |
| **Tablets** | Not optimized for v1 — phone-first layout. Should work but not tested |

### Device Permissions

| Permission | Purpose | When Requested |
|------------|---------|----------------|
| **Camera** | Document capture (MRZ + OCR) | First scan attempt |
| **Internet** | eVisitor API calls, ad loading | Always (passive) |

No storage permission needed — app uses internal storage (Drift/sqflite). No location, contacts, microphone, or background location.

### Offline Mode

- **Queue is offline-first** — guests captured and stored locally regardless of network state.
- **Send requires network** — eVisitor API calls need connectivity. App detects offline state and shows clear messaging.
- **Credential storage** — fully offline via Android Keystore. No network needed to access stored facility profiles.
- **No cloud sync** — single-device source of truth. Queue and history are local only.

### Store Compliance

- **Data safety form:** Camera (document capture), local storage (guest data, credentials), ad network data collection (AdMob). No data shared with third parties beyond ad SDK.
- **Privacy policy:** Required. Must disclose local ID data processing, credential storage, ad personalization, 30-day retention.
- **CMP/UMP:** Required for EEA ad personalization consent. Must be shown before first ad load.
- **Content rating:** Likely "Everyone" — no objectionable content.
- **App category:** Travel & Local or Business.
- **Target audience:** Not children — no COPPA concerns. App handles adult identity documents.

### Implementation Considerations

**Camera UX:**
- Guide overlay for document alignment (passport/ID card frame)
- Torch toggle for low-light conditions
- Static capture (tap to shoot) — no live stream processing
- Immediate MRZ/OCR processing after capture with loading indicator

**State management:**
- Explicit state machine for queue items: `captured → confirmed → ready → sending → sent / failed / pausedAuth`
- Process death safety: queue state persists via local DB, not in-memory only
- App rotation: state preserved across configuration changes

**Testing strategy:**

- **Unit tests (Dart):** MRZ parser with ICAO TD1/TD2/TD3 checksum vectors; queue state machine transitions + process-death recovery; field validation against eVisitor length/format limits; Croatian error mapping.
- **Widget tests (Flutter):** Review card read-only/editable states, facility picker flows, form validation rendering.
- **Integration tests (Dart):** eVisitor transport layer (cookie auth, session expiry replay, retry/backoff) against the mock eVisitor server (Fastify + TypeScript), asserting against the full set of scripted response shapes (success, validation error, duplicate, 401, 503).
- **E2E tests (Patrol):** Full user journeys (scan → review → queue → batch send → history) driven by Patrol on a **headless Android emulator**. Patrol's native-side capabilities cover what Flutter integration tests cannot: granting the camera permission via the system dialog, toggling airplane mode to simulate offline, dismissing the Keystore/biometric prompt, and asserting notification content. Test syntax uses Patrol's `patrolTest` + `$` finder (e.g. `await $(#startScanning).tap()`) and `$.native` for system UI. The mock eVisitor server is started as a test dependency before each E2E run so scan-to-submit flows have a deterministic backend.
- **Scenario coverage:** All four user journeys — happy path (J1), OCR fallback + eVisitor error (J2), first-time onboarding (J3), multi-facility session switching (J4) — have a corresponding Patrol E2E test.
- **CI pipeline:** Unit + widget tests run on every push. Patrol E2E suite (minimum 5 passing tests) runs via `docker-compose -f docker-compose.e2e.yml up` on GHA `ubuntu-latest` (KVM-accelerated) — three containers: mock-evisitor, android-emulator (budtmo/docker-android), test-runner (Flutter SDK + patrol_cli). No real eVisitor API calls in CI. Coverage gate enforces ≥70% meaningful on push to `main`.
- **AI Integration Log:** Living document at `_bmad-output/ai-integration-log.md` updated per story. Covers agent usage, Postman MCP usage, test generation, debugging, and limitations. Required training deliverable.

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Problem-solving MVP — the minimum that replaces manual eVisitor web entry for Darko's apartment guests this summer. Not a platform, not a demo — a working tool for a real host.

**Resource:** Solo developer (Darko), 6 weeks to Play Store. No team scaling, no external dependencies except eVisitor API access.

**Cut strategy:** If any feature threatens the timeline, the answer is "ship without it" — not "slip." The OCR fallback + manual entry tiers ensure the app is useful even if MRZ accuracy is below target. The only hard blocker is the eVisitor API round-trip (Week 1 spike).

### MVP Feature Set (Phase 1 — 6 weeks)

**Core journeys supported:** All four (Journey 1–4). The MVP covers the happy path, the failure path, onboarding, and multi-facility — because the session-scoped facility is structural, not a growth feature.

**Must-have capabilities (ship blockers):**

| Capability | Why it's a ship blocker |
|------------|------------------------|
| eVisitor API login + submit (CheckInTourist or ImportTourists) | Without this, the app doesn't register guests |
| MRZ capture + checksum | Primary value proposition — scan instead of type |
| OCR fallback | Safety net when MRZ fails — ensures app is never a dead end |
| Manual entry (all fields editable) | Last resort — guarantees 100% document coverage |
| Review card (read-only / editable) | Host must confirm before send |
| Session-scoped facility picker | Structural differentiator — prevents wrong-object sends |
| Encrypted credential storage | Can't send without stored credentials |
| Local queue | Batch workflow — capture at door, send later |
| Croatian error mapping | Without this, eVisitor errors are incomprehensible |
| 30-day local history | Proof of submission — host trust |
| Ads + CMP/UMP | Revenue model; consent required for EEA |

**Nice-to-have in MVP (ship without if needed):**

| Capability | Why it's deferrable |
|------------|---------------------|
| Sound + haptic feedback | Polish, not function |
| Duplicate scan warning (24h) | Guardrail, not blocker — eVisitor catches dupes anyway |
| Background retry on send | Manual retry works; background retry is convenience |
| Per-guest facility re-assign before send | Can work around by deleting and re-scanning |
| Torch toggle | Camera flash works on most phones |

### Post-MVP Features

**Phase 2 (Summer → Fall 2026) — based on dogfooding learnings:**
- Checkout/deregistration (CheckOutTourist API)
- Read registered guests from eVisitor — view all reports (not just locally submitted), verify existing registrations, catch missing checkouts, single source of truth
- Improved OCR accuracy (commercial SDK evaluation)
- Play Store ASO (Croatian keywords)
- Analytics on capture pipeline performance
- UX polish based on real-season usage

**Phase 3 (2027+) — only if validated:**
- iOS port from Flutter codebase
- Paid tiers or seasonal pricing (only after ads prove insufficient)
- TZ partnership pilot
- Adjacent features (tourist tax, checkout automation)
- Offline-first strengthening

### Competitive Pricing Context

| Competitor | Pricing | Model |
|------------|---------|-------|
| **Official eVisitor app** | Free | Government-provided, basic |
| **mVisitor** | €6/month or €30/year (VAT incl.) | Subscription, unlimited registrations per OIB |
| **PrijaviTuriste** | Per-registration packs (from €4.99/30) | Metered, non-expiring packs |
| **Prijavko** | **Free** | Ad-supported; only truly free third-party option |

**Positioning advantage:** Both mVisitor and PrijaviTuriste charge. Prijavko is the only third-party tool that costs hosts nothing — the ad model removes all payment friction and metering anxiety.

### Risk Mitigation Strategy

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **eVisitor API round-trip fails in Flutter/Dio** | Medium | Critical | Week 1 spike is the kill switch. If cookie persistence fails, evaluate Kotlin fallback for transport layer before committing 5 more weeks. |
| **eVisitor API instability / downtime** | Medium | High | Local queue persists; bounded retry with exponential backoff + jitter; clear "offline" messaging; manual retry available |
| **Cookie/session expiry mid-batch** | Medium | Medium | Detect 401/redirect → re-authenticate → replay failed request; preserve queue state; no data loss |
| **MRZ accuracy below 90%** | Medium | High | OCR fallback carries the load — app is faster than manual web entry even at 70% MRZ pass rate. Commercial SDK evaluation (Phase 2) if both MRZ and OCR fail frequently. |
| **eVisitor API changes / field additions** | Low | High | Abstract API layer; Croatian error passthrough ensures new server-side rules surface naturally |
| **Credential theft from rooted device** | Low | Medium | Keystore-backed encryption; no plaintext storage; rooted devices are user's responsibility |
| **GDPR complaint about local data** | Low | Medium | Document images discarded after extraction; 30-day auto-cleanup; no cloud upload; privacy policy disclosure |
| **Play Store rejection** | Low | Medium | Data safety form accurate; privacy policy published; no deceptive patterns; CMP for ads |
| **Background retry becomes "ghost sends"** | Low | Medium | Bounded max attempts; visible sending/failed state; user-controlled retry after terminal failure |
| **Solo dev, 6-week timeline overrun** | Medium | High | "Nice-to-have" list is the pressure valve. If week 4 is behind, cut sound/haptic, duplicate warning, background retry, per-guest re-assign. Ship: scan → review → send → history. |

## Functional Requirements

### Document Capture & Recognition

- **FR1:** Host can capture a guest's identity document using the device camera
- **FR2:** System can extract guest data from the MRZ zone of a captured document with checksum validation (TD1, TD2, TD3 formats)
- **FR3:** System can fall back to OCR text extraction when MRZ parsing fails or MRZ is absent
- **FR4:** Host can manually enter or correct all guest data fields when automated extraction is insufficient
- **FR5:** System can determine the capture method used (MRZ, OCR, manual) and carry it as metadata

### Guest Data Review & Editing

- **FR6:** Host can review extracted guest data on a read-only confirmation card before submission
- **FR7:** Host can switch a review card to editable mode to correct any field
- **FR8:** Host can add data not extractable from documents (e.g., arrival date, departure date, facility assignment)
- **FR9:** System can validate guest data against eVisitor field requirements before allowing submission
- **FR10:** Host can delete a guest from the queue before submission

### Facility Management

- **FR11:** Host can add a facility profile with credentials (eVisitor username, password, facility ID) and per-facility defaults (TTPaymentCategory, ArrivalOrganisation, OfferedServiceType, default stay duration)
- **FR12:** Host can manage multiple facility profiles (edit, delete)
- **FR13:** Host can select a session-scoped active facility that applies to all subsequent captures
- **FR14:** Host can change the active facility between capture sessions
- **FR15:** System can store facility credentials and defaults encrypted on-device using hardware-backed keystore

### Guest Queue & Batch Workflow

- **FR16:** System can maintain a local queue of captured guests associated with the active facility
- **FR17:** Host can view all guests in the current queue
- **FR18:** Host can submit all ready guests in a single batch action
- **FR19:** Host can submit an individual guest from the queue
- **FR20:** System can track each guest's status through a defined state lifecycle (captured → confirmed → ready → sending → sent / failed)
- **FR21:** Host can retry submission for failed guests
- **FR22:** System can automatically purge unsent queue items older than 7 days to prevent stale data accumulation

### eVisitor API Integration

- **FR23:** System can authenticate with the eVisitor API using host credentials (ASP.NET Forms Authentication with cookie session)
- **FR24:** System can submit guest check-in data to eVisitor (CheckInTourist or ImportTourists endpoint)
- **FR25:** System can generate a unique GUID per guest submission and persist it locally for idempotency, future checkout, and cancellation
- **FR26:** System can detect session expiry or authentication failure and re-authenticate transparently
- **FR27:** System can parse eVisitor API error responses and present them as human-readable Croatian messages
- **FR28:** System can handle eVisitor API unavailability without losing queued guest data
- **FR29:** System can require BorderCrossing and PassageDate fields for non-EU guests before submission (conditional mandatory fields per eVisitor API rules)

### Submission History

- **FR30:** Host can view a history of submitted guests for the past 30 days
- **FR31:** Host can see the submission status and timestamp for each historical entry
- **FR32:** System can automatically purge history entries older than 30 days

### Consent & Monetization

- **FR33:** System can display ads within the app (AdMob integration)
- **FR34:** System can present a consent dialog for ad personalization compliant with EEA/UK requirements (UMP/CMP)
- **FR35:** Host can manage their ad consent preferences

### Onboarding

- **FR36:** System can detect first launch and guide the host through initial facility profile setup before scanning

### Feedback & Error Communication

- **FR37:** System can provide audible and/or haptic feedback on successful capture events
- **FR38:** System can display field-level validation errors in Croatian before submission
- **FR39:** System can warn the host when a duplicate guest scan is detected within 24 hours

## Non-Functional Requirements

### Performance

- **NFR1a:** MRZ capture-to-parsed-data display must complete within 3 seconds on mid-range Android devices (Snapdragon 600-series or equivalent, 2022+, release build)
- **NFR1b:** OCR fallback capture-to-parsed-data display must complete within 5 seconds on the same device class
- **NFR2:** Time-to-first-feedback after capture (e.g., "Reading document…") must be under 1 second — perceived progress reduces wait anxiety
- **NFR3:** Guest queue list rendering must remain smooth (no sustained jank) with up to 50 guests in a single session
- **NFR4:** App cold start to camera-ready state must complete within 5 seconds on mid-range devices (release build, subsequent launches — first install may be slower)
- **NFR5:** Warm resume (app backgrounded → foregrounded) to camera-ready must complete within 2 seconds
- **NFR6:** eVisitor API submission per guest: client-side timeout of 15 seconds; user-visible progress indicator during submission; retry available immediately on timeout
- **NFR7:** Review card field editing must have no perceptible input lag relative to system keyboard
- **NFR8:** App must remain responsive during background API submission — UI thread never blocked by network operations

### Security

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

### Integration

- **NFR19:** eVisitor API session management must handle cookie expiry (401, redirect-to-login, empty session) transparently — re-authenticate and replay failed request without user intervention or data loss
- **NFR20:** eVisitor API failures must never result in loss of queued guest data — queue persists through API errors, app crashes, and process death (SQLite/Drift with WAL)
- **NFR21:** eVisitor API retry policy must use exponential backoff with jitter on 429/503/timeout responses — no retry storms
- **NFR22:** App must gracefully degrade when eVisitor API is unreachable — all capture, review, and queue functions remain operational offline
- **NFR23:** ML Kit text recognition must function without network connectivity (on-device bundled model, no cloud API dependency)
- **NFR24:** AdMob integration must not block or delay core app functionality — ads load asynchronously, never interrupt capture or submission flows, and no full-screen interstitials during capture or submission sequences

### Reliability

- **NFR25:** Crash-free session rate must be ≥ 99.5% as measured by Firebase Crashlytics over trailing 28 days (target applies after first public release stabilization)
- **NFR26:** Guest state machine must be recoverable after process death — no guest stuck in transient state (sending) after app restart; resume or roll back to last stable state
- **NFR27:** After crash or process death, app must restore the user's session context (active facility, queue position) — not just data survival but continuity of workflow
- **NFR28:** Queue data must survive app updates without data loss
- **NFR29:** Duplicate submission prevention — system must not submit the same guest twice to eVisitor even after crash recovery or retry (idempotency key or server-side dedup check)
