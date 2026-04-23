---
title: "Product Brief: prijavko"
status: "complete"
created: "2026-04-22"
updated: "2026-04-22"
inputs:
  - "_bmad-output/brainstorming/brainstorming-session-2026-04-22-2127.md"
  - "_bmad-output/planning-artifacts/research/technical-evisitor-auth-lifecycle-research-2026-04-22.md"
  - "Web research: PrijaviTuriste, mVisitor, eVisitor official app, online.adriagate, May 2026 registration-number mandate"
---

# Product Brief: prijavko

> **Private hosts' fastest door-to-done, offline-aware.**
> *Never loses a submission. Never fails silently.*

## Executive Summary

Prijavko is an Android (Flutter) app that lets Croatian private-accommodation hosts register their guests in the national eVisitor system in seconds — from the doorway, on spotty Wi-Fi, without losing a submission to a dead session or a bad-batch rejection. It targets the ~110–125k-strong market of small private hosts ("iznajmljivači") who today juggle the clunky eVisitor web portal, the official mVisitor/eVisitor apps, or pay-per-registration competitor tools like PrijaviTuriste.

The product bet is narrow and deliberate: a **host-first, reliability-first** mobile tool that turns a legally mandatory chore into a 30-second interaction. Scan document → verify → send, with every scan persisted the moment it leaves the camera, every auth failure caught before it surprises anyone, and every batch reviewed guest-by-guest so one bad passport never kills the whole submission.

**Why now:** In **May 2026**, Croatia's new apartment registration-number mandate takes effect, raising the compliance stakes for every private host. The tooling gap between a host at the door and the eVisitor system has never mattered more — and it has never been cheaper to close with modern on-device OCR, NFC chip reads, and a stable (if undocumented) eVisitor Rhetos API.

## The Problem

It's 21:30, Saturday in July. A family of four arrives at a studio apartment in Split. The host has 20 minutes before he needs to be at the next apartment across town. He pulls out his phone and opens mVisitor. The session has silently logged him out three hours ago, but he won't know until he tries to submit. He scans four passports. The official app can't read the youngest child's document. He types the data in by hand — on his phone, at the door, in the stairwell's flickering light. He hits **Send All**. One field is flagged invalid. eVisitor rejects **the whole batch**. The host doesn't know which guest is the problem. The guests are waiting. His Wi-Fi just dropped.

This is the job today. The tools reflect the era they were built in: desktop-era web portals retrofitted onto phones, apps that fail silently when your session expires, batch submissions that reject four guests because of one bad field, and tax-agent-grade PMS tools that are overkill for a one- or five-apartment landlord.

The consequences compound: missed registrations trigger fines, disputed submissions rot in the queue for days, and every redundant data entry is an opportunity to type the wrong passport number into the national database.

## The Solution

Prijavko is a **single-purpose registration tool**, built with the host's real working conditions as a first-class design constraint.

- **Scan-first capture**: live MRZ detection with auto-shutter, three-second fallback to static tap-to-capture, manual entry as last resort. A semantic sanity layer on top of MRZ checksums catches impossible data (1899-02-30 birthdays, invalid ISO country codes) **before** it ever reaches eVisitor.
- **Neutral App pattern**: no persistent "active facility" toggle to forget. Every session makes an explicit facility choice, softened by a last-used shortcut. Wrong-facility submissions become a deliberate act, not a default.
- **Fail-safe, ephemeral queue**: every scanned guest is persisted to encrypted local storage the moment it's captured, with a client-side UUID. Send All is **manual and explicit** — the host decides when to push, reviews what's going, sees per-guest success/failure. After successful submission, records are kept for **3 days as a soft-undo buffer, then auto-purged**. No silent retry loops. No lost submissions. No long-term PII on the phone.
- **Opportunistic auth**: the app checks eVisitor session health in the background when you open it, surfaces a non-blocking credential banner if anything is wrong, and runs a pre-flight check before Send All. Problems are surfaced hours before they matter — never at the door.
- **Post-submit closure**: every successful batch ends with a shareable summary — **no guest names, no document numbers** — just "4 guests registered at Apartment Luna at 21:47". Emotional closure for the host, zero-PII proof-of-submission.
- **Poka-yoke throughout**: type-enforced zero-PII-in-logs (redacted at the `toString()` level, guarded in CI), a six-state auth machine that can't enter invalid states, a cookie jar encrypted with a Keystore-backed key.

## Validation & Evidence

What this brief is confident about vs. what it assumes:

| Confidence | Claim |
|---|---|
| ✅ Confirmed | eVisitor Rhetos API mechanics (Forms Auth, cookie lifecycle, error envelopes, Croatian system messages) — recipe-grade technical research done |
| ✅ Confirmed | Competitor landscape and pricing (mVisitor free, official eVisitor app free, PrijaviTuriste paid-packs, online.adriagate free web) |
| ✅ Confirmed | ~110–125k private-accommodation objects registered in eVisitor (HTZ / 2025 statistics) |
| ✅ Confirmed | May 2026 registration-number mandate timing |
| ⚠️ Assumed | Silent session death and batch-rejection are the *top* pains hosts feel — not yet validated in user interviews |
| ⚠️ Assumed | 5k installs is ~5% of TAM — real phone-first-solo-host TAM is likely smaller (30–60k) after excluding agency-managed and inactive registrations |
| ⚠️ Assumed | ≥90% first-time submission success rate is achievable with on-device MRZ — ML Kit real-world accuracy on worn docs / non-EU ID layouts may undercut this |
| ⚠️ Assumed | Willingness-to-pay at €4.99 for the v1.1 unlock — no signed-up beta list, no price test |
| ❌ Open | Exact payload change required by the May 2026 registration-number mandate |
| ❌ Open | Whether eVisitor exposes a server-side list/query endpoint for the v1.1 reported-history feature |

## What Makes This Different

Prijavko does not try to be a PMS, a channel manager, or a tax tool. It tries to do **one thing no incumbent does well**: survive the actual conditions of a peak-season door-check-in without silent failure.

| Incumbent | What they do | Where prijavko wins |
|---|---|---|
| **eVisitor web portal** (HTZ) | The legal source of truth | Desktop-first, session timeouts, unusable at the door |
| **mVisitor** (official HTZ app) | Free, scan + self-service | Thin wrapper over the portal; patchy offline/session handling; dated UX |
| **eVisitor mobile** (official HTZ app) | Newer official mobile client | Still a portal companion, not a host-first tool |
| **PrijaviTuriste** | Paid (pay-per-registration packs); polished | Free tier is capped at 15 registrations; free for TZ-partnered hosts only |
| **online.adriagate** | Free web "2-click" registration | Web-based; no real offline; not a door-side tool |

The **unfair advantages** are execution-shaped, not feature-shaped:

1. **A reliability thesis no one else has committed to.** Every design decision optimizes for "the host just got home at midnight — did all four guests actually register?" Competitors optimize for scanning speed; prijavko treats *never losing a submission* as the headline promise.
2. **Zero-retention privacy as a moat.** Guest passport data never persists on the phone after submission — 3-day soft-undo buffer, then gone. eVisitor is the authoritative store; the app is a transient courier. No other tool in this market can credibly say this, and it's a GDPR story that resonates with hosts and the one sentence a TZ can safely repeat to its hosts.
3. **A technical correctness advantage.** Deep research into the eVisitor Rhetos API surfaced auth quirks that would trip up a naive implementation (HTTP 400 masquerading as session-dead, cookie header gotchas, no refresh token). The error classifier handles them; competitors who "retry on 401" silently fail.
4. **A build advantage from being tiny.** Solo Flutter build, Android-first, no speculative features — shippable to Play Store in ~5 weeks. Incumbents have web + mobile + backend surfaces to maintain; prijavko ships one app that does one thing. This is also the answer to an HTZ competitive response: out-ship, don't out-feature.

**On the Flutter choice.** Android-first today, but Flutter keeps two cheap optionalities open that native-Android or KMP would not: (a) an **iOS port when there is revenue to fund it**, without a full rewrite; (b) a **guest-facing Flutter Web page** (not a host PWA — a different surface entirely) where travellers pre-enter their own data before arrival, feeding the host's queue. Neither is v1.0 scope; both stay reachable.

## Who This Serves

**Primary persona — the Small Private Host.** 1–3 apartments, often inherited coastal property. Manages bookings via Booking.com / Airbnb. Phone-first, Android-dominant. Part-time landlord: day job is something else. Pain points: eVisitor is "that thing I have to do" — tolerated, not loved. Rarely uses desktop tools in peak season.

**Secondary persona — the Small-Portfolio Manager.** 3–15 units across a town or stretch of coast. Often a family operation. More organized, more repeat-heavy workflows. Will pay a small one-time unlock for multi-unit quality-of-life features (facility picker memory, unsent-queue digest).

**Explicit non-goals.** Prijavko is not for:
- Hotels or accommodation over ~20 units (they have PMS tools)
- Campsites or camp-grounds (different eVisitor flow, not v1.0 scope)
- Charter yachts, agritourism, hostels (same eVisitor API — filed as *adjacent markets* for v1.2+)
- Power users wanting full PMS, channel-manager, or tax-computation features

## Success Criteria

**Leading indicators** (the tiller — controllable mid-season, checked monthly):

| Metric | Target |
|---|---|
| Weekly active hosts (July 2026) | 500+ |
| Play Store reviews ≥ 4★ | 50+ by end of August |
| Crash-free session rate | ≥ 99.5% |
| First-time submission success rate | ≥ 90% without field corrections — measured via zero-PII Crashlytics custom event `scan_to_submit` with `corrections_count`; denominator is guests that reached Send All, success = `corrections_count == 0` AND eVisitor returned 2xx |

**12-month north-star signals** (Play Store public launch → 12 months):

| Metric | Target | Why |
|---|---|---|
| Installs | 5,000+ | ~5% of the addressable Croatian private-host market; beachhead scale |
| Play Store rating | ≥ 4.5 | Trust is the moat; a tool that handles passports can't survive low ratings |
| 3-month retention | ≥ 40% | Seasonal tool; anyone still registering guests three months post-install is a real user |
| Paid-unlock conversion (v1.1) | ≥ 5% of active users | Validates willingness-to-pay if/when IAP ships |

**Revenue reality check.** At 5k users, AdMob yields roughly €800–€1,500/year (Croatia eCPMs, seasonal DAU). Ads alone do not sustain the project. The one-time **"Pro"** unlock in v1.1 is the actual business lever — at €4.99 and 5% conversion of 5k users, that's another ~€1,250 one-off. The commercial goal for year one is **validate willingness-to-pay**, not hit a revenue number.

**Kill criteria.** If by end of peak season 2026 (Sept 30) the app has <1,000 installs OR <3.5 rating OR <10% retention at month 3, sunset the project rather than sink another year into a validated failure. A planned exit is cheaper than a sunk-cost drift.

## Go-To-Market

Distribution is the single biggest solo-dev risk. The plan is narrow, cheap, and leverages the fact that nobody else in this niche is doing it:

- **Closed beta with ~10 real Croatian hosts** for 1–2 weeks before public listing (already in the plan). Convert all of them into Day-0 public reviews — launching with 10 genuine 4–5 star reviews is worth ~3x launching at 0.
- **Pre-launch landing page** in Croatian at a short domain, capturing waitlist emails. Seeded 4–6 weeks before Play Store submission via Facebook host groups ("Iznajmljivači Hrvatske", regional TZ groups) — these are *the* distribution channel for this segment, not ads.
- **Croatian-language ASO**. Competitor keyword density for *"prijava gostiju", "eVisitor prijava", "iznajmljivači aplikacija"* is low. A crafted title/short-description + 6 Croatian-language screenshots is almost all of the first year's organic install volume.
- **TZ partnership lever** (opportunistic, not MVP-critical). One endorsement from a mid-sized coastal TZ (Istra, Split-Dalmatia, Zadar) compounds across neighboring boards via peer pressure — a B2B2C flywheel with zero CAC, and the strongest defense against an eventual HTZ competitive response. First TZ outreach after public launch + 20+ organic reviews.
- **Pre-peak code freeze 2026-06-15**. Peak season is an 8-week live-fire test; a solo dev shipping new code in July is shipping regrets. Bugs only after that, no features.
- **Sensitive-data Play Store posture**. Passport/MRZ apps routinely trigger manual review (1–3 weeks). Data Safety declaration, privacy policy URL, ToS with a liability disclaimer, and a pre-submission Play Console review happen before the 2026-05-27 submission, not after.

## Scope

### In — v1.0 (target: Play Store submission 2026-05-27)
- Android-only, Flutter, min API 24+
- MRZ-first capture pipeline with static-tap and manual-entry fallbacks
- Semantic sanity layer on top of MRZ checksums
- Encrypted local queue (Drift/SQLite) with client-side UUIDs
- Neutral App facility picker with last-used shortcut
- Opportunistic background auth check + non-blocking credential banner + pre-flight on Send All
- eVisitor Forms Auth / Rhetos integration (JSON everywhere, `ImportTourists` XML wrapped as string, `/Date(ms+offset)/` date handling)
- Six-state auth machine, QueuedInterceptor re-auth serialization, circuit breaker after 3 consecutive login failures
- Type-enforced zero-PII-in-logs + CI grep guard
- Post-submit closure summary (shareable screenshot)
- Ephemeral local queue: unsent guests persist until submitted; successful submissions held 3 days as soft-undo buffer, then auto-purged
- AdMob + UMP/CMP consent
- Firebase Crashlytics for zero-PII crash telemetry

### Out — v1.0
- iOS (deferred, not cross-platform; separate native build post-launch)
- Flutter Web / PWA for hosts (explicitly rejected — the host flow is phone-at-the-door, not a browser)
- Guest self-check-in flow (host is legal data controller; v1.1 candidate)
- Multi-OIB UI (schema-ready in v1.0, UI unlocked in v1.1)
- NFC passport chip read (v1.1 differentiator)
- Background auto-retry / push-driven queue flush
- PMS, channel-manager, tax-calculator, widget, geolocation, iCal import

### Slip protocol (if 5-week timeline compresses)
Defer order: (1) hybrid live-first capture → static-only, (2) opportunistic auth banner → login-on-send, (3) Replace-Active-OIB setting, (4) shareable closure-summary screenshot.

**Irreducible launch floor** — below this, slip the date instead of the scope: scan → queue → manual Send All → successful submission against real eVisitor, with auth state machine and zero-PII logging. Everything else is dial-able.

## Roadmap Thinking

**v1.1 (Q3–Q4 2026) — paid unlock + differentiators.**
- "Pro" one-time IAP — or pivot to paid-once €4.99 if ads/data say so. Paywalled content:
  - **Reported-guests history view** fetched from eVisitor's server-side API (not local) — so the phone stays the transient courier it always was
  - CSV/PDF export of reported history (host-facing compliance artifact)
  - **Timestamped compliance receipt**: signed PDF of each submission (when it happened, which guests, which facility) — the host's legal-defense file against fines
  - Ad removal
- **NFC passport chip read** via `flutter_nfc_kit` — the single biggest technical differentiator no incumbent offers
- Multi-OIB UI (schema already in place from v1.0)
- Guest self-scan via link/QR (family/custodian semantics — ~30% of Croatian check-ins are families)
- Home-screen quick-scan widget (if real user demand signals emerge)

**v2+ directional bets (not committed).**
- **iOS port** once revenue funds it (natural Flutter payoff)
- **Guest-side Flutter Web surface** — travellers enter their own data on a personal link ahead of arrival; feeds the host's queue on check-in day

**v1.2+ (2027) — adjacent eVisitor segments.** Same API surface, different UI templates:
- Small-boat / charter yacht hosts
- Small hostels (under ~20 beds)
- Agritourism properties

**Vision (3 years).** Prijavko becomes the default phone-first eVisitor client for any small operator in Croatia's private-accommodation economy — the tool hosts open before they open the door. Trusted enough that tourism boards (TZs) proactively recommend it. Still free for the single-apartment landlord, still never loses a submission.

## Key Risks & Open Questions

**Pre-build blockers** (resolve before week 1 of the build):
- Exact payload change required by the **May 2026 registration-number mandate**
- Whether eVisitor exposes a **server-side list/query endpoint** for the v1.1 reported-history feature (if not, that Pro feature needs rethinking)
- **Play Store Data Safety** declaration for passport/MRZ data + published privacy policy + ToS with liability disclaimer
- **5 real host interviews** to validate that silent session death and batch rejection are the *actual* top pains — not the dev's single-user projection

**Ongoing risks:**
- **eVisitor API stability**: Rhetos endpoints are not a publicly-documented partner API. HTZ can change auth without notice. Mitigation: abstracted client, schema-drift monitoring, permanent Dio fake as test harness, production-canary ping account, in-app forced-update banner when the client-server contract breaks.
- **HTZ competitive response**: the official mVisitor/eVisitor apps can close the UX gap at any time. Mitigation: out-ship, not out-feature. Ship v1.1 NFC and self-scan before HTZ's next roadmap meeting finishes.
- **Solo-dev bus factor** during peak season (May–Sept). Mitigation: pre-peak code freeze 2026-06-15; explicit kill criteria; ToS disclaimer so that fines from app failure are never prijavko's liability.
- **Ads at the door** may actively undermine the ≥4.5 rating target — the exact moment of stress is the worst ad impression context. If Play Store reviews flag ads as the top complaint, consider ad-free free tier + earlier v1.1 Pro unlock.
- **Wrong-facility submissions** despite Neutral App — accepted residual risk; needs risk-register note in PRD.
- **MRZ OCR real-world accuracy** on worn documents and non-EU ID layouts may undercut the 90% target. Mitigation: semantic sanity layer catches garbage; static-tap and manual-entry fallbacks are first-class, not degraded modes.
