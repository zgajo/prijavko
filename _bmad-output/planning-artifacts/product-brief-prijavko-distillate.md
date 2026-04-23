---
title: "Product Brief Distillate: prijavko"
type: llm-distillate
source: "product-brief-prijavko.md"
created: "2026-04-22"
purpose: "Token-efficient context for downstream PRD creation"
---

# Prijavko Detail Pack (Distillate)

Dense overflow context from brainstorm + technical research + web research + elicitation. Each bullet is standalone. Consume alongside `product-brief-prijavko.md`.

---

## 1. Core product definition

- Android app, Flutter (Dart 3.x), min API 24+
- Single-purpose: phone-first eVisitor guest registration for Croatian private-apartment hosts
- Target: ~110–125k total private-accommodation objects in Croatia; realistic phone-first solo-host TAM likely 30–60k
- Personas: (a) single-apartment landlord 1–3 units; (b) small-portfolio manager 3–15 units
- Business model v1.0: free + AdMob. v1.1: one-time IAP "Pro" (€4.99 reference) — remove ads, reported-history view, CSV/PDF export, signed compliance receipt
- Tagline: "Private hosts' fastest door-to-done, offline-aware." + "Never loses a submission. Never fails silently."

## 2. Ephemeral queue posture (KEY DESIGN DECISION — overrides brainstorm)

- Local Drift queue is ephemeral; NOT a long-term PII repository
- Unsent guests persist until submitted
- After successful submission: retained 3 days as soft-undo buffer, then auto-purged
- eVisitor is the authoritative store; phone is a transient courier
- No configurable retention window (30/90/1y/Forever — REJECTED)
- No CSV/PDF export in v1.0 (deferred to v1.1 where it exports server-side history, not local archive)
- Marketing line approved: "Your guests' passport data never persists on your phone after submission"

## 3. Capture pipeline (v1.0)

- MRZ-first: live detection with auto-shutter on valid checksum
- 3-second timeout → static tap-to-capture fallback
- Manual-entry as last-resort tier
- **Semantic sanity layer** on top of MRZ checksum: reject impossible values (date 1899-02-30, invalid ISO country codes, expired documents, unrealistic birth years) before queue commit
- Non-EU ID cards + worn documents are known accuracy risk — static-tap and manual entry are first-class fallbacks, not degraded modes

## 4. Auth architecture (eVisitor Rhetos)

- Prod base: `https://www.evisitor.hr/eVisitorRhetos_API/`
- Test base: `https://www.evisitor.hr/testApi`
- Login endpoint: `/Resources/AspNetFormsAuth/Authentication/Login`
- Data endpoints: `/Rest/Htz/...`
- Login POST body: `{userName, password, apikey, PersistCookie: true}`
- Login response: `true` on success OR error envelope `{UserMessage, SystemMessage}` — login failure may return HTTP 200 with error body (Rhetos quirk)
- Cookies: `authentication`, `affinity`, `language` (NOT `.ASPXAUTH` — earlier assumption was wrong)
- Cookie header separator: `; ` (semicolon + space) — Dio handles automatically, relevant only for hand-rolled integrations
- Cookie TTL: likely 14 days sliding (ASP.NET Core Identity default) — `PersistCookie: true` survives process restart
- NO refresh token — full re-login on expiry
- Rhetos lockout: 5 failures → 5-minute lockout (server-enforced)

## 5. Error classifier (CRITICAL — prevents silent failure)

Session-dead-needs-reauth condition:
- HTTP 401 OR 403
- OR HTTP 400 with `SystemMessage` matching `/not authenticated|unauthorized|session/i`
- OR HTTP 200 with JSON error envelope AND endpoint != `/Login`

Croatian keyword regexes to refine in Week 1 spike:
- Locked: `/locked|zaključan/i`
- Invalid creds: `/invalid|nevažeć|neispra/i`
- Session/auth: `/session|prijava|auth/i`

UserMessage = Croatian, safe to surface in UI
SystemMessage = diagnostic, log-only (but redact first — see §10)

## 6. Auth state machine (6 states)

- `initial` → `unauthenticated` → `authenticating` → `authenticated` ⇄ `reauth`
- Plus `lockedOut(retryAfter)` and `authFailure(reason)`
- **Invariants:**
  - `authenticated` only after server-confirmed 200 + cookies present in jar
  - `reauth` only reachable from `authenticated`
  - `authFailure` transitions require a classification reason (poka-yoke)
- Use `QueuedInterceptor` (NOT `Interceptor`) to serialize re-auth so concurrent 401/400s trigger EXACTLY ONE login — prevents thundering-herd lockout
- Circuit breaker opens after 3 consecutive login failures for 6 minutes

## 7. Data store ownership (single source of truth per concern)

- **flutter_secure_storage** (Keystore-backed): credentials + cookie-jar encryption key + apikey
- **AES-GCM encrypted file (custom)**: cookie jar (`authentication`, `affinity`, `language`)
- **Drift / SQLite**: queue + facility data ONLY — NEVER auth state
- **Never:** cloud backup of credentials in v1.0 (design decision — protects keystore integrity on device migration)

## 8. Queue idempotency

- Every queued guest gets a client-side UUID at scan time, persisted in Drift
- Drift commit must be SYNCHRONOUS before success haptic/UI confirmation (no "optimistic" queue)
- If eVisitor supports idempotency key → use it
- Fallback: natural duplicate-detection on `(document_number, date_of_birth, date_of_entry)` — Week 1 spike must verify

## 9. Dates and payload wrapping

- Dates are .NET JSON `/Date(ms+offset)/` format — NOT `YYYYMMDD` (earlier assumption wrong)
- `ImportTourists` payload: XML as a string wrapped inside a JSON body (not pure XML, not pure JSON)
- Timezone: Europe/Zagreb

## 10. Zero-PII-in-logs guarantee

- **Poka-yoke at type level**: PII types override `toString()` → `[REDACTED]`
- **CI grep guard** on forbidden log patterns (documentNumber, firstName, etc.)
- Crashlytics: zero-PII crash telemetry
- Post-submit shareable summary contains NO names, NO document numbers — only counts and facility name

## 11. UX patterns (v1.0)

- **Neutral App**: NO persistent "active facility" toggle; every session makes an explicit facility choice. Last-facility shortcut softens pick-list friction
- **Passive queue + manual Send All**: no background auto-retry. Host explicitly pushes. Per-guest success/failure visible
- **Opportunistic auth**: silent auth check at app open + non-blocking credential banner + Send-All pre-flight
- **Post-Submit Closure Summary**: "N guests registered at Facility X at HH:MM" — shareable screenshot, emotional closure

## 12. Rejected ideas (do NOT re-propose)

| Idea | Why rejected |
|---|---|
| Host PWA / Flutter Web host surface | Host flow is phone-at-the-door, not a browser |
| Single-OIB-per-install, install-twice for multi-OIB | Play Store flags duplicate installs; confusing icons. Flipped to: OIB as first-class Drift schema column + Replace-Active-OIB setting + v1.1 multi-OIB UI (zero migration) |
| Configurable retention window (30/90/1y/Forever) | eVisitor is authoritative store. App = transient courier |
| CSV/PDF export in v1.0 | Deferred to v1.1 (exports server-side history, not local archive) |
| Background auto-retry / push-driven queue flush | Violates explicit-Send-All principle; masks silent failures |
| Pre-v1.0 architecture hooks (entry_source enum, graph queue state machine, OIB-as-signable-unit) | Violates Just-In-Time; speculative |
| Sentry self-hosted | Crashlytics is sufficient for v1.0 |
| iCal booking import | "No PMS" non-goal; reconsidered and rejected in elicitation |
| Tax calculator (boravišna pristojba filing) | Out of scope; host has accountant |
| Boravišna pristojba read-only summary | Rejected in elicitation — not a v1.1 priority |
| Home-screen widget (unconditional) | v1.1 candidate only if real demand surfaces |
| Geolocation-based facility auto-suggest | Violates Neutral App pattern; adds PII exposure |
| Tourist-board sponsorship deal | Overengineered for solo-dev v1.0 |
| iOS cross-platform build via Flutter in v1.0 | Deferred to v2+ when revenue funds port |

## 13. Slip protocol (defer order if 5-week timeline compresses)

1. Hybrid live-first capture → static-only
2. Opportunistic auth banner → login-on-send
3. Replace-Active-OIB setting
4. Shareable closure-summary screenshot

**Irreducible launch floor** (below this, slip the date not the scope):
- Scan → queue → manual Send All → successful real-eVisitor submission
- Auth state machine functional
- Zero-PII logging enforced

## 14. v1.1 roadmap (Q3–Q4 2026)

- **"Pro" IAP** paywalled content:
  - Reported-guests history view (server-side eVisitor API — needs endpoint verification)
  - CSV/PDF export of reported history
  - **Timestamped compliance receipt** (signed PDF per submission — host's legal-defense file)
  - Ad removal
- NFC passport chip read via `flutter_nfc_kit` — biggest unmatched technical differentiator
- Multi-OIB UI (schema already in v1.0)
- Guest self-scan via link/QR with family/custodian semantics (~30% of Croatian check-ins are families)
- Home-screen quick-scan widget (conditional on signal)

## 15. v2+ directional bets (NOT committed)

- **iOS port** once revenue funds it (Flutter payoff)
- **Guest-facing Flutter Web surface** — separate from host app: travellers pre-enter data on a personal link ahead of arrival, feeds host's queue
- v1.2+ adjacent segments (same eVisitor API, different UI): small-boat/charter yachts, small hostels (<20 beds), agritourism

## 16. Competitive intelligence

| Name | Model | Notes |
|---|---|---|
| **eVisitor web portal** (HTZ) | Free, legal source of truth | Desktop-first, session timeouts, unusable at door |
| **mVisitor** (official HTZ app, `uno.intersoft.mvisitor`) | Free Android/iOS | Built by Intersoft; thin portal companion; supports guest self-service via QR/link |
| **eVisitor mobile** (official HTZ, `hr.tz.evisitor`) | Free Android/iOS | Newer official mobile client; still portal-centric |
| **PrijaviTuriste** (`hr.prijavituriste`) | Pay-per-registration packs; 15 free trial; FREE for TZ-partnered hosts | Polished; Android + iOS; doc scanning + PDF invoice + Traffic Record |
| **online.adriagate** (web) | Free | Web "2-click" registration; often recommended on forums |
| **Rentlio** and other Croatian PMS | Paid subscription | Overkill for 1–15 unit hosts |

**Known common pain points (from host forums + FAQ):**
- eVisitor auto-logout leaves hosts stranded at the door
- Batch-send in eVisitor rejects ENTIRE batch if one guest is missing info — direct Poka-yoke differentiation target
- Guests refuse to show ID — hosts need multilingual PDF explainer (Adriagate blog has one)

## 17. GTM specifics

- **Pre-launch landing page** in Croatian, short domain, waitlist email capture — seed 4–6 weeks before Play Store submission
- **Facebook host groups** ("Iznajmljivači Hrvatske" + regional TZ groups) — primary organic channel
- **Croatian-language ASO** — wide-open keyword space: "prijava gostiju", "eVisitor prijava", "iznajmljivači aplikacija"
- **Closed beta: ~10 real hosts**, 1–2 weeks. Convert to Day-0 public reviews (10 genuine 4–5★ reviews ≈ 3× launch conversion vs zero reviews)
- **5 host interviews** pre-build — blocker — validate silent session death and batch rejection are actual top pains
- **TZ partnership** — start with ONE mid-sized coastal TZ (Istra, Split-Dalmatia, or Zadar). Co-branded "TZ-recommended" + optional TZ-facing compliance dashboard. Approach AFTER public launch + 20+ organic reviews
- **Pre-peak code freeze: 2026-06-15** — bugs only after that, no features. Peak June–August is live-fire; shipping new code in July = shipping regrets
- **Play Store sensitive-data review**: 1–3 weeks likely. Data Safety declaration + privacy policy URL + ToS with liability disclaimer MUST be ready before submission

## 18. Success metrics

**Leading indicators (controllable):**
- Weekly active hosts July 2026: 500+
- Play Store reviews ≥ 4★ by end of August: 50+
- Crash-free session rate: ≥ 99.5%
- First-time submission success rate: ≥ 90% without field corrections

**Lagging 12-month north stars:**
- 5,000+ installs
- Play Store rating ≥ 4.5
- 3-month retention ≥ 40%
- Paid-unlock conversion (v1.1): ≥ 5% of active users

**Revenue reference points:**
- AdMob at 5k users, Croatia eCPM + seasonal DAU → €800–€1,500/year
- €4.99 Pro IAP at 5% of 5k → ~€1,250 one-off
- Year 1 commercial goal: validate willingness-to-pay, NOT hit a revenue target

**Kill criteria (Sept 30, 2026):**
- <1,000 installs OR <3.5 rating OR <10% retention@3mo → sunset

## 19. Open research questions

1. **Legal window question** — now closed: no local PII retention beyond 3 days (handled in §2)
2. **May 2026 registration-number mandate** — exact payload change required in `ImportTourists` or new endpoint?
3. **Server-side eVisitor history API** — does it exist? Query/list endpoint for prior submissions? Blocker for v1.1 Pro reported-history
4. **eVisitor idempotency key support** — Week 1 spike
5. **MultiOIB frequency** in the real Croatian small-host market — drives v1.1 UX investment; collected via in-app feedback post-launch
6. **HTZ posture** on third-party API clients — tolerated, encouraged, or at-risk of cease-and-desist?

## 20. Accepted residual risks (document in risk register)

- **F9** — Drift performance at 40+ guests/session
- **F16** — wrong-facility submission despite Neutral App pattern (regulatory consequence potential)
- **Keystore credential loss** on device migration (no cloud backup by design)
- **Solo-dev bus factor** during May–Sept peak — mitigation: pre-peak freeze + ToS liability disclaimer + kill criteria
- **MRZ real-world accuracy** on worn documents and non-EU layouts may undercut 90% target — mitigation: semantic sanity layer + first-class fallbacks
- **Ads at stressful door moment** may actively hurt ≥4.5 rating — monitor reviews; pivot to ad-free + earlier Pro unlock if reviews flag ads as #1 complaint

## 21. Legal / compliance posture (v1.0)

- Host is sole legal data controller under Croatian tourism law
- Zero local retention post-submission (3-day buffer only) — minimizes GDPR exposure
- Privacy policy URL required for Play Store
- ToS with liability disclaimer: fines from app failure are not prijavko's liability
- Play Store Data Safety declaration for passport/MRZ data
- AdMob + UMP/CMP for EU consent — watch for sensitive-data ad policy edge cases

## 22. Stack (committed)

- Flutter, Dart 3.x
- Dio 5.x + dio_cookie_manager + PersistCookieJar
- flutter_secure_storage (Keystore)
- Drift / SQLite
- Riverpod 3, Freezed
- Firebase Crashlytics
- AdMob + UMP/CMP
- In-repo Dio fake as permanent integration-test harness (not just dev fixture)
- Google Play Console Closed Beta track for ~10-host validation

## 23. Timeline

- **Today**: 2026-04-22
- **Play Store submission**: 2026-05-27 (~5 weeks solo part-time, ~25 working days halved for reality)
- **Closed beta**: ~1–2 weeks pre-submission (from ~2026-05-13)
- **Pre-peak freeze**: 2026-06-15
- **Peak season live-fire**: June–August 2026
- **Kill-criteria checkpoint**: 2026-09-30
- **v1.1 target window**: Q3–Q4 2026
