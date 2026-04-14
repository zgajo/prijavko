import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_provider.dart';
import '../../core/l10n/context_l10n.dart';

/// Offline strip shown below the status bar when there is no usable connection.
///
/// Does not consume the full [SafeArea] itself; the shell positions this above
/// tab content so insets stay consistent with [SafeArea] on the body.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  static bool _isOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return false;
    }
    return results.any((ConnectivityResult r) => r != ConnectivityResult.none);
  }

  /// Offline strip — also used when the plugin fails (fail-safe: assume unreachable).
  static Widget _offlineStrip(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          context.l10n.offlineNoConnection,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onErrorContainer),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ConnectivityResult>> connectivity = ref.watch(
      connectivityProvider,
    );
    return connectivity.when(
      data: (List<ConnectivityResult> results) {
        if (_isOnline(results)) {
          return const SizedBox.shrink();
        }
        return _offlineStrip(context);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _offlineStrip(context),
    );
  }
}
