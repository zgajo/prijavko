# Task 9 — README + repo-root wiring + manual smoke

Part of [Story 1.6](../1-6-mock-evisitor-server.md). Covers AC **#13, #15** and the quality-gate sign-off.

**Goal:** Document the mock so a new developer can run it in <5 minutes; confirm end-to-end that the Flutter AVD talks to the mock.

## Dependencies

- Tasks 1–8 merged.

## Deliverables

### `test-infra/README.md`

Required sections (order matters for scannability):

1. **Overview** — what lives here, why it exists (test-infra contains project-owned test tooling; mock-evisitor is the first inhabitant). Mock is never shipped in the app binary.
2. **Prerequisites** — Node 22 (`.nvmrc` in `mock-evisitor/`), Yarn 1.x, Android Studio AVD for the Flutter smoke.
3. **Quick start** — two-terminal flow (mock `yarn dev` + Flutter `flutter run --dart-define-from-file=config/local.json`).
4. **Running contract tests** — `cd test-infra/mock-evisitor && yarn test`.
5. **Building for Docker (Story 2.1)** — `yarn build` produces `dist/`; noting that Story 2.1 will add the Dockerfile consuming this output.
6. **How fixtures work** — all scripted responses live under `fixtures/*.json`; `src/fixtures.ts` validates them at boot and crashes fast; to add a new error case: add a JSON file + a pattern check in `submit.ts`.
7. **Scenario headers** — `X-Mock-Scenario` supports comma-separated values:
   - `unavailable` → 503 (outranks all)
   - `expire-session` → forces session missing
   - `redirect-login` → combined with `expire-session` returns 302 + HTML (exercises the non-JSON AuthFailure path in the Flutter client)
8. **Guest doc-number patterns** — `ERR_VALIDATION_*` → 400/per-guest error; `ERR_DUPLICATE_*` → 409/per-guest error.
9. **Cookie + session TTL** — cookie name `ASP.NET_SessionId` (case-sensitive!). `SESSION_TTL_SECONDS` env var (default 300). Short TTLs let Patrol E2E (Story 2.3) naturally exercise re-auth.
10. **Endpoints reference** — table mirroring architecture.md:329–334.
11. **Relationship to Flutter configs** — `config/local.json` (AVD → host via `10.0.2.2:8080`, this story) and `config/test.json` (coming in Story 2.1, compose-only). `config/dev.json` points at real eVisitor test API and is retained for ad-hoc use.
12. **Troubleshooting** — `ECONNREFUSED` from AVD → check server bound `0.0.0.0`; missing cookie after login → check exact cookie name casing; `yarn install` fails → check Node 22.

### Repo-root wiring decision

Decision for this story: **standalone yarn project** (no repo-root workspace file). Rationale: single TypeScript package; Story 2.1 adds a Dockerfile (not a yarn workspace). Document the decision in `test-infra/README.md` under a brief "Project layout" note.

If Yarn Berry (`yarn@3+`) is preferred over classic v1, a `.yarnrc.yml` pinning `nodeLinker: node-modules` is acceptable; otherwise classic Yarn 1.x with no rc file is fine.

### `.gitignore` verification (should already be from task 1)

Confirm these are present at repo root:

```
test-infra/**/node_modules
test-infra/**/dist
test-infra/**/coverage
test-infra/**/.yarn
```

## Manual smoke test (the story's true acceptance gate)

Run from a clean `yarn install`:

1. `cd test-infra/mock-evisitor && yarn dev` → logs `listening on 0.0.0.0:8080`
2. From host shell: `curl -s http://localhost:8080/healthz` → `{"status":"ok"}`
3. From AVD shell (`adb shell`): `curl -s http://10.0.2.2:8080/healthz` → `{"status":"ok"}` (proves bind-address is correct)
4. Flutter: `cd prijavko && flutter run --dart-define-from-file=config/local.json` on AVD
5. In the app (or via DevTools HTTP inspector), trigger a `POST /Login` with `testuser` / `testpass` → Flutter receives 200 + cookie set in Dio jar
6. Trigger a `POST /CheckInTourist` with a clean `DocumentNumber` → 200 + empty envelope
7. Trigger same with `DocumentNumber=ERR_VALIDATION_FOO` → 400 + Croatian error surfacing in Flutter UI (if error path already wired) or in logs

(Steps 5–7 may require Epic 6 code that doesn't exist yet — if so, use `curl` from the host proxying through AVD instead, and document in the PR that end-to-end app-level validation is deferred to Epic 6.)

## Acceptance checks (story-level gates)

- [ ] `yarn test` green across all task-7 files
- [ ] `yarn build` produces `dist/server.js` with zero TS errors
- [ ] `curl http://localhost:8080/healthz` works from host
- [ ] `adb shell curl http://10.0.2.2:8080/healthz` works from AVD
- [ ] `prijavko/config/local.json` present; `dev.json` unchanged
- [ ] `test-infra/README.md` covers all 12 sections above
- [ ] All 9 task files in [1-6-tasks/](.) are checked off in the parent story

## Commit

`test-infra: README + repo layout decision + manual smoke verification`

## Close the story

After this task, update `_bmad-output/implementation-artifacts/sprint-status.yaml`:

```
1-6-mock-evisitor-server: in-progress → review → done
```

Follow the BMAD dev-story + code-review workflow as usual.
