# Story 1.6: Mock eVisitor Server

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer**,
I want **a local Fastify + TypeScript mock of the eVisitor REST API running from day one**,
so that **every subsequent epic (Auth, Submit, Queue, History) can make real HTTP calls against a deterministic backend without depending on the rate-limited, snapshot-scheduled real eVisitor test API**.

## Acceptance Criteria

1. **Mock reachable from AVD** — Given the mock server is started with `yarn dev` from `test-infra/mock-evisitor/`, when the Flutter app runs with `--dart-define-from-file=config/local.json` on an Android Studio AVD, then `http://10.0.2.2:8080` resolves to the mock and `POST /Login`, `POST /CheckInTourist`, `POST /ImportTourists` requests succeed end-to-end. Server MUST bind to `0.0.0.0` (not `127.0.0.1`) so AVD loopback `10.0.2.2` can reach it.

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

12. **Contract tests (node:test) green** — Given contract tests in `test-infra/mock-evisitor/test/`, when `yarn test` runs (invokes `node --test --experimental-strip-types`), then every fixture/scenario listed in AC 2–9 is covered by at least one test asserting: exact HTTP status, exact `Content-Type`, presence/shape of `Set-Cookie` (login), and exact JSON envelope shape (`{SystemMessage, UserMessage}` or array thereof). Tests run headlessly (no external HTTP calls) — exercise Fastify via `app.inject()`. [Test framework choice follows the installed `fastify` skill's `rules/testing.md` guidance — node's built-in test runner over third-party runners.]

13. **Run scripts documented** — Given `test-infra/README.md`, when a new developer reads it, then they find: (a) `cd test-infra/mock-evisitor && yarn install && yarn dev` starts the server on `:8080`, (b) `yarn test` runs contract tests, (c) `yarn build` produces a `dist/` suitable for the Docker image built in Story 2.1, (d) the relationship between `config/local.json` (AVD dev) and `config/test.json` (compose CI — future Story 2.1).

14. **Flutter local config wired** — Given `prijavko/config/`, when inspecting the folder, then `local.json` exists with exact contents `{"API_BASE":"http://10.0.2.2:8080","AD_ENABLED":"false"}` (string `"false"` matches existing `dev.json`/`prod.json` convention — `String.fromEnvironment` consumes strings). **This replaces `dev.json` for daily development going forward** — `dev.json` MAY remain for pointing at the real eVisitor test API when needed, but `local.json` is the new default.

15. **No Flutter coupling** — Given the mock is a separate TypeScript project, when inspecting `test-infra/mock-evisitor/package.json`, then it has zero dependencies on Flutter/Dart tooling. The TypeScript project can be cloned, installed, and run on a machine without Flutter SDK. (Parallel-implementable with Story 1.1 — validated: 1.1 is done, this story is unblocked.)

16. **Fastify skill consulted** — During implementation the dev MUST load and follow the `fastify` skill installed at `.claude/skills/fastify/` (source: mcollina/skills). Rules files under `.claude/skills/fastify/rules/` are authoritative for plugin structure, routes, schemas, serialization, error-handling, hooks, logging, configuration, testing, typescript, cors-security, and deployment. Where this story's AC conflicts with the skill, the AC wins; everywhere else, follow the skill.

## Tasks / Subtasks

This story is big — it's split into nine sequential task files under [1-6-tasks/](1-6-tasks/). Each task is independently reviewable. Complete and commit them in order; later tasks assume earlier ones landed.

| # | Task | File | Covers AC |
|---|---|---|---|
| 1 | Project scaffold (Fastify 5 + TS strip-types + Node 22) | [1-6-tasks/task-01-project-scaffold.md](1-6-tasks/task-01-project-scaffold.md) | #1, #15, #16 |
| 2 | Fixtures loader + types | [1-6-tasks/task-02-fixtures-loader.md](1-6-tasks/task-02-fixtures-loader.md) | #10 |
| 3 | `/Login` route + cookie issuance | [1-6-tasks/task-03-login-route.md](1-6-tasks/task-03-login-route.md) | #2, #3 |
| 4 | Session store + validation preHandler | [1-6-tasks/task-04-session-store.md](1-6-tasks/task-04-session-store.md) | #6, #11 |
| 5 | `/CheckInTourist` + `/ImportTourists` routes | [1-6-tasks/task-05-submit-routes.md](1-6-tasks/task-05-submit-routes.md) | #4, #5, #6, #7, #9 |
| 6 | `/healthz` endpoint | [1-6-tasks/task-06-healthcheck.md](1-6-tasks/task-06-healthcheck.md) | #8 |
| 7 | Contract tests (`node --test` via inject) | [1-6-tasks/task-07-contract-tests.md](1-6-tasks/task-07-contract-tests.md) | #12 |
| 8 | Flutter `config/local.json` wiring | [1-6-tasks/task-08-flutter-local-config.md](1-6-tasks/task-08-flutter-local-config.md) | #14 |
| 9 | README + repo-root wiring + manual smoke | [1-6-tasks/task-09-readme-smoke.md](1-6-tasks/task-09-readme-smoke.md) | #13, #15 |

**Recommended rhythm:** one commit per task, one PR for the whole story (or per task if review bandwidth allows). Do NOT skip ahead — `submit.ts` (task 5) depends on the session store (task 4) and fixtures (task 2).

- [x] Task 1 — Project scaffold
- [x] Task 2 — Fixtures loader
- [ ] Task 3 — Login route
- [ ] Task 4 — Session store
- [ ] Task 5 — Submit routes
- [ ] Task 6 — Healthcheck
- [ ] Task 7 — Contract tests
- [ ] Task 8 — Flutter local config
- [ ] Task 9 — README + smoke

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
| **Runtime** | **`node:22`** (current LTS line, codename "Jod"). Dockerfile in Story 2.1 must use `node:22-alpine`. Set `"engines": { "node": ">=22 <23" }` in `package.json` and add `.nvmrc` with `22` to prevent version drift. **Native TypeScript support:** Node 22 supports `--experimental-strip-types` — we use this (no `tsx`/`ts-node` needed) per the `fastify` skill's TS guidance. [Supersedes earlier architecture.md:518 `node:20` mention — decision 2026-04-17.] |
| **Language** | TypeScript with `strict: true`, `noUncheckedIndexedAccess: true`, `exactOptionalPropertyTypes: true`. Zero `any` — use `unknown` and narrow. Source files use `.ts` extension; run directly via `node --experimental-strip-types src/server.ts`. [Poka-yoke — project craftsmanship rules + fastify skill `rules/typescript.md`] |
| **Package manager** | **yarn** (classic v1.x or modern berry — use whichever the user already has; default **Yarn 1.x** for simplicity). Commit `yarn.lock`. Do NOT use npm or pnpm inside `test-infra/`. **Supersedes earlier "pnpm workspaces" mention in epics.md:449** — decision 2026-04-17. |
| **HTTP framework** | **Fastify v5.x locked** — `"fastify": "^5.0.0"`. v5 is required (native ESM, undici, improved TS types). Do not fall back to v4. [Source: architecture.md:325 + decision 2026-04-17] |
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
| `fastify` | `^5.0.0` **(locked to v5 — decision 2026-04-17)** | Native ESM, undici transport, improved TS types. v4 is not an option in this story. |
| `@fastify/cookie` | `^11.0.0` (matches Fastify 5) | `reply.setCookie()` with `maxAge` in seconds — matches AC #2, #11 |
| `@fastify/formbody` | `^8.0.0` (matches Fastify 5) | `/Login` form-encoded body parsing |
| `fast-xml-parser` | `^4.5.0` | XML body parsing for CheckInTourist/ImportTourists; no known CVEs in 4.5+ as of 2026-04 |
| `typescript` | `^5.6.0` | Source type-checking only — runtime uses Node 22 strip-types, no transpile needed for dev |
| `@types/node` | `^22.0.0` | Matches Node 22 runtime |

**Dev/run commands (no bundler, no tsx):**
- Dev: `node --experimental-strip-types --watch src/server.ts`
- Tests: `node --experimental-strip-types --test test/**/*.test.ts`
- Type-check only: `tsc --noEmit`
- Build (for Docker in 2.1): `tsc -p .` → `dist/` → run with `node dist/server.js`

**Do NOT add:** `express`, `koa`, `hapi` (Fastify is chosen), `nodemon`/`tsx`/`ts-node` (Node 22 `--watch --experimental-strip-types` replaces them), `body-parser` (Fastify ships its own), `vitest`/`jest`/`mocha` (Node's built-in `node:test` is the choice — lighter, zero config, matches `fastify` skill `rules/testing.md` preference for `app.inject()` + `node:test`).

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

Claude Haiku 4.5

### Debug Log References

### Completion Notes List

**Task 2 (Fixtures Loader):**
- Created 7 fixture JSON files (login_success.json, 6 submit error/success fixtures)
- Implemented fixtures.ts with type-safe validation using discriminated union validators
- Fixtures load at boot with fail-fast behavior — malformed fixtures cause process.exit(1)
- Added tsconfig.check.json to support typecheck with .js imports (Node 22 strip-types)
- Server boots successfully, fixtures accessible via app.fixtures decorator with full TypeScript support
- Fixture validation tested: mutating fixture causes expected error message

### File List

**Task 2 — Fixtures loader:**
- test-infra/mock-evisitor/src/fixtures.ts (new)
- test-infra/mock-evisitor/fixtures/login_success.json (new)
- test-infra/mock-evisitor/fixtures/submit_success.json (new)
- test-infra/mock-evisitor/fixtures/submit_error_validation.json (new)
- test-infra/mock-evisitor/fixtures/submit_error_duplicate.json (new)
- test-infra/mock-evisitor/fixtures/submit_error_session.json (new)
- test-infra/mock-evisitor/fixtures/submit_error_unavailable.json (new)
- test-infra/mock-evisitor/fixtures/submit_redirect_login.html (new)
- test-infra/mock-evisitor/src/server.ts (modified — added fixture loading + module augmentation)
- test-infra/mock-evisitor/package.json (modified — updated test script glob)
- test-infra/mock-evisitor/tsconfig.check.json (new)
