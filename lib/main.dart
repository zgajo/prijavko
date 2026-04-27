import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prijavko/app/providers.dart';
import 'package:prijavko/core/security/security_service.dart';
import 'package:prijavko/design/extensions.dart';
import 'package:prijavko/design/icons.dart';
import 'package:prijavko/design/theme.dart';
import 'package:prijavko/design/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  applyMainAppFontConfig();

  final securityService = SecurityService();
  // WHY: SecurityService loads the AES-GCM key once at startup — not lazily
  // on first use — so any flutter_secure_storage failure (Keystore unavailable,
  // corrupt entry) crashes visibly at launch rather than silently during a
  // guest submission at 2 AM. Jidoka: stop the line early.
  await securityService.init();

  final appDocDir = await getApplicationDocumentsDirectory();
  final cookieJarDir = '${appDocDir.path}/.evisitor_cookie_jar';

  runApp(
    ProviderScope(
      overrides: [
        securityServiceProvider.overrideWithValue(securityService),
        cookieJarDirectoryProvider.overrideWithValue(cookieJarDir),
      ],
      child: const MainApp(),
    ),
  );
}

// WHY: Manrope ships as bundled assets under assets/google_fonts/Manrope/
// (Story 1.2 AC8). Disabling runtime fetching turns a missing-asset bug
// into a loud startup exception in dev/CI rather than a silent CDN
// fallback that violates the offline-tolerant PRD NFR. Poka-yoke.
//
// Factored out of `main()` so `test/design/offline_fonts_test.dart` can
// exercise it directly — the only sanctioned way to drive the same
// initialization the production app performs.
void applyMainAppFontConfig() {
  GoogleFonts.config.allowRuntimeFetching = false;
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'prijavko',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      // WHY: ThemeMode.system is literal — no in-app toggle until the
      // user-preferences story lands. PRD NFR-U2 (follow system dark/light)
      // is satisfied by construction.
      themeMode: ThemeMode.system,
      home: const _DesignSystemPreview(),
    );
  }
}

// WHY: Throwaway smoke-test surface for the design system. Renders one
// instance of every theming primitive — typography, button hierarchy,
// card surface, semantic-color extension, Material Symbols rounded —
// so a misconfigured token or a missing font asset paints visibly
// wrong on the very first frame. Replaced by the welcome flow when
// onboarding lands.
//
// TODO(story-1.5): replace with WelcomeScreen once onboarding lands.
class _DesignSystemPreview extends StatelessWidget {
  const _DesignSystemPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;

    return Scaffold(
      // i18n-ignore: design-system preview scaffold; removed in 1.5
      appBar: AppBar(title: const Text('prijavko')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TokensSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                // i18n-ignore: design-system preview scaffold; removed in 1.5
                'Design system',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: TokensSpace.s16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(TokensSpace.s16),
                  child: _PreviewButtons(),
                ),
              ),
              const SizedBox(height: TokensSpace.s24),
              _SemanticSwatch(
                color: semantic.warning,
                onColor: semantic.onWarning,
                // i18n-ignore: design-system preview scaffold; removed in 1.5
                label: 'warning',
              ),
              const SizedBox(height: TokensSpace.s8),
              _SemanticSwatch(
                color: semantic.success,
                onColor: semantic.onSuccess,
                // i18n-ignore: design-system preview scaffold; removed in 1.5
                label: 'success',
              ),
              const SizedBox(height: TokensSpace.s8),
              // WHY: closureAccent ships without a paired `onClosureAccent`
              // (see lib/design/extensions.dart header). The swatch renders
              // the gold as a non-text-bearing accent — a thin strip with
              // an icon-only label — to honour that contract on day one.
              _ClosureAccentStrip(color: semantic.closureAccent),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewButtons extends StatelessWidget {
  const _PreviewButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton(
          onPressed: () {},
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Symbols.check_rounded),
              SizedBox(width: TokensSpace.s8),
              // i18n-ignore: design-system preview scaffold; removed in 1.5
              Text('Preview'),
            ],
          ),
        ),
        const SizedBox(height: TokensSpace.s12),
        OutlinedButton(
          onPressed: () {},
          // i18n-ignore: design-system preview scaffold; removed in 1.5
          child: const Text('Preview'),
        ),
      ],
    );
  }
}

class _SemanticSwatch extends StatelessWidget {
  const _SemanticSwatch({
    required this.color,
    required this.onColor,
    required this.label,
  });

  final Color color;
  final Color onColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpace.s16,
        vertical: TokensSpace.s12,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(
          Radius.circular(TokensRadius.button),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: onColor),
      ),
    );
  }
}

class _ClosureAccentStrip extends StatelessWidget {
  const _ClosureAccentStrip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TokensSpace.s32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(
          Radius.circular(TokensRadius.button),
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Symbols.check_rounded),
    );
  }
}
