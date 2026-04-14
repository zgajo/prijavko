// ignore_for_file: public_member_api_docs
//
// App routing (Story 1.5) — [go_router] with:
// - [facilitiesRouteRefreshProvider] + [GoRouter.refreshListenable] so redirects
//   re-run when facility rows change (Drift watch).
// - [appRouterProvider] — single [GoRouter] per [ProviderScope], disposed on
//   unmount.
//
// Named stack stubs (Epic 3 full-screen flow): capture, review, confirm.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:prijavko/data/database/app_database_provider.dart';
import 'package:prijavko/features/history/presentation/screens/history_screen.dart';
import 'package:prijavko/features/home/presentation/screens/home_screen.dart';
import 'package:prijavko/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:prijavko/features/queue/presentation/screens/queue_screen.dart';
import 'package:prijavko/features/settings/presentation/screens/settings_screen.dart';

import 'go_router_refresh_stream.dart';
import 'main_shell.dart';
import 'stack_route_stubs.dart';

/// Root navigator for full-screen routes (onboarding, capture stack).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNavigator',
);

/// Listenable driven by [FacilitiesDao.watchAllFacilities] for [GoRouter].
final facilitiesRouteRefreshProvider = Provider<FacilitiesRouteRefreshNotifier>(
  (Ref ref) {
    final db = ref.watch(appDatabaseProvider);
    final FacilitiesRouteRefreshNotifier notifier =
        FacilitiesRouteRefreshNotifier(db.facilitiesDao.watchAllFacilities());
    ref.onDispose(notifier.dispose);
    return notifier;
  },
);

/// Declarative router: onboarding guard, tab shell, named stack stubs.
final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final FacilitiesRouteRefreshNotifier refresh = ref.watch(
    facilitiesRouteRefreshProvider,
  );
  final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      return _guardRedirect(refresh, state);
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingScreen();
        },
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return MainNavigationShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState state) {
                  return const HomeScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/queue',
                builder: (BuildContext context, GoRouterState state) {
                  return const QueueScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/history',
                builder: (BuildContext context, GoRouterState state) {
                  return const HistoryScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                builder: (BuildContext context, GoRouterState state) {
                  return const SettingsScreen();
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/capture',
        name: 'capture',
        parentNavigatorKey: rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const CaptureStubScreen();
        },
      ),
      GoRoute(
        path: '/review',
        name: 'review',
        parentNavigatorKey: rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const ReviewStubScreen();
        },
      ),
      GoRoute(
        path: '/confirm',
        name: 'confirm',
        parentNavigatorKey: rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const ConfirmStubScreen();
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

String? _guardRedirect(
  FacilitiesRouteRefreshNotifier refresh,
  GoRouterState state,
) {
  final String path = state.uri.path;
  if (!refresh.hasFacilities) {
    if (path == '/onboarding') {
      return null;
    }
    return '/onboarding';
  }
  if (path == '/onboarding') {
    return '/home';
  }
  return null;
}
