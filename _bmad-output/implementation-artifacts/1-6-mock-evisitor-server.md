# Story 1.6: Mock eVisitor Server

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer**,
I want **a local Fastify + TypeScript mock of the eVisitor REST API running from day one**,
so that **every subsequent epic (Auth, Submit, Queue, History) can make real HTTP calls against a deterministic backend without depending on the rate-limited, snapshot-scheduled real eVisitor test API**.

## Acceptance Criteria

1. **Mock reachable from AVD** — Given the mock server is started with `pnpm dev` from `test-infra/mock-evisitor/`, when the Flutter app runs with `--dart-define-from-file=config/local.json` on an Android Studio AVD, then `http://10.0.2.2:8080` resolves to the mock and `POST /Login`, `POST /CheckInTourist`, `POST /ImportTourists` requests succeed end-to-end. Server MUST bind to `0.0.0.0` (not `127.0.0.1`) so AVD loopback `10.0.2.2` can reach it.

2. **Login success path** — Given a `POST /Login` with form-encoded `username=testuser&password=testpass` (valid test credentials defined in fixtures), when the mock processes the request, then it responds `200 OK` with header `Set-Cookie: ASP.NET_SessionId=testsession123; HttpOnly; Path=/; Max-Age=<SESSION_TTL_SECONDS>`. Cookie name **MUST be** `ASP.NET_SessionId` (exact casing — matches real eVisitor).

3. **Login failure path** — Given a `POST /Login` with invalid credentials (anything not matching the valid fixture), when the mock processes the request, then it responds `401 Unauthorized` with no `Set-Cookie` header.

4. **Validation error (duplicate detection by doc number pattern)** — Given a `POST /CheckInTourist` or `POST /ImportTourists` whose XML body contains a guest `DocumentNumber` matching the pattern `ERR_VALIDATION_*`, when the mock processes the request, then it responds `400 Bad Request` with JSON body `{"SystemMessage":"Validation error: invalid document","UserMessage":"Putovnica nije važeća."}`. Croatian `UserMessage` MUST be passed through verbatim (matches real eVisitor error envelope).

5. **Duplicate guest error** — Given a guest `DocumentNumber` matching pattern `ERR_DUPLICATE_*`, when the mock processes the request, then it responds `409 Conflict` with JSON body `{"SystemMessage":"Duplicate guest","UserMessage":"Gost je već prijavljen."}`.

6. **Session expiry / re-auth path** — Given a request with an absent cookie, expired cookie (past `Max-Age`), OR with header `X-Mock-Scenario: expire-session`, when the mock processes `POST /CheckInTourist` or `POST /ImportTourists`, then it responds on **two branches, both exercised by tests**:
   - Default: `401 Unauthorized` with `{"SystemMessage":"Session expired","UserMessage":""}` JSON body.
   - When header `X-Mock-Scenario: redirect-login` is also present: `302 Found` with `Location: /Login` header **and an HTML body** (`Content-Type: text/html`) containing a minimal login page — this exercises the `AuthFailure` non-JSON body path in the Flutter client.

7. **Service unavailable path** — Given a request with header `X-Mock-Scenario: unavailable` (any endpoint), when the mock processes the request, then it responds `503 Service Unavailable` with `{"SystemMessage":"Service unavailable","UserMessage":""}`.

8. **Healthcheck** — Given `GET /healthz`, when the mock is running, then it responds `200 OK` with `{"status":"ok"}` in <50ms. Used by `docker-compose.e2e.yml` (Epic 2, Story 2.1) healthcheck probe — endpoint MUST be dependency-free (no filesystem/db access).

9. **Import batch response shape** — Given a `POST /ImportTourists` with a batch of N guests in XML body, when the mock processes it, then it responds `200 OK` with a JSON **array** of per-guest entries `[{"ID":"<guid>","SystemMessage":"","UserMessage":""}, ...]` preserving the `ID` (GUID) from each guest XML element. Errors for individual guests (`ERR_VALIDATION_*`, `ERR_DUPLICATE_*`) appear as non-empty `SystemMessage`/`UserMessage` on that guest's entry; the HTTP status remains 200 for partial-success batches (matches real eVisitor semantics — per-guest errors, not batch rejection).

10. **Fixtures drive responses** — Given the fixture directory `test-infra/mock-evisitor/fixtures/`, when the mock boots, then all scripted responses (success bodies, error envelopes) are loaded from **JSON files** on disk — NOT hardcoded in route handlers. Adding a new error case = adding a JSON fixture + a pattern match, not editing handler code.

11. **Configurable session TTL** — Given env var `SESSION_TTL_SECONDS` (default `300`), when the mock starts, then the `Set-Cookie` `Max-Age` and server-side session expiry both honor this value. Patrol E2E tests (Epic 2.3) rely on short TTLs to exercise natural re-auth without `X-Mock-Scenario` headers.

12. **Contract tests (vitest) green** — Given contract tests in `test-infra/mock-evisitor/test/`, when `pnpm test` runs (invokes `vitest`), then every fixture/scenario listed in AC 2–9 is covered by at least one test asserting: exact HTTP status, exact `Content-Type`, presence/shape of `Set-Cookie` (login), and exact JSON envelope shape (`{SystemMessage, UserMessage}` or array thereof). Tests run headlessly (no external HTTP calls) — exercise Fastify via `app.inject()`.

13. **Run scripts documented** — Given `test-infra/README.md`, when a new developer reads it, then they find: (a) `cd test-infra/mock-evisitor && pnpm install && pnpm dev` starts the server on `:8080`, (b) `pnpm test` runs contract tests, (c) `pnpm build` produces a `dist/` suitable for the Docker image built in Story 2.1, (d) the relationship between `config/local.json` (AVD dev) and `config/test.json` (compose CI — future Story 2.1).

14. **Flutter local config wired** — Given `prijavko/config/`, when inspecting the folder, then `local.json` exists with exact contents `{"API_BASE":"http://10.0.2.2:8080","AD_ENABLED":"false"}` (string `"false"` matches existing `dev.json`/`prod.json` convention — `String.fromEnvironment` consumes strings). **This replaces `dev.json` for daily development going forward** — `dev.json` MAY remain for pointing at the real eVisitor test API when needed, but `local.json` is the new default.

15. **No Flutter coupling** — Given the mock is a separate TypeScript project, when inspecting `test-infra/mock-evisitor/package.json`, then it has zero dependencies on Flutter/Dart tooling. The TypeScript project can be cloned, installed, and run on a machine without Flutter SDK. (Parallel-implementable with Story 1.1 — validated: 1.1 is done, this story is unblocked.)

## Tasks / Subtasks

- [ ] **Create `test-infra/mock-evisitor/` Fastify + TypeScript project** (AC: #1, #15)
  - [ ] `pnpm init`; `pnpm add fastify @fastify/formbody @fastify/cookie`; `pnpm add -D typescript tsx vitest @types/node @vitest/coverage-v8`
  - [ ] `tsconfig.json`: `"target":"ES2022","module":"NodeNext","strict":true,"outDir":"dist"`
  - [ ] `package.json` scripts: `"dev":"tsx watch src/server.ts"`, `"build":"tsc -p ."`, `"start":"node dist/server.js"`, `"test":"vitest run"`, `"test:coverage":"vitest run --coverage"`
  - [ ] Entry: `src/server.ts` — `buildApp()` factory (for `app.inject()` tests) + `listen({ host: '0.0.0.0', port: 8080 })` in `main`

- [ ] **Fixture loader** (AC: #10)
  - [ ] `test-infra/mock-evisitor/fixtures/`: `login_success.json`, `login_failure.json`, `submit_success.json`, `submit_error_validation.json`, `submit_error_duplicate.json`, `submit_error_session.json`, `submit_error_unavailable.json`
  - [ ] `src/fixtures.ts`: read JSON files at boot, type via `FixtureEnvelope = { SystemMessage: string; UserMessage: string }`, export `loadFixtures()` → typed record

- [ ] **Login route** (AC: #2, #3)
  - [ ] `src/routes/login.ts`: `POST /Login` with `@fastify/formbody` parsing
  - [ ] Valid credentials (hardcoded in a fixture `login_success.json`): `username=testuser`, `password=testpass` → `reply.setCookie('ASP.NET_SessionId', 'testsession123', { httpOnly: true, path: '/', maxAge: SESSION_TTL_SECONDS }).code(200).send({ status: 'ok' })`
  - [ ] Invalid → `reply.code(401).send()` (no body needed — matches AC #3)
  - [ ] **Guardrail:** cookie name MUST be exactly `ASP.NET_SessionId` — real eVisitor is case-sensitive

- [ ] **Session validation hook** (AC: #6, #11)
  - [ ] `src/session.ts`: `validateSession(request)` reads `ASP.NET_SessionId` cookie, checks in-memory session store (map of `token → expiresAt`), returns `{ valid: boolean, expired: boolean }`
  - [ ] `SESSION_TTL_SECONDS` from `process.env.SESSION_TTL_SECONDS ?? '300'` — parsed once at boot
  - [ ] On valid login, insert `'testsession123' → Date.now() + ttl*1000` into store

- [ ] **Submit routes** (AC: #4, #5, #6, #9)
  - [ ] `src/routes/submit.ts`: `POST /CheckInTourist` and `POST /ImportTourists`
  - [ ] Body parsing: accept `application/xml` and `text/xml`; use a minimal XML parser (`fast-xml-parser` — add dep) to extract `DocumentNumber` and `ID` per guest
  - [ ] Scenario precedence (ordered — first match wins):
    1. Header `X-Mock-Scenario: unavailable` → 503 + fixture `submit_error_unavailable.json`
    2. Header `X-Mock-Scenario: expire-session` OR no/expired cookie → if also `X-Mock-Scenario: redirect-login` → 302 + HTML body; else 401 + fixture `submit_error_session.json`
    3. For each guest: `DocumentNumber` matches `/^ERR_VALIDATION_/` → error envelope; `/^ERR_DUPLICATE_/` → error envelope
    4. Default → success envelope
  - [ ] `CheckInTourist` returns a single object; `ImportTourists` returns an array preserving per-guest `ID`

- [ ] **Healthcheck** (AC: #8)
  - [ ] `src/routes/health.ts`: `GET /healthz` → `{ status: 'ok' }`. No imports of session/fixture modules — standalone

- [ ] **Contract tests (vitest)** (AC: #12)
  - [ ] `test-infra/mock-evisitor/test/login.test.ts` — both credentials paths, cookie name + HttpOnly + Max-Age assertions
  - [ ] `test/submit.test.ts` — CheckInTourist: success, ERR_VALIDATION, ERR_DUPLICATE; ImportTourists: batch with mixed outcomes (asserts per-guest `ID` preserved, status remains 200)
  - [ ] `test/session.test.ts` — missing cookie → 401; `X-Mock-Scenario: redirect-login` → 302 + `Content-Type: text/html`; expired session via `SESSION_TTL_SECONDS=1` + `setTimeout`
  - [ ] `test/health.test.ts` — 200, body shape, responds without side effects
  - [ ] Use `app.inject({ method, url, headers, payload })` — no real network

- [ ] **Flutter `config/local.json`** (AC: #14)
  - [ ] Create `prijavko/config/local.json` with `{"API_BASE":"http://10.0.2.2:8080","AD_ENABLED":"false"}`
  - [ ] Sanity check: `cd prijavko && flutter build apk --debug --dart-define-from-file=config/local.json` succeeds (does NOT require the mock to be running — compile-time dart defines)

- [ ] **`test-infra/README.md`** (AC: #13)
  - [ ] Sections: Overview, Quick start (`pnpm install && pnpm dev`), Running contract tests, How fixtures work, Scenario headers (`X-Mock-Scenario: unavailable | expire-session | redirect-login`), Relationship to Flutter configs (`local.json` now, `test.json` coming in Story 2.1), env vars (`SESSION_TTL_SECONDS`, `PORT` default 8080)

- [ ] **Project-root wiring** (AC: #15)
  - [ ] If adopting pnpm workspaces at repo root: add root `pnpm-workspace.yaml` with `packages: ['test-infra/*']`. If NOT adopting workspaces yet, the mock-evisitor folder is a standalone pnpm project — document choice in `test-infra/README.md`
  - [ ] `.gitignore`: ensure `test-infra/**/node_modules`, `test-infra/**/dist`, `test-infra/**/coverage` are ignored

- [ ] **Quality gates**
  - [ ] `pnpm test` green (all contract tests pass)
  - [ ] `pnpm build` succeeds with zero TS errors (`strict: true`)
  - [ ] Manual smoke: `pnpm dev` → `curl http://localhost:8080/healthz` → `{"status":"ok"}`
  - [ ] Manual smoke: AVD + Flutter app built with `config/local.json` → login to mock succeeds (cookie set, subsequent submit accepted)

## Dev Notes

### Scope

- **In:** Fastify + TypeScript mock project under `test-infra/mock-evisitor/`; fixtures; contract tests via `vitest`; `config/local.json` in Flutter app; `test-infra/README.md`; manual smoke against AVD.
- **Out:** Dockerfile for the mock (Story **2.1**). `docker-compose.e2e.yml` (Story **2.1**). `config/test.json` (Story **2.1**). Patrol E2E suite (Story **2.3**). Dart client code calling the mock (Epic **6**).
- **Parallel-implementable marker from epics.md:** "Implement parallel with Story 1.1" — Story 1.1 is already `done`, so this story is now simply the last Epic 1 story; no coordination overhead.

### Architecture compliance

- **Mock project location:** `test-infra/mock-evisitor/` at repo root (NOT inside `prijavko/`). [Source: `_bmad-output/planning-artifacts/architecture.md` — "Mock eVisitor Server Contract"]
- **Endpoints mirrored:** `/Login`, `/CheckInTourist`, `/ImportTourists`, `/healthz`. [Source: architecture.md:329–334]
- **Fixtures location:** `test-infra/mock-evisitor/fixtures/*.json`. [Source: architecture.md:336]
- **Contract tests location:** `test-infra/mock-evisitor/test/`. [Source: architecture.md:354]
- **Cookie name:** `ASP.NET_SessionId` (exact — matches real eVisitor ASP.NET Forms Auth). [Source: architecture.md:331, 345]
- **Error envelope:** `{SystemMessage, UserMessage}` JSON — `UserMessage` is the Croatian human-readable string passed through to the user by Dart's `ErrorMapper`. [Source: architecture.md:318]
- **Dual-use flavors:** `local.json` (AVD → host mock via `10.0.2.2`) + `test.json` (compose → `mock-evisitor:8080`). `test.json` is Story 2.1; do NOT create it in this story. [Source: architecture.md:411–420]

### Technical requirements (guardrails)

| Topic | Requirement |
|-------|-------------|
| **Runtime** | `node:20` (LTS). Dockerfile in 2.1 uses `node:20-alpine`. Use `"engines": { "node": ">=20 <21" }` in `package.json` to prevent version drift. [Source: architecture.md:518] |
| **Language** | TypeScript with `strict: true`, `noUncheckedIndexedAccess: true`, `exactOptionalPropertyTypes: true`. Zero `any` — use `unknown` and narrow. [Poka-yoke — project craftsmanship rules] |
| **Package manager** | **pnpm** (chosen by epics.md — "pnpm workspaces"). Commit `pnpm-lock.yaml`. Do NOT use npm/yarn inside `test-infra/`. [Source: epics.md:449] |
| **HTTP framework** | **Fastify** v4.x or v5.x (both stable in 2026) — prefer v5 for native ESM + undici. Justify version pin in a comment in `package.json`. [Source: architecture.md:325] |
| **Bind address** | `0.0.0.0` — binding `localhost`/`127.0.0.1` blocks AVD loopback. Emulator `10.0.2.2` → host loopback; if server is on loopback-only, connection fails silently with `ECONNREFUSED`. [Poka-yoke — stated AC #1] |
| **Port** | `8080` default. Honor `process.env.PORT` for flexibility, but all docs/configs assume `8080`. |
| **XML parsing** | `fast-xml-parser` (`^4.x`). Fastify doesn't ship XML parsing — register a custom content-type parser OR read raw body and parse in handler. Keep parsing in `src/xml.ts` isolated (easy swap, unit-testable). |
| **Cookie plugin** | `@fastify/cookie` — for `reply.setCookie(...)` with correct attributes. |
| **Form body plugin** | `@fastify/formbody` — `/Login` is form-encoded (matches real eVisitor). |
| **Session store** | In-memory `Map<token, expiresAt>`. No persistence — every restart is a clean slate (good for CI determinism). Do NOT introduce Redis or SQLite. |
| **Fixture schema** | Every fixture JSON MUST conform to `{ "SystemMessage": string, "UserMessage": string }` (or array thereof for batch). Validate at load time — fail fast if malformed. |
| **Error handling** | Fastify global error handler returns `500 { SystemMessage: "Internal mock error", UserMessage: "" }` — never leak stack traces. |
| **Logging** | Fastify's built-in pino logger, `level: 'info'` in dev, `'warn'` when `NODE_ENV=test`. Log every request method + url + status — helps debugging Patrol E2E failures in CI. |

### Scenario header precedence (critical — test this explicitly)

When multiple `X-Mock-Scenario` values could apply, apply this order (first match wins):

1. `X-Mock-Scenario: unavailable` → 503 (outranks everything — simulates total outage)
2. Session check: `X-Mock-Scenario: expire-session` OR missing/expired cookie → 401 (or 302 if also `redirect-login`)
3. Per-guest doc-number patterns (`ERR_VALIDATION_*`, `ERR_DUPLICATE_*`) → per-guest error envelope
4. Default → success envelope

This ordering exists because Patrol tests stack scenarios (e.g., "during an import batch, session expires mid-request"). Document the ordering in `test-infra/README.md` AND in a header comment in `src/routes/submit.ts`.

### Library / framework versions (latest stable, 2026-04)

| Package | Version constraint | Rationale |
|---------|-------------------|-----------|
| `fastify` | `^5.0.0` (or `^4.28.0` if v5 native-ESM friction) | Fastify 5 stable since late 2024; better TS types, native ESM. v4 is LTS'd. Pick one and pin. |
| `@fastify/cookie` | matching major of fastify | Plugin major aligns with Fastify major |
| `@fastify/formbody` | matching major of fastify | Same |
| `fast-xml-parser` | `^4.5.0` | Actively maintained, no known CVEs in the 4.5+ line as of 2026-04 |
| `vitest` | `^2.0.0` (or `^3.0.0` if stable on your node 20) | `vitest` 3.x GA'd early 2026 — either is fine; align with lockfile once installed |
| `@vitest/coverage-v8` | matching vitest major | v8 coverage is the default going forward |
| `tsx` | `^4.19.0` | Watch-mode dev runner; replaces ts-node-dev |
| `typescript` | `^5.6.0` | Stable LTS line for node 20 |

**Do NOT add:** `express`, `koa`, `hapi` (pick one framework — Fastify), `nodemon` (`tsx watch` replaces it), `body-parser` (Fastify ships its own), `jest` (vitest is the choice).

### File structure (expected touch list)

| Path | Action |
|------|--------|
| `test-infra/mock-evisitor/package.json` | **New** |
| `test-infra/mock-evisitor/tsconfig.json` | **New** |
| `test-infra/mock-evisitor/pnpm-lock.yaml` | **New** (committed) |
| `test-infra/mock-evisitor/src/server.ts` | **New** — `buildApp()` + `main()` |
| `test-infra/mock-evisitor/src/fixtures.ts` | **New** — fixture loader + types |
| `test-infra/mock-evisitor/src/session.ts` | **New** — cookie/session helpers |
| `test-infra/mock-evisitor/src/xml.ts` | **New** — XML body parser wrapper |
| `test-infra/mock-evisitor/src/routes/login.ts` | **New** |
| `test-infra/mock-evisitor/src/routes/submit.ts` | **New** (CheckInTourist + ImportTourists) |
| `test-infra/mock-evisitor/src/routes/health.ts` | **New** |
| `test-infra/mock-evisitor/fixtures/login_success.json` | **New** |
| `test-infra/mock-evisitor/fixtures/login_failure.json` | **New** |
| `test-infra/mock-evisitor/fixtures/submit_success.json` | **New** |
| `test-infra/mock-evisitor/fixtures/submit_error_validation.json` | **New** |
| `test-infra/mock-evisitor/fixtures/submit_error_duplicate.json` | **New** |
| `test-infra/mock-evisitor/fixtures/submit_error_session.json` | **New** |
| `test-infra/mock-evisitor/fixtures/submit_error_unavailable.json` | **New** |
| `test-infra/mock-evisitor/test/login.test.ts` | **New** |
| `test-infra/mock-evisitor/test/submit.test.ts` | **New** |
| `test-infra/mock-evisitor/test/session.test.ts` | **New** |
| `test-infra/mock-evisitor/test/health.test.ts` | **New** |
| `test-infra/README.md` | **New** — overview + quick start |
| `prijavko/config/local.json` | **New** — `{"API_BASE":"http://10.0.2.2:8080","AD_ENABLED":"false"}` |
| `.gitignore` (repo root) | **Edit** — add `test-infra/**/node_modules`, `dist`, `coverage` |
| `pnpm-workspace.yaml` (repo root) | **Optional** — only if adopting workspaces; document either way |

### Testing requirements

- **Framework:** `vitest` (not jest) — per architecture.md:441 ("TypeScript (mock server) | vitest --coverage | fixture JSON files").
- **Approach:** Use `fastify.inject({ method, url, headers, payload, cookies })` — no real network bind during tests. Fast, deterministic, cookie-friendly.
- **Coverage exclusions:** fixture JSON files, `server.ts` `main()` entrypoint (not `buildApp()` — that's the testable core). [Source: architecture.md:441]
- **Coverage target:** The repo-wide combined gate is **70% meaningful**. Aim ≥85% on this package (small codebase, behavior-heavy) to leave headroom for the combined gate once more TypeScript lands. [Source: architecture.md:403, 442]
- **Don't test:** The pino logger, fixture file I/O errors (covered by fail-fast at boot), third-party plugin internals.

### Previous story intelligence (Stories 1.1–1.5)

**Directly relevant from Epic 1:**

- **1.1 (project init)** chose `pnpm` as the expected package manager for TypeScript tooling in this repo. Follow suit. [Retro: "Pub dependency graph" item is Dart-only — this story is TS, separate toolchain.]
- **1.1 added `config/dev.json`** pointing at the real eVisitor test API. This story adds `config/local.json` pointing at the mock — they coexist; `local.json` becomes the daily default.
- **1.2 DB tests** established the "in-memory + `closeStreamsSynchronously` + explicit close" discipline for Drift streams. The TS analog here: close the Fastify server after each test file via `afterAll(() => app.close())` — prevents port/handle leaks in CI.
- **1.3, 1.4** — no direct TS impact.
- **1.5** — established that `config/local.json` is the canonical dev flavor; this story is where it physically appears. Router/connectivity work is a consumer of the mock in future Patrol tests (2.3).

**Epic 1 retro lessons to apply here:**

- **Fail-safe behavior (ConnectivityBanner lesson):** If fixture loading fails at boot, crash LOUDLY (`process.exit(1)` with a clear message) — do NOT serve stale defaults silently. This is Jidoka (stop the line).
- **Don't bundle cross-concern commits:** Keep this story's commits scoped to `test-infra/` + `prijavko/config/local.json` + `.gitignore`. No opportunistic edits to planning docs. [Retro: "Cross-story bundling" item.]
- **Deferred work log:** If a scope item gets cut (e.g., adopting workspaces), log it in `_bmad-output/implementation-artifacts/deferred-work.md` with severity and source.

### Anti-patterns to reject (disaster prevention)

- ❌ **Hardcoding response bodies in handlers.** Violates AC #10. New error cases would require code changes instead of fixture edits.
- ❌ **Using `express` or any non-Fastify framework.** Architecture pins Fastify. [architecture.md:325]
- ❌ **Binding to `127.0.0.1` / `localhost`.** AVD cannot reach it through `10.0.2.2`. Fails silently.
- ❌ **`ASP.NET_SessionID` / `asp.net_sessionid` / any casing variation.** Must be exactly `ASP.NET_SessionId` — real eVisitor is case-sensitive, and the Flutter Dio cookie jar will not match.
- ❌ **Persisting sessions to disk/Redis/SQLite.** In-memory is deliberate; CI determinism requires clean boot.
- ❌ **Returning `{ error: "..." }` shape.** Must be `{ SystemMessage, UserMessage }` — `ErrorMapper` in the Flutter client depends on this exact shape. [architecture.md:318]
- ❌ **Batch rejection on first bad guest in `ImportTourists`.** Must be per-guest partial-success array — matches real eVisitor. [AC #9]
- ❌ **Adding Dockerfile / docker-compose.yml in this story.** That's Story 2.1.
- ❌ **Adding facility-lookup endpoints.** Out of scope — architecture explicitly excludes them. [architecture.md:358]
- ❌ **Rate limiting.** Mock deliberately has none. [architecture.md:360]

### Project structure notes

- **Location rationale:** `test-infra/` (repo root) — NOT under `prijavko/`. Flutter app and mock are independent deliverables; mock survives Flutter refactors.
- **Workspace decision:** The architecture mentions "pnpm workspaces under `test-infra/mock-evisitor/`" (epics.md:449). Interpretation: the mock is the first citizen, additional workspace members may land later (e.g. `test-infra/test-runner` in Story 2.1 is a Dockerfile — not a pnpm package — so workspaces may remain trivial). Adopt `pnpm-workspace.yaml` if it simplifies future additions; skip otherwise. Document in `test-infra/README.md`.

### References

- `_bmad-output/planning-artifacts/epics.md` — Story 1.6 (lines ~402–455): user story, AC, technical notes
- `_bmad-output/planning-artifacts/architecture.md` — "Mock eVisitor Server Contract" (lines ~322–361): endpoints, fixtures table, session semantics, intentional omissions
- `_bmad-output/planning-artifacts/architecture.md` — "Config flavors" (lines ~410–420): `local.json` / `test.json` / `prod.json` relationship
- `_bmad-output/planning-artifacts/architecture.md` — Testing & Coverage (lines ~439–444): vitest, exclusions, 70% gate
- `_bmad-output/project-context.md` — "Mock server (test-infra only)" quick-facts table
- `_bmad-output/implementation-artifacts/epic-1-retro-2026-04-14.md` — fail-safe + commit-scoping lessons
- [Fastify docs](https://fastify.dev/docs/latest/) — `app.inject()`, content-type parsers, plugin registration
- [fast-xml-parser](https://github.com/NaturalIntelligence/fast-xml-parser) — XML body parsing
- [vitest](https://vitest.dev/) — test runner, coverage

### Latest tech notes (2026-04)

- **Fastify 5** — native ESM support; `fastify.inject()` returns `LightMyRequest.Response` (sync-ish, perfect for vitest). Use `import Fastify from 'fastify'`.
- **`@fastify/cookie` v11+** supports Fastify 5; `reply.setCookie(name, value, { maxAge })` sets `Max-Age` in seconds (matches ACs).
- **`fast-xml-parser` v4.5+** — stable API, `XMLParser({ ignoreAttributes: false, parseAttributeValue: true })` is typical for XML with nested elements.
- **Node 20 LTS** — supported through April 2026 entry-level, then maintenance. For a test-only tool this is safe through project lifetime.
- **pino** (shipped by Fastify) — structured JSON logs; pair with `pino-pretty` only in dev if readability matters. Don't add unless needed.

### Hansei questions before committing

1. **Clarity:** Can a new developer run `pnpm install && pnpm dev` and understand what the mock does without reading Dart code? (If no, improve `test-infra/README.md`.)
2. **Poka-yoke:** If someone changes the cookie name, does a test fail immediately? (Must be yes.)
3. **Omotenashi:** When Patrol tests fail in CI six months from now, will logs make it obvious whether the mock returned the expected scenario? (Log method + url + status + `X-Mock-Scenario` header if present.)
4. **Jidoka:** On malformed fixture JSON at boot, does the server crash with a clear message instead of serving a partial response set? (Must crash.)
5. **Muda:** Did I add any dependency that isn't exercised by a test or the runtime path? (Remove it.)

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
