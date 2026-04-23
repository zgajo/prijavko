# PII guard regex (NFR-S7 CI half)

This file is the authoritative source for the regex that
[`pii_guard.yml`](../../.github/workflows/pii_guard.yml) runs on every
push and PR. Keep the `PII_REGEX` env var in the workflow in lockstep
with the pattern documented here.

## Pattern

```regexp
(print|debugPrint|AppLogger\.\w+)\(.*\.(documentNumber|firstName|lastName|dateOfBirth|nationality|documentExpiry|mrzLine1|mrzLine2)
```

### What it catches

Any call to `print(...)`, `debugPrint(...)`, or any `AppLogger.<method>(...)`
whose argument contains a `.`-access to one of the PII fields the app
handles at the camera boundary:

- `documentNumber`
- `firstName`
- `lastName`
- `dateOfBirth`
- `nationality`
- `documentExpiry`
- `mrzLine1`
- `mrzLine2`

These are the exact field names used across the MRZ parser, guest entry
model, and eVisitor request builder (the latter two land in Epics 2–6;
the regex is already protecting those future commits).

### Grep invocation

The workflow uses GNU grep in Perl-compatible mode so `\w` matches what it
means in a typical language (`[A-Za-z0-9_]`):

```sh
grep -rnP --include='*.dart' -- "$PII_REGEX" lib/ test/ integration_test/
```

A single match exits grep with status 0, which the workflow converts to a
build failure with `::error::PII log pattern detected`.

## Examples

### ❌ Blocked (regex matches, build fails)

```dart
debugPrint('Scanned guest ${guest.firstName}');
print('MRZ OK: ${mrz.documentNumber}');
AppLogger.info('Expiry ${doc.documentExpiry}');
AppLogger.error('Line2=${scan.mrzLine2}');
```

### ✅ Allowed (regex does not match, build passes)

```dart
debugPrint('Queue size: ${queue.length}');
AppLogger.info('Send complete: $successCount/$totalCount');
print('boot_ms=$bootMs');
AppLogger.warn('Circuit breaker opened');
// Referring to the PII field name in a comment is fine.
// (regex requires the literal `(` of a call before the `.field`.)
```

## If this regex needs to change

1. Update the `PII_REGEX` env var in
   [`pii_guard.yml`](../../.github/workflows/pii_guard.yml).
2. Update the pattern block and the example lists above in the same
   commit.
3. Run the updated grep locally against `lib/ test/ integration_test/`
   to confirm it is clean before pushing.

The regex is deliberately narrow — only `print | debugPrint | AppLogger.*`.
If a new log facade is introduced (e.g. `TelemetryService.*` in Epic 9),
add its name here rather than broadening to `.*\.\w+\(` which would
generate false positives on legitimate non-log call sites.
