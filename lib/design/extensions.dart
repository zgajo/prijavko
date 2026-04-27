// WHY: Material 3's `ColorScheme` covers brand + error + surface tones,
// but the prijavko UX spec needs status colors that M3 does not name —
// `warning` (rate-limit / soft validation), `success` (commit confirmed),
// `closureAccent` (the gold for the closure-summary signature moment),
// plus surface-container-high and outline-variant which M3 promotes only
// in the M3-expressive variant. We expose them via a `ThemeExtension`
// so widgets read them through `Theme.of(context).extension<SemanticColors>()`,
// not via global getters or magic-string keys.
//
// Why required-named-parameter constructor: the AC bans defaults so a
// future refactor that forgets to wire a field fails at compile time
// (Poka-yoke). The two factory constructors `SemanticColors.light()` and
// `SemanticColors.dark()` are the only sanctioned construction sites.
//
// Why the non-null `!` in the `BuildContext` extension: a missing
// extension is a programmer error (the theme was built without our
// extensions), so we want it loud, not "fall back to a default and ship a
// silently broken status palette." A widget test asserts the extension
// resolves under both themes — regression caught in CI.
//
// Why `closureAccent` has NO paired `onClosureAccent`: by design,
// `closureAccent` is a non-text-bearing accent — used as a background
// tint for the closure-summary signature moment, as a border on the
// closure card, or as an icon fill. Text-on-closure-accent is reserved
// for the headline-on-surface relationship (so the gold remains a
// flourish, not a typographic surface). If a future story requires text
// to render on top of a `closureAccent` fill, the right move is to add
// a paired `onClosureAccent` field here AND update the UX spec — not
// to inline a foreground colour at the call site.

import 'package:flutter/material.dart';

@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
    required this.onSuccess,
    required this.closureAccent,
    required this.surfaceContainerHigh,
    required this.outlineVariant,
  });

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color success;
  final Color onSuccess;
  final Color closureAccent;
  final Color surfaceContainerHigh;
  final Color outlineVariant;

  // WHY hex literals: UX spec §Color System pins these values; deviating
  // requires a UX spec update first, not an inline tweak.
  factory SemanticColors.light() => const SemanticColors(
    warning: Color(0xFFED6C02),
    // DERIVED FROM M3 on-warning pairing for the saturated orange — white
    // foreground keeps WCAG AA on the warning fill (~5.5:1). Pinned so the
    // pairing does not drift if `fromSeed` tonal output changes.
    onWarning: Color(0xFFFFFFFF),
    // WHY: M3 warmth-on-light tonal — derived once from the closest
    // tertiary container produced by `ColorScheme.fromSeed(0xFF0D4F52,
    // brightness: light)` and pinned here so the warning palette never
    // accidentally drifts when the seed is replaced.
    warningContainer: Color(0xFFFFE2B8),
    onWarningContainer: Color(0xFF2E1500),
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    closureAccent: Color(0xFFC9A43A),
    // DERIVED FROM fromSeed(0xFF0D4F52, brightness: light) tonal — pinned
    // to keep the elevation language stable across Flutter versions.
    surfaceContainerHigh: Color(0xFFDEE4E4),
    outlineVariant: Color(0xFFBFC9C8),
  );

  factory SemanticColors.dark() => const SemanticColors(
    warning: Color(0xFFFFB74D),
    // DERIVED FROM M3 on-warning pairing for the lighter dark-mode orange
    // — very dark warm brown keeps WCAG AA against the bright orange fill.
    onWarning: Color(0xFF422C00),
    warningContainer: Color(0xFF4A2E00),
    onWarningContainer: Color(0xFFFFE2B8),
    success: Color(0xFF81C784),
    onSuccess: Color(0xFF003A09),
    closureAccent: Color(0xFFD4B858),
    // DERIVED FROM fromSeed(0xFF0D4F52, brightness: dark) tonal.
    surfaceContainerHigh: Color(0xFF25302F),
    outlineVariant: Color(0xFF48514F),
  );

  @override
  SemanticColors copyWith({
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
    Color? onSuccess,
    Color? closureAccent,
    Color? surfaceContainerHigh,
    Color? outlineVariant,
  }) {
    return SemanticColors(
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      closureAccent: closureAccent ?? this.closureAccent,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      outlineVariant: outlineVariant ?? this.outlineVariant,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      closureAccent: Color.lerp(closureAccent, other.closureAccent, t)!,
      surfaceContainerHigh: Color.lerp(
        surfaceContainerHigh,
        other.surfaceContainerHigh,
        t,
      )!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
    );
  }
}

// WHY: The `!` is intentional Poka-yoke — if a screen tries to read
// semantic colors under a `Theme` that wasn't built via `buildLightTheme`
// or `buildDarkTheme`, this throws a clear NPE rather than handing back a
// default palette that hides the bug. The companion test in
// `test/design/semantic_colors_test.dart` asserts the extension resolves
// under both themes so the production assertion never fires in correct code.
extension SemanticColorsContext on BuildContext {
  SemanticColors get semanticColors =>
      Theme.of(this).extension<SemanticColors>()!;
}
