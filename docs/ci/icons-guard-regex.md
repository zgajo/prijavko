# Icons guard regex (Story 1.2 AC5.5)

This file is the authoritative source for the regex that
[`icons_guard.yml`](../../.github/workflows/icons_guard.yml) runs on every
push and PR. Keep the `ICONS_REGEX` env var in the workflow in lockstep
with the pattern documented here.

## Pattern

```regexp
(Icon\s*\(\s*|Icon\.adaptive\s*\(\s*)Icons\.
```

### What it catches

Any `Icon(Icons.<name>)` or `Icon.adaptive(Icons.<name>)` call site.
The guard exists because two different icon APIs are reachable from
`flutter/material.dart`:

- **`Icons.<name>`** — Material Icons font, classic Material 2 stroke.
  Loaded automatically when `flutter.uses-material-design: true`.
- **`Symbols.<name>_rounded`** — Material Symbols (rounded variant), the
  project's house style. Re-exported via
  `package:prijavko/design/icons.dart`.

The two fonts use different stroke widths, optical sizes, and
proportions. Mixing them produces a subtle but real visual inconsistency
that compiles, renders, and ships silently. The guard catches the
collision at PR time so the design system stays coherent.

### Grep invocation

The workflow uses GNU grep in Perl-compatible mode so `\s` matches what
it means in a typical language (`[\t\n\r\f\v ]`):

```sh
grep -rnP --include='*.dart' -- "$ICONS_REGEX" lib/ test/ integration_test/
```

A single match exits grep with status 0, which the workflow converts to
a build failure with `::error::Material Icons leak detected`.

## Examples

### ❌ Blocked (regex matches, build fails)

```dart
const Icon(Icons.check);
Icon(Icons.warning, color: Colors.amber);
return Icon(Icons.check_circle);
// extra whitespace doesn't help
Icon (  Icons.bookmark);
// the platform-adaptive constructor is also blocked
Icon.adaptive(Icons.share);
```

### ✅ Allowed (regex does not match, build passes)

```dart
const Icon(Symbols.check_rounded);
Icon(Symbols.warning_rounded, color: warning);
// Referring to Icons. in a doc comment is fine — the regex requires
// the literal `Icon(` call shape preceding `Icons.`.
/// Material Icons (Icons.foo) is forbidden — use Symbols instead.
final iconsClassName = 'Icons.something'; // string literal, not a call
```

## If this regex needs to change

1. Update the `ICONS_REGEX` env var in
   [`icons_guard.yml`](../../.github/workflows/icons_guard.yml).
2. Update the pattern block and the example lists above in the same
   commit.
3. Run the updated grep locally against `lib/ test/ integration_test/`
   to confirm it is clean before pushing.

The regex deliberately matches the call shape, not bare `Icons.`. A
future codebase change might legitimately reference the `Icons` class in
a doc comment or a string — broadening the regex to `Icons\.\w+` would
generate false positives there.

## Known scope holes (intentional)

The two patterns above cover the realistic ways a `Material Icons` font
glyph reaches a render. The guard does **not** match:

- Bare `IconData` references: `final IconData x = Icons.foo;`. These
  almost always then flow into an `Icon(...)` call, which the guard
  catches downstream.
- Prefix-aliased imports: `import 'package:flutter/material.dart' as m;`
  followed by `Icon(m.Icons.foo)`. Detecting this requires AST analysis,
  not a grep — out of scope for a CI guard.
- `Icons.<name>` literals inside multi-line string literals or dartdoc
  code fences spanning lines. A doc-comment example that types
  `Icon(Icons.foo)` in `lib/**` will trip the guard; keep illustrative
  examples in `docs/`.

If a real-world miss appears in code review, lift the relevant case
into the alternation rather than expanding to `Icons\.\w+` (which
generates noise). Document each such addition here in lockstep.
