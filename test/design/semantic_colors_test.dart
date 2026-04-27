// Story 1.2 AC6.2 — guards `lib/design/extensions.dart`.
// Asserts the SemanticColors extension resolves under BOTH themes and
// that light != dark (regression: a copy-paste that points both factories
// at the same palette would defeat the design contract silently).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/design/extensions.dart';

void main() {
  Future<SemanticColors> resolveSemanticColors(
    WidgetTester tester, {
    required Brightness brightness,
  }) async {
    late SemanticColors captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
          extensions: <ThemeExtension<dynamic>>[SemanticColors.light()],
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          extensions: <ThemeExtension<dynamic>>[SemanticColors.dark()],
        ),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: Builder(
          builder: (ctx) {
            captured = ctx.semanticColors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return captured;
  }

  testWidgets('SemanticColors resolves under light theme', (tester) async {
    final colors = await resolveSemanticColors(
      tester,
      brightness: Brightness.light,
    );
    // guards AC3.4 — non-null `!` extension does not throw under a correctly
    // wired light theme.
    expect(colors, isNotNull);
    // guards AC3.1 — every required field is non-null (compile-time
    // enforced by required-named-parameter constructor; runtime sanity).
    expect(colors.warning, isNotNull);
    expect(colors.onWarning, isNotNull);
    expect(colors.warningContainer, isNotNull);
    expect(colors.onWarningContainer, isNotNull);
    expect(colors.success, isNotNull);
    expect(colors.onSuccess, isNotNull);
    expect(colors.closureAccent, isNotNull);
    expect(colors.surfaceContainerHigh, isNotNull);
    expect(colors.outlineVariant, isNotNull);
  });

  testWidgets('SemanticColors resolves under dark theme', (tester) async {
    final colors = await resolveSemanticColors(
      tester,
      brightness: Brightness.dark,
    );
    // guards AC3.4 — `!` works under dark theme too.
    expect(colors, isNotNull);
    expect(colors.warning, isNotNull);
    expect(colors.onWarning, isNotNull);
    expect(colors.success, isNotNull);
  });

  test('light and dark palettes are not symlinked', () {
    final light = SemanticColors.light();
    final dark = SemanticColors.dark();
    // guards AC6.2 — a regression that re-uses one factory for both themes
    // (e.g. accidental copy-paste of `SemanticColors.light()` into the dark
    // builder) would make every field equal across modes. Spot-check the
    // signature fields that hosts notice first.
    // ignore: deprecated_member_use
    expect(light.warning.value, isNot(equals(dark.warning.value)));
    // ignore: deprecated_member_use
    expect(light.onWarning.value, isNot(equals(dark.onWarning.value)));
    // ignore: deprecated_member_use
    expect(light.success.value, isNot(equals(dark.success.value)));
    // ignore: deprecated_member_use
    expect(light.closureAccent.value, isNot(equals(dark.closureAccent.value)));
  });

  test('copyWith preserves every untouched field', () {
    final base = SemanticColors.light();
    final tweaked = base.copyWith(warning: const Color(0xFF000000));
    // guards AC3.3 — copyWith must rewrite ONLY the named field; field
    // crossover bugs (e.g. `warningContainer: warning ?? this.warningContainer`
    // typo on 9 fields) get caught by checking every untouched field.
    // ignore: deprecated_member_use
    expect(tweaked.warning.value, 0xFF000000);
    expect(tweaked.onWarning, base.onWarning);
    expect(tweaked.warningContainer, base.warningContainer);
    expect(tweaked.onWarningContainer, base.onWarningContainer);
    expect(tweaked.success, base.success);
    expect(tweaked.onSuccess, base.onSuccess);
    expect(tweaked.closureAccent, base.closureAccent);
    expect(tweaked.surfaceContainerHigh, base.surfaceContainerHigh);
    expect(tweaked.outlineVariant, base.outlineVariant);
  });

  group('lerp', () {
    final a = SemanticColors.light();
    final b = SemanticColors.dark();

    test('t=0.0 returns this (every field)', () {
      // guards AC3.3 — endpoints are the lerp contract; assert ALL nine
      // fields, not just one, so a copy-paste bug in one Color.lerp call
      // (e.g. `Color.lerp(success, other.warning, t)`) gets caught.
      final r = a.lerp(b, 0.0);
      expect(r.warning, a.warning);
      expect(r.onWarning, a.onWarning);
      expect(r.warningContainer, a.warningContainer);
      expect(r.onWarningContainer, a.onWarningContainer);
      expect(r.success, a.success);
      expect(r.onSuccess, a.onSuccess);
      expect(r.closureAccent, a.closureAccent);
      expect(r.surfaceContainerHigh, a.surfaceContainerHigh);
      expect(r.outlineVariant, a.outlineVariant);
    });

    test('t=1.0 returns other (every field)', () {
      final r = a.lerp(b, 1.0);
      // guards AC3.3 — at t=1 every field equals `other`'s field.
      expect(r.warning, b.warning);
      expect(r.onWarning, b.onWarning);
      expect(r.warningContainer, b.warningContainer);
      expect(r.onWarningContainer, b.onWarningContainer);
      expect(r.success, b.success);
      expect(r.onSuccess, b.onSuccess);
      expect(r.closureAccent, b.closureAccent);
      expect(r.surfaceContainerHigh, b.surfaceContainerHigh);
      expect(r.outlineVariant, b.outlineVariant);
    });

    test('t=0.5 produces a midpoint distinct from both endpoints', () {
      // guards AC3.3 — a buggy lerp that returns `this` regardless of t
      // would still satisfy endpoint tests; the midpoint catches it.
      final r = a.lerp(b, 0.5);
      expect(r.warning, isNot(a.warning));
      expect(r.warning, isNot(b.warning));
      expect(r.onWarning, isNot(a.onWarning));
      expect(r.onWarning, isNot(b.onWarning));
      expect(r.success, isNot(a.success));
      expect(r.success, isNot(b.success));
      expect(r.closureAccent, isNot(a.closureAccent));
      expect(r.closureAccent, isNot(b.closureAccent));
    });
  });
}
