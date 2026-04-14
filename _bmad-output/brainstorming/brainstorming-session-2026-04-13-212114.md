---
stepsCompleted: [1, 2]
inputDocuments: []
session_topic: 'Mobile-only eVisitor guest check-in: scan ID/passport, extract fields, submit to eVisitor (problem space similar to PrijaviTuriste / mVisitor)'
session_goals: 'Ship a working application; native mobile constraints only (no web-first requirement)'
selected_approach: 'progressive-flow'
techniques_used:
  - 'What If Scenarios'
  - 'Mind Mapping'
  - 'SCAMPER Method'
  - 'Decision Tree Mapping'
ideas_generated: 18
context_file: ''
---

# Brainstorming Session Results

**Facilitator:** Darko
**Date:** 2026-04-13

## Session Overview

**Topic:** Mobile-only eVisitor guest check-in: scan ID/passport, extract fields, submit to eVisitor (problem space similar to PrijaviTuriste / mVisitor).

**Goals:** Deliver a **working** application--not a paper prototype--within a **mobile-only** product boundary.

### Context Guidance

_No external context file was supplied._

### Session Setup

Scope locked to **native mobile** (iOS/Android). Comparable products: [PrijaviTuriste](https://evisitor-checkin.web.app/), [mVisitor](https://mvisitor.hr/)--used as reference for features and UX expectations, not as copy targets. Technique path: **Progressive Technique Flow** (broad -> patterns -> refine -> plan).

## Technique Selection

**Approach:** Progressive Technique Flow
**Journey:** Exploration -> patterns -> refinement -> implementation branching.

| Phase | Technique | Role |
|-------|-----------|------|
| 1 | What If Scenarios | Maximum divergence; stress assumptions |
| 2 | Mind Mapping | Cluster and name themes |
| 3 | SCAMPER | Compress to shippable MVP slices |
| 4 | Decision Tree Mapping | Explicit next spikes and decisions |

**Rationale:** You need a **working** mobile app, so we force weird cases and business angles early (Phase 1), then organize (2), cut scope (3), and serialize engineering bets (4).

### Phase 1 -- Complete (partial; user advanced early)

_Technique: What If Scenarios_

**[Product #1]: Host-Only Gate**
_Concept_: Only the host device/account performs check-in; guests never complete submission themselves.
_Novelty_: Cuts an entire product surface (guest links, QR self-flow) and narrows abuse/GDPR/consent story vs. self-check-in competitors.

**[Pipeline #1]: MRZ-First, OCR-Second**
_Concept_: Parse MRZ when present for structured fields and checksums; escalate to full-document OCR when MRZ is absent or confidence is low.
_Novelty_: Optimizes for passports/ICAO docs first; forces explicit UX for "no MRZ" docs instead of pretending one pipeline fits all.

**[Gating #1]: Block Submit Until Host Edits**
_Concept_: If extraction confidence is low or fields conflict, submission stays disabled until the host explicitly corrects/confirms fields.
_Novelty_: Aligns with "no silent poison in eVisitor" and pairs with MRZ/OCR fallback without auto-trusting garbage.

**[Multi-Tenancy #1]: Hot-Swap Facility Profiles (v1 Core)**
_Concept_: Host stores credentials for all facilities once; a persistent **Facility Toggle** switches active context in under a second--no full logout/retype between guests.
_Novelty_: Makes multi-property viable in peak season; local encrypted token/credential storage is the enabling constraint, not polish.

**[Multi-Tenancy #2]: Per-Facility Defaults**
_Concept_: Each facility profile carries its own defaults (object category, default arrival/departure windows, bound eVisitor API credentials/keys). One switch reloads the entire submission context.
_Novelty_: Removes "think per unit" under stress; encodes that eVisitor is not one flat account in real host life.

**[Queue #1]: Scan-First, Assign-and-Send-Later ("The Queue")**
_Concept_: Decouple physical capture at the door from admin: scan many guests rapidly regardless of active profile; buffer locally; later UI assigns each buffered guest to a facility and confirms send.
_Novelty_: Solves "switching accounts between guests in the sun" by splitting **throughput** from **routing**--offline-first friendly.

**[Integrity #1]: Duplicate Scan Soft Warning**
_Concept_: Same document scanned twice within 24h on this device -> discrete prompt: already scanned today; proceed anyway?
_Novelty_: Cheap guardrail against the common double-submit chaos without hard-blocking edge cases.

**[Scope-Negative #1]: v1 Explicit Non-Goals**
_Concept_: No cross-OIB / multi-legal-entity in one session; no ML auto-routing guest->unit; no analytics beyond Sent/Failed.
_Novelty_: Protects an 8-week ship by refusing the riskiest "magic" features.

**[Positioning #1]: "Smart Scanner with a Queue"**
_Concept_: v1 success = fast capture + deferred assignment + one-tap per-profile push to eVisitor when the network and the host are ready.
_Novelty_: Product sentence that sales engineers and implementers can agree on; implies architecture (buffer, profiles, retry).

---

### Phase 1 -- Open threads (for Mind Map / SCAMPER)

- Keychain/biometric boundary for encrypted credential blobs; rotation if facility password changes.
- Queue item states: captured -> assigned facility -> ready to send -> sent/failed (and conflict with "block submit" on bad fields *before* queueing vs allow queue with validation gate at send--worth one decision).
- eVisitor API failure modes vs "buffer forever" policy (TTL, visible stale queue).

---

### Phase 2 -- Complete

_Technique: Mind Mapping_

**Center:** Smart Scanner with a Queue

**Branch 1 -- CAPTURE (door-side speed)**
- MRZ parser (ICAO 9303)
- OCR fallback (full doc region detect)
- Confidence score per field
- Camera UX: guide overlay, torch, auto-shutter on MRZ detect
- Gallery import (photo already taken)
- Decision: on-device vs cloud vision (latency vs accuracy)

**Branch 2 -- QUEUE (the buffer)**
- States: captured -> fields_confirmed -> facility_assigned -> ready -> sending -> sent / failed
- Validation gate between captured and fields_confirmed (host edits here)
- Facility assignment as separate step (batch-assignable)
- Offline-first: persists across app kill / reboot
- Open: queue item TTL / stale cleanup

**Branch 3 -- PROFILES (multi-facility)**
- Hot-swap toggle (top bar, sub-second context switch)
- Per-profile: eVisitor credentials, object category, default dates
- Encrypted local storage (Keychain / Android Keystore)
- Credential lifecycle: re-auth prompt on expiry
- Scope: single OIB only in v1

**Branch 4 -- eVISITOR TRANSPORT (the API layer) -- RISK RESOLVED**
- Official REST API at .../eVisitorRhetos_API/Rest/Htz
- Auth: ASP.NET Forms Auth (username + password -> .ASPXAUTH session cookie)
- Payload: REST + JSON for auth, XML string body for ImportTourists
- Dio + persistent cookie jar (proven pattern)
- No OAuth, no API key, no TAN in API layer
- Spike estimate: 1-2 days to confirm round-trip
- Risk assessment: LOW -- documented, stable (2015+ API), no partnership gate

**Branch 5 -- INTEGRITY (trust guardrails)**
- Block submit on low-confidence fields
- Duplicate scan soft warning (24h window)
- Field-level validation (date formats, country codes, doc number checksum)
- Open: local audit log / export for host records

**Branch 6 -- SCOPE FENCE (v1 non-goals)**
- No guest self-check-in
- No cross-OIB
- No auto-routing guest -> facility
- No invoicing / fiscal receipts
- No analytics beyond sent/failed
- No web dashboard

**Risk ranking after transport resolution:**
1. CAPTURE (MRZ/OCR accuracy and speed on real docs)
2. QUEUE (offline state machine correctness)
3. PROFILES (credential encryption + lifecycle)
4. eVISITOR TRANSPORT (low -- documented API)

---

### Phase 3 -- Complete

_Technique: SCAMPER_

#### S -- Substitute (DECIDED)

| # | Substitution | Status | Dev savings |
|---|-------------|--------|-------------|
| S1 | General OCR -> MRZ-only; non-MRZ docs = manual entry | ACCEPTED | ~3 weeks |
| S2 | Live camera view -> Static capture + crop + process | ACCEPTED | ~1-2 weeks |
| S3 | Per-field confidence scoring -> Binary MRZ checksum pass/fail | ACCEPTED (mandatory) | ~1 week |
| S4 | Free-form queue batch-assign -> Session-based auto-assign to active facility + per-guest "Re-assign" dropdown before send | COMPROMISE | Net zero |

**S4 detail (the compromise):**
- Host taps "Start Scanning" and picks facility -> all scans auto-tagged to that facility
- "Finish" closes the scanning session
- Before send: guest list shows each guest with a facility dropdown to re-assign if needed
- No complex batch-sorting UI; no drag-and-drop; just one dropdown per row
- Covers 90% of "wrong facility" errors at minimal implementation cost

#### C -- Combine (DECIDED)

| # | Combine | Into | Status |
|---|---------|------|--------|
| C1 | Scan session + Queue | Single "Scan Session List" screen | ACCEPTED |
| C2 | MRZ result + edit form | Single review card (two states: read-only vs editable) | ACCEPTED |
| C3 | Profile switcher + scan start | "Start Scanning" = pick facility; app is "neutral" between sessions | ACCEPTED (winner) |

**C3 "Neutral App" detail:** No persistent facility toggle in top bar. Facility context exists only inside a scan session. Prevents "forgot to switch" bug by design (Poka-yoke).

#### A -- Adapt (DECIDED)

| # | Adapt from | Apply as | Status |
|---|-----------|----------|--------|
| A1 | Airline boarding gate | Sound + haptic on MRZ pass/fail; host doesn't look at screen for happy path | ACCEPTED (winner) |
| A2 | Banking KYC doc detection | Host picks "Passport" or "ID Card" before scan (moved to E -- simplified to manual pick) | REPLACED by E2 |
| A3 | POS batch close | "Close session + Send all" as end-of-session action | ACCEPTED (merged into flow) |

#### M -- Modify / Magnify (DECIDED)

| # | Modify | Status |
|---|--------|--------|
| M1 | Rich sound/haptic feedback loop (scan -> beep -> next = 3s muscle memory) | ACCEPTED |
| M2 | Map eVisitor error codes to human Croatian sentences | ACCEPTED |
| M3 | 30-day local session history (read-only, proof of submission) | ACCEPTED |

#### P -- Put to other uses (DECIDED)

All deferred to v2+: tourist tax calculation, fiscal receipts, guest history across seasons, TZ dashboards. **Scope fence holds.**

#### E -- Eliminate (DECIDED)

| # | Eliminate | Rationale |
|---|-----------|-----------|
| E1 | Gallery import | Live capture only; gallery = ambiguity + security concern. v1.1 if demanded. |
| E2 | Doc type auto-detection | Host picks Passport / ID Card manually. Two buttons. Removes vision model. |
| E3 | Offline auto-retry | Host taps Send manually. No background daemon. State machine stays simple. |
| E4 | Multi-device sync | Single device per account for v1. No cloud sync of queue/sessions. |

#### R -- Reverse / Rearrange (DECIDED)

| # | Reverse | Status |
|---|---------|--------|
| R1 | Review card = primary screen after scan (not queue list first) | ACCEPTED |
| R2 | Defer eVisitor login until first Send (not app launch) | ACCEPTED |

#### SCAMPER -- Final v1 Flow

```
[App neutral] -> "Start Scanning" (pick facility)
  -> Pick doc type (Passport / ID Card)
    -> Static capture + crop
      -> MRZ parse
        -> PASS: Review card (read-only, beep + haptic) -> Confirm -> session list
        -> FAIL: Review card (editable fields, error sound) -> Host edits -> Confirm -> session list
  -> (repeat for next guest)
  -> "Finish Session"
-> Session list: per-guest re-assign dropdown if needed
-> "Send All" (triggers eVisitor login if first time)
  -> Batch submit via REST + cookie auth
  -> Per-guest status: sent / failed (Croatian error messages)
-> 30-day local history (read-only)
```

**Eliminated:** general OCR, live camera, confidence UI, gallery import, doc type auto-detect, background retry, multi-device sync, all v2 features.

**Added via SCAMPER:** neutral app state, auditory/haptic feedback loop, deferred auth, Croatian error mapping, 30-day history.

---

### Phase 4 -- Complete

_Technique: Decision Tree Mapping_

#### Platform decision: Android-only for v1

- Eliminates iOS Keychain, Apple review, and dual-platform testing
- Encrypted storage: EncryptedSharedPreferences / Android Keystore only
- Flutter still valid (cross-platform later) OR native Kotlin — tech stack TBD
- Cuts release prep by ~1 week (no Apple review cycle)

#### Engineering sequence (8 weeks, Android-only)

**Week 1 — SPIKE: eVisitor API round-trip**
- Login (OIB + password -> .ASPXAUTH cookie via Dio + cookie jar)
- ImportTourists (minimal XML, 1 guest)
- Deliverable: proven API client (login + submit + logout)
- Gate: if API fails, escalate immediately; all other work continues in parallel

**Week 2-3 — CAPTURE: MRZ pipeline**
- MRZ library decision (ML Kit free vs paid SDK — 2-day spike with real docs)
- ICAO 9303 parser: TD1 (ID cards), TD2, TD3 (passports) + check digit validation
- Static capture: camera plugin -> take photo -> crop -> MRZ pipeline
- Host picks Passport / ID Card -> hints expected MRZ format
- Deliverable: scan real passport -> structured fields with pass/fail

**Week 3-4 — CORE UX: review card + session flow**
- Review card: two states (read-only on pass / editable on fail)
- Sound + haptic feedback on scan result
- Session flow: Start Scanning (pick facility) -> scan loop -> Finish Session
- Session list with per-guest facility re-assign dropdown
- Deliverable: full scan -> review -> session list (no send yet)

**Week 4-5 — PROFILES: multi-facility + encrypted storage**
- Profile CRUD (add/edit/delete facility with credentials + defaults)
- Android Keystore / EncryptedSharedPreferences for credential blobs
- Facility picker integrated into "Start Scanning"
- Deliverable: multi-facility profiles with encrypted credentials

**Week 5-6 — SEND: batch submit + error handling**
- Deferred auth: login on first "Send All" with selected facility's credentials
- Batch submit: per-guest XML build -> ImportTourists -> status update
- Error mapping: eVisitor codes -> Croatian human sentences
- Failed guests: stay in list with "Retry" + edit option
- Deliverable: end-to-end flow against real eVisitor

**Week 6-7 — INTEGRITY + POLISH**
- Duplicate scan warning (24h window)
- Field validation (dates, ISO 3166 country codes, doc number format)
- 30-day session history (local SQLite/Hive, read-only)
- Error states: no network, eVisitor down, invalid/expired credentials
- Edge cases: app killed mid-session, rotation, permissions
- Deliverable: hardened app, all guardrails active

**Week 7-8 — TESTING + RELEASE**
- Real-document testing (passports from multiple countries)
- Multi-facility scenario testing
- eVisitor submission verification
- Performance on low-end Android devices
- Play Store prep (screenshots, description, privacy policy)
- Deliverable: Play Store-ready build

#### Critical path
- Week 1 spike unblocks everything
- Week 2-3 MRZ library fork is biggest technical decision
- Android-only removes ~1 week of platform parity work

#### v1 scope contract

**In:** MRZ-only, static capture, binary checksum, neutral app, session-based scanning, per-guest re-assign, batch send, deferred auth, sound/haptic, Croatian errors, 30-day history, duplicate warning, Android-only
**Out:** general OCR, live camera, confidence UI, gallery import, doc auto-detect, auto-retry, multi-device sync, iOS, guest self-check-in, cross-OIB, invoicing, analytics, web dashboard

#### Monetization & revenue bar (2026-04-13)

- **Model:** **free app + ads** (e.g. in-app ads / mediation) as the working revenue hypothesis for a public build—not **paid** as the default v1 path.
- **Success expectation:** **coffee money → hobby money** (seasonal, niche utility); **not** a salary-replacement bar—avoids warping scope to maximize ARPU.
- **Build implication:** place ads at **natural breakpoints** (e.g. after send/session), add **EU-appropriate consent/CMP** for ad personalization where required; treat payout above store fees as upside.
