# Bundled fonts — Manrope (SIL OFL 1.1)

This file is the audit trail for Story 1.2 AC8.2. The Manrope font files
shipped under [`assets/google_fonts/Manrope/`](../../assets/google_fonts/Manrope/)
are **bundled with the APK/AAB** rather than fetched from the Google Fonts
CDN at first launch. Rationale: prijavko is an offline-tolerant utility
(PRD NFR — peak-season hosts work over spotty connectivity), so a missing
network on first launch must not produce a Tofu render or a stalled UI.

`lib/main.dart` sets `GoogleFonts.config.allowRuntimeFetching = false;`
before `runApp`, which turns a missing-asset bug into a hard startup
exception (Poka-yoke). This makes asset-pipeline regressions impossible
to ship silently.

## Source

- Designer / project: Mikhail Sharanda (Mishanya Sharanda)
- Canonical maintained source: <https://github.com/sharanda/manrope> *(repo
  was offline at install time; user supplied the static TTF set from a
  cached Manrope distribution including the same OFL.txt that the
  upstream `google/fonts` mirror ships, see SHA-256 below)*
- Mirror used for verification: <https://github.com/google/fonts/tree/main/ofl/manrope>
- License: SIL Open Font License, Version 1.1 — full text in
  [`assets/google_fonts/Manrope/OFL.txt`](../../assets/google_fonts/Manrope/OFL.txt)

## What we ship and why

The 5 weights bundled match the 12-style Material 3 typescale defined in
[Story 1.2 AC2.3](../../_bmad-output/implementation-artifacts/1-2-design-system-foundation.md):

| Weight | File | Used by Material 3 slots |
| ------ | ---- | ------------------------ |
| 400 (Regular)   | `Manrope-Regular.ttf`   | `bodyLarge`, `bodyMedium` |
| 500 (Medium)    | `Manrope-Medium.ttf`    | `bodySmall` |
| 600 (SemiBold)  | `Manrope-SemiBold.ttf`  | `headlineSmall`, `titleLarge`, `titleMedium`, `labelLarge`, `labelMedium` |
| 700 (Bold)      | `Manrope-Bold.ttf`      | `displayMedium`, `headlineLarge`, `headlineMedium` |
| 800 (ExtraBold) | `Manrope-ExtraBold.ttf` | `displayLarge` |

Italics are deliberately **not bundled** — UX spec §Typography forbids
italics for the host's reading context. Lighter weights (200/300) are
absent because the typescale never falls below `bodySmall` at 12/500.

## Filename convention

The `google_fonts` package's local-asset detection requires
`Manrope-<Style>.ttf` filenames to resolve to specific weights. Renaming
or adding suffixes (e.g. `Manrope-Regular-400.ttf`) breaks resolution
and triggers a runtime exception (because we set
`allowRuntimeFetching = false`). Do not rename.

## SHA-256

Recompute with `shasum -a 256 assets/google_fonts/Manrope/*.ttf
assets/google_fonts/Manrope/OFL.txt` from the repo root. Any drift here
means the asset has been modified or replaced — investigate before
shipping.

```text
4aed5d180a4f41ed21f07e678486f889bb40eb0ddf5f473769b6302f507d1e36  Manrope-Bold.ttf
5be6d9b21d23981ab520f0bfc7800c434c9d093467ef24b85b16877e7709b03b  Manrope-ExtraBold.ttf
88d3f8ef004b53483a202772d09acaab17ca99dd41905d9b4ab07ac635632378  Manrope-Medium.ttf
6383bd9f81e56d61139884d8e42cb7b2146a11dde4efde55c8bff1e4c2c0bbe8  Manrope-Regular.ttf
abbefa1f58c7355b663c19f29ffe4cd7fc8c93a9e5f8b68f08d1e9ba2bc4ba0d  Manrope-SemiBold.ttf
58d49f25b2cacdfe83739d557ac9319c48bf3ed3e9e33b6678ddb972b475ce7c  OFL.txt
```

## SIL OFL 1.1 obligations

§4 of the license requires that the OFL itself ship with the font
binaries. `OFL.txt` is bundled in the same asset folder so the obligation
is satisfied at distribution time (it ends up inside the AAB alongside
the TTFs).

The OFL allows commercial use, modification, and bundling without
royalty. There is no obligation to credit Manrope in the app UI; the
license text travelling with the binaries is sufficient. Should we ever
fork or modify the font, §1 forbids using the "Manrope" Reserved Font
Name on the modified version — we'd have to rename. Today we ship the
upstream files unchanged.
