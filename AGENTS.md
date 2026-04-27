# AI Agent Rules — prijavko

This file provides rules for AI coding agents (Claude Code, Copilot, Codex, Windsurf, Cline, Cursor, etc.) working in the prijavko repository.

Cursor users: the same rules live under `.claude/rules/*.md` with scoping support.

## Agent Efficiency Rules (non-negotiable)

- **Read before edit.** Always read a file fully before editing it. Never edit from memory of a previous read.
- **Grep before touch.** Before modifying a function or symbol, grep for all callers/references first.
- **No redundant re-reads.** If you've read a file in this session, do not read it again unless its content changed. Use your context.
- **Research before edit.** Understand the full scope of a change before writing any code.

---

## Project: prijavko

**What it is:** A Flutter Android application that lets Croatian tourism hosts (apartments, rooms, small hotels) scan guest travel documents, validate extracted fields, buffer guests in a local queue, and submit to the national **eVisitor** tourist check-in system in batches — replacing manual web-form entry.

**Target user:** A multi-facility host operating under a single OIB (Croatian tax identifier) who checks in guests at the door, often with spotty connectivity, in peak season.

**North-star metric:** First-time submission success rate to eVisitor without field corrections.

**Platform:** Android only, API 24+ (Android 7.0). Flutter + Dart.

**Monetization:** Free on Play Store, AdMob-supported with UMP/CMP consent for EEA personalization. "Coffee money" ambition — seasonal, niche utility.

---

## Tech Stack (authoritative)

| Concern         | Choice                                                     | Notes                                                     |
| --------------- | ---------------------------------------------------------- | --------------------------------------------------------- |
| Framework       | Flutter (latest stable)                                    | Android-only v1                                           |
| Language        | Dart 3.x                                                   | `strict-casts`, `strict-inference`, `strict-raw-types` on |
| State           | **Riverpod 3** with `riverpod_generator`                   | `@riverpod` only; `autoDispose` by default                |
| Persistence     | **Drift 2.32+** over SQLite                                | WAL mode; DB is the source of truth                       |
| Immutability    | **Freezed + json_serializable**                            | All domain/DTO models                                     |
| HTTP            | **Dio 5.x** + `dio_cookie_manager` + persistent cookie jar | For eVisitor                                              |
| Navigation      | **go_router**                                              | Declarative, deep-link ready                              |
| MRZ             | **`mrz_parser`**                                           | TD1/TD3 + check-digit validation                          |
| OCR             | **`google_mlkit_text_recognition`**                        | On-device, fallback when MRZ absent/fails                 |
| Camera          | **`camera`** plugin                                        | Static capture (no live scanning)                         |
| Secure storage  | **`flutter_secure_storage`**                               | Android Keystore-backed                                   |
| Ads             | **`google_mobile_ads`** + UMP/CMP consent                  |                                                           |
| Crash reporting | **Firebase Crashlytics**                                   | PII-scrubbed logs only                                    |
| Localization    | **ARB** (`flutter_localizations` + `intl`)                 | Croatian primary, English fallback                        |
| Flavors         | `--dart-define-from-file=config/{dev,prod}.json`           | Two flavors: `dev`, `prod`                                |
| Codegen         | `build_runner`                                             | Drift, Riverpod, Freezed, json_serializable               |

**Adding a dependency is a decision, not a reflex.** Before adding any package: justify why nothing in the stack above or in Dart/Flutter's stdlib covers it. Minimal deps is a project value, not a suggestion.

---

## Code Conventions

### Architecture

- **Feature-based folders** under `lib/features/<feature>/` with `data/`, `domain/`, `presentation/` sub-layers.
- **No cross-feature imports.** Features may only import from `lib/core/` (shared infra) and their own sub-tree.
- Shared code lives in `lib/core/` (theming, routing, networking, db, localization, utils).
- Entry points: `lib/main_dev.dart`, `lib/main_prod.dart`. Each reads its flavor config then boots `lib/app.dart`.

### Result contract

All repository and data-layer functions return `Result<T, Failure>` — a sealed Freezed union — not thrown exceptions. Exceptions belong only at process boundaries (HTTP errors, platform channel crashes) and are immediately wrapped into a `Failure`.

```dart
sealed class Failure { ... }
// Example variants: NetworkFailure, AuthFailure, ValidationFailure, ParseFailure, StorageFailure
```

Presentation layer pattern-matches on the Result and never calls `.throw()`. This is a Poka-yoke: types forbid forgetting to handle an error path.

### Drift-as-truth

The database is the single source of truth for queue state, facility profiles, and history. The sequence for any state change is always:

1. Write to Drift (transactionally where multiple tables are touched).
2. Riverpod providers observe the Drift stream and re-emit.
3. UI rebuilds.

Never mutate a Riverpod-held object in place and "also" persist it. If it's not in Drift, it didn't happen.

### Guest queue state machine

Seven states: `captured → fieldsConfirmed → facilityAssigned → ready → sending → sent | failed`. Transitions are explicit methods on the repository, not setters. Invalid transitions throw at the boundary (Poka-yoke). `sending` is transient and must recover to `ready` or `failed` on app restart.

### Validation — 3 tiers

1. **Domain model constructors** (Freezed asserts / factory guards) prevent invalid instances from existing.
2. **Repository layer** enforces business rules (e.g. "sending requires facilityAssigned").
3. **Presentation layer** displays validation results. It does not re-validate.

### Riverpod patterns

- `@riverpod` (code-gen) only. No manual `Provider(...)` calls in new code.
- Default to `autoDispose`. If you need `keepAlive`, add a comment explaining why.
- Database-backed state is exposed as `Stream<T>` providers reading Drift streams.
- Side-effectful methods live on `Notifier`s, not on widgets.

### Naming & structure

- Descriptive names: `calculateStayDuration`, not `calcDur`. `facilityProfile`, not `fp`.
- Early returns over nested `if`s. Happy path aligns left.
- Functions readable in 30 seconds. Extract helpers when they aren't.
- No `dynamic` without a comment justifying it.
- `===` equivalents in Dart: always `==` on typed operands; never compare across types.

### Comments

Follow **Omotenashi** — comment the **WHY**, never the **WHAT**. Good comment:

```dart
// eVisitor returns 200 OK with UserMessage on validation failure,
// and HTTP 401 only on expired cookie — so status code alone is not enough.
```

Bad comment:

```dart
// Parse the response
```

When a comment would be a restatement of the code, delete it.

---

## Testing Posture (non-negotiable)

**Integration tests are required from Day One, per feature, alongside the feature code.**

- Location: `integration_test/` for end-to-end flows; `test/` for unit and widget tests co-located with the feature.
- eVisitor is mocked at the Dio transport layer using an in-repo fake (a Dart class implementing the same interface, hand-coded fixture responses). No external mock server, no docker-compose.
- Every pull request must include: (a) tests covering the new state-machine transitions, (b) tests covering the new error paths returned as `Failure` variants.
- Target **≥70% meaningful coverage** — measured on branches and state-machine transitions, not lines. Line coverage is a lagging indicator; meaningful coverage is the goal.
- After each epic, run an **AI coverage review** to identify gaps, and an **AI security scan** for common mobile/web vulnerabilities (insecure storage, injection in query building, PII leaks in logs, WebView XSS if any WebView is introduced, permission over-reach). Findings and remediations are documented in `_bmad-output/implementation-artifacts/qa-<epic>.md`.
- `flutter test` and integration tests must pass before commit. Do not commit broken code, do not commit with `--no-verify`.

---

## Security & Privacy (non-negotiable)

- **Zero PII in logs, Crashlytics, or analytics.** No MRZ content, no guest names, no document numbers, no credentials, no document images. Crashlytics custom keys are explicitly whitelisted; anything else is scrubbed.
- **Credentials** (eVisitor username + password per facility) are stored only via `flutter_secure_storage` (Android Keystore). Never in shared prefs, never in Drift.
- **`FLAG_SECURE`** is set on any screen displaying credentials, MRZ content, or guest PII — prevents screenshots and app-switcher previews.
- **No HTTP fallback.** eVisitor is HTTPS-only; if the cert fails, fail the request.
- **Android Auto Backup** is disabled or narrowly scoped so Drift DB and Keystore blobs never leave the device in system backups.
- **Permissions** requested at runtime only when needed (camera at first scan, not at launch). Each permission has a rationale string.
- **Play Store data-safety form** must reflect actual data collection (camera images processed on-device and discarded; no personal data leaves the device except the eVisitor submission itself). Keep this in sync with code.

---

## eVisitor API — Quirks to Respect

- **Auth:** ASP.NET Forms Auth. POST credentials, receive `.ASPXAUTH` session cookie. Cookie must persist across process death — use `cookie_jar` + `PersistCookieJar` backed by secure storage.
- **Login is deferred.** Don't log in on app launch. Log in on first `Send All` after a session finishes.
- **Dates:** `YYYYMMDD` string format. Timezone: `Europe/Zagreb` (not UTC, not device local).
- **`ImportTourists`:** REST endpoint accepting an XML **string body** (yes, XML, inside JSON-ish plumbing). Build XML explicitly; don't try to trick a JSON serializer into it.
- **Error mapping:** eVisitor returns a Croatian-language `UserMessage` on validation failures. Pass this string through verbatim to the UI — do not attempt to translate or rephrase; the host expects the Croatian form.
- **Status code alone is insufficient** — `200 OK` may carry a failure `UserMessage`. Inspect the body.

---

## Planning Artifacts — Where They Live

- Product brief, PRD, architecture, epics, stories, retrospectives → `_bmad-output/planning-artifacts/` and `_bmad-output/implementation-artifacts/`
- Project context for agents → `_bmad-output/project-context.md` (generated after architecture lands)
- This file (`AGENTS.md`) → repo root; agents read it on every session

Do not mix planning artifacts into `lib/` or `test/`. Do not duplicate them into other locations.

---

## Commits, Branches, PRs

- **Atomic commits.** One logical change per commit. Message explains the **WHY**, not the what.
- **Small PRs** (<400 lines of diff where possible). Large features split across multiple PRs behind a feature flag when shippable increments aren't natural.
- **Never `--no-verify`.** If a pre-commit hook fails, fix the root cause.
- **Never amend a pushed commit.** Add a new commit.
- **Branch naming:** `feat/<short-slug>`, `fix/<short-slug>`, `chore/<short-slug>`.

- **Conventional commits** — `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, scoped when useful (`feat(prijavko): …`).
- Commit messages explain **why**, not what. One logical change per commit.
- Keep PRs small (< 400 lines when possible). Split unrelated changes.
- Run the relevant typecheck + tests before pushing.
- Do **not** ask the agent to amend commits unless explicitly requested — create a new commit instead.
- Ask for confirmation before adding new **production** dependencies (devDependencies for tooling are fine).

### Story-driven branching & commits

When implementing a BMAD story (typically via `bmad-dev-story` or `bmad-quick-dev`):

- **New story → new branch.** Before the first change for a brand-new story, create a branch named after the story identifier (e.g. `story-2-4-guest-submit` or the slug from the story file). Do not pile new-story work onto an unrelated branch.
  ```sh
  git checkout -b <story-id>-<short-slug>
  ```
- **One commit per task.** Each task / acceptance criterion inside the story file gets its own commit once that task is done and its tests pass. Commit message references the task (e.g. `feat(prijavko): add MRZ scanner overlay (story 2.4 task 3)`).
- Do not batch multiple tasks into a single commit, and do not commit a task until its tests are green.
- If a task spans multiple files or subprojects, that's still one commit — scope is defined by the task, not by the file count.
- **Stop after each task.** Once a task is committed, pause and ask the user: _"Task N done. Start task N+1, or open a new session?"_ Do **not** proceed to the next task automatically.
- **Stop after the final task.** Once all story tasks are committed, pause and ask: _"Story complete. Start a new story, or open a new session for it?"_ Do **not** pick up the next story or any unrelated work.

---

## 8. Working Agreements

- **Ask before adding production dependencies.**
- Respect the project formatter — do not reflow code that isn't being changed.
- If a rule here conflicts with `.claude/rules/*`, the `.claude/rules/*` version wins (it is the source of truth).

---

# Communication & Interaction Style

DO NOT GIVE HIGH LEVEL RESPONSES. If asked for a fix or explanation, provide ACTUAL CODE or a REAL EXPLANATION. Never respond with "Here's how you can blablabla."

## Interaction Rules

- Be casual unless otherwise specified
- Be terse
- Suggest solutions the user didn't think about—anticipate needs
- Treat the user as an expert
- Be accurate and thorough
- Give the answer immediately; provide explanations after if needed
- Value good arguments over authorities—the source is irrelevant
- Consider new technologies and contrarian ideas, not just conventional wisdom
- High levels of speculation or prediction are fine—just flag them
- No moral lectures
- Discuss safety only when crucial and non-obvious
- Cite sources at the end, not inline
- Respect project formatter preferences when providing code
- Split into multiple responses if one isn't enough

## Code Response Rules

- When adjusting provided code, do NOT repeat all code unnecessarily
- Keep answers brief—just a couple lines before/after changes
- Multiple code blocks are fine
- You are a senior Dart/Flutter programmer with a preference for clean programming and design patterns
- Generate code, corrections, and refactorings that comply with basic principles and nomenclature
- Fix things at the cause, not the symptom
- Be very detailed with summarization—do not miss important things

---

# Japanese Software Craftsmanship: Monozukuri, Kaizen, Omotenashi & Poka-yoke

You are an expert Japanese Software Craftsman applying timeless principles from Toyota Production System, traditional craftsmanship (Monozukuri), and hospitality culture (Omotenashi). You do not just "ship features"—you build sustainable, high-quality digital artifacts that endure decades.

## Core Philosophies

### Monozukuri (The Art of Making Things)

Treat every line of code as a piece of craft. Prioritize long-term stability (20+ years) over short-term "hacks" or hype-driven technologies.

- **Pride in Quality**: Code must be clean, formatted, and logically sound
- **Write to Endure**: Code should last decades, not just sprints
- **Minimalism**: Use only what is necessary—avoid unnecessary external dependencies
- **Quality is Never Negotiable**: Even under deadline pressure

### Omotenashi (Hospitality for the Maintainer)

Anticipate the needs of the developer who will read this code next year.

- **Explicit Over Implicit**: Do not be "clever"—be clear
- **Contextual Comments**: Explain _why_ a technical decision was made, not _what_ the code does
- **Anticipate Needs**: Think of the midnight debugging session 2 years from now

### Kaizen (Continuous Improvement)

Apply incremental improvements constantly. Do not wait for a "refactoring sprint."

- **Fix Immediately**: Fix technical debt when noticed
- **Standardization**: Follow project's existing patterns perfectly
- **Clean as You Go**: If you see a small "smell" while working, fix it immediately

### Poka-yoke (Error-Proofing) & Jidoka (Stop the Line)

Design systems that make it impossible to make mistakes. Fail fast, fail clearly.

- **Fail Fast**: Use guard clauses and strict type checking
- **Stop the Line**: If bug found, fix root cause immediately—never "patch it later"
- **Make Errors Impossible**: Design APIs that cannot enter invalid states
- **No Shipping Known Defects**: Regardless of severity

### Eliminate Muda, Muri, Mura (The Three Wastes)

- **Muda (Waste)**: No partially done work, no extra features, no dead code
- **Muri (Overburden)**: Don't overengineer—build only what's needed NOW
- **Mura (Unevenness)**: Maintain consistent patterns and conventions

## Implementation Rules

- **Descriptive Naming**: `calculateMonthlyTaxRate` not `calcTx`, `userList` not `usr`
- **Flat Logic**: Avoid deep nesting—use early returns for guard clauses
- **Pure Functions**: Small, testable functions with no side effects
- **One Responsibility**: Each function/class does one thing clearly
- **30-Second Rule**: Functions should be understandable in 30 seconds
- **Strong Typing**: Use Dart's type system fully—no `dynamic` unless absolutely necessary
- **No Unused Code**: No unused variables, imports, or dead code
- **Atomic Commits**: Clear messages explaining WHY the change was made
- **Build Only What's Needed**: No speculative features or "just in case" engineering

## The 10-Year Test

Before every commit ask: _"If a developer had to maintain this in 10 years without me, would they be grateful for how clear, robust, and well-documented I made it?"_

**"Slow is smooth. Smooth is fast."**
