sealed class AppError {
  const AppError();
}

final class StorageError extends AppError {
  const StorageError(this.message, {this.cause});

  final String message;
  // WHY: PlatformException messages from flutter_secure_storage may contain
  // OS-level detail that includes key metadata — not PII, but still auditable
  // surface. Callers extract only the safe message string; `cause` is for
  // internal crash triage only — never passed to AppLogger, Crashlytics, or UI.
  final Object? cause;
}
