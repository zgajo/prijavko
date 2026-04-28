#!/usr/bin/env bash
# Spec-drift guard: asserts that load-bearing values in the codebase
# still match what PRD/architecture/stories declare.
#
# Why: implementation stories cite specific minSdk/targetSdk values and
# require concrete files (tokens, cert pins, security config). When code
# diverges from spec, agents and contributors silently lose traceability.
# This script is the build-blocking signal — fail loud, fail early.
#
# Add new checks when a story commits to a load-bearing constant or path.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

EXPECTED_MIN_SDK=24
EXPECTED_TARGET_SDK=36
EXPECTED_COMPILE_SDK=36

GRADLE_FILE="android/app/build.gradle.kts"
README="README.md"

REQUIRED_FILES=(
  "lib/design/tokens.dart"                                  # Story 1.2
  "lib/design/theme.dart"                                   # Story 1.2
  "lib/core/security/cert_pins.dart"                        # Story 1.3
  "lib/core/env/evisitor_env.dart"                          # README — env switch
  "android/app/src/main/res/xml/network_security_config.xml" # Story 1.1 — NFR-S1
  "android/app/src/main/AndroidManifest.xml"                # Story 1.1
)

errors=0

fail() {
  echo "FAIL: $*" >&2
  errors=$((errors + 1))
}

# ---------- Android SDK pins ----------
gradle_min=$(grep -E "^\s*minSdk\s*=" "$GRADLE_FILE" | grep -oE "[0-9]+" | head -1)
gradle_target=$(grep -E "^\s*targetSdk\s*=" "$GRADLE_FILE" | grep -oE "[0-9]+" | head -1)
gradle_compile=$(grep -E "^\s*compileSdk\s*=" "$GRADLE_FILE" | grep -oE "[0-9]+" | head -1)

[[ "$gradle_min" == "$EXPECTED_MIN_SDK" ]] \
  || fail "$GRADLE_FILE minSdk=$gradle_min, expected $EXPECTED_MIN_SDK (PRD NFR-C1, README)"
[[ "$gradle_target" == "$EXPECTED_TARGET_SDK" ]] \
  || fail "$GRADLE_FILE targetSdk=$gradle_target, expected $EXPECTED_TARGET_SDK (README)"
[[ "$gradle_compile" == "$EXPECTED_COMPILE_SDK" ]] \
  || fail "$GRADLE_FILE compileSdk=$gradle_compile, expected $EXPECTED_COMPILE_SDK"

grep -qE "minSdk[\` ]*$EXPECTED_MIN_SDK" "$README" \
  || fail "$README does not advertise minSdk $EXPECTED_MIN_SDK"
grep -qE "targetSdk[\` ]*$EXPECTED_TARGET_SDK" "$README" \
  || fail "$README does not advertise targetSdk $EXPECTED_TARGET_SDK"

# ---------- Required files (story acceptance artifacts) ----------
for path in "${REQUIRED_FILES[@]}"; do
  [[ -f "$path" ]] || fail "missing required file: $path"
done

# ---------- AndroidManifest hardening (Story 1.1, NFR-S6) ----------
manifest="android/app/src/main/AndroidManifest.xml"
grep -q 'android:allowBackup="false"' "$manifest" \
  || fail "$manifest must set android:allowBackup=\"false\" (NFR-S6)"
grep -q 'android:fullBackupContent="false"' "$manifest" \
  || fail "$manifest must set android:fullBackupContent=\"false\" (NFR-S6)"

# ---------- Result ----------
if [[ $errors -gt 0 ]]; then
  echo "" >&2
  echo "spec_drift_check: $errors check(s) failed." >&2
  exit 1
fi

echo "spec_drift_check: all checks passed."
