import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/design/tokens.dart';
import 'package:prijavko/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Welcome & sensitive-data disclosure screen — the first user-facing screen.
///
/// Renders the data-handling disclosure (what passport data is processed, how
/// long it is kept, where the policy lives) so the host gives informed consent
/// before granting camera permission. Story 1.5 AC5.
///
/// WHY ConsumerStatefulWidget (not ConsumerWidget): TapGestureRecognizer
/// instances require lifecycle management (initState / dispose). Leaking them
/// holds references to the widget tree across navigations — a documented
/// memory-leak anti-pattern. StatefulWidget gives us dispose().
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  // WHY: recognizers are created once in initState and disposed in dispose().
  // Creating them inline in build() would produce a new recognizer on every
  // rebuild and leak the old ones — Flutter does not dispose gesture
  // recognizers automatically for TextSpan.
  late final TapGestureRecognizer _privacyPolicyRecognizer;
  late final TapGestureRecognizer _termsOfServiceRecognizer;

  static const _privacyPolicyUrl = 'https://prijavko.hr/privacy';
  static const _termsOfServiceUrl = 'https://prijavko.hr/terms';

  @override
  void initState() {
    super.initState();
    _privacyPolicyRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl(_privacyPolicyUrl);
    _termsOfServiceRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl(_termsOfServiceUrl);
  }

  @override
  void dispose() {
    _privacyPolicyRecognizer.dispose();
    _termsOfServiceRecognizer.dispose();
    super.dispose();
  }

  /// Launches the given URL in the device's default browser.
  ///
  /// WHY externalApplication: opens in the OS default browser, not an in-app
  /// WebView. Privacy policies need full browser features (cookies, bookmarks).
  ///
  /// WHY silent catch: the links will 404 until Story 10.4 publishes the
  /// static pages. That is expected. The disclosure is informational — a
  /// failed link does not block the host from proceeding.
  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Intentionally silent — see WHY above.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    return Scaffold(
      // WHY no AppBar: Welcome is a full-screen onboarding disclosure.
      // There is nothing before it (ConsentGate is transparent). System
      // back = exit app (default when at the root route). No back button
      // needed or desired.
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TokensSpace.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // WHY s64 top margin: UX spec §Spacing — "emotional top
                      // margin for onboarding moments". Creates breathing room
                      // and reinforces the trust-premise framing.
                      const SizedBox(height: TokensSpace.s64),
                      Text(
                        l10n.welcomeHeadline,
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: TokensSpace.s24),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: l10n.welcomeBody,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const TextSpan(text: '\n\n'),
                            // WHY Semantics wrapper: TapGestureRecognizer on
                            // TextSpan does not auto-generate accessibility
                            // labels. Wrapping provides TalkBack with the link
                            // text and a meaningful hint (WCAG 2.1 §2.4.6).
                            WidgetSpan(
                              child: Semantics(
                                label: l10n.welcomePrivacyPolicyLink,
                                link: true,
                                child: Text.rich(
                                  TextSpan(
                                    text: l10n.welcomePrivacyPolicyLink,
                                    style: linkStyle,
                                    recognizer: _privacyPolicyRecognizer,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              // i18n-ignore: structural connector between two
                              // localized link labels; not user-facing copy
                              text: ' & ',
                              style: theme.textTheme.bodyLarge,
                            ),
                            WidgetSpan(
                              child: Semantics(
                                label: l10n.welcomeTermsOfServiceLink,
                                link: true,
                                child: Text.rich(
                                  TextSpan(
                                    text: l10n.welcomeTermsOfServiceLink,
                                    style: linkStyle,
                                    recognizer: _termsOfServiceRecognizer,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: TokensSpace.s32),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: TokensSpace.s16,
                right: TokensSpace.s16,
                // WHY s24 bottom: gesture inset per UX spec §Standard Screen
                // Skeleton — 72dp CTA zone = 56dp button + 16dp padding.
                // Extra 8dp keeps the button clear of the gesture bar on
                // Android devices without hardware buttons.
                bottom: TokensSpace.s24,
                top: TokensSpace.s16,
              ),
              child: FilledButton(
                // WHY context.go (not context.push): linear onboarding has
                // no back-stack. push() adds a stack entry so back returns
                // here; go() replaces, which is correct for a one-way flow.
                onPressed: () => context.go('/onboarding/camera-permission'),
                child: Text(l10n.welcomeContinueButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
