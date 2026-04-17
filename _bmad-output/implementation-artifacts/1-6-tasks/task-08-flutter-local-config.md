# Task 8 — Flutter `config/local.json`

Part of [Story 1.6](../1-6-mock-evisitor-server.md). Covers AC **#14**.

**Goal:** Wire the AVD-to-mock config flavor in the Flutter project. Keep `dev.json` intact (points at real eVisitor test API) for ad-hoc use.

## Dependencies

- None on prior tasks (independent); land alongside tasks 1–7.

## Deliverables

### `prijavko/config/local.json`

```json
{
  "API_BASE": "http://10.0.2.2:8080",
  "AD_ENABLED": "false"
}
```

Note: `"false"` is a string, matching existing `dev.json`/`prod.json` convention — `String.fromEnvironment` requires string values.

### No other Flutter file changes

- Do NOT touch `dev.json`, `prod.json`, `lib/`, or any Dart code.
- Do NOT delete `dev.json` — keeping it per decision 2026-04-17.

## Quick reference for devs (don't add this to code — use in PR description / README task 9)

Daily workflow going forward:

```bash
# Terminal 1 — mock
cd test-infra/mock-evisitor && yarn dev

# Terminal 2 — Flutter app on AVD
cd prijavko
flutter run --dart-define-from-file=config/local.json
```

## Acceptance checks

- [ ] `prijavko/config/local.json` exists with exact contents above
- [ ] `cd prijavko && flutter build apk --debug --dart-define-from-file=config/local.json` succeeds with zero warnings
- [ ] `prijavko/config/dev.json` is unchanged (`git diff config/dev.json` shows no changes)
- [ ] Manual smoke with mock running: Flutter app on AVD reaches mock at `10.0.2.2:8080` (validated in task 9 smoke)

## Commit

`prijavko(config): add local.json pointing AVD at host mock on 10.0.2.2:8080`
