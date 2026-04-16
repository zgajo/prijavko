import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/theme/theme.dart';

void main() {
  group('AppQueueTheme', () {
    testWidgets('is registered on light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Builder(
            builder: (BuildContext context) {
              final AppQueueTheme? ext = Theme.of(
                context,
              ).extension<AppQueueTheme>();
              expect(ext, isNotNull);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('is registered on dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (BuildContext context) {
              final AppQueueTheme? ext = Theme.of(
                context,
              ).extension<AppQueueTheme>();
              expect(ext, isNotNull);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    test('light and dark ThemeData both use Material 3', () {
      final ThemeData light = buildLightTheme();
      final ThemeData dark = buildDarkTheme();
      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.extensions[AppQueueTheme], isNotNull);
      expect(dark.extensions[AppQueueTheme], isNotNull);
    });

    test('fromColorScheme maps semantic roles to ColorScheme slots', () {
      const ColorScheme scheme = ColorScheme.light();
      final AppQueueTheme q = AppQueueTheme.fromColorScheme(scheme);
      expect(q.queuedColor, scheme.secondary);
      expect(q.sentColor, scheme.primaryContainer);
      expect(q.pausedAuthColor, scheme.tertiary);
    });

    test('copyWith overrides only provided fields', () {
      final AppQueueTheme base = AppQueueTheme.fromColorScheme(
        const ColorScheme.light(),
      );
      final AppQueueTheme next = base.copyWith(queuedColor: Colors.black);
      expect(next.queuedColor, Colors.black);
      expect(next.queuedIcon, base.queuedIcon);
    });

    test('lerp returns this when other is null', () {
      final AppQueueTheme a = AppQueueTheme.fromColorScheme(
        const ColorScheme.light(),
      );
      expect(a.lerp(null, 0.25), same(a));
    });

    test('lerp interpolates between two themes and clamps t', () {
      final AppQueueTheme a = AppQueueTheme.fromColorScheme(
        ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      );
      final AppQueueTheme b = AppQueueTheme.fromColorScheme(
        ColorScheme.fromSeed(seedColor: Colors.indigo),
      );
      final AppQueueTheme mid = a.lerp(b, 0.5);
      expect(mid.queuedColor, isNot(equals(a.queuedColor)));
      final AppQueueTheme clamped = a.lerp(b, 2.0);
      expect(clamped.queuedColor, a.lerp(b, 1.0).queuedColor);
    });
  });
}
