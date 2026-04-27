// WHY LoginFailure (not the architecture's AuthFailureReason enum):
// AuthFailureReason (sessionDead | credentialsInvalid | lockedOut | network |
// contractBreak) lands in Epic 2 Story 2.1 alongside AuthState. `sessionDead`
// is meaningless during *first* login — there is no session yet to be dead.
// Story 1.7 ships the smaller, login-specific union.
//
// TODO(story-2.2): EvisitorErrorClassifier subsumes LoginResponseClassifier;
// LoginFailure variants map 1:1 to AuthFailureReason minus sessionDead.
// Provide a `toAuthFailure` extension during the transition.

/// Login-specific failure variants — compile-time exhaustive via `sealed`.
///
/// WHY sealed (not enum): variants carry data (retryAfter, userMessage,
/// statusCode). Exhaustive `switch` at the screen makes "I forgot to handle
/// lockout" structurally impossible.
sealed class LoginFailure {
  const LoginFailure();
}

final class CredentialsInvalid extends LoginFailure {
  const CredentialsInvalid({this.userMessage});

  /// Verbatim Croatian from eVisitor's UserMessage; null if absent.
  /// Surfaced as-is to the UI per NFR-L3 — do not translate or rephrase.
  final String? userMessage;
}

final class AccountLockedOut extends LoginFailure {
  const AccountLockedOut({required this.retryAfter});

  /// When the lockout expires — prijavko-side 6-minute budget per architecture
  /// §Circuit breaker (stricter than Rhetos' 5 minutes).
  final DateTime retryAfter;
}

final class NetworkUnreachable extends LoginFailure {
  const NetworkUnreachable();
}

final class ServerError extends LoginFailure {
  const ServerError(this.statusCode);
  final int statusCode;
}

final class ContractBreak extends LoginFailure {
  const ContractBreak(this.reason);

  /// Diagnostic only — never shown to user.
  final String reason;
}
