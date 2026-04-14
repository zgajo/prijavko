import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/database/app_database.dart';

/// Bridges [FacilitiesDao.watchAllFacilities] to [GoRouter.refreshListenable] so
/// [GoRouter.redirect] re-evaluates when facility rows change (Epic 2) without an
/// app restart.
///
/// Disposal cancels the stream subscription; pair with [Provider.onDispose] when
/// registered as a Riverpod provider.
final class FacilitiesRouteRefreshNotifier extends ChangeNotifier {
  FacilitiesRouteRefreshNotifier(Stream<List<DbFacility>> facilityStream) {
    _subscription = facilityStream.listen(
      _onFacilities,
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'prijavko/router',
            context: ErrorDescription(
              'FacilitiesRouteRefreshNotifier: watchAllFacilities failed',
            ),
          ),
        );
      },
    );
  }

  late final StreamSubscription<List<DbFacility>> _subscription;
  List<DbFacility> _rows = <DbFacility>[];

  /// Whether at least one facility row exists (onboarding vs shell).
  bool get hasFacilities => _rows.isNotEmpty;

  void _onFacilities(List<DbFacility> rows) {
    _rows = rows;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
