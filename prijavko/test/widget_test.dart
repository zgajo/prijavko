import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prijavko/app.dart';
import 'package:prijavko/core/config/app_config.dart';
import 'package:prijavko/core/config/app_config_provider.dart';

void main() {
  testWidgets('renders dev-like API base when config is overridden', (
    tester,
  ) async {
    const config = AppConfig(
      apiBase: 'https://www.evisitor.hr/testApi',
      adEnabled: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: const PrijavkoApp(),
      ),
    );

    expect(find.textContaining('evisitor.hr/testApi'), findsOneWidget);
    expect(find.textContaining('Ads: false'), findsOneWidget);
  });
}
