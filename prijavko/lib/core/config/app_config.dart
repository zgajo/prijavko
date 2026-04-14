/// Compile-time environment loaded from `--dart-define` / `--dart-define-from-file`.
///
/// Run (dev): `flutter run --dart-define-from-file=config/dev.json`
/// Build (prod): `flutter build appbundle --dart-define-from-file=config/prod.json`
class AppConfig {
  const AppConfig({required this.apiBase, required this.adEnabled});

  final String apiBase;
  final bool adEnabled;

  /// Reads [String.fromEnvironment] keys injected at build time (no secrets in source).
  factory AppConfig.fromEnvironment() {
    const apiBase = String.fromEnvironment('API_BASE');
    const adEnabledRaw = String.fromEnvironment('AD_ENABLED');

    if (apiBase.isEmpty) {
      throw StateError(
        'API_BASE is not set. Use --dart-define-from-file=config/dev.json or config/prod.json.',
      );
    }

    if (adEnabledRaw.isEmpty) {
      throw StateError(
        'AD_ENABLED is not set. Use --dart-define-from-file=config/dev.json or config/prod.json.',
      );
    }

    final adFlag = adEnabledRaw.toLowerCase();
    if (adFlag != 'true' && adFlag != 'false') {
      throw StateError(
        'AD_ENABLED must be "true" or "false", got: $adEnabledRaw',
      );
    }

    final adEnabled = adFlag == 'true';
    return AppConfig(apiBase: apiBase, adEnabled: adEnabled);
  }
}
