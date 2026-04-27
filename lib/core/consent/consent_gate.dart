// WHY: ConsentGate renders a SDK-driven full-screen form. The form's HTML/CSS
// is the SDK's, not ours. We do not screenshot, log, or persist any of its
// content. The widget's only output is a transient ConsentState; that state
// never carries PII.
//
// WHY placement: ConsentGate wraps the entire app at root, before any route or
// screen widget. This ensures UMP consent is requested before any ad-capable
// widget (AdBanner, Story 10.1) is mounted — satisfying GDPR sequencing.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prijavko/core/consent/consent_providers.dart';
import 'package:prijavko/core/consent/consent_state.dart';

class ConsentGate extends ConsumerStatefulWidget {
  const ConsentGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends ConsumerState<ConsentGate> {
  @override
  void initState() {
    super.initState();
    // WHY: post-frame callback prevents a black flash on launch. UMP's native
    // consent form is a full-screen Android Activity; calling it before the
    // Flutter engine renders its first frame causes a visible flicker.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(consentControllerProvider.notifier).gather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final consentState = ref.watch(consentControllerProvider);

    return switch (consentState) {
      ConsentLoading() => const _ConsentLoadingScaffold(),
      ConsentObtained() || ConsentNotRequired() => widget.child,
      // WHY: ConsentFailed does NOT block the app. Failure means non-personalized
      // ads (safe default via requestNonPersonalizedAdsProvider). The user should
      // never see a "consent failed" error screen — they get full app access.
      // TODO(story-9.x): emit telemetry event consent_gather_failed
      ConsentFailed() => widget.child,
    };
  }
}

// Shown for the ~50ms UMP RPC window in EEA users. Non-EEA users never see it
// because requestConsentInfoUpdate returns notRequired synchronously from cache.
// No user-facing strings: the form text is entirely SDK-owned and localized.
// i18n-ignore: ConsentLoadingScaffold has no user-facing strings (AC11.2)
class _ConsentLoadingScaffold extends StatelessWidget {
  const _ConsentLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading'),
      ),
    );
  }
}
