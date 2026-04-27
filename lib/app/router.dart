import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/features/auth/login_screen.dart';
import 'package:prijavko/features/onboarding/camera_permission_screen.dart';
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
        // TODO(story-3.x): replace placeholder with HomeScreen + AdBanner + queue
        // i18n-ignore: placeholder scaffold; replaced in Epic 3
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Home — Epic 3'))),
      ),
    ],
    // TODO(story-2.3): add redirect callback reading authNotifierProvider
  );
}
