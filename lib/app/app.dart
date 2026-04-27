import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prijavko/app/router.dart';
import 'package:prijavko/core/bootstrap/boot_gate.dart';
import 'package:prijavko/core/consent/consent_gate.dart';
import 'package:prijavko/design/theme.dart';
import 'package:prijavko/l10n/app_localizations.dart';

class PrijavkoApp extends ConsumerWidget {
  const PrijavkoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'prijavko',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      // WHY ThemeMode.system: no in-app toggle until user-preferences story.
      // PRD NFR-U2 (follow system dark/light) satisfied by construction.
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // WHY builder for ConsentGate: MaterialApp.router has no `home:` param.
      // Wrapping in builder places ConsentGate between MaterialApp (theme
      // provider) and the Navigator (route tree) so:
      //   (a) Theme.of(context) works inside _ConsentLoadingScaffold,
      //   (b) consentControllerProvider resolves via ancestor ProviderScope,
      //   (c) the Router/Navigator doesn't build until consent resolves —
      //       no wasted route evaluation during the ~50ms consent RPC.
      builder: (context, child) =>
          ConsentGate(child: BootGate(child: child ?? const SizedBox.shrink())),
    );
  }
}
