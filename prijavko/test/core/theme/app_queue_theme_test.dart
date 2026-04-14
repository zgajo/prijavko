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
  });
}
