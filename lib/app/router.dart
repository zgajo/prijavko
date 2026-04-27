import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/features/onboarding/welcome_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

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
            // TODO(story-1.6): replace placeholder with CameraPermissionScreen
            // i18n-ignore: placeholder scaffold; replaced in Story 1.6
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Camera permission — Story 1.6')),
            ),
          ),
        ],
      ),
    ],
    // TODO(story-2.3): add redirect callback reading authNotifierProvider
  );
}
