import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// Compile-time [AppConfig] from `--dart-define` / `--dart-define-from-file`.
///
/// Prefer migrating to `riverpod_generator` once it resolves cleanly with the SDK's
/// pinned `test` / `test_api` (see pubspec dev comment).
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
