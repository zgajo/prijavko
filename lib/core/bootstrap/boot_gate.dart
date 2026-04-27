// WHY ConsumerStatefulWidget: BootGate holds _navigated — an instance bool
// that prevents double-navigation if a hot-reload or rebuild fires before
// the post-frame callback executes (Poka-yoke). Mirrors LoginScreen's
// double-tap guard pattern from Story 1.7.
//
// WHY placement (inside ConsentGate, before the router):
// The widget-tree wrapping order on cold start (outermost → innermost):
//   1. ProviderScope (main.dart)
//   2. MaterialApp.router (PrijavkoApp.build)
//   3. ConsentGate (Story 1.4) — gates on UMP consent resolution
//   4. BootGate (this story) — gates on sessionBootstrapProvider.future
//   5. Router (go_router) — initialLocation: '/onboarding'
//
// WHY consent before boot: UMP must precede any Drift/Keystore touch (Story
// 1.4 ordering invariant). Bootstrap reads Keystore — it must come after
// consent resolution.
//
// WHY no router redirect callback: go_router's redirect is synchronous and
// cannot await Futures. BootGate resolves the async provider once, then
// either lets the initial '/onboarding' location stand (FreshFirstRun) or
// imperatively goNamed to '/home' (SessionLive / CookiesMissing). This is
// the documented Riverpod 3 + go_router 14 pattern for async-bootstrap-
// then-redirect — avoids nullable-provider race conditions.
//
// i18n-ignore: BootGate shows only BootLoadingScaffold — no user-facing
// strings. The loading surface is sub-50ms transient on cold start.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/core/bootstrap/boot_loading_scaffold.dart';
import 'package:prijavko/core/bootstrap/session_bootstrap.dart';
import 'package:prijavko/core/bootstrap/session_bootstrap_provider.dart';

class BootGate extends ConsumerStatefulWidget {
  const BootGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BootGate> createState() => _BootGateState();
}

class _BootGateState extends ConsumerState<BootGate> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(sessionBootstrapProvider);
    return boot.when(
      loading: () => const BootLoadingScaffold(),
      // Jidoka — never swallow bootstrap errors. A Keystore failure at startup
      // must crash visibly, not silently fall back to first-run onboarding.
      error: (e, st) => throw e,
      data: (decision) {
        _navigateOnce(context, decision);
        return widget.child;
      },
    );
  }

  void _navigateOnce(BuildContext context, SessionBootstrap decision) {
    if (_navigated) return;
    _navigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (decision) {
        case BootFreshFirstRun():
          // No navigation: go_router's initialLocation: '/onboarding' already
          // lands the user on WelcomeScreen. No goNamed call needed.
          break;
        case BootSessionLive():
          context.goNamed('home');
        case BootCookiesMissing():
          // Route to home; Epic 2 Story 2.7's CredentialBanner handles recovery
          // on the Home screen.
          context.goNamed('home');
        case BootCredentialsMissing():
          // TODO(story-2.8): route to goNamed('credentials-missing-recovery')
          // once Story 2.8's recovery screen exists and Story 3.1 makes
          // facility profiles writable. Until then, this branch is unreachable
          // (hasFacilityProfileProvider always returns false in v1.0).
          debugPrint(
            '[BootGate] BootCredentialsMissing reached — stub; '
            'no navigation until Story 2.8.',
          );
      }
    });
  }
}
