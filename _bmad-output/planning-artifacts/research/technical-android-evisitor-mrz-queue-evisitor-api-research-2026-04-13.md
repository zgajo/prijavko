---
stepsCompleted: [1, 2, 3, 4, 5, 6]
lastStep: 6
inputDocuments:
  - '_bmad-output/planning-artifacts/research/market-mobile-evisitor-guest-check-in-hr-research-2026-04-13.md'
  - '_bmad-output/brainstorming/brainstorming-session-2026-04-13-212114.md'
workflowType: 'research'
research_type: 'technical'
research_topic: 'Android-first eVisitor mobile client: MRZ capture, offline queue/session state, Croatian eVisitor REST (Forms Auth + cookies), encrypted facility credentials'
research_goals: 'Inform the 8-week Android v1 plan (API spike → MRZ → session UX → multi-facility profiles → batch send → integrity): choose/defend stack (Flutter vs Kotlin), integration patterns (Dio + persistent cookies, XML payloads), local persistence (queue, SQLite/Hive), MRZ pipeline (ML Kit + mrz_parser vs commercial SDK), security/storage (Keystore; Jetpack security-crypto deprecation), and monetization tech (AdMob + UMP/CMP for EEA). Align with market differentiation (throughput, session-scoped facility, host-only MRZ) from parallel market research.'
user_name: 'Darko'
date: '2026-04-13'
web_research_enabled: true
source_verification: true
---

# Technical Research: Android eVisitor client (MRZ, queue, Forms-auth REST)

**Date:** 2026-04-13  
**Author:** Darko  
**Research Type:** Technical  

---

## Research Overview

This report is **project-scoped technical research** for **Prijavko**: an **Android-first** native client that **captures travel-document MRZ**, **buffers guests in a local queue** tied to **scan sessions**, **stores per-facility eVisitor credentials** encrypted on-device, and **submits** to Croatia’s **eVisitor REST API** using **ASP.NET Forms Authentication** (session cookie), as defined in the [brainstorming session](_bmad-output/brainstorming/brainstorming-session-2026-04-13-212114.md). It complements the [market research](_bmad-output/planning-artifacts/research/market-mobile-evisitor-guest-check-in-hr-research-2026-04-13.md) by grounding **differentiation claims** (throughput, session facility context, host-only capture) in **implementable architecture and verified libraries**.

**Methodology:** web-verified sources (Google ML Kit, Android Jetpack release notes, Pub.dev, Google Ads consent policy). The **eVisitor HTTP surface** (Rhetos REST, `ImportTourists`, cookie auth) is treated as **product spike truth** from the brainstorm until replaced by your own captured traces.

**Read first:** [Executive Summary](#executive-summary) and [Strategic Technical Recommendations](#strategic-technical-recommendations); earlier sections are structured by the BMAD technical research steps.

---

<!-- Content appended per technical research workflow steps 1–6 -->

## Technical Research Scope Confirmation

**Research Topic:** Android-first eVisitor mobile client: MRZ capture, offline queue/session state, Croatian eVisitor REST (Forms Auth + cookies), encrypted facility credentials  

**Research Goals:** Inform the 8-week Android v1 plan: stack choice, integration patterns, persistence, MRZ pipeline, security storage, ad/consent stack; align with market differentiation and brainstorm scope fence.

**Technical Research Scope:**

- **Architecture Analysis** — mobile offline-first state, session/queue model, transport layer  
- **Implementation Approaches** — Flutter vs Kotlin-only, testing, CI, Play release  
- **Technology Stack** — MRZ/OCR, HTTP, local DB, crypto  
- **Integration Patterns** — REST + cookies, XML bodies, retry semantics  
- **Performance Considerations** — peak-season burst capture, low-end Android  

**Research Methodology:**

- Current web data with rigorous source verification  
- Multi-source validation for critical technical claims  
- Confidence level framework for uncertain information (e.g. undisclosed eVisitor SLA)  

**Scope Confirmed:** 2026-04-13  

---

## Technology Stack Analysis

*Scope: this product, not generic enterprise cloud.*

### Programming Languages

| Option | Role | Notes |
|--------|------|--------|
| **Kotlin** | Primary if Android-only | Matches brainstorm “Android-only v1”; full access to CameraX, ML Kit, Jetpack, Keystore without FFI overhead. |
| **Dart (Flutter)** | Cross-platform later | Single codebase for future iOS; **Week 1–2** must prove **platform channels** or **Dart FFI** for cookie jar + identical TLS behavior vs pure Kotlin. |

**Popular pattern:** Kotlin-first for a compliance-critical, camera-heavy MVP is the lower-risk path; Flutter remains valid if team velocity and shared UI outweigh native integration cost.

**Confidence:** High for “Kotlin is default Android systems language”; Medium for Flutter fit until spike completes.

_Sources: Flutter/Dart ecosystem for MRZ — [mrz_parser on Pub.dev](https://pub.dev/packages/mrz_parser), [flutter_mrz_scanner](https://pub.dev/packages/flutter_mrz_scanner); Kotlin remains Android default per platform docs._

### Development Frameworks and Libraries

| Layer | Kotlin-oriented | Flutter-oriented |
|-------|------------------|------------------|
| **UI** | Jetpack Compose, Material 3 | Flutter Material 3 |
| **Camera / capture** | CameraX + still capture (per SCAMPER: static photo, not live OCR) | `camera` plugin + same |
| **MRZ / OCR** | ML Kit Text Recognition v2 after crop; custom MRZ parse | Same via `google_mlkit_*` packages |
| **HTTP** | OkHttp + cookie store, or Ktor client | **Dio** + [cookie_jar](https://github.com/flutterchina/cookie_jar) + [dio_cookie_manager](https://pub.dev/packages/dio_cookie_manager) |
| **Local DB** | Room | drift / sqflite / isar |
| **MRZ parsing** | JVM port or JNI of ICAO TD1/TD3 parser | **[mrz_parser](https://pub.dev/packages/mrz_parser)** (TD1, TD2, TD3, MRV) |

**Important (verified):** Google’s **Document Scanner API** digitizes/crops documents; it does **not** replace MRZ parsing — you combine **Document Scanner** (or static camera) + **Text Recognition** + **MRZ parser** ([ML Kit Document Scanner](https://developers.google.com/ml-kit/vision/doc-scanner), [Text Recognition v2](https://developers.google.com/ml-kit/vision/text-recognition/v2/android)).

### Database and Storage Technologies

- **Queue + session metadata:** relational model fits **Room** (Kotlin) or **drift/sqflite** (Flutter): guests, session id, facility id, state enum, timestamps, sync error text.  
- **Credential blobs:** encrypt with **Android Keystore**–backed keys; avoid storing raw passwords in plaintext SharedPreferences.  
- **30-day history:** same DB or separate table with retention job.

### Development Tools and Platforms

- **IDE:** Android Studio (Kotlin) or Android Studio + Flutter plugin.  
- **CI:** Gradle-managed unit tests + on-device/instrumented tests for MRZ samples.  
- **Distribution:** Google Play; **Play Integrity** optional later for abuse reduction on ad-supported free tier.

### Cloud Infrastructure and Deployment

- **None for v1** per brainstorm (no backend). All “cloud” is **eVisitor** upstream.  
- **Future:** only if you add sync, analytics backend, or crash reporting — then Kotlin/Flutter both support standard APM (Firebase Crashlytics, etc.) with GDPR review.

### Technology Adoption Trends

- **On-device ML + privacy** aligns with host trust narrative ([market research](_bmad-output/planning-artifacts/research/market-mobile-evisitor-guest-check-in-hr-research-2026-04-13.md)).  
- **Jetpack `security-crypto`:** as of **1.1.0-beta01+**, release notes state APIs were **deprecated in favour of platform APIs and direct Android Keystore use** ([Jetpack Security release notes](https://developer.android.com/jetpack/androidx/releases/security)) — plan migration off convenience wrappers to **Keystore + explicit encryption** (or Tink) for long-lived code.

### Quality Assessment (stack)

| Claim | Confidence |
|-------|------------|
| ML Kit: Document Scanner ≠ MRZ parser | **High** (Google docs) |
| security-crypto deprecation direction | **High** (Jetpack release notes) |
| Flutter Dio + PersistCookieJar pattern | **High** (community + package docs) |
| eVisitor API stability | **Medium** (internal spike; no public SLA cited here) |

---

## Integration Patterns Analysis

### API Design Patterns (eVisitor-shaped client)

The brainstorm specifies:

- **REST** endpoints under `.../eVisitorRhetos_API/Rest/Htz`  
- **Auth:** ASP.NET **Forms** — typically **POST login** → **`.ASPXAUTH` cookie`** on subsequent calls  
- **Payload:** JSON wrapper with **XML string** for `ImportTourists`

**Client pattern:**

1. **Single `Dio`/`OkHttp` instance** with **cookie persistence** (disk) so session survives process death.  
2. **Login** once per “send burst” (or reuse until 401/expired).  
3. **Sequential or bounded concurrent** `ImportTourists` per guest; map transport errors to Croatian strings (product requirement).  
4. **No OAuth/API key** in v1 — cookies are the integration contract.

_Sources: Dio + [PersistCookieJar](https://github.com/flutterchina/cookie_jar) pattern ([Stack Overflow / community writeups](https://stackoverflow.com/questions/69238243/initialize-dio-with-persistent-cookie-at-the-start-of-the-program)); ASP.NET Forms uses cookie sessions (Microsoft stack behavior)._

### Communication Protocols

- **HTTPS only**; pin certificates only if product policy requires (adds operational burden).  
- **HTTP cookies** — watch **SameSite=None; Secure** if server ever sets cross-site rules; mobile app same-origin less fragile than web.

### Data Formats and Standards

- **MRZ:** ICAO 9303 **TD1** (ID cards), **TD3** (passports); checksum validation in parser ([mrz_parser](https://pub.dev/packages/mrz_parser)).  
- **XML:** build minimal valid fragments per eVisitor schema (spike output).  
- **JSON:** for REST wrappers around XML bodies.

### System Interoperability Approaches

- **Point-to-point** only: app ↔ eVisitor. No ESB.  
- **Failure handling:** expose **queue item state** (`failed`) + **Retry** + **Edit** (brainstorm); align with **circuit breaker** pattern on client (backoff, don’t hammer a 503).

### Microservices Integration Patterns

**N/A** for v1 (no services). If you add a backend later: **API Gateway + BFF** for mobile is the common pattern; out of scope.

### Integration Security Patterns

- **Session fixation:** always HTTPS; clear cookie jar on logout.  
- **Credential storage:** **Keystore**-wrapped encryption keys; **BiometricPrompt** optional gate before showing facility credentials.  
- **GDPR:** minimize fields stored locally; define retention for queue items (TTL brainstorm “open thread”).

---

## Architectural Patterns and Design

### System Architecture Patterns

| Pattern | Application |
|---------|----------------|
| **Offline-first** | Queue persists across kill; **no** background auto-retry per SCAMPER — host taps **Send**. |
| **Explicit state machine** | `captured → fields_confirmed → facility_assigned → ready → sending → sent/failed` (brainstorm). |
| **Session-scoped facility** | **“Neutral app”** — facility chosen at **Start Scanning**; reduces wrong-facility submits (market doc poka-yoke). |
| **Hexagonal / ports** | Ports: `MrzCapture`, `EvisitorGateway`, `GuestRepository`; adapters: ML Kit, Dio, Room. |

### Design Principles and Best Practices

- **SOLID:** thin `EvisitorGateway` interface so spike can swap mock/real.  
- **Fail fast:** MRZ checksum fail → editable review card; block send until resolved (brainstorm).  
- **Idempotent UI:** duplicate scan warning (24h) without hard-blocking edge cases.

### Scalability and Performance Patterns

- **Client-side only:** scale = fast MRZ path + small DB queries on low-end phones.  
- **Batch send:** serialize HTTP if server rejects concurrency; measure in spike.

### Integration and Communication Patterns

- Already covered: cookie session, XML payloads.

### Security Architecture Patterns

- **Defense in depth:** Keystore + encrypted DB fields + minimal logging (no PII in crash logs).  
- **Ads (brainstorm):** **Google Mobile Ads** + **UMP SDK** for EEA/UK/Switzerland — Google policy expects a **certified CMP** and **Consent Mode** alignment for personalization/measurement ([Google Ad Manager — CMP](https://support.google.com/admanager/answer/16918505?hl=en), [Consent Mode v2 / EEA](https://support.google.com/google-ads/answer/13695607?hl=en)).

### Data Architecture Patterns

- **Single-device source of truth** (no multi-device sync v1).  
- **Migrations:** Room/drift migrations for queue schema changes.

### Deployment and Operations Architecture

- **Play internal testing** → closed → production.  
- **Remote config:** optional later for ad placements / feature flags — not required for MVP.

---

## Implementation Approaches and Technology Adoption

### Technology Adoption Strategies

- **Week 1 gate:** eVisitor round-trip — if fail, stop feature work and fix transport ([brainstorm](_bmad-output/brainstorming/brainstorming-session-2026-04-13-212114.md)).  
- **Incremental:** MRZ before polish; profiles before wide beta.

### Development Workflows and Tooling

- **Git** + **CI** running unit tests (MRZ parser, state transitions).  
- **Detekt/ktlint** or **dart analyze** + **format**.

### Testing and Quality Assurance

| Layer | What to test |
|-------|----------------|
| **MRZ** | Golden images: glare, skew, partial frame — expect edit path |
| **Parser** | TD1/TD3 checksum vectors (ICAO test samples) |
| **Queue** | Kill app mid-session; reboot; state intact |
| **Transport** | Mock server returning eVisitor-shaped errors → Croatian mapping |

### Deployment and Operations Practices

- **Staged rollout** on Play (countries: HR primary).  
- **Monitoring:** Firebase Crashlytics (PII scrubbing policy).

### Team Organization and Skills

- **Android** (camera, Keystore, Play), **HTTP/debugging** (Charles/mitmproxy for spike), **Croatian copy** for errors.

### Cost Optimization and Resource Management

- **OSS first:** ML Kit + mrz_parser vs **commercial MRZ SDKs** (Scanbot, Dynamsoft) if accuracy insufficient — budget trade-off ([Dynamsoft Flutter MRZ tutorial](https://www.dynamsoft.com/codepool/flutter-mrz-scanner-android-ios.html) as example vendor path).

### Risk Assessment and Mitigation

| Risk | Mitigation |
|------|------------|
| MRZ OCR weak on some devices | Edit path; optional paid SDK; torch + capture UX |
| Cookie/session expiry mid-batch | Re-login prompt; preserve queue |
| security-crypto deprecation | Move to Keystore + direct crypto per Google guidance |
| Ad policy / consent | UMP + certified CMP; test EEA flows |

### Technical Research Recommendations (implementation)

#### Implementation Roadmap (aligned to brainstorm)

1. **Spike:** login + cookie + one `ImportTourists`  
2. **MRZ:** static capture → ML Kit text → parse + checksum  
3. **UX:** session flow + review card + sounds/haptics  
4. **Profiles:** encrypted credentials + facility picker  
5. **Send:** batch + errors + retry  
6. **Integrity:** duplicate warning, 30-day history, edge cases  

#### Technology Stack Recommendations

| Area | Recommendation |
|------|----------------|
| **Default** | **Kotlin + Compose + CameraX + Room + OkHttp/Ktor** unless Flutter team speed is decisive |
| **MRZ** | ML Kit Text Recognition v2 + **mrz_parser** (Flutter) or JVM parser (Kotlin) |
| **HTTP** | Persistent cookie jar + single client instance |
| **Secrets** | Android Keystore + avoid deprecated convenience APIs long-term |
| **Ads/consent** | AdMob + UMP ([policy context](https://support.google.com/admanager/answer/16918505?hl=en)) |

#### Skill Development Requirements

- ICAO MRZ edge cases; ASP.NET cookie behavior; Play data safety form for ID data.

#### Success Metrics and KPIs

- **Spike:** 100% login+submit success on test account  
- **MRZ:** checksum pass rate on sample set; edit rate by document type  
- **Prod:** submit success rate, time-to-send, Crash-Free Sessions  

---

# Android eVisitor Client: Comprehensive Technical Research (Synthesis)

## Executive Summary

Building a **host-only, Android-first** eVisitor client boils down to four engineering pillars: **(1)** a reliable **MRZ capture → parse → checksum → edit** path using **ML Kit** (and optionally commercial SDKs if free-tier accuracy fails); **(2)** **cookie-based session** integration with Croatia’s **Forms-auth REST** surface, implemented with **persistent cookie storage** (e.g. Dio + `PersistCookieJar` on Flutter, OkHttp cookie jar on Kotlin); **(3)** an **offline-first queue and session state machine** with **encrypted facility credentials** using **Android Keystore**, noting Jetpack **security-crypto**’s move to deprecate convenience APIs in favor of **direct Keystore** use ([Jetpack Security release notes](https://developer.android.com/jetpack/androidx/releases/security)); **(4)** **monetization** via ads requires **Google-certified CMP** / **UMP**-style consent for EEA traffic ([Google CMP help](https://support.google.com/admanager/answer/16918505?hl=en)). The **Week 1 API spike** remains the critical path gate before scaling UI work ([brainstorm](_bmad-output/brainstorming/brainstorming-session-2026-04-13-212114.md)).

**Key Technical Findings:**

- **ML Kit Document Scanner** helps **capture/crop**; **MRZ extraction** still needs **Text Recognition** + **ICAO parser** ([ML Kit Document Scanner](https://developers.google.com/ml-kit/vision/doc-scanner), [Text Recognition v2](https://developers.google.com/ml-kit/vision/text-recognition/v2/android)).  
- **Dart ecosystem** exposes **[mrz_parser](https://pub.dev/packages/mrz_parser)** and **[flutter_mrz_scanner](https://pub.dev/packages/flutter_mrz_scanner)** for faster integration; production teams sometimes buy **Scanbot/Dynamsoft** MRZ modules for accuracy.  
- **EncryptedSharedPreferences / security-crypto** direction is **deprecation toward Keystore** — design storage accordingly ([Jetpack Security](https://developer.android.com/jetpack/androidx/releases/security)).  
- **Cookie auth** with Dio is a **solved pattern**; edge cases are **persistence timing** and **server cookie formats** ([cookie_jar](https://github.com/flutterchina/cookie_jar)).  

**Technical Recommendations:**

1. **Ship spike first** — login + `ImportTourists` + cookie persistence.  
2. **Kotlin default** unless Flutter ownership is strong; re-evaluate after MRZ + HTTP spike in chosen stack.  
3. **Parser + checksum in unit tests**; ML Kit in instrumented tests.  
4. **Plan Keystore-first secrets**; treat `security-crypto` as transitional if used at all.  
5. **UMP + policy-compliant ads** before public HR + EEA rollout.  

---

## Table of Contents

1. [Research Overview](#research-overview)  
2. [Technical Research Scope Confirmation](#technical-research-scope-confirmation)  
3. [Technology Stack Analysis](#technology-stack-analysis)  
4. [Integration Patterns Analysis](#integration-patterns-analysis)  
5. [Architectural Patterns and Design](#architectural-patterns-and-design)  
6. [Implementation Approaches and Technology Adoption](#implementation-approaches-and-technology-adoption)  
7. [Executive Summary](#executive-summary)  
8. [Strategic Technical Recommendations](#strategic-technical-recommendations)  
9. [Technical Risks and Mitigations](#technical-risks-and-mitigations)  
10. [Source Documentation](#source-documentation)  
11. [Technical Research Conclusion](#technical-research-conclusion)  

---

## Strategic Technical Recommendations

| Priority | Recommendation |
|----------|----------------|
| **P0** | Complete **eVisitor transport spike** (cookie session + XML import) before parallel feature development. |
| **P0** | Implement **MRZ checksum gate** + **manual edit** — never silent bad data to eVisitor. |
| **P0** | **Encrypt credentials** with **Keystore**; avoid plaintext password storage. |
| **P1** | **Room/sqflite** schema for queue + sessions; test **process death** and **migration**. |
| **P1** | **UMP/consent** path for ad-supported model in EEA ([Google Ads consent updates](https://support.google.com/google-ads/answer/13695607?hl=en)). |
| **P2** | Evaluate **commercial MRZ SDK** only if free pipeline misses accuracy SLA on real passports. |

---

## Technical Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| eVisitor API/session instability | Med | High | Queue + clear retry; user-visible degraded mode |
| MRZ OCR errors | Med | High | Checksum + edit UI; optional commercial SDK |
| Cookie/session edge cases | Med | Med | Logout clears jar; integration tests with real responses |
| Deprecating security wrappers | Low (timeline) | Med | Keystore-first design now |
| GDPR / ads consent | Med (enforcement) | Med | UMP + minimal data collection |

---

## Source Documentation

### Primary web sources (verified 2026-04-13)

- ML Kit — [Document Scanner](https://developers.google.com/ml-kit/vision/doc-scanner), [Document Scanner Android](https://developers.google.com/ml-kit/vision/doc-scanner/android), [Text Recognition v2 Android](https://developers.google.com/ml-kit/vision/text-recognition/v2/android)  
- Jetpack — [Security release notes (security-crypto 1.1.0 / deprecation note)](https://developer.android.com/jetpack/androidx/releases/security)  
- Dart — [mrz_parser](https://pub.dev/packages/mrz_parser), [flutter_mrz_scanner](https://pub.dev/packages/flutter_mrz_scanner)  
- HTTP — [cookie_jar / PersistCookieJar](https://github.com/flutterchina/cookie_jar), [Dio cookie discussion](https://stackoverflow.com/questions/69238243/initialize-dio-with-persistent-cookie-at-the-start-of-the-program)  
- Ads / consent — [Google CMP overview](https://support.google.com/admanager/answer/16918505?hl=en), [Consent Mode v2 / EEA](https://support.google.com/google-ads/answer/13695607?hl=en)  
- Commercial MRZ (example) — [Dynamsoft Flutter MRZ](https://www.dynamsoft.com/codepool/flutter-mrz-scanner-android-ios.html)  

### Internal project sources

- [_bmad-output/brainstorming/brainstorming-session-2026-04-13-212114.md](_bmad-output/brainstorming/brainstorming-session-2026-04-13-212114.md) — SCAMPER flow, API assumptions, 8-week plan  
- [_bmad-output/planning-artifacts/research/market-mobile-evisitor-guest-check-in-hr-research-2026-04-13.md](_bmad-output/planning-artifacts/research/market-mobile-evisitor-guest-check-in-hr-research-2026-04-13.md) — competitive and JTBD context  

### Limitations

- **eVisitor** public SLA and schema documentation not consolidated here — spike + captured traces are authoritative.  
- **No benchmark** of your app vs PrijaviTuriste/mVisitor — requires device-side trials.  

---

## Technical Research Conclusion

The **lowest-risk v1** is **Kotlin-native Android** with **ML Kit Text Recognition** + **ICAO MRZ parsing**, **Room** for the queue, **OkHttp** with a **persistent cookie store** for Forms auth, and **Keystore-backed** encryption for facility passwords. **Flutter** remains viable if you accept integration-testing cost on **camera + cookies + Keystore**. **Jetpack security-crypto**’s deprecation trajectory favors **direct Keystore** planning. **Ad-supported** revenue requires **UMP/CMP** diligence for **EEA/UK**. **Next step:** execute **Week 1 spike** and lock stack based on measured HTTP + MRZ results.

---

**Workflow status:** technical research steps **1–6** complete.  
**Document:** `/_bmad-output/planning-artifacts/research/technical-android-evisitor-mrz-queue-evisitor-api-research-2026-04-13.md`
