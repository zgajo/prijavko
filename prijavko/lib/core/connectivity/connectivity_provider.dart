import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live connectivity for [ConnectivityBanner] (Story 1.5) and send gating (Epic 5).
///
/// The stream is owned by the platform plugin; callers do not cancel it.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((
  Ref ref,
) {
  return Connectivity().onConnectivityChanged;
});
