import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prijavko/design/extensions.dart';
import 'package:prijavko/design/icons.dart';
import 'package:prijavko/design/theme.dart';

void main() {
  // WHY: Manrope ships as bundled assets under assets/google_fonts/Manrope/
  // (Story 1.2 AC8). Disabling runtime fetching turns a missing-asset bug
  // into a loud startup exception in dev/CI rather than a silent CDN
  // fallback that violates the offline-tolerant PRD NFR. Poka-yoke.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const MainApp());
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                // i18n-ignore: design-system preview scaffold; removed in 1.5
                'prijavko',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      FilledButton(
                        onPressed: () {},
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Symbols.check_rounded),
                            SizedBox(width: 8),
                            // i18n-ignore: design-system preview scaffold; removed in 1.5
                            Text('Preview'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {},
                        // i18n-ignore: design-system preview scaffold; removed in 1.5
                        child: const Text('Preview'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SemanticSwatch(
                color: semantic.warningContainer,
                onColor: semantic.onWarningContainer,
                // i18n-ignore: design-system preview scaffold; removed in 1.5
                label: 'warning',
              ),
              const SizedBox(height: 8),
              _SemanticSwatch(
                color: semantic.success,
                onColor: semantic.onSuccess,
                // i18n-ignore: design-system preview scaffold; removed in 1.5
                label: 'success',
              ),
              const SizedBox(height: 8),
              _SemanticSwatch(
                color: semantic.closureAccent,
                onColor: theme.colorScheme.onSurface,
                // i18n-ignore: design-system preview scaffold; removed in 1.5
                label: 'closureAccent',
              ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: onColor),
      ),
    );
  }
}
