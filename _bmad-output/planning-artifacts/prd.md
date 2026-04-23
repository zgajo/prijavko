---
stepsCompleted:
  - step-01-init
  - step-02-discovery
  - step-02b-vision
  - step-02c-executive-summary
  - step-03-success
  - step-04-journeys
  - step-05-domain
  - step-06-innovation
  - step-07-project-type
  - step-08-scoping
  - step-09-functional
  - step-10-nonfunctional
  - step-11-polish
  - step-12-complete
classification:
  projectType: mobile_app
  domain: general
  domainOverlay: govtech-integration + GDPR/privacy compliance
  complexity: high
  projectContext: greenfield
inputDocuments:
  - _bmad-output/planning-artifacts/product-brief-prijavko.md
  - _bmad-output/planning-artifacts/product-brief-prijavko-distillate.md
  - _bmad-output/planning-artifacts/research/technical-evisitor-auth-lifecycle-research-2026-04-22.md
  - _bmad-output/brainstorming/brainstorming-session-2026-04-22-2127.md
documentCounts:
  briefs: 2
  research: 1
  brainstorming: 1
  projectDocs: 0
workflowType: 'prd'
---

# Product Requirements Document - prijavko

**Author:** Darko
**Date:** 2026-04-22

## Executive Summary

Prijavko is an Android (Flutter) app that lets Croatian private-accommodation hosts register their guests in the national eVisitor system in seconds — from the doorway, on spotty Wi-Fi, without losing a submission to a dead session or a batch-rejection. Target market: ~110–125k registered private-accommodation objects (realistic phone-first solo-host TAM 30–60k). Primary persona is the 1–3-apartment landlord; secondary is the 3–15-unit family operator.

The job today is broken by its era: desktop-first portals retrofitted onto phones, official apps that fail silently when a session expires, batch submissions that reject four guests because of one bad field, and PMS-grade tools priced for operators ten times larger. Missed registrations trigger fines; disputed submissions rot for days; every redundant data-entry is a chance to type the wrong passport number into the national database.

Prijavko is a single-purpose registration tool built with the host's real working conditions as a first-class design constraint: MRZ-first capture with static-tap and manual-entry fallbacks, a semantic sanity layer on top of MRZ checksums, a fail-safe ephemeral queue (3-day soft-undo then auto-purge — eVisitor is the authoritative store), an explicit manual Send All with per-guest success/failure, opportunistic auth checks that surface credential problems hours before the door, and a post-submit closure summary that carries zero PII.

**Why now.** In May 2026, Croatia's new apartment registration-number mandate takes effect, raising compliance stakes for every private host. On-device MRZ OCR, NFC chip reads, and a stable-if-undocumented eVisitor Rhetos API make the tooling gap cheaper to close than it has ever been.

### What Makes This Special

Prijavko's differentiation is execution-shaped, not feature-shaped. Three reinforcing bets:

1. **A reliability thesis no incumbent has committed to.** Every design decision optimizes for "the host just got home at midnight — did all four guests actually register?" Observable, not aspirational: a six-state auth machine that cannot enter invalid states; a `QueuedInterceptor` that serializes re-auth so concurrent 401/400s trigger exactly one login; a Rhetos-aware error classifier that reads HTTP 400 + `SystemMessage` as session-dead (the naive "retry on 401" interceptor from any Dio tutorial silently fails against eVisitor); a semantic sanity layer catching 1899-02-30 birthdays before they reach the API; a CI-enforced zero-PII log guard at the type level; a `scan_to_submit` Crashlytics custom event with `corrections_count` so the reliability claim is measurable in the field.

2. **Zero-retention privacy as a moat.** Guest passport data never persists on the phone after submission — 3-day soft-undo buffer, then gone. eVisitor is the authoritative store; the phone is a transient courier. No other tool in this market can credibly say this, and it is the one GDPR sentence a TZ can safely repeat to its hosts.

3. **A build advantage from being tiny.** Solo Flutter build, Android-first, shippable in ~5 weeks. Incumbents have web + mobile + backend surfaces to maintain; prijavko ships one app that does one thing. This is also the answer to an eventual HTZ competitive response: out-ship, don't out-feature.

**Core insight.** The eVisitor integration gap is not a UI problem — it is a silent-failure problem. The real job is not "scan faster"; it is "make the host feel certain the submission actually happened, even when it is 21:30 on Wi-Fi that is about to drop."

## Project Classification

- **Project Type:** Mobile app (Android-first, Flutter, min API 24+; iOS and guest-facing web surface explicitly deferred to v1.1+)
- **Domain:** General consumer utility with a govtech-integration surface (Croatian National Tourist Board / HTZ eVisitor Rhetos API) and a GDPR / sensitive-data compliance overlay (passport/MRZ data → Play Store Data Safety declaration, privacy policy, ToS liability disclaimer)
- **Complexity:** High — driven by (a) an undocumented, quirky external API with HTTP 400-masquerading-as-401 semantics, 5-fail server-side lockout, no refresh token, and Croatian-language error envelopes; (b) regulated data (passports) with Play Store manual-review exposure; (c) offline-aware explicit-send queue with idempotency and 3-day auto-purge; (d) Poka-yoke design discipline throughout (type-enforced PII redaction, six-state auth machine, QueuedInterceptor re-auth serialization); (e) solo-dev 5-week timeline against a hard May 2026 regulatory deadline
- **Project Context:** Greenfield (no existing code; Product Brief, Distillate, and eVisitor auth-lifecycle research completed 2026-04-22)

## Success Criteria

### User Success

A prijavko user succeeds when the door-side registration stops being a source of stress. Concretely:

- **The door-moment outcome.** A four-guest check-in at 21:30 on flaky Wi-Fi ends in under 60 seconds with an explicit, per-guest success confirmation and a post-submit closure summary the host can screenshot. No silent "did-it-send?" anxiety. No "I'll check tomorrow on desktop" deferrals.
- **The no-surprise guarantee.** Session-dead is never discovered at the door — the opportunistic auth check + non-blocking credential banner + Send-All pre-flight catch auth problems hours earlier.
- **The "one bad passport" guarantee.** One rejected guest does not kill the other three. Per-guest success/failure on Send All is the observable form of this promise.
- **The zero-PII-footprint guarantee.** After submission, no passport data persists on the phone beyond the 3-day soft-undo buffer. Hosts can hand their phone to a guest, spouse, or tax inspector without leaking the last customer's documents.

**Qualitative success signals** (Play Store reviews, beta feedback):
- "It just worked at 11pm"
- "I didn't have to retype anything"
- "I could see exactly which guest the problem was"
- "I actually trust this for peak season"

### Business Success

**Leading indicators** (controllable, checked monthly from July 2026):

| Metric | Target | Rationale |
|---|---|---|
| Weekly active hosts (July 2026) | ≥500 | First peak-season traction signal; ~1% of phone-first TAM |
| Play Store reviews ≥4★ | ≥50 by end of August 2026 | Closed-beta Day-0 reviews (10) + organic must compound 5× in 8 weeks |
| Play Store average rating | ≥4.5 | Trust is the moat; a passport-handling app cannot survive low ratings |

**12-month north-star signals** (Play Store public launch + 12 months):

| Metric | Target | Why |
|---|---|---|
| Installs | 5,000+ | ~5–15% of realistic phone-first-solo-host TAM (30–60k); beachhead scale |
| 3-month retention | ≥40% | Seasonal tool; anyone still registering at month 3 is a real user, not a tourist download |
| Paid-unlock conversion (v1.1 Pro IAP) | ≥5% of active users | Validates willingness-to-pay; revenue-reality goal, not a revenue-target goal |

**Revenue reality check.** Year-1 commercial goal is **validate willingness-to-pay**, not hit a revenue number. AdMob at 5k users + Croatia eCPM ≈ €800–€1,500/year. €4.99 Pro IAP × 5% of 5k ≈ €1,250 one-off. Total year-1 revenue envelope is sub-€3k. This is a validation budget, not a business case.

**Kill criteria (2026-09-30 checkpoint).** Any one triggers a planned sunset rather than a sunk-cost drift into year two:
- <1,000 installs
- OR <3.5 Play Store rating
- OR <10% retention at month 3

### Technical Success

**Reliability (the headline promise, measurable):**

| Metric | Target | Measurement |
|---|---|---|
| First-time submission success rate | ≥90% without field corrections | Crashlytics custom event `scan_to_submit`; denominator = guests that reached Send All; success = `corrections_count == 0` AND eVisitor returned 2xx |
| Crash-free session rate | ≥99.5% | Firebase Crashlytics, zero-PII telemetry |
| Silent-failure rate (auth classifier false negatives) | 0 confirmed cases in peak season | Manual triage of every "I submitted but it didn't arrive" review + integration-test harness covering HTTP 400-SystemMessage variants |
| Zero-PII log guarantee | 0 CI grep-guard violations across all merged commits | Build-blocking CI check on forbidden log patterns (documentNumber, firstName, MRZ line, etc.) |

**Compliance (non-negotiable before launch):**

| Milestone | Deadline | Status gate |
|---|---|---|
| Play Store Data Safety declaration submitted | Before 2026-05-27 | Sensitive-data manual review accepted |
| Privacy policy published (public URL) | Before 2026-05-27 | Linked in Play Store listing + in-app Settings |
| ToS with liability disclaimer published | Before 2026-05-27 | Host is sole legal data controller; fines from app failure are not prijavko's liability |
| May 2026 registration-number mandate payload support | Before first mandate-effective check-in (TBD, May 2026) | Week-1 spike must confirm exact payload change; blocker if unresolved |
| AdMob + UMP/CMP EU consent | Before 2026-05-27 | EEA consent surface on first launch |

**Auth lifecycle correctness (from technical research):**
- Six-state auth machine covers `initial → unauthenticated → authenticating → authenticated ⇄ reauth`, plus `lockedOut(retryAfter)` and `authFailure(reason)`. Invariant-enforced (no invalid state transitions).
- `QueuedInterceptor` (not `Interceptor`) serializes re-auth under concurrent 401/400s → exactly one login.
- Error classifier handles HTTP 400 + `SystemMessage` session-dead case (not just 401/403). Integration-test harness covers all three (401, 403, 400+regex) + Croatian-language error keyword variants (`locked|zaključan`, `invalid|nevažeć|neispra`, `session|prijava|auth`).
- Circuit breaker opens after 3 consecutive login failures for 6 minutes → prevents Rhetos 5-fail server-side lockout.

### Measurable Outcomes

The single dashboard (Crashlytics + Play Store Console) must show, at a glance:

1. **Crash-free session rate** (target ≥99.5%)
2. **`scan_to_submit` success rate** (target ≥90% without corrections)
3. **Auth-recovery latency** (time from session-dead detection to next successful submission — target p50 < 30s)
4. **Queue stuck count** (guests in queue > 24h without successful submission — target 0)
5. **Play Store rating** (target ≥4.5)
6. **Weekly active hosts** (target 500+ in July 2026)

## Product Scope

### MVP — Minimum Viable Product (target submission 2026-05-27)

**Irreducible launch floor** — below any of these, slip the date, not the scope:
- Scan → queue → manual Send All → successful submission against real eVisitor
- Six-state auth machine functional with classifier handling HTTP 400-SystemMessage case
- Zero-PII log guarantee enforced at type level + CI grep guard
- Play Store Data Safety declaration + privacy policy + ToS submitted and accepted

**MVP scope (committed):**
- Android-only, Flutter, min API 24+
- MRZ-first capture with auto-shutter → 3-sec static-tap fallback → manual-entry fallback
- Semantic sanity layer on top of MRZ checksums (reject 1899-02-30, invalid ISO country codes, expired docs, unrealistic birth years)
- Encrypted Drift/SQLite queue, client-side UUID at scan time, synchronous commit before success haptic
- Neutral App facility picker with last-used shortcut (no persistent "active facility" toggle)
- Opportunistic background auth check + non-blocking credential banner + pre-flight check on Send All
- eVisitor Forms Auth / Rhetos integration (JSON everywhere, `ImportTourists` XML-as-string in JSON body, `/Date(ms+offset)/` date handling)
- Six-state auth machine + `QueuedInterceptor` re-auth serialization + 3-failure circuit breaker
- Type-enforced zero-PII-in-logs + CI grep guard
- Post-submit closure summary (shareable screenshot, zero-PII)
- Ephemeral local queue: unsent guests persist until submitted; successful submissions held 3 days as soft-undo buffer, then auto-purged
- AdMob + UMP/CMP EU consent
- Firebase Crashlytics (zero-PII)
- In-repo Dio fake as permanent integration-test harness (not just a dev fixture)

**Slip protocol (defer order if 5-week timeline compresses):**
1. Hybrid live-first capture → static-only
2. Opportunistic auth banner → login-on-send (manual refresh only)
3. Replace-Active-OIB setting (schema-ready, UI deferred)
4. Shareable closure-summary screenshot (textual summary only)

### Growth Features (v1.1 — Q3–Q4 2026, post-peak-season)

**Pro one-time IAP (€4.99 reference):**
- Reported-guests history view (server-side eVisitor query API — Week-1 spike must verify endpoint exists; blocker for this feature if not)
- CSV/PDF export of server-side reported history
- **Timestamped compliance receipt** — signed PDF of each submission (when, which guests, which facility); host's legal-defense file against disputed fines
- Ad removal

**Differentiator features:**
- **NFC passport chip read** via `flutter_nfc_kit` — single biggest technical differentiator no incumbent offers
- **Multi-OIB UI** (schema already in place from v1.0 — zero migration)
- **Guest self-scan via link/QR** with family/custodian semantics (~30% of Croatian check-ins are families)
- Home-screen quick-scan widget (conditional on real demand signals)

### Vision (v2+ directional bets — not committed)

- **iOS port** once revenue funds it — natural Flutter payoff, no rewrite
- **Guest-facing Flutter Web surface** — separate from host app; travellers pre-enter data on a personal link ahead of arrival; feeds host's queue on check-in day
- **v1.2+ adjacent eVisitor segments** (same Rhetos API, different UI templates): small-boat/charter yachts, small hostels under ~20 beds, agritourism

**Three-year vision.** Prijavko becomes the default phone-first eVisitor client for any small operator in Croatia's private-accommodation economy — the tool hosts open before they open the door. Trusted enough that tourism boards proactively recommend it. Still free for the single-apartment landlord, still never loses a submission.

## User Journeys

### Journey 1 — First Install & First-Ever Registration (Onboarding)

**Persona: Ana (all primary-host variants start here)**
- 34, owns one inherited studio in Trogir. Registers ~40 guests per season.
- Hates eVisitor web, currently uses the official mVisitor app, lost 6 guests to silent batch rejection last August.

**Opening scene.** Friday morning, 10:15, calm. Ana saw prijavko mentioned in "Iznajmljivači Hrvatske" on Facebook. She installs from Play Store on Wi-Fi at home.

**Rising action.**
1. First launch → UMP/CMP EU consent surface (ad personalization yes/no — Ana taps "yes").
2. Sensitive-data screen: "Prijavko scans passports and sends them to eVisitor. Your data never leaves your phone except to eVisitor. After submission, it is kept 3 days as a safety buffer, then deleted. [Learn more → Privacy Policy]." Single clear OK.
3. Camera permission prompt. Ana allows.
4. eVisitor login screen: `userName`, `password`, `apikey` (with inline help: "Find this in your eVisitor Settings → API"). Ana pastes from 1Password.
5. Login POSTs to `/Resources/AspNetFormsAuth/Authentication/Login`. Rhetos returns `true` + 3 cookies (`authentication`, `affinity`, `language`) into `PersistCookieJar`, encrypted at rest by a Keystore-backed key.
6. Facility-picker screen. Her one OIB has one facility ("Apartman Luna, Trogir"). It's auto-selected; she sees the "last used: Luna" shortcut. One tap → Home screen.

**Climax.** Ana sees the big "Scan Guest" button. It does exactly what she expected. No dashboard, no wizard, no nudge to upgrade.

**Resolution.** She puts the phone back in her pocket. No guests arriving today. Total time from install to "ready": **~90 seconds**.

**Capabilities revealed:** consent flow, credential capture via flutter_secure_storage, login handshake + cookie persistence, facility-picker first load, last-used shortcut, zero-dashboard home.

---

### Journey 2 — Primary Happy Path: 4-Guest Door Check-in

**Persona: Ana again. Three weeks after install. It's 21:30, Saturday, July.**

**Opening scene.** A family of four (two parents, two kids) is at the studio door. Ana opens prijavko. Opportunistic background auth check pinged `/Rest/Htz/Hello` (or similar cheap endpoint) ~4 hours ago when she opened the app; session is live. No credential banner. Home screen shows "Apartman Luna" at the top and a single big "Scan Guest" button.

**Rising action.**
1. Tap Scan → camera. MRZ detection live. First passport: autoshutter fires at 0.8s on valid checksum. Haptic "click." Drift commits the guest synchronously with a client-side UUID before the success indicator shows. Guest 1 of N visible in the "Unsent" row.
2. Second passport: worn, glare. Auto-shutter fails 3 seconds → static-tap fallback surfaces ("Tap to capture"). Ana taps. Capture succeeds. Drift commits.
3. Third passport (child): non-EU layout, MRZ partial. Manual-entry fallback surfaces. Ana types 5 fields in 20 seconds. Semantic sanity layer catches her mistyped birth year `2012` (OK) but would catch `1299` (rejected inline with "Unrealistic year").
4. Fourth passport: smooth live MRZ, done in 1.2s.
5. "Unsent — 4 guests" on screen. Tap **Send All**.
6. Pre-flight: auth still live, network OK. Classifier armed. Submission POSTs `ImportTourists` (XML-as-JSON-string) with `/Date(ms+offset)/` fields.
7. Per-guest progress: `Guest 1 ✓ · Guest 2 ✓ · Guest 3 ✓ · Guest 4 ✓`.

**Climax.** The **Closure Summary**: "4 guests registered at Apartman Luna at 21:47." Zero-PII. Share button. Ana screenshots and texts her husband "✅ done."

**Resolution.** Submitted records enter the 3-day soft-undo buffer. Unsent queue empty. Total door-side time: **~58 seconds**. Ana is at the next apartment 8 minutes later.

**Capabilities revealed:** opportunistic auth check, MRZ-first capture with 3-tier fallback, semantic sanity layer, synchronous Drift commit, Send-All pre-flight, per-guest success reporting, post-submit closure summary, 3-day soft-undo buffer.

---

### Journey 3 — Edge Case: Silent Session Death + Wi-Fi Drop

**Persona: Marko, 48, owns two apartments in Split. Registered ~200 guests so far this season.**

**Opening scene.** 23:10, Wednesday. Marko opens prijavko at the door. The app had been backgrounded for 9 days. The eVisitor cookie is 15+ days old; sliding-window expiration no longer covers it.

**Rising action.**
1. On app resume, the opportunistic auth check hits a cheap authenticated endpoint → HTTP 400 with `{UserMessage: "Niste prijavljeni", SystemMessage: "User is not authenticated"}`. **The naïve "retry on 401" interceptor would miss this entirely.** Prijavko's classifier matches `SystemMessage` against `/not authenticated|unauthorized|session/i` and transitions the auth machine from `authenticated` → `reauth`.
2. Non-blocking **credential banner** appears at the top of the home screen: "⚠️ Your eVisitor session has expired. Tap to reconnect." Marko is at the door with guests watching — he taps once. Prijavko re-POSTs credentials (stored in flutter_secure_storage). Rhetos returns `true`, new cookies written.
3. Marko starts scanning — 2 guests, live MRZ, both committed to Drift.
4. Mid-Send-All, Wi-Fi drops. First guest: timeout. Classifier: network (not auth). Queue entry marked "pending retry." Guest 2 also pending.
5. Marko steps inside, reconnects to apartment Wi-Fi. Opens prijavko. The app does **not** auto-retry (no background flush — explicit-Send-All principle). Home shows "2 Unsent — tap Send All to retry."
6. Tap Send All. Both succeed. Per-guest ✓✓.

**Climax.** Closure summary. Marko realises: had he been using mVisitor, the silent logout would have made him think the first Send had gone through. He'd have found out three days later when a fine arrived.

**Resolution.** Prijavko absorbed two independent failure modes — session dead + Wi-Fi drop — without silent loss.

**Capabilities revealed:** error classifier (HTTP 400 + `SystemMessage` + Croatian regex), six-state auth machine with `authenticated → reauth` transition, `QueuedInterceptor` serialization, non-blocking credential banner, explicit-Send-All (no auto-retry), network vs. auth classification, retry-visibility in UI.

---

### Journey 4 — Edge Case: One Bad Passport in a Batch of Five

**Persona: Ivana, 29, Istra-coast, two studios.**

**Opening scene.** Saturday 19:45. Five-guest group check-in. Ivana scans four passports cleanly. Fifth guest (elderly grandmother) hands her an expired ID card. MRZ checksum passes; the semantic sanity layer flags "Document expired 2024-11-03."

**Rising action.**
1. Prijavko inline-rejects the scan with a Croatian-language explanation: "Isteklo 2024-11-03 — tražite valjani dokument." Ivana politely asks the grandmother for her valid passport. Grandmother retrieves it. New scan, clean.
2. Five guests in queue. Tap Send All.
3. eVisitor rejects guest 3 (unrelated: a field prijavko's sanity layer didn't cover — a newly-introduced May-2026 mandate field Ivana didn't enter because the app's UI for it was behind a feature flag).
4. Per-guest response: `Guest 1 ✓ · Guest 2 ✓ · Guest 3 ✗ (missing apartment registration number) · Guest 4 ✓ · Guest 5 ✓`.
5. Prijavko shows 4 successful + 1 failed. The failed guest is highlighted with an **edit** affordance. Ivana taps, enters the missing field, taps "Resend failed."
6. Guest 3 ✓. Closure summary: "5 guests registered at Villa Mare at 19:58."

**Climax.** Under mVisitor or the eVisitor web portal, the entire batch of 5 would have been rejected on guest 3's missing field. Ivana would have had to re-enter all 5 guests or discover the failure hours later.

**Resolution.** Prijavko's per-guest isolation + retry-failed-only flow reduced a 15-minute salvage operation to 45 seconds.

**Capabilities revealed:** semantic sanity layer (expiry date check), per-guest success/failure rendering, edit-and-retry-failed-only affordance, forward compatibility for May-2026 mandate fields.

---

### Journey 5 — Secondary Persona: Multi-Facility Evening

**Persona: Tomislav, 57, family operator. 8 studios on Pelješac. Wife, two adult children, one OIB. 12 check-ins on a peak Saturday.**

**Opening scene.** 16:00, Saturday. Tomislav is driving between properties. His phone has prijavko open between check-ins.

**Rising action.**
1. At Studio Lumin: taps "Scan Guest." Facility-picker surfaces briefly because this is a new session — "Last used: Villa Petra" is the shortcut; he dismisses it and explicitly picks Lumin. **Neutral App pattern:** he made a conscious facility choice. No persistent "active facility" flag to forget.
2. Scans 2 guests. Sends. Closure summary.
3. Drives to Villa Petra. Opens the app. Same pattern — facility chooser. Last-used is now Lumin; he picks Petra. Scans 3 guests. Sends.
4. By evening, 4 facilities × 8–12 guests registered. Zero wrong-facility submissions.

**Climax.** Tomislav realises that prijavko's deliberate facility-picking friction (one extra tap per session) is precisely what saves him from the catastrophic error he made on eVisitor web in 2025 — he registered 4 guests against the wrong apartment, got fined, spent two weeks contesting it.

**Resolution.** Tomislav files prijavko under "trustworthy tools." After season, he pays €4.99 for the v1.1 Pro unlock because the compliance-receipt PDF is worth more than that in one avoided fine argument.

**Capabilities revealed:** Neutral App facility picker, last-used shortcut as *hint not default*, multi-facility-per-session, wrong-facility avoidance.

---

### Journey Requirements Summary

The five journeys reveal the following capability areas (each capability is traced to one or more journeys — the contract for functional requirements in Step 9):

| Capability Area | Journeys | Contract |
|---|---|---|
| **Onboarding & Consent** | J1 | UMP/CMP EU consent, sensitive-data disclosure, camera permission, eVisitor credential capture, first-login handshake |
| **Auth Lifecycle** | J1, J2, J3 | Six-state machine, QueuedInterceptor re-auth serialization, classifier (HTTP 400 + SystemMessage + Croatian regex), circuit breaker, Keystore-backed credential storage + encrypted cookie jar, opportunistic background check |
| **Capture Pipeline** | J2, J4 | MRZ live detection with auto-shutter, 3-sec static-tap fallback, manual-entry fallback, semantic sanity layer (birth year, country code, document expiry), inline rejection with Croatian-language reason |
| **Queue & Drift Persistence** | J2, J3, J4 | Client-side UUID at scan time, synchronous commit before success haptic, unsent-row visibility, persist across app kill |
| **Facility Picker (Neutral App)** | J1, J2, J5 | Explicit per-session choice, last-used shortcut as hint (not default), no persistent "active facility" flag, facility visible on home |
| **Send All + Pre-Flight** | J2, J3, J4 | Manual-only, no background retry, pre-flight auth + network check, per-guest parallel-or-serial submission, per-guest success/failure rendering, edit-and-retry-failed-only |
| **Credential Banner** | J3 | Non-blocking, surfaces auth drift, single-tap reconnect |
| **Closure Summary** | J2, J3, J4, J5 | Zero-PII, shareable screenshot, facility + count + time |
| **Queue Lifecycle** | All | Unsent: persist-until-submitted; Submitted: 3-day soft-undo, then auto-purge |
| **Error/Network Classification** | J3 | Network vs. auth vs. validation vs. server-error — each produces a different UI affordance |
| **Mandate-Forward Fields** | J4 | May-2026 registration-number field, UI surface pending Week-1 spike |
| **Instrumentation** | All (implicit) | `scan_to_submit` event with `corrections_count`, zero-PII Crashlytics, crash-free session rate, queue-stuck counter |

**What's intentionally NOT a journey in v1.0:**
- Guest self-scan (v1.1 Pre-Queue Inbox — captured as Future Vision in brainstorming)
- Admin / support dashboards (no admin surface — this is a single-user app)
- Multi-OIB switching (schema-ready; UI deferred to v1.1)
- NFC passport chip read (v1.1 differentiator)
- Reported-history view (v1.1 Pro IAP, blocked on server-side endpoint verification)

## Domain-Specific Requirements

### Compliance & Regulatory

**Croatian tourism law.**
- Host is the **sole legal data controller** under Croatian tourism/tourism-tax law (Zakon o boravišnoj pristojbi + Zakon o pružanju usluga u turizmu). Prijavko is a **data processor only for the transient moment of transport to eVisitor**, and a courier thereafter.
- Guest registration is legally mandatory within 24 hours of arrival. The app's explicit-Send-All UX must never introduce a delay path that lets a host inadvertently miss the 24-hour window. The queue-stuck-count > 24h technical metric (target 0) is the observable form of this.
- **May 2026 apartment registration-number mandate** (exact payload change TBD; Week-1 spike is blocker). Every facility submission must carry the new registration number in `ImportTourists`. Schema/UI must be forward-compatible without a breaking v1.0 → v1.1 data migration.

**GDPR (EU 2016/679).**
- Lawful basis: **legal obligation** (Art. 6(1)(c)) for the guest-registration flow (host is fulfilling Croatian tourism-law obligation), not consent. Passport data is a Special Category (Art. 9) only where the specific field would reveal health/biometric — MRZ + standard passport data is not itself Art. 9, but **proximity to Art. 9 warrants Art. 32 security rigor regardless**.
- **Data-minimization by design**: only fields eVisitor requires, no analytics on guest data, no marketing profiling, no third-party SDK receives any guest field.
- **Storage limitation**: 3-day soft-undo buffer post-submission, then AES-GCM-encrypted file is deleted and Drift row is hard-removed. Auto-purge is a scheduled Dart isolate job at app open, enforced regardless of user action.
- **Right to erasure**: trivially satisfied because of zero-retention-by-design — by day 4 there is nothing to erase. Documented in Privacy Policy.
- **Transparency**: in-app "Your Data" screen showing (a) what's currently stored (unsent queue + submitted < 3 days), (b) the 3-day auto-purge, (c) the Privacy Policy URL, (d) "Delete everything now" button (hard wipe of Drift + cookie jar + flutter_secure_storage).
- **DPIA posture**: technically recommended for large-scale/systematic processing of passports, but for a solo-host single-facility operator the scale threshold doesn't apply to prijavko's operator — the host. If prijavko itself hits >5k active users it does not change the DPIA picture because prijavko-the-app is not the controller for the guest data; each host is. Documented in a lightweight "Processor posture statement" referenced from the Privacy Policy.
- **Cross-border transfer**: none. All traffic is host-device → eVisitor (HR). AdMob/Crashlytics traffic carries no guest PII (type-enforced). Crashlytics is US-hosted; covered by SCCs in Firebase ToS — disclosed in Privacy Policy.

**Play Store (Google Play policies).**
- **Data Safety declaration** must list: camera (collected, on-device only, not transmitted), passport data (collected, transmitted to eVisitor, not shared with Google or third parties, retained ≤3 days post-submission), host credentials (collected, encrypted at rest, not transmitted to Google).
- **Sensitive permissions justification** (camera only — no NFC until v1.1).
- **Sensitive-data manual review** expected (1–3 weeks). Submission package must include: live Privacy Policy URL, live ToS URL, feature list with data-handling justification.
- **Target SDK level** per latest Play Store mandate at submission date (2026-05-27). Flutter's default target SDK usually tracks within 1 release of requirement.
- **AdMob policy compliance**: sensitive content + passport-adjacent flow must not serve personalized ads without UMP/CMP consent. Watch for AdMob sensitive-data edge cases; if reviews flag ads as the #1 complaint, trigger the ad-free-free-tier pivot.

### Technical Constraints

**Cryptography & key management (Poka-yoke at the platform level).**
- **Credentials** (`userName`, `password`, `apikey`): stored in `flutter_secure_storage`, Android Keystore-backed, `AES/GCM/NoPadding` with hardware-backed key where available.
- **Cookie jar** (`authentication`, `affinity`, `language`): serialized to an AES-GCM-encrypted file on app-internal storage. Key lives in flutter_secure_storage (Keystore-wrapped).
- **Drift database**: holds queue + facility data only — never auth state, never cookies, never credentials. Passport fields in Drift are AES-GCM-encrypted-at-rest for unsent queue rows; successful-submission rows inside the 3-day buffer are encrypted identically and then hard-deleted on auto-purge.
- **No cloud backup** of any of the above. Android `allowBackup=false` in manifest — explicit opt-out; protects Keystore integrity on device migration at the cost of re-login after a device change. Documented as "accepted residual risk" in the risk register.
- **Certificate pinning** to `www.evisitor.hr` on Dio's HttpClient. Pin set is refreshed via an in-app forced-update banner (no remote config rotation — solo-dev simplicity wins over cert-rotation automation).

**PII discipline (type-level Poka-yoke).**
- All model classes carrying PII override `toString() → "[REDACTED type=X]"`. CI grep guard fails the build on `print`, `debugPrint`, `logger.{d,i,w,e}` calls that reference whitelisted PII field names or type names.
- Crashlytics: zero-PII. Custom events carry counts, facility IDs, error codes — never free-text from guest records.
- Post-submit closure summary: `"N guests at {Facility} at {HH:mm}"` — no names, no documents, no nationalities.

**Observability with zero-PII.**
- Crashlytics events: `scan_to_submit`, `auth_state_transition`, `send_all_result`, `queue_purge`, `classifier_mismatch`.
- Silent-failure tripwire: periodic sanity check that the queue-stuck-count > 24h fires as a zero-PII Crashlytics custom event (not a local notification — solo-dev observability only).
- Integration-test harness (permanent Dio fake) covers: 401, 403, 400+SystemMessage variants (EN + Croatian), Rhetos lockout envelope, Croatian keyword regex set, `ImportTourists` XML-as-JSON-string, `/Date(ms+offset)/` round-trip, cookie-jar-persistence-across-restart, 3-day auto-purge.

**Offline & reliability.**
- App must function without network *except* at Send All. Scan → queue is fully offline.
- Time source: Europe/Zagreb; `DateTime.now().toUtc()` for all timestamps in ImportTourists; facility-local rendering for UI.
- App resume after >14 days of backgrounding: opportunistic auth check → classifier → credential banner if session dead. Never silent failure.

### Integration Requirements

**eVisitor Rhetos API (the single external dependency).**
- Production base: `https://www.evisitor.hr/eVisitorRhetos_API/`
- Test base: `https://www.evisitor.hr/testApi`
- Transport: JSON everywhere. `ImportTourists` is XML-as-string-inside-JSON-body (not pure XML).
- Date format on the wire: `/Date(ms+offset)/` (NOT `YYYYMMDD`).
- Session cookies: `authentication`, `affinity`, `language` — all three must be forwarded.
- **Error classifier contract** (load-bearing — documented in Step 3 success metrics):
  - HTTP 401 or 403 → session dead.
  - HTTP 400 with `SystemMessage` matching `/not authenticated|unauthorized|session/i` → session dead.
  - HTTP 200 with JSON error envelope `{UserMessage, SystemMessage}` at any endpoint other than `/Login` → session dead.
  - Croatian-language keyword regex set (refine in Week 1 spike): `locked|zaključan`, `invalid|nevažeć|neispra`, `session|prijava|auth`.
- **Lockout protection** (Poka-yoke — client-side, never tests the server):
  - Rhetos server-side policy: 5 login failures → 5-minute lockout.
  - Client-side circuit breaker: opens after 3 consecutive login failures, stays open 6 minutes. User sees "Previše neuspješnih pokušaja — pričekajte 6 minuta."
- **No refresh token**: re-auth is always a full re-login with stored credentials. `QueuedInterceptor` serializes concurrent 401/400s so one expiry triggers exactly one login, not N.
- **No public partner API**: the eVisitor Rhetos API is undocumented as a partner surface. HTZ can change auth without notice. Mitigations:
  - Production-canary ping account (minimum-data, monitored by the app itself + optional solo-dev dashboard) validates cookie/login contract is still live.
  - In-app forced-update banner when the client-server contract breaks: served via a static `prijavko.hr/min-version.json`-style endpoint that only holds a min-supported-version integer (zero backend, zero user data).
  - Permanent Dio fake as regression harness.

**AdMob + UMP/CMP.**
- EU consent surface on first launch. Re-prompt on policy updates.
- Ad slots are never rendered during camera/scan or Send All progress — reliability promise > ad revenue.
- If reviews flag ads as #1 complaint, pre-agreed pivot: ad-free free tier + earlier v1.1 Pro unlock.

**Firebase Crashlytics.**
- Zero-PII custom events. Full symbolication for Dart stack traces.
- US-hosted; covered by SCCs in Firebase DPA; disclosed in Privacy Policy.

### Risk Mitigations (Domain-Specific)

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **HTZ silent API change** (auth envelope, cookie names, payload shape) | Medium | High (app-breaking) | Production-canary ping + integration-test harness run on CI against testApi nightly + in-app forced-update banner on contract break |
| **Play Store sensitive-data manual review rejection** (passport app under scrutiny) | Medium | High (launch slip) | Data Safety declaration pre-drafted and reviewed internally before submission; privacy policy + ToS live and linked; targeted-at-API-tier justification written |
| **HTZ competitive response** (mVisitor closes the UX gap) | Medium | Medium (commoditization) | Ship v1.1 (NFC + self-scan + compliance receipt) before HTZ next major release; out-ship not out-feature |
| **GDPR complaint from a host who had a device seized / lost** | Low | Medium (reputation) | 3-day auto-purge + no cloud backup + Keystore-backed encryption ensures post-3-day recoverability = 0; lost-device exposure is limited to the active 3-day buffer at worst |
| **AdMob sensitive-content policy edge case** (ads on a passport-scanner screen) | Medium | Low–Medium (revenue + rating) | No ad impressions during scan/Send-All flows; UMP/CMP in full; monitored as a review-driven pivot trigger |
| **Credential loss on device migration** (no backup by design) | Medium | Low (user re-logs in) | Documented in onboarding: "You'll re-enter your eVisitor credentials when switching devices"; host knows credentials anyway |
| **Rhetos 5-failure lockout triggered by runaway re-auth** | Low (with QueuedInterceptor) | Medium (host locked out 5 min) | QueuedInterceptor serializes re-auth; client-side circuit breaker opens at 3 failures for 6 minutes — strictly more conservative than server-side 5 / 5 |
| **May-2026 mandate payload mismatch** (field name/shape wrong at launch) | Medium | High (rejected submissions across the userbase) | Week-1 spike must verify payload against testApi; feature flag gates UI exposure so mandate field can be enabled when server-side enforcement starts |
| **Wrong-facility submission** despite Neutral App | Low | Medium (regulatory) | Explicit per-session facility choice + facility prominently visible on home + post-submit closure summary names facility — documented residual risk |
| **Solo-dev bus factor during May–Sept peak** | Low | High (no one to fix) | Pre-peak code freeze 2026-06-15; ToS liability disclaimer; kill-criteria-driven sunset at 2026-09-30 rather than zombie maintenance |

## Innovation & Novel Patterns

### Detected Innovation Areas

Prijavko's novelty is not in interaction — there is no AR, no gesture innovation, no AI. It is in **architectural discipline and positioning inversions** that separate it from every incumbent. These are the moat, and each is deliberately non-removable:

1. **Zero-retention as product positioning.** Competitors in this niche (mVisitor, PrijaviTuriste, online.adriagate) all implicitly promise "secure retention" of guest data on-device. Prijavko inverts this: the app is explicitly a transient courier, the phone stores nothing past the 3-day soft-undo buffer, eVisitor is the authoritative store. This is a one-sentence GDPR story (*"your guests' passport data never persists on your phone after submission"*) that no competitor can credibly replicate without rearchitecting — and it is the one line a TZ can safely pass to its hosts.

2. **Error classifier as a product feature.** The naive Dio-tutorial interceptor retries on 401 and silently fails against eVisitor (Rhetos returns HTTP 400 for unauthorized, per [Rhetos issue #182](https://github.com/Rhetos/Rhetos/issues/182)). Prijavko's classifier inspects status code **and** body `SystemMessage`, matches against a Croatian-keyword regex set, and surfaces "your session is dead" hours before the host reaches the door. Competitors treat auth as plumbing; prijavko elevates it to a promise the host can feel.

3. **Neutral App facility pattern.** Every incumbent uses "last active facility" as the default. Prijavko requires an explicit per-session choice, with last-used available as a *hint* (not a default). One extra tap per session buys elimination of wrong-facility submissions — the regulatory-consequence class of errors. Design inversion, not feature addition.

4. **Type-level Poka-yoke for zero-PII logs.** PII types override `toString() → "[REDACTED]"` at the compiler level. CI grep-guard fails the build on `print`, `debugPrint`, `logger.*` calls that reference whitelisted PII field names. Privacy becomes impossible-to-regress by construction, not by runtime vigilance. Standard industry practice is runtime log redaction; compiler-level enforcement is not.

5. **Permanent Dio fake as CI regression harness.** Unusual for solo-dev mobile projects — fakes are normally dev-only fixtures. Prijavko makes the Dio fake a first-class repo artifact running nightly in CI against the testApi, with contract-drift detection. This is the concrete operational mitigation for the HTZ-silent-API-change risk that every eVisitor client faces.

### Market Context & Competitive Landscape

The Croatian eVisitor client market has five incumbents (eVisitor web, mVisitor, eVisitor mobile, PrijaviTuriste, online.adriagate). Feature overlap is ~80% identical across all of them. No incumbent has committed to any of the five inversions above. The gap is not "missing features" — it is "missing discipline." This is exploitable by a solo builder precisely because each incumbent is optimizing for feature parity with the other incumbents, not for the host at 21:30 on Wi-Fi.

### Validation Approach

| Innovation | Validation signal | Deadline |
|---|---|---|
| Zero-retention positioning | Marketing copy test in closed beta (10 hosts) + Play Store listing; qualitative feedback on "hand-phone-to-inspector" test | Pre-launch (2026-05-20) |
| Error classifier | Silent-failure rate = 0 confirmed cases in peak season; nightly integration-test harness passes | Peak season (July–Aug 2026) |
| Neutral App facility | Closed-beta feedback on whether the extra tap registers as friction or relief; zero wrong-facility submissions across beta + first month | 2026-08-31 |
| Type-level zero-PII | CI grep-guard violations = 0 across all merged commits | Ongoing (build-blocking) |
| Permanent Dio fake | Nightly CI run against testApi passes; contract-drift regressions caught pre-production | Ongoing (from Week 1) |

### Risk Mitigation

- **If zero-retention positioning doesn't land in closed beta** (hosts want *more* retention for their own records): pivot Pro-tier messaging from "compliance receipt" to "host-side audit trail with export" — still server-side-fetched, still zero-local-retention, but reframed. The architecture doesn't change; the marketing does.
- **If the error classifier misses a variant** (HTZ introduces a new Croatian error string): the nightly CI harness flags it, the classifier is amended, shipped via normal Play Store channel — no production outage because the client-side circuit breaker opens at 3 failures regardless of classifier correctness.
- **If Neutral App friction is rejected by beta hosts**: fall back to "last-facility-default with confirm banner" — preserves the wrong-facility prevention with zero extra friction. Behavior reconfigurable via local setting, schema unchanged.
- **If type-level zero-PII causes developer productivity drag**: the cost is Darko's alone (solo dev); benchmark acceptable if shipping velocity stays within 10% of unguarded baseline.
- **If permanent Dio fake drifts from eVisitor reality**: the nightly CI run detects it; this is the intended mechanism, not a failure.

## Mobile App Specific Requirements

### Project-Type Overview

Prijavko is an **Android-only Flutter 3.x app**, min API 24+ (Android 7.0 Nougat), targeting phone-first Croatian private-accommodation hosts. Single-activity, edge-to-edge, dark-theme-aware, Croatian-language primary with English secondary. Play Store distribution only (no APK sideload support, no F-Droid, no alternative stores). Offline-first for capture; online-only for Send All submission. Built with zero-backend posture — eVisitor is the only external dependency besides Firebase Crashlytics and Google AdMob.

### Visual Contract

The visual source-of-truth lives in the [Figma file](https://www.figma.com/design/7rV9d2uNYbZe03IvIUxGwL/prijavko?m=auto&t=wg8eg0IpKtrUZUB5-1); the canonical Figma-node → Flutter-widget/token mapping is [`_bmad-output/planning-artifacts/figma-code-contract.md`](./figma-code-contract.md), and the re-build pipeline (regenerates the Figma file from tokens/components in code) lives in [`tools/figma-scripts/`](../../tools/figma-scripts/). PRD does not duplicate the contract — treat those three artifacts as authoritative for any UI-fidelity question.

### Technical Architecture Considerations

**Framework choice — Flutter (cross-platform, Android-only v1.0).**
- Dart 3.x, Flutter stable channel.
- Rejected alternatives: native Android (Kotlin/Jetpack Compose) — slower solo-dev iteration; KMP (Kotlin Multiplatform) — less mature tooling, same UI cost as native.
- Flutter preserves two cheap optionalities: (a) iOS port when revenue funds it, no rewrite; (b) Flutter Web surface for future guest-facing self-scan — separate from host app.
- **Single-platform v1.0 posture**: Android Manifest, Play Store listing, and all platform-specific code paths assume Android only. iOS code paths guarded or omitted; no speculative cross-platform abstraction.

**State management and persistence.**
- **Riverpod 3** for state management; Freezed for immutable models; `build_runner` for codegen.
- **Drift / SQLite** for queue and facility persistence (never auth state, never cookies, never credentials).
- **flutter_secure_storage** (Android Keystore-backed) for credentials (`userName`, `password`, `apikey`) and cookie-jar encryption key.
- **AES-GCM-encrypted file (custom)** for cookie jar (`authentication`, `affinity`, `language`) — encryption key held in flutter_secure_storage.
- **No cloud backup**: `allowBackup="false"` and `android:fullBackupContent="false"` in AndroidManifest. Accepted residual risk: re-login required on device migration. Documented in onboarding.

**Network layer.**
- **Dio 5.x** HTTP client.
- **dio_cookie_manager** + **PersistCookieJar** for cookie binding and on-disk persistence; jar path = `path_provider.getApplicationDocumentsDirectory()`.
- **Certificate pinning** to `www.evisitor.hr` on Dio's HttpClient (SHA-256 pin set for leaf + intermediate).
- **QueuedInterceptor** (not `Interceptor`) serializes re-auth — exactly one login on concurrent 401/400.
- **Timeouts**: connect 10s, receive 30s, send 30s. `ImportTourists` gets extended receive timeout (60s) for larger batches.

**Observability.**
- **Firebase Crashlytics** — Dart symbolication, zero-PII custom events: `scan_to_submit`, `auth_state_transition`, `send_all_result`, `queue_purge`, `classifier_mismatch`, `queue_stuck_24h`.
- No Sentry, no Datadog, no self-hosted observability in v1.0 (explicit rejection in distillate §12).

**Testing.**
- `flutter_test` for unit and widget tests.
- `integration_test` for E2E against the in-repo **permanent Dio fake** (not dev-only — first-class repo artifact).
- Nightly CI run against eVisitor **testApi** base (`https://www.evisitor.hr/testApi`) with a minimal-data canary account; drift from fake to real triggers build failure.
- `mocktail` for unit-level mocks where needed; never for integration-level HTTP.

### Platform Requirements

**Android.**
- **Min SDK**: 24 (Android 7.0 Nougat) — covers ~99% of Croatian host devices per 2025 market share data.
- **Target SDK**: latest per Play Store policy at submission time (2026-05-27) — Flutter's default typically tracks within 1 release of requirement.
- **ABI support**: arm64-v8a (primary), armeabi-v7a (secondary for older midrange devices). No x86/x86_64 (emulator-only).
- **64-bit requirement** already satisfied by Flutter defaults.
- **Screen sizes**: phone portrait primary; tablet portrait/landscape best-effort (no blocking). No foldables-specific handling in v1.0.

**Network security.**
- `network_security_config.xml`: HTTPS-only enforced (`cleartextTrafficPermitted="false"`), cert pinning declared.
- No ATS-style dev-mode exception in release builds. Debug builds may hit localhost for Dio fake tests.

**Localization.**
- Primary: **Croatian (hr)** — default and fallback.
- Secondary: English (en) — declared for Play Store international surfacing.
- All user-facing strings in Croatian first, English second; no in-app language toggle (Android system locale drives).

### Device Permissions

**v1.0 (minimal set).**

| Permission | Purpose | Justification for Play Store |
|---|---|---|
| `android.permission.CAMERA` | MRZ capture (live detection + static-tap fallback) | "Required to scan passport MRZ for eVisitor registration. Frames are processed on-device; raw images are never stored or transmitted." |
| `android.permission.INTERNET` | eVisitor API calls, AdMob, Crashlytics | Standard |
| `android.permission.ACCESS_NETWORK_STATE` | Pre-flight network check before Send All | Standard |
| Haptic feedback (no explicit permission on API 24+) | Scan success/failure feedback | N/A |

**Explicitly NOT requested in v1.0:**
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` — no geolocation-based facility auto-suggest (rejected in distillate §12; violates Neutral App pattern)
- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` — no image save, no CSV export (v1.1)
- `NFC` — deferred to v1.1
- `READ_CONTACTS` / `SEND_SMS` — guest self-scan SMS flow deferred to v1.1+
- `POST_NOTIFICATIONS` — no push, no local notifications in v1.0
- `FOREGROUND_SERVICE` — no background worker, no auto-retry (explicit-Send-All principle)

### Offline Mode

Prijavko is **offline-first for capture, online-only for Send All**. Explicit, not best-effort:

| Flow | Network Requirement |
|---|---|
| App launch, onboarding, login | Online (credentials verified against eVisitor) |
| Facility picker, last-used shortcut | Offline (facility data cached locally after first login) |
| Scan Guest → Drift queue commit | **Fully offline**. Camera, MRZ detection, semantic sanity layer, encrypted Drift persist — zero network |
| Manual entry → Drift queue commit | Fully offline |
| Opportunistic auth check | Online-only, non-blocking (fails silently if offline; banner stays neutral until network returns) |
| Send All | **Online-only**. Pre-flight network check blocks Send with a clear "You are offline — connect and try again" message |
| Closure summary | Offline (renders from in-memory submission result) |
| 3-day auto-purge | Runs on app open regardless of network state |

**State persistence on process death:**
- Unsent queue: persists indefinitely across app kills, device reboots, and battery-out scenarios (Drift/SQLite with WAL).
- Cookie jar: persists across app kills; AES-GCM-encrypted at rest.
- Credentials: persist in Keystore across app kills and uninstalls (OS-policy-dependent).
- **On uninstall**: everything is wiped (Android app-data purge).

**No offline queue-flush retry.** App re-opening after offline period does not auto-attempt Send. Host must explicitly tap Send All. This is architectural, not a limitation — it preserves the explicit-Send-All promise.

### Push Strategy

**v1.0: NO PUSH. Zero FCM. No local notifications.**

This is a deliberate inversion of mobile-app convention:
- No background auto-retry (would violate explicit-Send-All principle)
- No "reminder to register guest" notifications (host already has booking platform notifications)
- No marketing push (ads-supported tier, but never push-based)
- No "your session is about to expire" push (opportunistic in-app check covers this)

**FCM dependency deliberately excluded** from v1.0 build — reduces Data Safety declaration scope, reduces Play Store review friction, eliminates an entire class of Android-background-process edge cases (Doze mode, App Standby, battery optimization exemptions).

**Future v1.1+ reconsideration (not committed):**
- Local notification for queue-stuck > 24h (opt-in) — aligns with compliance promise, does not violate explicit-Send-All because the notification is an *alert*, not a trigger
- Push notification for HTZ API contract-break forced-update banner — lower priority than in-app detection (which already handles it)

### Store Compliance

**Play Store sensitive-data posture (passport/MRZ app).**
- Expected manual review: 1–3 weeks. Build submission target: 2026-05-27 to accommodate.
- Pre-submission checklist (all must be live and linked before upload):
  - Privacy Policy URL (hosted at `prijavko.hr/privacy` — static HTML page)
  - Terms of Service URL (`prijavko.hr/terms`) with liability disclaimer (host is sole legal data controller; fines from app failure are not prijavko's liability)
  - Data Safety declaration completed per the form:
    - Data types collected: camera images (not retained, processed on-device), passport data (collected, transmitted to eVisitor only, retained ≤3 days), host credentials (collected, encrypted at rest, not transmitted to third parties)
    - Data shared: none with third parties (eVisitor submission is the service's core purpose, not "sharing"); AdMob receives no guest data; Crashlytics receives no PII
    - Security practices: data encrypted in transit (HTTPS + cert-pinning), data encrypted at rest (AES-GCM with Keystore-backed key), user can request data deletion (covered by auto-purge)
- Play Store listing:
  - Croatian-language primary title + short description
  - 6 Croatian-language screenshots demonstrating scan → queue → Send All → closure summary flow
  - Category: **Business** (not Travel — Business matches the host-utility framing; Travel is consumer-facing)
  - Content rating: 3+ (no violence, no user-generated content, no social features)

**AdMob + UMP/CMP.**
- **Google Mobile Ads Android SDK** (current stable) + **UMP SDK** for EEA/UK/CH consent.
- Consent surface on first launch; re-prompt on policy updates detected by UMP.
- Ad formats v1.0: banner on home screen (below fold, outside scan/Send flows), interstitial after **successful** Send (not on error, not during — placement sensitivity).
- Sensitive-content safeguard: verify no ads render during camera preview, Send All progress, or credential banner surfacing.
- Pivot trigger documented: if Play Store reviews flag ads as the #1 complaint, ad-free free tier + early v1.1 Pro unlock.

**Google Play Console tracks.**
- **Internal testing** (Darko + 1–2 devices during first 2–3 weeks of build) — no external testers.
- **Closed testing** — 10 real Croatian hosts, ~1–2 weeks pre-submission (target 2026-05-13 start).
- **Production** — 2026-05-27 submission, staged rollout (20% → 50% → 100% over 7 days) to catch any real-device issues before full exposure.

### Implementation Considerations

**Build & release posture.**
- Signed AAB (Android App Bundle), not APK. Play App Signing enrolled (Google manages the upload key).
- Version code strategy: monotonically increasing int; mapped 1:1 to `major.minor.patch` via git tag → `v1.0.0` = versionCode 10000, `v1.0.1` = 10001.
- Obfuscation: Dart's `--obfuscate --split-debug-info` for release builds; R8 enabled for Android layer.
- ProGuard rules committed for Drift, Riverpod, Freezed, Dio codegen.
- Automated builds via GitHub Actions (free tier; nightly testApi canary + release-on-tag).

**Craftsmanship guardrails (from project rules, non-negotiable).**
- TypeScript-style strict typing equivalent in Dart: `dart analyze` fatal on warnings, `--fatal-infos` in CI.
- No `dynamic` in production paths (Dart equivalent of no-`any`).
- Early-return flat logic, no deep nesting.
- JSDoc-equivalent Dart doc comments on every public class and function explaining *why* (non-obvious constraints), not *what*.
- CI grep-guard for forbidden log patterns (PII field names, type names).
- Atomic commits with WHY-focused messages.

**Solo-dev operational posture.**
- Single maintainer (Darko). Pre-peak code freeze: **2026-06-15**. Peak season June–August = bugs only, no features.
- Kill-criteria checkpoint: 2026-09-30.
- ToS explicitly disclaims liability for fines resulting from app failure; host knows and accepts this on first launch.

### Explicit Non-Goals (v1.0 Mobile Scope)

- iOS build (deferred v2+)
- Desktop/web UI (deferred v2+ for guest-facing only, never host)
- Foldable-optimized layouts
- Tablet-optimized layouts (best-effort only)
- Widgets (home-screen quick-scan v1.1 conditional)
- Push notifications of any kind
- Background processing or foreground services
- Geolocation
- Camera-based barcode/QR scanning outside MRZ (no receipt scan, no QR booking import)
- iCal / booking-platform sync
- PMS / channel-manager features
- Tax/boravišna-pristojba computation
- In-app chat, social, or community features

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP approach: Validated-Reliability MVP.**

Prijavko's MVP is not a "problem-solving MVP" (we know the problem exists — eVisitor's UX gap is documented in every Croatian host forum) or a "revenue MVP" (v1.0 monetization is AdMob = €800–€1,500/year, a rounding error). It is a **validated-reliability MVP**: the launch floor is the smallest possible build that can credibly claim, under real-peak-season conditions, "never loses a submission, never fails silently" — and produce measurable evidence of that claim.

Three consequences flow from this choice:

1. **Observability is MVP, not post-MVP.** The `scan_to_submit` Crashlytics event with `corrections_count`, the `queue_stuck_24h` tripwire, and the zero-PII log guard are all v1.0 commits, not v1.1 adds. Without them, the reliability claim is unfalsifiable and the product has no story.
2. **Breadth-of-features is secondary.** Multi-OIB UI, NFC, guest self-scan, reported-history view are all *obviously useful* — and all deferred. They don't contribute to the validation question: *"Does the host trust that the four guests actually registered?"*
3. **Compliance posture is MVP.** Data Safety declaration, privacy policy, ToS, UMP/CMP, 3-day auto-purge, cert pinning — all v1.0. The app cannot ship with a known compliance gap because the Play Store manual review will catch it, and because a host cannot evaluate reliability if the app hasn't passed the regulatory baseline.

**Resource requirements.**
- **Team size**: 1 (Darko, part-time solo).
- **Skills**: senior Flutter/Dart (already), senior TS/Node background (transferable), intermediate BMAD process skill.
- **Time budget**: ~25 working days over 5 calendar weeks, halved for reality = **~12 effective working days** between 2026-04-23 and 2026-05-27.
- **Money budget**: sub-€500 out-of-pocket for v1.0 (Play Console €25 one-off, domain + static hosting ~€20/yr, Firebase Spark free tier, AdMob free, GitHub Actions free tier).
- **Non-dev blockers that consume budget**: 5 host interviews (~4 hours), 10-host closed beta recruitment (~4 hours), privacy policy + ToS drafting (~4 hours), Data Safety declaration (~2 hours), Play Store listing copy + 6 Croatian screenshots (~6 hours).

### MVP Feature Set (Phase 1) — Mapped to Journeys

**Core user journeys supported in v1.0:**

| Journey | Coverage |
|---|---|
| J1 — First Install & First-Ever Registration | Full |
| J2 — Primary Happy Path (4-guest door check-in) | Full |
| J3 — Silent Session Death + Wi-Fi Drop | Full |
| J4 — One Bad Passport in Batch of Five | Full (pending Week-1 spike confirming May-2026 mandate field shape) |
| J5 — Multi-Facility Evening | Full (single-OIB, multi-facility — the typical Croatian case) |

**Must-have capabilities** — the capability areas from Step 4's Journey Requirements Summary, all v1.0:
Onboarding & Consent, Auth Lifecycle, Capture Pipeline, Queue & Drift Persistence, Facility Picker (Neutral App), Send All + Pre-Flight, Credential Banner, Closure Summary, Queue Lifecycle, Error/Network Classification, Mandate-Forward Fields, Instrumentation.

**Irreducible launch floor** (re-stated from Step 3 for single-source-of-truth cross-reference):
- Scan → queue → manual Send All → successful submission against real eVisitor
- Six-state auth machine functional with classifier handling HTTP 400 + SystemMessage
- Zero-PII log guarantee enforced at type level + CI grep guard
- Play Store Data Safety declaration + privacy policy + ToS submitted and accepted

### Post-MVP Features

**Phase 2 — v1.1 (Q3–Q4 2026, post-peak-season).**
Explicit priorities, paid-tier anchored by compliance receipt:
1. **NFC passport chip read** (`flutter_nfc_kit`) — biggest technical differentiator, no incumbent offers
2. **Reported-guests history view** — server-side eVisitor fetch; **blocked on Week-1 spike** to verify endpoint exists. If no endpoint → pivot Pro feature to "signed compliance receipts generated client-side at submission time"
3. **CSV/PDF export** of server-side reported history
4. **Timestamped compliance receipt PDF** — signed at submission time, host's legal-defense file
5. **Ad removal** (Pro IAP unlock)
6. **Multi-OIB UI** — schema already in v1.0, UI surface only
7. **Guest self-scan via link/QR** (Pre-Queue Inbox pattern from brainstorming) — family/custodian semantics, ~30% of Croatian check-ins are families
8. **Home-screen quick-scan widget** — conditional on real demand signals (not speculative)

**Phase 3 — v1.2+ (2027) and v2+.**
Not committed. Directional:
- **iOS port** once revenue funds it (natural Flutter payoff, no rewrite)
- **Guest-facing Flutter Web surface** — separate app; travellers pre-enter data on a signed link ahead of arrival
- **Adjacent eVisitor segments** (same Rhetos API, different UI templates): small-boat/charter yachts, small hostels under ~20 beds, agritourism
- **TZ-partner compliance dashboard** (B2B2C, opportunistic — only after public launch + 20 organic reviews and only with one genuinely interested mid-sized coastal TZ)

### Risk Mitigation Strategy

**Technical risks (launch-window).**

| Risk | Severity | Mitigation |
|---|---|---|
| May-2026 mandate payload wrong at launch | High | **Week-1 spike is blocker** — verify exact payload against testApi before the next 4 weeks are sunk. Mandate UI behind feature flag; can be enabled via Play Store update without migration |
| eVisitor Rhetos error-classifier miss on a new Croatian error string | Medium | Permanent Dio fake + nightly CI against testApi catches drift; client-side circuit breaker opens at 3 failures regardless of classifier correctness |
| MRZ OCR accuracy below 90% target on worn documents / non-EU IDs | Medium | Semantic sanity layer catches garbage before queue; static-tap and manual entry are first-class fallbacks (not degraded modes) — acceptance gate is "submission succeeds" not "OCR succeeds" |
| Flutter/Dio cookie-jar serialization edge cases on process restart | Low | `integration_test` covers jar persistence across app kills; permanent Dio fake reproducibly exercises this |

**Market risks (validation-window).**

| Risk | Severity | Mitigation |
|---|---|---|
| "Silent session death" and "batch rejection" are not the top pains hosts actually feel | High | **5 host interviews are a pre-build blocker** — the brief says so, the distillate says so, this PRD re-confirms it. If interviews say "actually the top pain is X", scope pivots *before* build, not during |
| Willingness-to-pay for €4.99 Pro tier fails to materialize at 5% | Medium | Year-1 commercial goal is validate WTP, not hit revenue. Kill-criteria checkpoint 2026-09-30 ensures we don't throw year-2 money at a failed validation |
| HTZ ships a competing UX update to mVisitor during our peak season | Medium | Out-ship, not out-feature: v1.1 NFC + self-scan + compliance receipt shipped before HTZ's next roadmap meeting finishes |
| Ads undermine the ≥4.5 rating target | Medium | Placement rules: no ads during scan / Send All / credential-banner surfacing. Pivot trigger documented: if reviews flag ads as #1 complaint, ad-free free tier + early v1.1 Pro unlock |

**Resource risks (solo-dev reality).**

| Risk | Severity | Mitigation |
|---|---|---|
| 5-week timeline compresses to 3–4 weeks because of life/day-job events | High | **Slip protocol** (documented in Step 3): (1) hybrid live-first capture → static-only; (2) opportunistic auth banner → login-on-send; (3) Replace-Active-OIB setting → deferred; (4) shareable closure-summary screenshot → textual only. Below the irreducible floor: slip the date, not the scope |
| Solo-dev bus factor during May–Sept peak season | Medium | Pre-peak code freeze **2026-06-15**; peak = bugs only, not features; ToS liability disclaimer; kill-criteria-driven sunset rather than zombie maintenance |
| Sensitive-data Play Store review takes 4+ weeks instead of 1–3 | Medium | Internal testing track used from Week 2 of build; closed-testing track from Week 4 (2026-05-13); production submission target 2026-05-27 assumes a worst-case 2-week review landing pre-peak-June. If rejected, fix-and-resubmit within 48h |
| Cost overrun beyond the €500 v1.0 budget | Low | Only AdMob + Firebase Spark scale risk; neither bills until material scale; Google Play is one-off |

### Scope Commitments (Signed-Off Statements)

- **v1.0 will not include**: iOS, web/PWA host surface, multi-OIB UI, NFC, guest self-scan, reported-history view, CSV/PDF export, compliance receipt, auto-retry, push notifications, geolocation, widgets, iCal import, tax computation, boravišna-pristojba filing, social/community features.
- **v1.0 will include**: every item in the MVP scope list above, subject to the documented slip protocol below the irreducible floor.
- **v1.1 will be scoped against real Play Store reviews, install volume, and peak-season Crashlytics data**, not against this PRD's speculation.
- **No feature survives into v1.0 that has no observable success metric.** Every capability in the MVP list maps to a measurable signal in Step 3's Technical Success table.

## Functional Requirements

### Onboarding & Consent

- FR1: Host can launch the app and be guided through first-run consent, permissions, and credential capture in a single linear flow.
- FR2: App can present an EU-consent surface for ad personalization before any ads are requested.
- FR3: App can present a sensitive-data disclosure explaining passport/MRZ processing, 3-day retention, and a link to the Privacy Policy before camera permission is requested.
- FR4: Host can grant or deny camera permission; manual entry remains fully functional if camera is denied.
- FR5: Host can enter and store eVisitor credentials (username, password, apikey) for subsequent sessions without re-entering.
- FR6: App can verify eVisitor credentials by performing a live login against the eVisitor authentication endpoint during onboarding.
- FR7: Host can replace or re-enter credentials at any time from the Settings surface.

### Authentication & Session Lifecycle

- FR8: App can maintain an eVisitor session across process restarts, device reboots, and periods of background inactivity.
- FR9: App can detect an expired or invalid session from eVisitor responses (regardless of HTTP status code) and classify the cause (session-dead, lockout, credentials-invalid, network, or server error).
- FR10: App can re-authenticate automatically using stored credentials when a dead session is detected, without duplicate concurrent login attempts.
- FR11: App can surface a non-blocking credential banner to the host when session-dead or credentials-invalid is detected, with a single-tap recovery action.
- FR12: App can refuse further login attempts after a configurable threshold of consecutive failures within a rolling window, and communicate the remaining wait to the host in Croatian.
- FR13: App can perform an opportunistic authentication check on app foregrounding without blocking the UI.
- FR14: Host can view current session state (authenticated, reauth-needed, locked-out) at a glance in the Settings surface.
- FR14.5: App can detect missing credentials on launch (Keystore returns no value for an existing facility profile) and surface a non-blocking "credentials missing — re-enter to continue" state with facility names pre-populated, without losing facility context or forcing full re-onboarding.

### Facility Management

- FR15: App can fetch and cache the list of facilities available to the host's eVisitor account on first successful login.
- FR16: Host can select exactly one facility at the start of each registration session.
- FR17: App can surface the last-used facility as a hint during facility selection, but not pre-select it as a default.
- FR18: Host can see the currently active facility on the home surface during an active registration session.
- FR19: App can refresh the facility list when the host explicitly requests it, without forcing a full re-login.

### Guest Capture

- FR20: Host can capture guest identity data by holding a passport or ID card in front of the camera; the app detects and parses a valid MRZ automatically.
- FR21: Host can tap a static capture control to capture a document image when live MRZ detection does not succeed within a bounded time.
- FR22: Host can enter guest data manually as a fallback when neither live nor static capture succeeds.
- FR23: App can validate captured or entered guest data against semantic sanity rules (date plausibility, document expiry, valid country codes, realistic birth years) before accepting it into the queue.
- FR24: Host can review and correct captured guest data before it is committed to the queue.
- FR25: App can reject a capture or entry inline with a Croatian-language explanation when sanity validation fails, without committing it to the queue.
- FR26: App can support future fields required by the May-2026 apartment registration-number mandate, gated by a feature flag, without breaking the existing capture flow.

### Queue & Local Persistence

- FR27: App can persist every captured guest to encrypted local storage with a client-generated unique identifier, synchronously, before surfacing any success indication to the host.
- FR28: App can preserve unsent guests across app kills, device reboots, and offline periods indefinitely until either submission succeeds or the host deletes them.
- FR29: Host can view the unsent queue with a per-guest status and initiate per-guest edit or delete actions.
- FR30: App can automatically delete successfully submitted guests after a 3-day soft-undo retention window, regardless of host action.
- FR31: Host can manually delete individual unsent or recently-submitted guests from the queue at any time.
- FR31.5: Host can replace the active OIB from the Settings surface via a destructive, typed-OIB-guarded confirmation that wipes all facility profiles, queue entries, credentials, and cookie jar, then re-launches onboarding (pressure-valve for OIB transitions without requiring multi-OIB UI in v1.0).

### Submission (Send All)

- FR32: Host can trigger a batch submission of all unsent guests for the active facility via an explicit action (no automatic submission, no background retry).
- FR33: App can perform a pre-flight check for authentication and network reachability immediately before submitting and block the submission with a clear message if either check fails.
- FR34: App can submit guests individually to eVisitor such that a rejection of one guest does not cause rejection of other guests in the same batch.
- FR35: App can report per-guest success or failure outcomes to the host after a submission batch completes.
- FR36: Host can edit a failed guest inline and retry only the failed guests without re-submitting already-successful ones.
- FR36.5: App can distinguish a rate-limited response (HTTP 429 or equivalent eVisitor throttling) from a submission failure and surface a non-blocking "eVisitor is busy — retrying..." message with exponential backoff, without counting the rate-limit as a per-guest failure outcome.
- FR36.6: App can track an `in_flight` queue state between `ready-to-send` and `accepted/rejected`; on app resume after process kill or crash, any `in_flight` entries are re-queried against eVisitor before any retry is attempted (or held for host review if a lookup endpoint is unavailable) — preventing silent double-submits.

### Post-Submission Closure

- FR37: App can present a closure summary after every submission batch, containing the facility name, number of guests registered, and the local submission timestamp — and containing no guest names, document numbers, or other PII.
- FR38: Host can share or screenshot the closure summary for their own records.

### Privacy & Data Lifecycle

- FR39: Host can view a "Your Data" surface listing what is currently stored on the device (unsent queue count, recently-submitted count within retention), with links to the Privacy Policy and Terms of Service.
- FR40: Host can trigger a complete wipe of all local data (queue, cached facilities, cookie jar, credentials) in a single action.

### Observability & Compliance Signals

- FR41: App can emit zero-PII telemetry events that allow the operator to measure submission success rate, session-dead-recovery rate, queue-stuck-over-24h count, and crash-free session rate — without transmitting any guest or credential data.
- FR42: App can present a forced-update banner when a remote minimum-supported-version signal indicates the current client is incompatible with eVisitor, and block submissions while the banner is active.

## Non-Functional Requirements

### Performance

- **NFR-P1**: Live MRZ auto-shutter fires within **1.5s** (p95) from camera-open on a well-lit, flat, in-date machine-readable document.
- **NFR-P2**: Static-tap fallback surfaces no later than **3s** of failed live detection.
- **NFR-P3**: A scanned guest is persisted to the encrypted local queue and reflected in the unsent-row UI within **300ms** (p95) of successful capture, with synchronous DB commit before the success haptic fires.
- **NFR-P4**: Semantic sanity validation completes within **50ms** (p95) of capture submission.
- **NFR-P5**: Send All pre-flight (auth + network) completes within **1s** (p95) and either blocks with a clear message or proceeds.
- **NFR-P6**: Per-guest submission latency is bounded by network/eVisitor; the UI per-guest progress indicator updates within **200ms** of each eVisitor response.
- **NFR-P7**: Post-submit closure summary renders within **200ms** of the last guest's response.
- **NFR-P8**: Cold start (process kill → home screen ready) completes within **2.5s** (p95) on the target device baseline (mid-range Android, 2023+ hardware).
- **NFR-P9**: Warm resume (app foregrounded after background) and opportunistic auth check complete within **1s** (p95), non-blocking.
- **NFR-P10**: App is capable of holding **at least 40 unsent guests** in a single registration session without UI degradation (list scrolls smoothly at 60fps, edit/delete operations complete within 200ms). Verified by integration test.

### Security

- **NFR-S1**: All data in transit uses **HTTPS with TLS 1.2+**; cleartext traffic is rejected at platform level (`network_security_config.xml`).
- **NFR-S2**: All calls to `www.evisitor.hr` are pinned via SHA-256 certificate pins (leaf + intermediate); a pin mismatch aborts the request without retry.
- **NFR-S3**: Credentials (`userName`, `password`, `apikey`) are stored in flutter_secure_storage with Android Keystore-backed AES/GCM; hardware-backed keys used where available.
- **NFR-S4**: The session cookie jar (`authentication`, `affinity`, `language`) is encrypted at rest via AES-GCM; the encryption key lives in flutter_secure_storage.
- **NFR-S5**: Passport/MRZ data in the Drift queue is AES-GCM-encrypted at the column level for guest-identifying fields.
- **NFR-S6**: Android `allowBackup="false"` and `fullBackupContent="false"` — no cloud backup path for any app data.
- **NFR-S7**: No PII field value appears in any log line or any telemetry event. Enforced at two layers: (a) PII-bearing types override `toString()` to `[REDACTED]`, (b) build-blocking CI grep guard fails merges that reference forbidden log patterns.
- **NFR-S8**: Crashlytics stack traces are symbolicated but carry zero free-text from guest records; custom events carry counts, facility IDs, error codes only.
- **NFR-S9**: App passes the OWASP MASVS L1 verification level as a build-time self-audit (documented checklist checked pre-submission).
- **NFR-S10**: 3-day auto-purge of submitted guests is enforced regardless of host action or app state; documented in Privacy Policy and in-app "Your Data" surface.
- **NFR-S11**: Release builds disable verbose Dio request/response logging; Crashlytics uses an allowlist of custom-key names; every transitive dependency's default logging output is reviewed pre-submission; a staging acceptance test triggers an intentional crash in a PII-carrying code path and the Firebase Console output is manually inspected to verify zero guest or credential data leaked via a third-party SDK.

### Reliability

- **NFR-R1**: Crash-free session rate ≥ **99.5%** (measured via Crashlytics).
- **NFR-R2**: `scan_to_submit` first-time success rate ≥ **90%** without field corrections (per the metric defined in Step 3 Technical Success).
- **NFR-R3**: Silent-failure rate (confirmed auth-classifier false negatives in production) = **0** during peak season (2026-06-01 → 2026-09-30).
- **NFR-R4**: Queue-stuck count (unsent guests > 24h old) = **0** on every host's device at every app open (telemetry emits an event when non-zero).
- **NFR-R5**: No submission to eVisitor is lost as a result of process kill, device reboot, network drop, or storage pressure — the queue always either shows the guest as pending or as submitted, never as "gone."
- **NFR-R6**: The app recovers from an expired session automatically on next action, without requiring the host to re-enter credentials (unless credentials themselves are invalid).
- **NFR-R7**: Re-auth under concurrent auth-triggering requests produces exactly **one** login call (not N); serialized via a QueuedInterceptor-equivalent mechanism.
- **NFR-R8**: Client-side circuit breaker opens after **3 consecutive login failures** for **6 minutes**, strictly more conservative than the Rhetos server-side 5 / 5-minute lockout.
- **NFR-R9**: App operates offline for all capture, queue, and facility-picker flows; only Send All and the opportunistic auth check require network.

### Integration

- **NFR-I1**: All eVisitor requests use JSON envelopes; `ImportTourists` uses XML-as-string inside a JSON body; dates are `/Date(ms+offset)/` format.
- **NFR-I2**: Error classifier correctly identifies session-dead across HTTP 401, HTTP 403, HTTP 400-with-`SystemMessage`, and HTTP 200-with-error-envelope-at-non-Login-endpoint cases.
- **NFR-I3**: Error classifier matches Croatian-language error text (`/locked|zaključan/i`, `/invalid|nevažeć|neispra/i`, `/session|prijava|auth/i`) as well as English; regex set is refined via Week-1 spike.
- **NFR-I4**: Integration contract with eVisitor is verified by a permanent in-repo Dio fake that runs on every CI build, plus a nightly CI run against the real eVisitor testApi with a minimal-data canary account.
- **NFR-I5**: Drift from the fake contract to the real eVisitor behavior triggers a CI failure; drift is resolved before merging.
- **NFR-I6**: No guest data (PII) is transmitted to AdMob, Crashlytics, Firebase, Google Play, or any third party — only to eVisitor.
- **NFR-I7**: Forced-update mechanism: the app polls a static `prijavko.hr/min-version.json`-style URL on cold start; if current build < `minSupportedVersion`, the app surfaces a forced-update banner and blocks Send All.

### Compatibility

- **NFR-C1**: App runs on Android 7.0 (API 24) or higher; target SDK is the latest mandated by Play Store at submission time.
- **NFR-C2**: App supports arm64-v8a and armeabi-v7a ABIs; no x86 support.
- **NFR-C3**: App renders correctly in phone portrait on screen sizes from 4.7" to 6.9"; landscape and tablet portrait render without layout breakage but are not design-optimized.
- **NFR-C4**: Camera access works on devices supporting CameraX requirements (effectively all API-24+ devices with a rear camera).
- **NFR-C5**: App does not require Google Play Services beyond ML Kit MRZ (on-device) and Firebase Crashlytics.

### Localization

- **NFR-L1**: All host-facing copy is available in Croatian (primary) and English (secondary); active language follows Android system locale, with Croatian as fallback for unsupported locales.
- **NFR-L2**: Date, time, and number formats follow the active locale conventions.
- **NFR-L3**: Error messages surfaced to the host include both the Croatian eVisitor `UserMessage` (when present) and a prijavko-provided Croatian explanation that is safe for UI display.
- **NFR-L4**: No user-facing string is English-only; missing translations block release.

### Accessibility

- **NFR-A1**: All interactive targets meet a minimum **48×48 dp touch target** size (Android accessibility guideline).
- **NFR-A2**: Text contrast meets **WCAG 2.1 AA** (contrast ratio ≥ 4.5:1 for body, ≥ 3:1 for large text) in both light and dark themes.
- **NFR-A3**: Every actionable control exposes a content description for Android TalkBack screen readers; scan, Send All, credential banner, and closure summary are fully screen-reader navigable.
- **NFR-A4**: Manual-entry keyboard interactions respect system font scaling up to **200%** without layout breakage.

*Scope note: prijavko does not target broad public accessibility audiences in v1.0, and Croatia has not adopted a binding WCAG equivalent for mobile apps. These NFRs are good-stewardship baselines, not legal minimums.*

### Maintainability

- **NFR-M1**: Dart analyzer runs with `--fatal-warnings --fatal-infos` on CI; zero warnings in merged code.
- **NFR-M2**: No production code uses `dynamic` except in boundary deserialization paths that immediately coerce to typed models.
- **NFR-M3**: Public classes and functions carry a doc comment explaining *why* (business context, non-obvious constraints) — not *what* (code should show that).
- **NFR-M4**: Commit messages explain the *why*; atomic commits preferred over batched.
- **NFR-M5**: Test coverage is measured but not gated on a percentage; instead, the capability contract (Step 9 FRs) + the integration-test harness (NFR-I4) must cover every MVP capability. Deliberate coverage ≥ **70% meaningful** on auth + queue + classifier subsystems.
- **NFR-M6**: Pre-peak code freeze is **2026-06-15**; post-freeze merges are bugs only until the 2026-09-30 kill-criteria checkpoint.
- **NFR-M7**: The PRD, product brief, distillate, and eVisitor auth-lifecycle research are the authoritative context artifacts; changes to product scope update the PRD first, then the code.
- **NFR-M8**: AI coverage review + security scan run at the end of every epic (Weeks 1–4); findings are remediated in the same week they are discovered; Week 5 is reserved for Play Store prep with zero open technical dependencies.
