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
    expect(colors.success, isNotNull);
  });

  test('light and dark warning differ — palettes are not symlinked', () {
    final light = SemanticColors.light();
    final dark = SemanticColors.dark();
    // guards AC6.2 — a regression that re-uses one factory for both themes
    // (e.g. accidental copy-paste of `SemanticColors.light()` into the dark
    // builder) would make warning equal across modes.
    // ignore: deprecated_member_use
    expect(light.warning.value, isNot(equals(dark.warning.value)));
    // ignore: deprecated_member_use
    expect(light.success.value, isNot(equals(dark.success.value)));
    // ignore: deprecated_member_use
    expect(light.closureAccent.value, isNot(equals(dark.closureAccent.value)));
  });

  test('copyWith overrides only the named fields', () {
    final base = SemanticColors.light();
    final tweaked = base.copyWith(warning: const Color(0xFF000000));
    // guards AC3.3 — `copyWith` must preserve non-named fields untouched.
    // ignore: deprecated_member_use
    expect(tweaked.warning.value, 0xFF000000);
    expect(tweaked.success, base.success);
    expect(tweaked.closureAccent, base.closureAccent);
  });

  test('lerp at t=0.0 returns this; t=1.0 returns other', () {
    final a = SemanticColors.light();
    final b = SemanticColors.dark();
    // guards AC3.3 — `lerp` honours the standard endpoints contract.
    expect(a.lerp(b, 0.0).warning, a.warning);
    expect(a.lerp(b, 1.0).warning, b.warning);
  });
}
