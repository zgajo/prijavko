---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments:
  - https://www.evisitor.hr/eVisitorWiki/Javno.Web-API.ashx
  - https://github.com/Rhetos/AspNetFormsAuth/blob/master/Readme.md
  - https://www.nuget.org/packages/Rhetos.AspNetFormsAuth/
  - https://github.com/Rhetos/AspNetFormsAuth/blob/master/src/Rhetos.AspNetFormsAuth/AuthenticationService.cs
  - https://github.com/Rhetos/Rhetos/issues/182
  - https://pub.dev/packages/hive_cookie_store
  - https://pub.dev/packages/cookie_jar
  - https://pub.dev/packages/dio_cookie_manager
  - https://pub.dev/packages/flutter_secure_storage
  - https://riverpod.dev/docs/whats_new
  - https://code-maze.com/user-lockout-aspnet-core-identity/
  - https://vibe-studio.ai/insights/certificate-pinning-in-flutter-with-dio
workflowType: 'research'
lastStep: 6
research_type: 'technical'
research_topic: 'eVisitor Forms Auth & .ASPXAUTH cookie lifecycle (Flutter/Dart + Dio)'
research_goals: |
  Produce an implementation recipe (first-spike grade) for eVisitor Forms Authentication
  and the .ASPXAUTH cookie lifecycle, targeting a Flutter/Dart + Dio 5.x +
  dio_cookie_manager + persistent cookie jar stack on Android. Deep-scope focus on
  auth lifecycle only. Questions to answer:
    1.  Login endpoint, payload & response shapes (2026 state)
    2.  .ASPXAUTH cookie TTL — documented vs observed; sliding expiration?
    3.  Re-auth trigger detection (401 vs HTML redirect vs empty XML) from a client
    4.  Concurrent session limits per eVisitor account (one OIB → multi-worker?)
    5.  Credential rotation — does password change invalidate active cookies?
    6.  CSRF / anti-forgery tokens alongside .ASPXAUTH?
    7.  Dio 5.x + dio_cookie_manager specifics — ASP.NET Forms Auth interop gotchas,
        persistent jar serialization, cookie-at-rest via flutter_secure_storage
    8.  Observability — failed vs expired vs locked-account signatures
    9.  eVisitor 2024–2026 auth changes (announced OAuth/OIDC migration?)
    10. Rate limits / lockout on the login endpoint
user_name: 'Darko'
date: '2026-04-22'
web_research_enabled: true
source_verification: true
---

# Research Report: technical

**Date:** 2026-04-22
**Author:** Darko
**Research Type:** technical
**Research Topic:** eVisitor Forms Auth & .ASPXAUTH cookie lifecycle (Flutter/Dart + Dio)

---

## Research Overview

**Motivation.** eVisitor is the single external integration prijavko must talk to. Authentication is the outer gate of that integration — every other concern (queue, retry, offline buffering, batch submission) depends on having a stable, observable, recoverable session. Getting auth wrong produces the worst-class failures: silent dropped check-ins at peak season, when hosts can least afford to notice.

**Scope.** Deep-focus research on the auth lifecycle only: login handshake, session cookie mechanics, re-auth triggers, error classification, lockout handling, and the concrete Dart implementation recipe for a Flutter + Dio + dio_cookie_manager + PersistCookieJar + flutter_secure_storage stack. Out of scope: `ImportTourists` semantics, queue topology, iOS clients, anything downstream of a valid session.

**Key findings (three headline corrections + one show-stopper).** The eVisitor wiki contradicts common community write-ups on three points: the session cookie is **not** `.ASPXAUTH` (three named cookies — `authentication`, `affinity`, `language`), the transport is **JSON everywhere** (including `ImportTourists`, which wraps XML as a string inside JSON), and dates use **.NET JSON format** (`/Date(ms+offset)/`, not `YYYYMMDD`). The show-stopper: Rhetos historically returns **HTTP 400 for unauthorized instead of 401** ([issue #182](https://github.com/Rhetos/Rhetos/issues/182)) — a naive "retry on 401" interceptor from any Dio tutorial will silently fail against eVisitor. The classifier must inspect status code **and** body `SystemMessage`. Full findings, detection rules, and concrete implementation recipe in the sections below. For the at-a-glance summary see **Executive Summary — Auth Lifecycle Synthesis** at the end of this document.

**Grounding & confidence.** Primary source: the official [eVisitor Web API wiki](https://www.evisitor.hr/eVisitorWiki/Javno.Web-API.ashx). Since the wiki is sparse on session mechanics, secondary grounding is the [Rhetos/AspNetFormsAuth](https://github.com/Rhetos/AspNetFormsAuth) source and readme. Where they disagree, the wiki wins; where silent, Rhetos defaults are the best-available prior. Every load-bearing claim in this document is tagged **[H]** (directly documented), **[M]** (inferred framework default, spike-verifiable), or **[L]** (industry practice, must verify).

---

## Technical Research Scope Confirmation

**Research Topic:** eVisitor Forms Auth & `.ASPXAUTH` cookie lifecycle (Flutter/Dart + Dio)

**Research Goals:** Produce an implementation recipe (first-spike grade) for the 10 auth-lifecycle questions listed in frontmatter. Stack is fixed (Dart 3.x, Dio 5.x, `dio_cookie_manager`, `PersistCookieJar`, `flutter_secure_storage`); research output must be shaped for that stack.

**Technical Research Scope:**

- Architecture Analysis — Rhetos.AspNetFormsAuth session model; single vs. multi-session; password-rotation invalidation; CSRF posture
- Implementation Approaches — Dio + `dio_cookie_manager` + `PersistCookieJar` patterns; cookie-at-rest via `flutter_secure_storage`; re-auth interceptor topology
- Technology Stack — eVisitor server side (Rhetos/ASP.NET) and client side (already chosen)
- Integration Patterns — login handshake, expiry detection, retry+re-auth sequencing, concurrent session semantics
- Performance / Operational — rate limits, lockout, observability signals, cookie TTL budgeting for seasonal-idle hosts

**Research Methodology:** Current web data with rigorous source verification; multi-source validation for load-bearing claims; confidence level framework for uncertain information; stack-specific actionable output.

**Scope Confirmed:** 2026-04-22

---

## Technology Stack Analysis

> **⚠️ Memory correction.** Three prior assumptions about eVisitor turned out to be **wrong** per the official wiki — flagging here because they also show up in stale write-ups across the web:
>
> 1. Session cookie is **not** `.ASPXAUTH`. The Rhetos plugin sets three cookies named `authentication`, `affinity`, `language`. Classic `.ASPXAUTH` is a `System.Web.Security` artifact; eVisitor doesn't use it.
> 2. Transport is **JSON for everything**, including `ImportTourists`. The XML is passed as a *string field* inside a JSON envelope — not a raw XML body.
> 3. Dates are **.NET JSON format** `"/Date(1426028400000+0100)/"`, not `YYYYMMDD`.
>
> These corrections are now reflected in reference memory.

### Server-Side Stack (eVisitor)

| Layer | Technology | Source / Confidence |
|---|---|---|
| Application framework | Rhetos (DSL-driven server framework, .NET) | eVisitor wiki endpoint path `/eVisitorRhetos_API/` **[H]** |
| Auth plugin | [Rhetos.AspNetFormsAuth](https://www.nuget.org/packages/Rhetos.AspNetFormsAuth/) (latest 6.0.0) | [GitHub repo](https://github.com/Rhetos/AspNetFormsAuth) **[H]** |
| Underlying auth primitive | ASP.NET Core Identity cookie authentication (wraps `CookieAuthenticationOptions`) | Rhetos readme **[H]** |
| Transport | HTTPS, REST, JSON request/response | eVisitor wiki: *"Svi parametri za rest pozive se šalju u JSON formatu"* **[H]** |
| Date serialization | .NET JSON `/Date(ms+offset)/` | eVisitor wiki **[H]** |
| Environments | Production (`https://www.evisitor.hr/eVisitorRhetos_API/Rest/`), Test (`https://www.evisitor.hr/testApi`) | eVisitor wiki **[H]** |

**Key implication:** Because the auth model is ASP.NET Core Identity cookies (via Rhetos), **modern API-endpoint behavior applies** — unauthorized requests return **HTTP 401/403**, not a 302 redirect to an HTML login page. This diverges from legacy `System.Web.Security` Forms Auth and is the #1 load-bearing fact for client design. **[M]** — framework default; unconfirmed specifically for eVisitor's config.

_Popular Languages:_ Server is .NET (C#); client ecosystem (per public integrator list) includes PHP, Java, .NET, and now Flutter (this project).
_Emerging Languages:_ No migration announced — Rhetos.AspNetFormsAuth 6.0.0 was released for .NET 8, suggesting ongoing maintenance rather than rewrite.
_Language Evolution:_ Classic Forms Auth → ASP.NET Core Identity cookies (same cookie-based client contract, different server internals).
_Performance Characteristics:_ Cookie auth cost is negligible; the real load profile is on `ImportTourists` and reporting endpoints, out of scope here.
_Source:_ [eVisitor Web API wiki](https://www.evisitor.hr/eVisitorWiki/Javno.Web-API.ashx), [Rhetos.AspNetFormsAuth](https://github.com/Rhetos/AspNetFormsAuth)

### Authentication Surface (eVisitor Endpoints)

**Base path (prod):** `https://www.evisitor.hr/eVisitorRhetos_API/Resources/AspNetFormsAuth/Authentication/`

| Endpoint | Method | Status | Notes |
|---|---|---|---|
| `/Login` | POST | Documented in wiki | Body `{userName, password, apikey, PersistCookie}`. Returns `true` or error JSON `{UserMessage, SystemMessage}`. Sets 3 cookies. **[H]** |
| `/Logout` | POST | Documented in wiki | Needs existing cookies; returns empty body. **[H]** |
| `/ChangeMyPassword` | POST | Exists in Rhetos — **not** documented in wiki | May or may not be exposed at eVisitor's router. **[L]** — verify with spike. |
| `/GeneratePasswordResetToken`, `/SendPasswordResetToken`, `/ResetPassword`, `/UnlockUser`, `/SetPassword` | POST | Exist in Rhetos — **not** documented in wiki | Same — probably exposed, but undocumented contract. Treat as "password flows happen via web UI, not API" for v1. **[L]** |

_Major Frameworks:_ Rhetos (server); Dio 5.x (client). No alternatives to evaluate — both are fixed.
_Micro-frameworks:_ `dio_cookie_manager` (Dio interceptor binding cookies to requests), `cookie_jar` (persistent storage).
_Evolution Trends:_ Rhetos 6 tracks .NET 8; `dio`/`cookie_jar` under active maintenance by cfug/flutterchina.
_Ecosystem Maturity:_ Mature on both sides.
_Source:_ [Rhetos/AspNetFormsAuth Readme](https://github.com/Rhetos/AspNetFormsAuth/blob/master/Readme.md), [dio_cookie_manager](https://pub.dev/packages/dio_cookie_manager), [cookie_jar](https://pub.dev/packages/cookie_jar)

### Session Cookie Surface (What the Client Receives)

| Cookie | Purpose (inferred) | Behavior |
|---|---|---|
| `authentication` | Auth ticket — the session identity | Must be resent on every subsequent request; expiry is the binding constraint. **[H]** it exists, **[M]** its TTL. |
| `affinity` | Load-balancer stickiness (server routing) | Cookie routing — likely short-lived ALB/NLB affinity cookie. Dropping it may cause inconsistent reads between servers. **[M]** |
| `language` | UI language preference | Not load-bearing for auth but wiki mandates forwarding it. **[H]** |

**Critical implementer gotcha (documented):** When a vendor manually concatenates cookies into a `Cookie:` header, the separator must be `; ` (semicolon), not a space. eVisitor's wiki explicitly calls this out as a frequent integrator bug. With Dio + `dio_cookie_manager` this is automatic — only a problem if someone hand-rolls the header. **[H]**

_Relational Databases / NoSQL / In-Memory / Data Warehousing:_ N/A for this research slice — session state is cookie-based on the server; client-side state is Drift (already chosen), which stores queue + facility data, not session data. Session cookies live in `PersistCookieJar`, not the Drift DB.
_Source:_ [eVisitor Web API wiki](https://www.evisitor.hr/eVisitorWiki/Javno.Web-API.ashx)

### Cookie TTL & Expiration Behavior

| Parameter | Value | Confidence |
|---|---|---|
| Rhetos / ASP.NET Core Identity default `CookieAuthenticationOptions.ExpireTimeSpan` | **14 days** | **[M]** — framework default, eVisitor may override |
| `PersistCookie: true` effect | Likely sets `Expires`/`Max-Age` so cookie survives process restart; `false` → session cookie, lost when process ends | **[M]** — inferred from ASP.NET Core Identity behavior, not explicitly documented for Rhetos |
| Sliding expiration | ASP.NET Core default is **on** — resets TTL if ≥50% of window elapsed on a request | **[M]** |
| 401 on expiry (for API endpoints) | Yes, not 302 redirect — "Cookie login redirects are disabled for known API endpoints" is the modern ASP.NET Core posture | **[M]** — strongly expected, confirm with spike |

**Classic `System.Web.Security` Forms Auth** defaults to 30-minute timeout — if any old write-up about eVisitor says "30 minutes", it's likely extrapolating from the wrong framework. The real default is 14 days.

_Source:_ [FormsAuthentication.SlidingExpiration (Microsoft Learn)](https://learn.microsoft.com/en-us/dotnet/api/system.web.security.formsauthentication.slidingexpiration?view=netframework-4.8.1), [Cookie login redirects disabled for API endpoints (Microsoft Learn)](https://learn.microsoft.com/en-us/dotnet/core/compatibility/aspnet-core/10/cookie-authentication-api-endpoints), [Authentication cookie lifetime & sliding expiration (brokul.dev)](https://brokul.dev/authentication-cookie-lifetime-and-sliding-expiration)

### Client-Side Stack (Already Chosen for prijavko)

| Concern | Choice | Role in auth lifecycle |
|---|---|---|
| HTTP client | Dio 5.x | Request pipeline, interceptors |
| Cookie binding | `dio_cookie_manager` | Attaches cookies from jar to outgoing requests; reads `Set-Cookie` into jar |
| Cookie storage | `cookie_jar` → `PersistCookieJar` | Serializes cookies to disk so session survives app restart |
| Storage root | `path_provider.getApplicationDocumentsDirectory()` | `PersistCookieJar` requires an existing writable path **[H]** |
| Encryption at rest | `flutter_secure_storage` (Android Keystore-backed, already in stack) | Wrap the jar file (or encrypt cookie blob) with a key held in Keystore; session cookie is bearer-equivalent — treat like a credential |
| Secure transport | HTTPS enforced by `NetworkSecurityConfig` (Android default post-API-28) | Non-negotiable |

_IDE and Editors:_ Android Studio / VSCode + Dart extension — irrelevant to this research.
_Version Control:_ Git — irrelevant to this research.
_Build Systems:_ Flutter tool + `build_runner` (for Freezed/Riverpod/Drift codegen) — irrelevant to auth lifecycle.
_Testing Frameworks:_ `flutter_test`, `mocktail`, `integration_test` — relevant in Step 5 for how we'll contract-test the auth flow.
_Source:_ [dio_cookie_manager](https://pub.dev/packages/dio_cookie_manager), [cookie_jar](https://pub.dev/packages/cookie_jar), [Solving Cookie Persistence in Flutter (Spense)](https://blog.spense.money/a-solution-to-persistent-cookie-storage-in-flutter-8e70b14d8045)

### Cloud Infrastructure and Deployment

Not a decision space for this research — eVisitor's infrastructure is operated by the Croatian National Tourist Board (HTZ). Client-side, prijavko runs on end-user Android devices. The only infra-adjacent concern is the `affinity` cookie: it signals that eVisitor is behind a load balancer with sticky sessions. Dropping affinity likely triggers a different backend instance and, in the worst case, requires re-login. **[M]** — unconfirmed but consistent with the cookie's name and wiki mandate.

_Major Cloud Providers / Container Technologies / Serverless / CDN:_ N/A for this research slice.
_Source:_ [eVisitor Web API wiki](https://www.evisitor.hr/eVisitorWiki/Javno.Web-API.ashx)

### Technology Adoption Trends

- **No announced migration** to OAuth 2.0 / OIDC / bearer tokens as of 2026-04 based on web search coverage; eVisitor appears committed to the cookie model for the foreseeable future. **[M]** — absence of news isn't proof, but nothing surfaced.
- **Rhetos 6.0.0 (NuGet 2024+)** tracks .NET 8 — the server stack is being kept current, which reduces the risk of a forced client rewrite.
- **Community examples are sparse** — public GitHub search for "eVisitor API authentication" in Flutter/Dart/PHP returned no directly usable reference integrations. Most integrators are closed-source SaaS (Chekin, Hostify, etc.).
- **Competitor apps** ([PrijaviTuriste](https://play.google.com/store/apps/details?id=hr.prijavituriste), [mVisitor](https://mvisitor.hr/)) exist on Play Store — behavior is observable but internals are not.

_Migration Patterns:_ None active — cookie-based Forms-style auth is the steady state.
_Emerging Technologies:_ N/A in this surface.
_Legacy Technology:_ Worth monitoring — if HTZ ever migrates to OIDC, every existing integrator rewrites. Low probability near-term but keep it on the risk register.
_Community Trends:_ Integrators treat eVisitor as a private contract; no open-source reference implementation dominates.
_Source:_ [eVisitor official site](https://www.evisitor.hr/), [PrijaviTuriste](https://play.google.com/store/apps/details?id=hr.prijavituriste), [Croatia eVisitor overview (Chekin)](https://chekin.com/en/blog/croatia-evisitor-what-is-it-how-to-register-your-vacation-rental/)

---

## Integration Patterns Analysis

### API Design Patterns

**Pattern in play: Cookie-authenticated REST with an out-of-band auth exchange.**

eVisitor doesn't use the OAuth 2.0 / bearer-token / refresh-token pattern that most 2020s Flutter tutorials assume. The auth exchange and the data exchange are **on the same origin, same transport, but logically separate**:

1. Auth resource family under `/Resources/AspNetFormsAuth/Authentication/` — returns `true`/`false` and sets session state in cookies
2. Data resource family under `/Rest/Htz/...` — consumes those cookies; does not issue them

**Implications for client design:**

- No token to store in app memory → the cookie jar *is* the credential store.
- No "access vs refresh token" distinction → single expiring artifact (the `authentication` cookie).
- On expiry there is no silent refresh handshake — the only recovery is **a full re-login with username + password**. Credentials must be available at re-auth time, which means they must live on the device. Android Keystore via `flutter_secure_storage` is the right home.
- There is **no token introspection endpoint** — the client cannot proactively ask "is my session still valid?" without making a real call. Best substitute: a cheap GET against a lightweight endpoint (e.g. a single-row metadata resource) as a "ping" before batch submission. **[M]**

_RESTful APIs:_ eVisitor is idiomatic REST with GET/POST/PUT/DELETE semantics on `/Rest/Htz/<Entity>/` paths, plus RPC-style POST actions (`CheckInTourist`, `ImportTourists`, `Logout`). Pagination, sorting, and filtering are documented on collection GETs.
_GraphQL APIs:_ N/A — eVisitor is REST-only.
_RPC and gRPC:_ N/A — though the action endpoints (`/ImportTourists` etc.) are effectively JSON-RPC style inside a REST envelope.
_Webhook Patterns:_ N/A — no webhook surface documented. Clients must poll.
_Source:_ [eVisitor Web API wiki](https://www.evisitor.hr/eVisitorWiki/Javno.Web-API.ashx)

### Login Handshake — Concrete Sequence

```
Client (Dio)                              eVisitor (Rhetos)
────────────                              ────────────────
1. POST /AspNetFormsAuth/Authentication/Login
   Content-Type: application/json
   { userName, password, apikey, PersistCookie: true }
                                          │
                                          │ SignInManager.PasswordSignInAsync(
                                          │   userName, password,
                                          │   isPersistent: true,
                                          │   lockoutOnFailure: true)
                                          │
                                 ◄──── 2. 200 OK
                                       Content-Type: application/json
                                       Body: true
                                       Set-Cookie: authentication=...; HttpOnly; Secure; (Max-Age=…)
                                       Set-Cookie: affinity=...; (LB-managed TTL)
                                       Set-Cookie: language=...; (long-lived)

3. POST /Rest/Htz/ImportTourists
   Cookie: authentication=…; affinity=…; language=…
   Content-Type: application/json
   { "Xml": "<Tourists>…</Tourists>" }
                                          │
                                          │ CookieAuthenticationHandler validates
                                          │ ticket → User populated → action runs
                                          │
                                 ◄──── 4. 200 OK / 4xx / 5xx
```

**Failure mode on Login (documented wiki example):**

```json
HTTP/1.1 200 OK
Content-Type: application/json

{"UserMessage": null, "SystemMessage": "Application is not registered or is deactivated or API key has expired."}
```

Note the **status code 200 on login failure** in some Rhetos error paths — the body carries the signal, not the status. Matches the Rhetos pattern: exceptions caught at the controller are serialized into a JSON error envelope. **[M]** — consistent with Rhetos issue [#182](https://github.com/Rhetos/Rhetos/issues/182) "Why does unauthorized return 400, bad request" — Rhetos is notorious for **wrapping auth/authorization outcomes in unexpected status codes**. Concrete rule for the client: **do not rely on status code alone**; always parse the body.

_Source:_ [Rhetos AuthenticationService.cs](https://github.com/Rhetos/AspNetFormsAuth/blob/master/src/Rhetos.AspNetFormsAuth/AuthenticationService.cs), [eVisitor Web API wiki](https://www.evisitor.hr/eVisitorWiki/Javno.Web-API.ashx)

### Communication Protocols

**Transport:** HTTPS only. No mention of HTTP fallback, no certificate pinning requirement documented (pinning is a client-side decision — **recommended**, given the sensitivity of personal data in `ImportTourists` and the bearer-equivalent nature of the `authentication` cookie). **[L]** — our call, not eVisitor's mandate.

**Cookie framing — the semicolon gotcha:** `Cookie: authentication=…; affinity=…; language=…` — three cookies separated by `; ` (semicolon + space). eVisitor's wiki explicitly warns against using space-only separators. With Dio + `dio_cookie_manager` this is handled by the stdlib; the warning exists for integrators hand-rolling headers in PHP/curl. Our client is safe by construction, but it's worth a unit test that asserts the outbound header shape so it stays safe through future refactors. **[H]**

**Cookie attributes (inferred, needs spike verification):**

- `authentication` — expected `HttpOnly; Secure; SameSite=Lax` (ASP.NET Core Identity defaults). `HttpOnly` is irrelevant on Flutter native (no browser JS) but still good hygiene.
- `affinity` — typically `Secure` but **not necessarily `HttpOnly`** — LB-managed cookies vary. May have a shorter TTL than `authentication`, and its loss can silently break session continuity if eVisitor's LB drops the client to a different backend mid-flight. **[M]**
- `language` — long-lived, non-sensitive.

_HTTP/HTTPS Protocols:_ Standard REST over HTTPS; Dio handles TLS natively via `HttpClient`.
_WebSocket Protocols:_ N/A — eVisitor has no documented WebSocket surface.
_Message Queue Protocols:_ N/A server-side. Client-side, the Drift-backed queue is prijavko's internal MQ analog (see "Event-Driven Integration" below).
_grpc and Protocol Buffers:_ N/A.
_Source:_ [eVisitor Web API wiki](https://www.evisitor.hr/eVisitorWiki/Javno.Web-API.ashx)

### Data Formats and Standards

| Format | Where it shows up | Notes |
|---|---|---|
| **JSON** | Everywhere: request bodies, response bodies, error envelopes | Default. Dio handles via `jsonDecode`. |
| **XML as a string** | Body of `ImportTourists`/`ImportTouristCheckOut` only | The JSON envelope wraps a `"Xml"` string field whose value is a full XML document. Serialize the XML separately (e.g. `xml` package) and embed as a JSON-escaped string. **[H]** |
| **.NET JSON date** | All date fields: `"/Date(1426028400000+0100)/"` | Custom Dio `JsonDecoder`/`Converter` needed to map into `DateTime`. Do NOT use ISO 8601 on the wire — eVisitor will reject it. **[H]** |
| **Error envelope** | On authentication and many API failures: `{"UserMessage": string|null, "SystemMessage": string}` | `UserMessage` is Croatian, safe to surface to UI unmodified. `SystemMessage` is diagnostic, log only. **[H]** |

_JSON and XML:_ JSON for framing, XML for tourist import payloads only.
_Protobuf and MessagePack:_ N/A.
_CSV and Flat Files:_ N/A on this API surface.
_Custom Data Formats:_ The .NET JSON date format is the only non-standard thing; it's an ecosystem quirk, not an eVisitor invention.
_Source:_ [eVisitor Web API wiki](https://www.evisitor.hr/eVisitorWiki/Javno.Web-API.ashx), [.NET JSON Date format reference](https://learn.microsoft.com/en-us/dotnet/standard/datetime/how-to-serialize-datetime)

### System Interoperability Approaches

**Client topology: single `Dio` instance, layered interceptors, persistent cookie jar.**

```
┌─────────────────────────────────────────────────────────┐
│  Riverpod provider graph                                │
│    → EvisitorApiClient (wraps Dio)                      │
└─────────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Dio (singleton, baseUrl = eVisitor prod/test)          │
│                                                         │
│  Interceptors (execution order, outbound ↓ / inbound ↑):│
│                                                         │
│   [1] LogInterceptor (redact cookies + password)        │
│   [2] CookieManager (reads Set-Cookie → jar,            │
│        attaches Cookie: from jar on request)            │
│   [3] AuthInterceptor (QueuedInterceptor)               │
│        - detects expired session on response            │
│        - locks, triggers re-login,                      │
│          replays queued requests                        │
│   [4] RetryInterceptor (idempotent GETs only;           │
│        does NOT retry ImportTourists)                   │
└─────────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  PersistCookieJar                                       │
│    → encrypted file storage (encryption key in          │
│       flutter_secure_storage / Android Keystore)        │
└─────────────────────────────────────────────────────────┘
```

**Why `QueuedInterceptor` and not `InterceptorsWrapper`:** Regular `Interceptor` lets concurrent requests flow through simultaneously. If 5 parallel requests all hit an expired session, you get 5 re-login attempts — a "thundering herd" of failed logins that **will trip the account lockout** (`lockoutOnFailure: true` is hard-coded in Rhetos's `PasswordSignInAsync` call). `QueuedInterceptor` serializes: only one re-login fires, the rest wait and replay with the new cookies. This is non-negotiable for multi-parallel batch submission. **[H]** — consensus pattern in Dio community. _Sources:_ [QueuedInterceptor explainer (Kuifatieh)](https://medium.com/@muhammad.kuifatieh/efficient-refresh-token-handling-in-dio-with-queued-interceptors-cc846dfdebf9), [dio issue #1308 (QueuedInterceptor proposal)](https://github.com/flutterchina/dio/issues/1308)

**Expiry detection rule (core integration contract):**

```
A response is "session dead, re-auth needed" IF:
  (status == 401 OR status == 403)
  OR (status == 400 AND body.SystemMessage matches /not authenticated|unauthorized|session/i)
  OR (status == 200 AND body is a JSON error envelope with SystemMessage
      matching /not authenticated|unauthorized|session/i
      AND the endpoint is NOT /Authentication/Login itself)

Everything else → pass through, don't re-auth.
```

The 400/200-with-body cases cover the Rhetos quirk documented in [issue #182](https://github.com/Rhetos/Rhetos/issues/182). **[M]** — exact match strings must be verified against live responses during the spike; treat the regexes as placeholders.

**Anti-pattern to avoid:** A generic "retry on any 401" interceptor — this is the pattern shipped by 90% of Dio refresh-token tutorials and it will **misbehave against Rhetos** because:
- It'll miss expired sessions that surface as 400
- It'll re-auth on legitimate 401s from ACL-style authorization failures (not all 401s are session-related)
- It'll loop if `/Login` itself returns 401 (bad credentials)

_Point-to-Point Integration:_ This is what we are — prijavko device ↔ eVisitor backend.
_API Gateway Patterns:_ N/A — no intermediary.
_Service Mesh:_ N/A — single client, single server.
_Enterprise Service Bus:_ N/A.
_Source:_ [Mastering Auth in Flutter with Dio (7twilight)](https://dev.to/7twilight/mastering-auth-in-flutter-with-dio-from-simple-access-tokens-to-a-refresh-flow-27cf), [dio_refresh package](https://pub.dev/packages/dio_refresh)

### Microservices Integration Patterns → Client-Side Resilience Patterns

Re-purposing this bucket: eVisitor is a single monolithic-ish service, so "microservices patterns" map to **client-side resilience**.

| Pattern | Applicability | Notes |
|---|---|---|
| **API Gateway pattern** | N/A | No gateway on the client side. |
| **Service discovery** | N/A | Hardcoded base URL per flavor (`dev`/`prod`). |
| **Circuit breaker** | **Yes** — for the auth endpoint specifically | If 3 consecutive login attempts fail, open circuit for N minutes before trying again — otherwise we trip the lockout. Implement as a simple counter in the `AuthInterceptor`. **[H]** — required given `lockoutOnFailure: true`. |
| **Retry with exponential backoff** | **Yes — for GETs; no — for `ImportTourists`** | GET is idempotent. `ImportTourists` may not be (wiki doesn't clarify) — a retry could create duplicate check-ins. Default: retry only on network-level failures (connection reset), never on HTTP-level errors, until we verify idempotency semantics in the spike. **[M]** |
| **Saga pattern** | N/A for auth specifically | Relevant for multi-step check-in flow (scan → validate → submit), not for session management. |
| **Bulkhead** | Minor | Separate Dio instances for auth vs. data could isolate failures; complexity not justified for v1. |

_API Gateway Pattern:_ N/A.
_Service Discovery:_ Hardcoded per-flavor base URL.
_Circuit Breaker Pattern:_ Required on the login endpoint (lockout protection).
_Saga Pattern:_ N/A for this slice.
_Source:_ [Rhetos AuthenticationService.cs (lockoutOnFailure)](https://github.com/Rhetos/AspNetFormsAuth/blob/master/src/Rhetos.AspNetFormsAuth/AuthenticationService.cs)

---

## Architectural Patterns and Design

### System Architecture Patterns

**The chosen pattern: offline-first single-page mobile client with persistent session, durable outbound queue, and server-driven session validity.**

In plain terms: prijavko is a **write-mostly** client that collects guest check-ins locally (Drift), buffers them in a state machine, and attempts delivery to eVisitor when network + session allow. The auth session is a **gate**, not a source of state — server is the source of truth for session validity.

Two architectural decisions follow from that framing:

1. **Session state is a projection, not a source.** The real auth state lives in three places: (a) the credentials in `flutter_secure_storage`, (b) the cookie jar on disk, (c) eVisitor's server-side session. Our client-side `AuthState` is a derived view over the first two + the result of the last attempted call. We do not attempt to "know" whether the session is valid without asking.
2. **Queue ≠ session.** Guests in the queue are independent of auth state. A locked-out account doesn't clear the queue — it just blocks submission until the lockout window passes. This is load-bearing for the "spotty connectivity + seasonal idle" use case in AGENTS.md.

_Microservices / Monolithic / Serverless:_ eVisitor server architecture is out of scope. Client is monolithic Flutter app — appropriate for single-user utility scale.
_Event-driven and reactive architectures:_ Internal only — Riverpod subscribes to Drift streams; no external events. See Step 3 "Event-Driven Integration" for detail.
_Domain-driven design patterns:_ Yes, per AGENTS.md — feature-based folders (`lib/features/<feature>/data|domain|presentation/`), Result-based error contract at the data layer boundary. Auth is its own feature folder.
_Cloud-native / edge architecture:_ N/A — mobile client, not distributed.
_Source:_ Internal architecture from [AGENTS.md](AGENTS.md)

### Design Principles and Best Practices

**Applied to the auth lifecycle specifically, the project's japanese-craftsmanship rules translate to:**

- **Poka-yoke (error-proofing):** The `Result<T, Failure>` contract from AGENTS.md means auth failure paths are **types**, not exceptions. `AuthFailure.lockedOut`, `AuthFailure.invalidCredentials`, `AuthFailure.networkDown` — each is a distinct variant that **forces** presentation-layer handling. No silent catches.
- **Omotenashi (hospitality for the maintainer):** The auth interceptor will be invoked from every outbound request for years. Name methods for *what they guard against*, not what they do — `shouldTriggerReauth()` is worse than `isResponseSessionExpiry()`. Every branch in the expiry detection rule gets a comment saying *why* that specific shape signals expiry (so a future maintainer doesn't simplify it away when Rhetos fixes the 400-not-401 bug).
- **Just-in-time:** Don't build token-refresh machinery we don't need. Don't build a circuit-breaker with 6 configurable knobs — one counter + one timeout. Don't abstract over "auth providers" when we have exactly one.
- **Kaizen:** The encrypting cookie `Storage` impl is ~40 lines. The `AuthInterceptor` is ~100 lines. Resist the urge to pull in `dio_refresh` or similar — it's built for OAuth 2.0 refresh-token semantics, not for full-re-login-on-every-expiry, and it'd carry assumptions that conflict with our model.

**Clean-architecture layering** (already established in AGENTS.md):

```
┌──────────────────────────────────────────────────┐
│ presentation: AuthScreen, AuthStatusIndicator    │
│   consumes AuthNotifier state via ref.watch      │
├──────────────────────────────────────────────────┤
│ domain:  AuthState sealed class (Freezed)        │
│          Credentials value object                │
│          AuthFailure variants                    │
├──────────────────────────────────────────────────┤
│ data:    AuthRepository (owns credentials &      │
│            cookie jar lifecycle)                 │
│          EvisitorApiClient (Dio + interceptors)  │
└──────────────────────────────────────────────────┘
```

_SOLID principles / Clean architecture / Hexagonal:_ Domain has no knowledge of Dio, cookie_jar, or secure_storage — repository is the port, secure_storage/cookie_jar adapters are the implementations.
_API design / GraphQL vs REST:_ Predetermined — REST, cookie-authed.
_Database design / Data architecture:_ Auth state never goes into Drift. Cookies are in the jar file, credentials in Keystore. Drift owns only queue + facility data. **Separation of session state from business state is a hard rule.**
_Source:_ [AGENTS.md](AGENTS.md), [japanese-craftsmanship.md](.claude/rules/japanese-craftsmanship.md)

### Session Lifecycle State Machine

The central design artifact for this research — six states, explicit transitions, Poka-yoke-driven.

```
                        ┌──────────────────┐
                        │     initial      │
                        │ (app cold start, │
                        │  no credentials) │
                        └────────┬─────────┘
                                 │ credentials saved
                                 ▼
                ┌────────────────────────────────┐
                │      unauthenticated           │
                │  (credentials present,         │◄──────────┐
                │   no valid cookie)             │           │
                └────────┬───────────────────────┘           │
                         │ login()                           │
                         ▼                                   │
                ┌────────────────────────────────┐           │
                │      authenticating            │           │
                └────┬────────────┬──────────────┘           │
                     │            │                          │
             success │            │ failure                  │
                     │            └──────┐                   │
                     ▼                   ▼                   │
       ┌───────────────────────┐   ┌─────────────────┐       │
       │    authenticated      │   │  authFailure    │       │
       │ (cookie in jar,       │   │  (classified    │       │
       │  requests can flow)   │   │   by reason)    │       │
       └──┬─────┬──────────────┘   └────┬─────────┬──┘       │
          │     │                       │         │          │
  401/400 │     │                       │ invalid │          │
  session │     │                       │  creds  │          │
  dead    │     │                       │         │          │
          │     │                       │         ▼          │
          │     │                       │   (clear creds,    │
          │     │                       │    go to initial)  │
          ▼     │                       │                    │
     ┌──────────┴────────────┐          │  locked            │
     │       reauth          │          │  out               │
     │  (holds request       │          ▼                    │
     │   queue via           │   ┌──────────────────┐        │
     │   QueuedInterceptor,  │   │    lockedOut     │        │
     │   runs single login)  │   │ (wait backoff,   │        │
     └────┬────────────┬─────┘   │  then retry)     │        │
          │            │         └─────────┬────────┘        │
   success│            │failure            │                 │
          │            │                   │ backoff elapsed │
          ▼            ▼                   └─────────────────┘
   back to        (re-enter authFailure
   authenticated   with new classification)
   (replay queue)
```

**Invariants (enforced by types):**

- `authenticated` is only entered after a server-confirmed 200 response from Login with cookies in the jar — never speculatively.
- `reauth` is only entered from `authenticated` — you cannot re-auth from a state where credentials haven't been established.
- Transitions from `authFailure` require **classification** (reason) — you cannot sit in a generic "failed" state.

**State machine in Dart** (sealed Freezed union):

```dart
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.authenticating() = _Authenticating;
  const factory AuthState.authenticated({required DateTime sessionEstablishedAt}) = _Authenticated;
  const factory AuthState.reauth() = _Reauth;
  const factory AuthState.lockedOut({required DateTime retryAfter}) = _LockedOut;
  const factory AuthState.authFailure(AuthFailure reason) = _AuthFailure;
}
```

### Error Classification (the core rule, extracted as a module)

The detection logic from Step 3 becomes its own decision function — **the most test-worthy code in the whole auth subsystem**. Because eVisitor's server returns unauthorized in multiple shapes, this module is also the place where the "test coverage = meaningful coverage" memory applies.

```
Classify(response) →
  ┌─ status 200 + body == true                           → OK
  ├─ status 200 + body is error envelope                 → inspect SystemMessage
  ├─ status 400 + body has SystemMessage                 → inspect SystemMessage
  ├─ status 401 OR 403                                   → SessionExpired
  ├─ status ≥ 500                                        → ServerError (do not reauth)
  ├─ no response (timeout, connection reset)             → NetworkDown
  └─ any other                                           → Unknown (log loudly, fail open)

inspect SystemMessage →
  ┌─ /locked|zaključan/i        → LockedOut (parse retry-after if present; default: 5 min)
  ├─ /invalid|nevažeć|neispra/i → InvalidCredentials
  ├─ /session|prijava|auth/i    → SessionExpired
  └─ anything else              → Unknown (domain error, surface SystemMessage as-is)
```

**Why the Croatian patterns:** eVisitor's `UserMessage` is in Croatian; `SystemMessage` is less consistent — sometimes English, sometimes localized. The regex must cover both. During the spike, log every unhandled `SystemMessage` we see so the regex catches up to reality. **[M]** — patterns need spike-based refinement.

_Source:_ [Rhetos AuthenticationService.cs](https://github.com/Rhetos/AspNetFormsAuth/blob/master/src/Rhetos.AspNetFormsAuth/AuthenticationService.cs), [ASP.NET Core Identity lockout (code-maze)](https://code-maze.com/user-lockout-aspnet-core-identity/)

### Scalability and Performance Patterns

Prijavko is a single-user mobile client; scalability dimensions are all **within one device**, not across devices:

| Axis | Concern | Pattern |
|---|---|---|
| Concurrent check-ins during peak | Multiple guests queued, multiple parallel `ImportTourists` | `QueuedInterceptor` serializes re-auth, not data calls. Data calls run in parallel, up to Dio's default `maxConnectionsPerHost`. **[H]** |
| Idle season (weeks without calls) | Cookie TTL runs out while app sits dormant | Accept re-login on first call of new season. Don't ping to keep alive — wastes cell data and triggers server cost. **[H]** |
| Battery / background | iOS-style background restrictions | Android target; work happens in foreground primarily. Queue drains when user returns to app. No background cookie-refresh needed. **[H]** |
| Memory / startup | `PersistCookieJar` reads from disk on init | Lazy-init jar on first request, not app boot. Keep cold-start fast. **[M]** |

_Horizontal vs vertical scaling:_ N/A — single-device.
_Load balancing / caching:_ The `affinity` cookie IS load-balancer-driven — server side handles it, we just forward.
_Distributed systems / consensus:_ N/A.
_Performance optimization:_ Primary win is **not making unnecessary auth probes** — treat the first 401/400 as the probe.
_Source:_ [dio_cookie_manager](https://pub.dev/packages/dio_cookie_manager)

### Integration and Communication Patterns

Already covered in Step 3. The architectural additions:

**Where interceptors live in the Riverpod graph:**

```dart
@riverpod
Dio evisitorDio(EvisitorDioRef ref) {
  final jar = ref.watch(cookieJarProvider);
  final authInterceptor = ref.watch(authInterceptorProvider);

  return Dio(BaseOptions(
    baseUrl: ref.read(envConfigProvider).evisitorBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    contentType: 'application/json',
  ))
    ..interceptors.addAll([
      LogInterceptor(requestHeader: true, requestBody: false, ..., /* redact cookies + password */),
      CookieManager(jar),
      authInterceptor,                       // QueuedInterceptor
      RetryInterceptor(retryOnMethods: {'GET'}, /* never retry POST */),
    ]);
}
```

**Provider dependency graph:**

```
envConfigProvider ─────────┐
                           ├──▶ evisitorDioProvider ─▶ evisitorApiClientProvider
cookieJarProvider ─────────┤                                      │
  └─ secureKeyProvider ────┤                                      ▼
                           │                              authRepositoryProvider
authInterceptorProvider ◄──┤                                      │
  └─ authNotifierProvider ─┘                                      │
            │                                                     │
            └────── uses authRepositoryProvider ◄─────────────────┘
```

**Important:** `authNotifierProvider` and `authInterceptorProvider` **both** need access to the `authRepositoryProvider` but must not cycle. The interceptor calls into the repository for `login()` but doesn't watch the notifier — it reports state changes **to** the notifier via a callback the repository exposes. This keeps the dependency DAG acyclic. **[H]** — Riverpod cycle detector will enforce this at test-time.

_API Design Patterns:_ Already covered in Step 3.
_Service Integration:_ Single-service integration — no fan-out.
_Data Integration:_ Drift for queue state; cookie jar for session state; `flutter_secure_storage` for credentials — three stores, clear ownership.
_Source:_ [Riverpod 3 release notes](https://riverpod.dev/docs/whats_new), [Handling Authentication State With go_router and Riverpod (Q agency)](https://q.agency/blog/handling-authentication-state-with-go_router-and-riverpod/)

### Security Architecture Patterns

**Threat model (explicit, short):**

| Adversary | Capability | Mitigation |
|---|---|---|
| Device thief (powered-off) | Read app sandbox files | Keystore-wrapped AES key for cookie jar + credentials |
| Device thief (unlocked phone) | App is open | Accept — OS-level screen lock is user's responsibility; app pin optional for v2 |
| Malicious app on same device | Read other apps' sandbox | Android app sandbox isolation protects us; nothing extra required **[H]** |
| MITM on hostile Wi-Fi | Intercept TLS | HTTPS enforced; certificate pinning optional (recommended v1) |
| Compromised or hostile `apikey` | Leaks from reverse-engineered APK | Accept — `apikey` is app-level, not per-user. Rotation = app release. Protect via code obfuscation if needed. |
| eVisitor insider | Access server-side session tables | Out of our control — rely on HTZ's posture |

**Cookie-at-rest pattern (recommended: custom encrypting `Storage`, not `hive_cookie_store`):**

Why custom: `hive_cookie_store` is v0.1.1, last updated 15 months ago, and brings `hive_ce` as a transitive dep (we have no other Hive usage). AGENTS.md rule: *"Adding a dependency is a decision, not a reflex."* A custom implementation:

- ~40 lines of Dart
- Uses `cryptography` or `pointycastle` (both already in most Flutter apps — but if not, `dart:io` + AES via a minimal dep)
- Wraps `cookie_jar`'s built-in `FileStorage` with encrypt-on-write / decrypt-on-read
- Key lives in `flutter_secure_storage` (Keystore-backed) and is generated on first run with `SecureRandom`

```dart
class EncryptedCookieStorage extends Storage {
  final Storage _inner;                  // FileStorage
  final SecretKey _key;                  // loaded from flutter_secure_storage
  final AesGcm _algorithm = AesGcm.with256bits();

  @override
  Future<String?> read(String key) async {
    final ciphertext = await _inner.read(key);
    if (ciphertext == null) return null;
    return _decrypt(ciphertext);
  }

  @override
  Future<void> write(String key, String value) =>
      _inner.write(key, _encrypt(value));
  // ... delete, init, etc.
}
```

Full implementation in Step 5.

**Certificate pinning — optional but recommended for v1:**

eVisitor handles OIB-level PII. A single MITM attack on hotel Wi-Fi could harvest guest data at scale. Pinning adds **exactly one build-time decision** (capture the cert SHA256) and ~15 lines of Dio adapter code. Cost/benefit is favorable. Counter: pinning brittleness when HTZ rotates certs — mitigation is backup pin (pin two adjacent cert fingerprints so rotation doesn't brick the app). **[M]** — our call; recommend doing it in v1. _Source:_ [Certificate Pinning in Flutter With Dio (Vibe Studio)](https://vibe-studio.ai/insights/certificate-pinning-in-flutter-with-dio)

_Security Frameworks:_ OWASP MASVS (Mobile Application Security Verification Standard) L1 — cookie-at-rest encryption and HTTPS enforcement get us there.
_Threat Landscape:_ MITM on public Wi-Fi is the realistic external threat; device compromise is the realistic internal threat.
_Secure Development Practices:_ Redact `Cookie:` and password from logs in `LogInterceptor` — non-negotiable. Crashlytics PII-scrubbing already a project rule (AGENTS.md).
_Source:_ [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage), [OWASP MASVS](https://mas.owasp.org/MASVS/)

### Data Architecture Patterns

| Store | Lifetime | Contents | Encryption |
|---|---|---|---|
| `flutter_secure_storage` | Persistent, device-bound | Username, password, cookie-jar encryption key, apikey (per-flavor) | Android Keystore |
| Cookie jar file (custom encrypting Storage) | Persistent, device-bound | `authentication`, `affinity`, `language` cookies | AES-GCM 256, key in Keystore |
| Drift SQLite DB (existing) | Persistent | Guest queue, facility data — **NO auth state** | None at DB level (sandbox only); add SQLCipher v2 |
| Riverpod in-memory state | Runtime only | Current `AuthState`, last `SystemMessage` | N/A |

**Hard rule: no auth state in Drift.** Temptation: "just cache the session expiry in a Drift table so we can show it in the UI." **Don't.** That creates two sources of truth — Drift and the cookie jar — that will drift apart. If the UI needs to show "session healthy", it subscribes to the `AuthNotifier`, which reads from the cookie jar. One source of truth.

_Relational Databases:_ Drift/SQLite — owned by business state, not auth.
_NoSQL Databases:_ N/A.
_In-Memory Databases:_ N/A.
_Data Warehousing:_ N/A.
_Source:_ [Drift](https://drift.simonbinder.eu/), [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)

### Deployment and Operations Architecture

| Concern | Approach |
|---|---|
| Flavor-based config | `--dart-define-from-file=config/{dev,prod}.json` provides `EVISITOR_BASE_URL` and `EVISITOR_API_KEY`. See [AGENTS.md](AGENTS.md). |
| Build-time secret hygiene | `config/*.json` files **must** be in `.gitignore` (verify); committed `.example.json` files document schema. |
| Certificate pin capture | Scripted via `openssl s_client -servername www.evisitor.hr -connect www.evisitor.hr:443 </dev/null \| openssl x509 -fingerprint -sha256 -noout` in a pre-release checklist. |
| Observability | Firebase Crashlytics with PII redaction (project rule). Add custom non-fatal reports for: login lockout tripped, 10+ consecutive 401/400, cookie-jar decryption failure (corrupted state). |
| Rollback on auth breakage | Remote kill-switch via Firebase Remote Config — force `AuthState.unauthenticated` on app start if flag set, so a botched release can be rescued without a Play Store push. **[M]** — optional for v1, cheap to add. |

_Source:_ [AGENTS.md](AGENTS.md), [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics)

---

## Implementation Approaches and Technology Adoption

### Technology Adoption Strategies

**Core adoption decision: build-in-house, not adopt-a-library, for the auth layer.**

Options evaluated and rejected:

| Option | Rejected because |
|---|---|
| `dio_refresh` | Built for OAuth 2.0 refresh-token flow (two-token model). eVisitor has no refresh token — full re-login required. Misfit assumptions = bug source. |
| `hive_cookie_store` | Lightly maintained (v0.1.1, 15 months stale), brings `hive_ce` transitive dep we don't otherwise need. Muri. |
| `http_certificate_pinning` package | For ~15 lines of equivalent Dio adapter code, adding a dep is waste. |
| Generic "auth state" Riverpod packages | Over-abstracted for a single-provider case. |

**Accepted:** Direct use of `dio`, `dio_cookie_manager`, `cookie_jar`, `flutter_secure_storage`, `cryptography` (already-declared-in-stack list per AGENTS.md; only `cryptography` is net-new and required for AES-GCM).

_Technology migration patterns:_ N/A — greenfield. The concern is locking in a model that doesn't paint us into a corner if eVisitor ever migrates to OIDC: our `AuthRepository` abstraction gives us a swap point.
_Gradual adoption vs big bang:_ Spike → MVP → production. See Implementation Roadmap below.
_Legacy modernization:_ N/A.
_Vendor evaluation:_ Each adopted pub.dev package reviewed for (a) last publish date, (b) maintainer, (c) issue velocity, (d) dep count.
_Source:_ [AGENTS.md](AGENTS.md), [pub.dev dio](https://pub.dev/packages/dio)

### Development Workflows and Tooling

**Implementation recipe (ordered by build sequence — each item depends on prior items):**

---

**1. `EncryptedCookieStorage` — custom encrypting wrapper around `FileStorage`**

```dart
// lib/features/auth/data/encrypted_cookie_storage.dart
import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Encrypting wrapper around `cookie_jar`'s FileStorage.
///
/// WHY: PersistCookieJar stores cookies in plaintext files by default
/// (confirmed in cookie_jar issue #23). The `authentication` cookie is
/// bearer-equivalent — leaking it gives an attacker a valid session until
/// its TTL expires (up to 14 days). Encrypting-at-rest limits blast radius
/// to the in-memory window of an active session.
class EncryptedCookieStorage extends Storage {
  EncryptedCookieStorage._(this._inner, this._secretKey);

  static const _keyAlias = 'evisitor_cookie_jar_key_v1';
  static final _secureStorage = const FlutterSecureStorage();
  static final _aes = AesGcm.with256bits();

  final FileStorage _inner;
  final SecretKey _secretKey;

  static Future<EncryptedCookieStorage> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final inner = FileStorage('${dir.path}/.evisitor_cookies/');
    await inner.init(false, true); // persistSession, ignoreExpires

    final key = await _loadOrGenerateKey();
    return EncryptedCookieStorage._(inner, key);
  }

  static Future<SecretKey> _loadOrGenerateKey() async {
    final existing = await _secureStorage.read(key: _keyAlias);
    if (existing != null) {
      return SecretKey(base64Decode(existing));
    }
    final key = await _aes.newSecretKey();
    final bytes = await key.extractBytes();
    await _secureStorage.write(key: _keyAlias, value: base64Encode(bytes));
    return key;
  }

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) =>
      _inner.init(persistSession, ignoreExpires);

  @override
  Future<String?> read(String key) async {
    final raw = await _inner.read(key);
    if (raw == null) return null;
    return _decrypt(raw);
  }

  @override
  Future<void> write(String key, String value) =>
      _inner.write(key, await _encrypt(value));

  @override
  Future<void> delete(String key) => _inner.delete(key);

  @override
  Future<void> deleteAll(List<String> keys) => _inner.deleteAll(keys);

  Future<String> _encrypt(String plaintext) async {
    final nonce = _aes.newNonce();
    final box = await _aes.encrypt(
      utf8.encode(plaintext),
      secretKey: _secretKey,
      nonce: nonce,
    );
    return base64Encode([...nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  Future<String> _decrypt(String encoded) async {
    final bytes = base64Decode(encoded);
    final nonce = bytes.sublist(0, 12);
    final mac = Mac(bytes.sublist(bytes.length - 16));
    final cipherText = bytes.sublist(12, bytes.length - 16);
    final plain = await _aes.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: _secretKey,
    );
    return utf8.decode(plain);
  }
}
```

---

**2. `CookieJarProvider` — Riverpod provider owning the jar's lifecycle**

```dart
// lib/features/auth/data/cookie_jar_provider.dart
@Riverpod(keepAlive: true)
Future<PersistCookieJar> cookieJar(CookieJarRef ref) async {
  final storage = await EncryptedCookieStorage.create();
  return PersistCookieJar(storage: storage, ignoreExpires: false);
}
```

`keepAlive: true` because session cookies outlive any individual screen. `ignoreExpires: false` because we want the jar to auto-purge expired cookies — that's our pre-401 safety net.

---

**3. `AuthInterceptor` — the brain**

```dart
// lib/features/auth/data/auth_interceptor.dart
import 'package:dio/dio.dart';

/// QueuedInterceptor (not Interceptor) — serializes re-auth so concurrent
/// 401/400s trigger exactly one login attempt, not N.
///
/// WHY: Rhetos calls PasswordSignInAsync(..., lockoutOnFailure: true) which
/// trips the ASP.NET Identity lockout (default 5 failures / 5 min) after
/// consecutive failures. Without serialization, 5 parallel batch submissions
/// against an expired session = 5 re-login attempts = potential lockout.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.repository, required this.onStateChange});

  final AuthRepository repository;
  final void Function(AuthState) onStateChange;

  // Circuit breaker — stop hammering Login after consecutive failures.
  int _consecutiveFailures = 0;
  DateTime? _circuitOpenUntil;
  static const _maxFailures = 3;
  static const _circuitCooldown = Duration(minutes: 6);

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;

    // Never attempt re-auth on a failing Login itself — infinite loop.
    if (path.contains('/Authentication/Login')) {
      return handler.next(err);
    }

    if (!_isSessionExpiry(err)) return handler.next(err);

    if (_circuitIsOpen()) {
      onStateChange(AuthState.lockedOut(retryAfter: _circuitOpenUntil!));
      return handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: const AuthFailure.lockedOut(),
      ));
    }

    onStateChange(const AuthState.reauth());
    final result = await repository.login();

    switch (result) {
      case Success():
        _consecutiveFailures = 0;
        onStateChange(AuthState.authenticated(sessionEstablishedAt: DateTime.now()));
        // Replay original request with fresh cookies attached by CookieManager.
        final retry = await repository.dio.fetch<dynamic>(err.requestOptions);
        return handler.resolve(retry);
      case Failure(:final failure):
        _consecutiveFailures++;
        if (failure is LockedOutFailure || _consecutiveFailures >= _maxFailures) {
          _circuitOpenUntil = DateTime.now().add(_circuitCooldown);
          onStateChange(AuthState.lockedOut(retryAfter: _circuitOpenUntil!));
        } else {
          onStateChange(AuthState.authFailure(failure));
        }
        return handler.reject(DioException(
          requestOptions: err.requestOptions,
          error: failure,
        ));
    }
  }

  bool _isSessionExpiry(DioException err) {
    final status = err.response?.statusCode ?? 0;
    final body = err.response?.data;
    if (status == 401 || status == 403) return true;
    if (status == 400 && body is Map) return _hasSessionExpiryMessage(body);
    if (status == 200 && body is Map) return _hasSessionExpiryMessage(body);
    return false;
  }

  bool _hasSessionExpiryMessage(Map body) {
    final msg = (body['SystemMessage'] as String?)?.toLowerCase() ?? '';
    return msg.contains('session') ||
        msg.contains('unauthorized') ||
        msg.contains('not authenticated') ||
        msg.contains('prijava');
  }

  bool _circuitIsOpen() =>
      _circuitOpenUntil != null && DateTime.now().isBefore(_circuitOpenUntil!);
}
```

---

**4. `AuthRepository` — credentials, login call, error classification**

```dart
// lib/features/auth/data/auth_repository.dart
class AuthRepository {
  AuthRepository({required this.dio, required this.credentials});

  final Dio dio;
  final CredentialsStore credentials;  // flutter_secure_storage wrapper

  Future<Result<void, AuthFailure>> login() async {
    final creds = await credentials.read();
    if (creds == null) return Failure(AuthFailure.noCredentials());

    try {
      final response = await dio.post(
        '/Resources/AspNetFormsAuth/Authentication/Login',
        data: {
          'userName': creds.userName,
          'password': creds.password,
          'apikey': creds.apiKey,
          'PersistCookie': true,
        },
      );

      // Rhetos returns 200+body=true on success, 200+error envelope on failure.
      if (response.data == true) return const Success(null);
      if (response.data is Map) return Failure(_classify(response.data as Map));
      return Failure(AuthFailure.unknown('unexpected body: ${response.data}'));
    } on DioException catch (e) {
      return Failure(AuthFailure.network(e.message ?? 'network error'));
    }
  }

  AuthFailure _classify(Map body) {
    final msg = (body['SystemMessage'] as String?)?.toLowerCase() ?? '';
    if (msg.contains('locked') || msg.contains('zaključan')) {
      return AuthFailure.lockedOut();
    }
    if (msg.contains('invalid') || msg.contains('nevažeć') || msg.contains('neispra')) {
      return AuthFailure.invalidCredentials();
    }
    if (msg.contains('api key') || msg.contains('not registered')) {
      return AuthFailure.apiKeyInvalid();
    }
    return AuthFailure.unknown(body['SystemMessage'] as String? ?? '');
  }

  Future<void> logout() =>
      dio.post('/Resources/AspNetFormsAuth/Authentication/Logout');
}
```

---

**5. `AuthNotifier` — Riverpod 3 `AsyncNotifier` for UI consumption**

```dart
// lib/features/auth/presentation/auth_notifier.dart
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Subscribe to interceptor state change callback via a side-channel.
    // The AuthInterceptor is wired with onStateChange: ref.read(authNotifierProvider.notifier).set
    // (see evisitorDio wiring).
    return const AuthState.initial();
  }

  void set(AuthState newState) => state = newState;

  Future<void> login(Credentials creds) async {
    state = const AuthState.authenticating();
    await ref.read(credentialsStoreProvider).save(creds);
    final result = await ref.read(authRepositoryProvider).login();
    switch (result) {
      case Success():
        state = AuthState.authenticated(sessionEstablishedAt: DateTime.now());
      case Failure(:final failure):
        state = AuthState.authFailure(failure);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    await ref.read(cookieJarProvider).then((jar) => jar.deleteAll());
    state = const AuthState.unauthenticated();
  }
}
```

---

_CI/CD pipelines and automation tools:_ Standard Flutter CI — `flutter analyze`, `flutter test`, integration tests against test API.
_Code quality and review processes:_ Per AGENTS.md.
_Testing strategies and frameworks:_ See below.
_Collaboration and communication tools:_ N/A — solo dev.
_Source:_ [dio_cookie_manager](https://pub.dev/packages/dio_cookie_manager), [cookie_jar](https://pub.dev/packages/cookie_jar), [cryptography package](https://pub.dev/packages/cryptography), [Riverpod 3.0](https://riverpod.dev/docs/whats_new)

### Testing and Quality Assurance

Per user-memory `feedback_qa.md`: **integration tests from day one + meaningful ≥70% coverage.** The auth layer is the most-tested in the codebase because it's the most failure-prone.

**Test pyramid, specific to auth:**

| Layer | What to test | How |
|---|---|---|
| **Unit** | `_isSessionExpiry()` classifier — every branch | Parameterized tests with fixture responses: 401, 403, 400+body, 200+error, 500, timeout, etc. |
| **Unit** | `_classify()` Croatian + English SystemMessage patterns | Fixture a table of observed SystemMessage strings; assert classification. Update as spike surfaces new strings. |
| **Unit** | `EncryptedCookieStorage` roundtrip | Write → restart (simulate) → read → assert plaintext match; assert ciphertext ≠ plaintext on disk. |
| **Unit** | Circuit-breaker | Simulate 3 failures → assert `_circuitIsOpen()` → advance time by 6 min → assert closed. |
| **Widget** | `AuthScreen` state rendering | Each `AuthState` variant renders the right UI. |
| **Integration** | Full login against eVisitor `testApi` | Real HTTP to test env; requires test creds + test apikey; runs nightly in CI if creds are in secret env. |
| **Integration** | Session-expiry recovery | Mock eVisitor's Dio adapter to return 400+"session expired" on call N, and 200+true on Login — verify request replays with new cookies. |
| **Integration** | Lockout recovery | Mock 5 consecutive login failures → verify `AuthState.lockedOut` with reasonable `retryAfter` → verify no further login calls until cooldown passes. |

**Contract test** against the test API (scheduled nightly): catches HTZ changing the auth contract. Cheap insurance.

_Unit testing / integration testing / QA tools:_ `flutter_test`, `mocktail`, `integration_test`. No new deps.
_Source:_ User memory `feedback_qa.md`, [AGENTS.md](AGENTS.md)

### Deployment and Operations Practices

| Practice | Implementation |
|---|---|
| Observability | Crashlytics non-fatal reports for: `AuthState.lockedOut` entered, cookie-jar decryption failure, 10+ consecutive classification=`unknown` SystemMessages (signals contract drift), Login returning 5xx (eVisitor infrastructure down). PII-scrubbed. |
| Release process | Standard Flutter → Play Store; internal test track → closed test → production. Flavor config split means test builds point at `testApi`, prod points at `eVisitorRhetos_API`. Verify with a release-build smoke test. |
| Release rollback | Firebase Remote Config kill-switch: `force_reauth_on_launch` boolean flag forces `AuthState.unauthenticated` on app start — recovers from a botched release without a Play Store revert. |
| Secret management | `config/prod.json` (git-ignored) holds `apikey`. `config/prod.example.json` (committed) documents schema with placeholder. |
| Incident runbook (minimum) | "App can't log in" → check Remote Config kill-switch → check Crashlytics for cookie-jar decryption errors (indicates key loss) → check `testApi` manually to see if eVisitor contract changed. |

_Monitoring and observability:_ Crashlytics (already in stack).
_Incident response:_ Manual — solo dev.
_Infrastructure as code:_ Flutter flavor config is our IaC equivalent.
_Security operations:_ Crashlytics redaction rule; no runtime secrets committed.
_Source:_ [AGENTS.md](AGENTS.md), [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics)

### Team Organization and Skills

Solo-dev project. Skills already in stack per user memory:
- Senior TypeScript/Node (gap for Dart — offset by AGENTS.md + 10k LOC codebase as walking doc)
- Intermediate BMAD skill (per user memory) — this research artifact IS part of the workflow

**Skill gaps to monitor:**
- ASP.NET / Rhetos internals — don't need to master, need to read source when contract diverges
- Dart `cryptography` package — standard crypto; shouldn't be tricky but worth a testing session

### Cost Optimization and Resource Management

Single mobile app, no servers to optimize. Relevant cost axes:

| Cost | Control |
|---|---|
| Play Store developer fee | $25 one-time, unavoidable |
| Firebase Crashlytics | Free tier ample for "coffee money" seasonal utility |
| eVisitor API calls | No direct cost, but aggressive retry against a rate-limited endpoint could result in block — architected against by circuit-breaker |
| Battery | Per-user cost; addressed by never background-pinging the API |

### Risk Assessment and Mitigation

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| eVisitor migrates to OAuth/OIDC | Low (no announcement) | High (full rewrite) | `AuthRepository` abstraction; monitor [HTZ business portal](https://www.htz.hr/en/collaborations-and-projects/evisitor) semi-annually |
| eVisitor cookie model changes (different cookie names, different TTL) | Medium | Medium | Nightly contract test; SystemMessage `unknown` reports via Crashlytics |
| Lockout trips mid-shift due to credential rotation by user | Medium | High (check-in blocked) | Circuit breaker + clear UI message with `retryAfter`; prompt user to re-enter if pattern persists |
| Cookie jar encryption key lost (Keystore wipe, reinstall) | Low | Low | Detect decrypt failure → clear jar → re-login; user re-enters credentials |
| Certificate rotation by HTZ breaks pinning | Low-medium (annual) | High (app bricked) | Backup pin (two cert fingerprints); monitor pin expiry via calendar reminder; fallback to Remote-Config-disabled pinning |
| Rhetos fixes the 400-not-401 bug without notice | Medium | Low (we already handle 401) | Our classifier matches both; no action needed |
| Concurrent-session behavior changes (server starts invalidating prior sessions) | Low | Low (our model assumes multi-session works; would still work but less efficiently) | Spike-verifiable; if confirmed, no code change |

_Source:_ [AGENTS.md](AGENTS.md), internal threat model

---

## Technical Research Recommendations

### Implementation Roadmap

**Phase 0 — Spike (1–2 days)**

Highest-leverage work: **prove the detection rule against the real API.** Nothing else depends on intuition — it depends on ground-truth responses.

- Register a test account + apikey on eVisitor test environment
- Write a throwaway Dart script (not full Flutter app) that:
  - Logs in, prints cookies received with attributes (TTL, HttpOnly, Secure)
  - Sleeps past suspected expiry, makes a data call, logs the exact response (status, headers, body)
  - Makes 5 bad-credential logins consecutively, logs the response after the lockout trips
  - Changes password via eVisitor web UI mid-session, makes a data call, logs response
- Populate classifier regex patterns from observed `SystemMessage` strings
- **Output:** `docs/research/evisitor-auth-spike-results.md` with raw response samples (PII-redacted)

**Phase 1 — MVP auth layer (2–3 days, post-spike)**

- Implement `EncryptedCookieStorage`, `CookieJarProvider`, `AuthRepository`, `AuthInterceptor`, `AuthNotifier`
- Wire into `EvisitorDioProvider` with all 4 interceptors
- Unit test the classifier with Phase 0 fixtures
- Integration test: successful login, session replay after forced 401

**Phase 2 — Hardening (1–2 days)**

- Circuit breaker state machine
- Lockout UI with `retryAfter` countdown
- Cert pinning with backup pin
- Crashlytics custom events
- Firebase Remote Config kill-switch

**Phase 3 — Operations**

- Nightly contract test in CI
- Release-checklist item: capture and compare cert fingerprint

**Defer to v2+:**

- App-level PIN/biometric over secure storage
- Logout-on-idle
- Multi-account support (one app, multiple OIBs)

### Technology Stack Recommendations

**Net-new dependencies to add:** `cryptography: ^2.7.x` (AES-GCM for cookie-at-rest). Everything else is already in AGENTS.md.

**Reject:** `dio_refresh`, `hive_cookie_store`, `http_certificate_pinning`, `auth0_flutter`, any OAuth SDK. All misfits for eVisitor's model.

### Skill Development Requirements

- 2 hours: familiarize with Rhetos.AspNetFormsAuth source (already done in this research — refer back as contract evolves)
- 1 hour: Dart `cryptography` package AES-GCM semantics (already 90% covered by recipe above)
- 4 hours: Rhetos error-shape observation during spike

### Success Metrics and KPIs

| Metric | Target | How measured |
|---|---|---|
| First-time submission success rate (north star, AGENTS.md) | >95% | Per-submission outcome logged in Drift; weekly rollup |
| Auth-induced submission failure rate | <1% | Crashlytics custom event + Drift outcome `failed (auth)` counter |
| Mean time to re-auth after expiry | <2s | Instrumentation in `AuthInterceptor` |
| Lockout incidents per month | <1 per active user | Crashlytics `AuthState.lockedOut` event count |
| `SystemMessage` classified as `unknown` | 0 (after Phase 0) | Crashlytics custom event; treat nonzero as contract-drift signal |

---

## Future Research Opportunities

- **eTurist / MUP transition**: Monitor for HTZ announcements of successor systems (rumored but unscheduled as of 2026-04). Trigger: any official HTZ news. Response: incremental TR on the new auth model.
- **Apikey registration workflow**: Current research couldn't confirm exact registration path for production apikey — spike-verify with HTZ before prod release. **[L]** confidence, **[H]** priority.
- **eVisitor 2.0 API**: Possible successor. No concrete evidence; monitor passively.
- **Concurrent-session server policy**: Verify empirically during spike whether multiple device logins coexist peacefully — load-bearing assumption for multi-facility use case.

---

# Executive Summary — Auth Lifecycle Synthesis

The prijavko-to-eVisitor authentication lifecycle is **not** a generic OAuth-with-refresh-token flow. It is **cookie-based Forms Authentication** on a Rhetos (ASP.NET Core Identity) backend with three load-bearing quirks that invalidate most off-the-shelf Flutter auth tutorials: (1) unauthorized surfaces as **HTTP 400, not 401**, historically; (2) there is **no refresh token** — every session expiry requires a full re-login, which means credentials must live on-device; (3) the login endpoint hard-codes **`lockoutOnFailure: true`**, so naive 401-retry interceptors risk locking the user out mid-shift. A correctly designed client serializes re-auth through a `QueuedInterceptor`, classifies expiry by inspecting status code AND body `SystemMessage`, circuit-breaks the login endpoint after consecutive failures, and encrypts the cookie jar at rest with a Keystore-wrapped AES key. All of this fits in ~200 lines of Dart across three files.

The research concludes that the eVisitor integration is **tractable for a solo dev** with known-good building blocks (Dio 5.x, `dio_cookie_manager`, `cookie_jar`, `flutter_secure_storage`, `cryptography`), **provided** we reject the common impulse to pull in a "refresh token" package designed for OAuth semantics that don't apply here. The recipe is durable: Rhetos 6.0.0 tracks .NET 8, and no OAuth/OIDC migration has been announced as of 2026-04. The largest residual risks are contract drift (mitigated by nightly contract tests and `unknown`-classification Crashlytics events) and apikey registration (unresolved; must be clarified with HTZ before production).

**Key Technical Findings**

- Three cookies (`authentication`, `affinity`, `language`), not `.ASPXAUTH` — all three forwarded on every call
- Cookie TTL defaults to 14 days (ASP.NET Core Identity default), with sliding expiration — **not** the 30-minute classic Web.Forms default some write-ups cite
- Error classification must inspect **status + body**, not status alone — Rhetos bugs around 400-vs-401 documented in [issue #182](https://github.com/Rhetos/Rhetos/issues/182)
- `PasswordSignInAsync(..., lockoutOnFailure: true)` is hard-coded in Rhetos — a client-side circuit breaker on the login endpoint is **mandatory** to prevent lockout during peak season
- CSRF tokens are not required — native mobile is not in the CSRF threat model, and Rhetos doesn't ship anti-forgery for API calls
- Transport is JSON end-to-end; `ImportTourists` wraps XML as a JSON string field, not a raw XML body
- `PersistCookieJar` is not encrypted by default ([cookie_jar issue #23](https://github.com/flutterchina/cookie_jar/issues/23)) — custom encrypting `Storage` wrapper recommended (~40 lines) over adding `hive_cookie_store` (stale dep)

**Top Recommendations (ranked)**

1. **Run the spike (Phase 0) before writing production code.** Observe real response shapes against the test API. Classifier regex patterns need empirical calibration.
2. **Use `QueuedInterceptor`, not `Interceptor` or `dio_refresh`.** Serialized re-auth is non-negotiable given `lockoutOnFailure: true`.
3. **Classify on status + body, not status alone.** Build the classifier as a pure function with its own test suite — it is the single most failure-prone piece of the auth layer.
4. **Custom `EncryptedCookieStorage` over `hive_cookie_store`.** ~40 lines of Dart, no stale transitive deps, Keystore-backed key.
5. **Add certificate pinning with a backup pin** in v1. eVisitor handles guest PII; the marginal cost is trivial, the risk avoidance meaningful.
6. **Treat `SystemMessage` classification = `unknown` as a first-class telemetry signal.** Crashlytics event + weekly review catches eVisitor contract drift before users do.

---

## Table of Contents

1. [Research Overview](#research-overview)
2. [Technical Research Scope Confirmation](#technical-research-scope-confirmation)
3. [Technology Stack Analysis](#technology-stack-analysis) — server-side stack, auth endpoints, cookie surface, TTL behavior, client-side stack, adoption trends
4. [Integration Patterns Analysis](#integration-patterns-analysis) — API design, login handshake diagram, communication protocols, data formats, client topology, resilience patterns, security
5. [Architectural Patterns and Design](#architectural-patterns-and-design) — state machine, error classification rule, provider graph, threat model, data architecture, deployment
6. [Implementation Approaches and Technology Adoption](#implementation-approaches-and-technology-adoption) — dependency decisions, concrete Dart recipe, testing strategy, ops, risk register
7. [Technical Research Recommendations](#technical-research-recommendations) — roadmap (Phase 0 spike → Phase 3 ops), stack, KPIs
8. [Future Research Opportunities](#future-research-opportunities)
9. [Executive Summary — Auth Lifecycle Synthesis](#executive-summary--auth-lifecycle-synthesis) (this section)

---

## Research Methodology and Source Verification

**Primary sources (canonical, H-confidence):**

- [eVisitor Web API wiki](https://www.evisitor.hr/eVisitorWiki/Javno.Web-API.ashx) — the documented contract, ground truth for endpoints, payloads, cookies
- [Rhetos/AspNetFormsAuth Readme](https://github.com/Rhetos/AspNetFormsAuth/blob/master/Readme.md) — the framework powering eVisitor's auth plugin
- [Rhetos/AspNetFormsAuth source](https://github.com/Rhetos/AspNetFormsAuth/blob/master/src/Rhetos.AspNetFormsAuth/AuthenticationService.cs) — definitive on `lockoutOnFailure: true` and method signatures
- [Rhetos issue #182](https://github.com/Rhetos/Rhetos/issues/182) — confirms historical 400-for-unauthorized behavior

**Secondary sources (M-confidence framework defaults):**

- [FormsAuthentication.SlidingExpiration (Microsoft Learn)](https://learn.microsoft.com/en-us/dotnet/api/system.web.security.formsauthentication.slidingexpiration?view=netframework-4.8.1)
- [Cookie login redirects disabled for API endpoints (Microsoft Learn)](https://learn.microsoft.com/en-us/dotnet/core/compatibility/aspnet-core/10/cookie-authentication-api-endpoints)
- [Authentication cookie lifetime & sliding expiration (brokul.dev)](https://brokul.dev/authentication-cookie-lifetime-and-sliding-expiration)
- [User Lockout with ASP.NET Core Identity (Code Maze)](https://code-maze.com/user-lockout-aspnet-core-identity/)

**Client-side implementation sources:**

- [dio_cookie_manager](https://pub.dev/packages/dio_cookie_manager), [cookie_jar](https://pub.dev/packages/cookie_jar), [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- [Mastering Auth in Flutter with Dio (7twilight)](https://dev.to/7twilight/mastering-auth-in-flutter-with-dio-from-simple-access-tokens-to-a-refresh-flow-27cf)
- [Efficient Refresh Token Handling with Queued Interceptors (Kuifatieh)](https://medium.com/@muhammad.kuifatieh/efficient-refresh-token-handling-in-dio-with-queued-interceptors-cc846dfdebf9)
- [Riverpod 3.0 release notes](https://riverpod.dev/docs/whats_new)
- [Certificate Pinning in Flutter With Dio (Vibe Studio)](https://vibe-studio.ai/insights/certificate-pinning-in-flutter-with-dio)
- [Solving Cookie Persistence in Flutter (Spense)](https://blog.spense.money/a-solution-to-persistent-cookie-storage-in-flutter-8e70b14d8045)

**Research web search queries executed:**

1. eVisitor Croatia Web API authentication login endpoint ASPXAUTH cookie
2. eVisitor eTurist 2025-2026 API migration OAuth OIDC authentication changes
3. Dio dart dio_cookie_manager PersistCookieJar ASP.NET Forms Authentication
4. ASP.NET Forms Authentication .ASPXAUTH cookie sliding expiration default timeout
5. Rhetos framework AspNetFormsAuth authentication cookie name timeout persistent
6. Rhetos framework unauthorized 400 401 authentication error response code
7. Dio interceptor 401 retry refresh token flutter pattern best practice
8. Dio QueuedInterceptorsWrapper lock unlock re-authenticate pending requests cookie
9. ASP.NET Core Identity cookie authentication concurrent sessions multiple devices invalidate
10. Rhetos REST API 401 response body format JSON UserMessage SystemMessage unauthorized
11. flutter cookie_jar PersistCookieJar encrypted storage flutter_secure_storage pattern
12. hive_cookie_store flutter encryption HiveCipher AES example usage
13. Riverpod 3 AsyncNotifier auth state login logout pattern
14. ASP.NET Identity lockout response distinguish locked out vs invalid credentials
15. Dio Flutter certificate pinning HttpClientAdapter pinned sha256 example
16. "eVisitor" API authentication cookie PHP OR Dart OR Flutter OR Java example github

**Quality assurance:**

- **Source verification:** Every H-tagged claim cross-checked against at least two independent sources (e.g. Rhetos Readme + source file; eVisitor wiki + ASP.NET Core Identity docs).
- **Confidence calibration:** Claims that could not be empirically verified against eVisitor's specific deployment are tagged [M] (framework default) or [L] (industry practice). The Phase 0 spike exists specifically to promote [M] claims to [H].
- **Research limitations:** (a) No live access to eVisitor production API during research; (b) no test apikey during research; (c) no public reference integrations in any language — most integrators are closed-source; (d) Croatian-language `SystemMessage` patterns in the classifier are best-guess and need spike-based refinement.
- **Transparency:** Three prior assumptions in user memory (cookie name, transport format, date format) were proven wrong during this research and have been corrected in `reference_evisitor.md`.

---

## Technical Research Conclusion

### Summary of Key Technical Findings

The eVisitor auth surface is **well-understood enough to build confidently**, with three caveats that were not obvious from public documentation alone: the 400-not-401 Rhetos quirk, the hard-coded `lockoutOnFailure: true`, and the three-cookie (not one) session model. Every major design decision — `QueuedInterceptor` topology, status-plus-body classifier, login circuit breaker, custom encrypting cookie storage — flows directly from those three facts.

The implementation recipe is compact: ~200 lines of Dart across `EncryptedCookieStorage`, `AuthInterceptor`, `AuthRepository`, `AuthNotifier`. No speculative abstractions, no premature "auth provider" interfaces, no framework-level indirection. Dependencies added: exactly one (`cryptography`).

### Strategic Technical Impact Assessment

For prijavko specifically, this research de-risks the **first load-bearing integration** the product has. It promotes the auth layer from "unknown surface that might sink the project" to "known recipe with clear failure modes and a testable classifier." That matters because:

- The north-star metric is *first-time submission success rate without field corrections* — auth failures count as submission failures from the user's perspective.
- The target user is a host at the door with spotty Wi-Fi in peak season — the app must not fail in clever, silent ways that mask a dead session as a network problem.
- The product is "coffee money ambition" — the engineering budget does not allow a second auth rewrite. Getting it right in Phase 1 is cheaper than getting it wrong twice.

The research also produces a clean **abstraction boundary** — the `AuthRepository` port — that isolates all eVisitor-specific behavior behind a Dart interface. If HTZ eventually migrates to OIDC, only the repository changes; the state machine, interceptor topology, UI, and error surface all stay as-is.

### Next Steps Technical Recommendations

**Immediate (this sprint):**

1. Acquire test-environment apikey from HTZ (prerequisite for Phase 0)
2. Execute the Phase 0 spike script — observe real responses, calibrate classifier patterns
3. Write the spike-results doc under `docs/research/evisitor-auth-spike-results.md`

**Next sprint (after Phase 0):**

4. Implement Phase 1 auth layer following the recipe in [Implementation Approaches](#implementation-approaches-and-technology-adoption)
5. Stand up nightly contract test in CI
6. Add Crashlytics events for `unknown` classification + lockout tripped

**Before first production release:**

7. Clarify apikey registration path with HTZ for production
8. Capture cert fingerprints (primary + backup) and wire pinning into release builds
9. Firebase Remote Config kill-switch added to main flow

**Monitor in perpetuity:**

10. HTZ communications for eTurist / OIDC migration signals
11. `unknown`-classification volume as a contract-drift leading indicator

---

**Research Completion Date:** 2026-04-22
**Research Period:** comprehensive current technical analysis, verified against 2024–2026 sources
**Document Length:** as needed for comprehensive technical coverage — recipe-grade, not survey-grade
**Source Verification:** all technical facts cited with current sources; confidence levels applied throughout
**Technical Confidence Level:** High on documented facts; Medium on framework-default inferences; empirical spike required for Low-confidence claims before production build

_This technical research document serves as the authoritative technical reference for eVisitor auth-lifecycle implementation in prijavko, and provides spike-ready guidance for the first-sprint auth layer build._


### Event-Driven Integration

Server side (eVisitor) is not event-driven — no webhooks, no pub/sub. The client-side analog matters for prijavko's "offline-first with spotty connectivity" requirement:

- **Event-like primitives:** guest state machine (`captured → fieldsConfirmed → … → sent`) — each transition is an "event" persisted in Drift before it becomes observable.
- **Replay on reconnect:** when the auth session is re-established, all queued `ready` guests are replayed through `ImportTourists`. The cookie jar surviving process death (via `PersistCookieJar`) is what makes "replay after crash/app-kill" possible.
- **Drift as event log:** writes to Drift are the durable record; Riverpod streams are the projection. If we needed it, we could add an explicit audit/outbox table — but v1 doesn't need it. **Muri watch:** don't over-engineer an outbox pattern before we've proven one is needed.

_Publish-Subscribe Patterns:_ Internal only — Riverpod providers subscribing to Drift streams.
_Event Sourcing:_ Not used. Drift stores current state, not event history.
_Message Broker Patterns:_ N/A — no broker in the prijavko stack (monzukuri: minimal deps).
_CQRS Patterns:_ N/A — overkill for a single-user mobile app.
_Source:_ Internal architecture from [AGENTS.md](AGENTS.md)

### Integration Security Patterns

| Concern | Pattern | Confidence |
|---|---|---|
| **Auth credential storage** | Username + password in `flutter_secure_storage` (Android Keystore-backed). Required because there's no refresh token — full re-login on expiry needs the original credentials on-device. | **[H]** |
| **Session cookie at rest** | `PersistCookieJar` **is not encrypted by default** — confirmed in [cookie_jar issue #23](https://github.com/flutterchina/cookie_jar/issues/23). The `authentication` cookie is bearer-equivalent; anyone with file-system access reads it. **Mitigation options:** (a) `hive_cookie_store` with AES cipher, key held in `flutter_secure_storage`; (b) custom `Storage` impl wrapping `PersistCookieJar`'s `FileStorage` with encrypt/decrypt in `read`/`write`. Option (b) is simpler — ~40 lines of Dart. | **[H]** |
| **TLS integrity** | HTTPS enforced by Android `NetworkSecurityConfig` (API 28+ default). **Certificate pinning** is optional but advisable for an app that ships user-identifying data to a government endpoint. Dio supports it via `HttpClientAdapter` override. | **[M]** — our call; not eVisitor's mandate |
| **API key rotation** | `apikey` is per-application; rotation needs a code release. No mitigation — treat as a build-time secret in the flavor config, not a runtime secret. | **[H]** |
| **Concurrent session attacks** | ASP.NET Core Identity by default **does not invalidate prior sessions on re-login** — multiple devices stay logged in. Good for multi-worker ops, but means if someone steals a cookie, logging out on the phone doesn't invalidate the stolen copy. Rhetos's `Logout` signs out locally only. **Mitigation:** minimize cookie TTL by avoiding `PersistCookie=true` for short-lived sessions — accept re-login cost in exchange for smaller attack window. Decision in Step 5. | **[M]** — derived from ASP.NET Identity default behavior |
| **Account lockout** | `PasswordSignInAsync(..., lockoutOnFailure: true)` is hard-coded in Rhetos. Defaults per ASP.NET Identity `IdentityOptions.LockoutOptions`: **5 failed attempts → 5-minute lockout**, configurable by eVisitor but defaults are the best prior. Client MUST circuit-break before tripping this, or we lock out the user in the middle of a check-in shift. | **[M]** |
| **CSRF / anti-forgery** | Not mentioned in eVisitor wiki, not mentioned in Rhetos source. Not applicable for non-browser REST clients anyway — CSRF exploits ambient browser cookies. Native mobile is not vulnerable. **No client action required.** | **[H]** |

_OAuth 2.0 and JWT:_ N/A — eVisitor uses cookie Forms Auth exclusively.
_API Key Management:_ `apikey` is a per-app secret, distributed via the flavor config `--dart-define-from-file`.
_Mutual TLS:_ Not documented as a requirement; not implementing.
_Data Encryption:_ HTTPS in flight; cookie jar encrypted at rest (pattern above).
_Source:_ [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage), [hive_cookie_store](https://pub.dev/packages/hive_cookie_store), [cookie_jar issue #23 (not encrypted by default)](https://github.com/flutterchina/cookie_jar/issues/23), [ASP.NET Core Cookie Authentication & revocation (Simple Talk)](https://www.red-gate.com/simple-talk/development/dotnet-development/using-auth-cookies-in-asp-net-core/)

---
