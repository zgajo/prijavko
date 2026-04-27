import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/design/icons.dart';
import 'package:prijavko/features/auth/login_screen.dart';
import 'package:prijavko/features/onboarding/camera_permission_screen.dart';
import 'package:prijavko/features/onboarding/welcome_screen.dart';
import 'package:prijavko/features/settings/settings_screen.dart';
import 'package:prijavko/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

// i18n-ignore: placeholder; the /home route is replaced wholesale by Story 5.5.
const _placeholderHomeText = 'Home — Epic 3';

// WHY keepAlive: GoRouter holds the navigation stack and browser-history state
// for the entire app lifetime. Disposing would silently lose the back-stack on
// any provider container invalidation — a subtle, hard-to-reproduce nav bug.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    // WHY /onboarding as initialLocation: the auth redirect (Story 2.x) will
    // send Unauthenticated users to /onboarding. Using it as the initial
    // location today means the redirect callback only needs to ADD the
    // condition, not change the route path — zero migration cost later.
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'camera-permission',
            name: 'camera-permission',
            builder: (context, state) => const CameraPermissionScreen(),
          ),
          GoRoute(
            path: 'login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        // TODO(story-5.5): replace placeholder with HomeScreen + AdBanner + queue;
        //   the gear-icon AppBar action below is interim and is owned by HomeScreen
        //   from Story 5.5 onwards (UX spec §AppBar).
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text(_placeholderHomeText),
            actions: [
              IconButton(
                icon: const Icon(Symbols.settings_rounded),
                tooltip: AppLocalizations.of(context).settingsButtonTooltip,
                onPressed: () => context.pushNamed('settings'),
              ),
            ],
          ),
          body: const Center(child: Text(_placeholderHomeText)),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'replace-credentials',
            name: 'replace-credentials',
            builder: (context, state) => const LoginScreen(replaceMode: true),
          ),
        ],
      ),
    ],
    // TODO(story-2.3): add redirect callback reading authNotifierProvider
  );
}
