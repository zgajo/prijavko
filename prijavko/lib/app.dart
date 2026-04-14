import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n/app_localizations.dart';
import 'core/l10n/context_l10n.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme.dart';

/// Resolves the app locale with a **Croatian-first** fallback (PRD / Story 1.4).
///
/// - If the platform [locale] matches a supported language (`hr` or `en`), we
///   return the matching [supported] entry (including language-only match).
///   So testers and bilingual hosts on **English** (`en-*`) devices see **English**
///   UI when the OS prefers English.
/// - If the platform locale is **not** supported (e.g. `de`, `fr`, or an
///   unsupported variant), we fall back to **`hr`**, not `en`, so the default
///   product language stays **Croatian**.
/// - Automated tests can force **`Locale('en')`** or **`Locale('hr')`** via
///   [MaterialApp.locale] to assert strings without depending on the host OS.
Locale _resolveAppLocale(Locale? locale, Iterable<Locale> supported) {
  if (locale == null) {
    return const Locale('hr');
  }
  for (final option in supported) {
    if (option.languageCode != locale.languageCode) {
      continue;
    }
    final countryCode = locale.countryCode;
    if (countryCode == null || countryCode.isEmpty) {
      return option;
    }
    if (option.countryCode == countryCode) {
      return option;
    }
  }
  for (final option in supported) {
    if (option.languageCode == locale.languageCode) {
      return option;
    }
  }
  return const Locale('hr');
}

/// Root widget; does not perform platform initialization (see [main]).
///
/// Uses [MaterialApp.router] with [appRouterProvider] (Story 1.5).
class PrijavkoApp extends ConsumerWidget {
  const PrijavkoApp({super.key});

  static const List<LocalizationsDelegate<dynamic>> _localizationDelegates =
      <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  static const List<Locale> _supportedLocales = <Locale>[
    Locale('hr'),
    Locale('en'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) => context.l10n.appTitle,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      localizationsDelegates: _localizationDelegates,
      supportedLocales: _supportedLocales,
      localeResolutionCallback: _resolveAppLocale,
      routerConfig: router,
    );
  }
}
