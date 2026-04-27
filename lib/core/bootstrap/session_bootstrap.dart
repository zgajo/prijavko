// WHY interim sealed class, not AuthState:
// AuthState (Epic 2 Story 2.1) is the production type. Story 1.8 needs a
// typed boot decision today. This mirrors Story 1.7's LoginFailure →
// AuthFailureReason JIT pattern. Each variant maps 1-to-1 to an AuthState
// constructor when Epic 2 lands:
//
//   BootFreshFirstRun      → AuthState.unauthenticated()
//   BootSessionLive        → AuthState.authenticated(facilitiesLoaded: false)
//   BootCookiesMissing     → AuthState.reauth()
//   BootCredentialsMissing → AuthState.authFailure(credentialsInvalid)
//
// WHY no BootError variant: any failure in the bootstrap pipeline (Keystore
// unavailable, decrypt thrown, IO error) is a Jidoka event — crash visibly
// at startup per SecurityService.init() precedent (Story 1.3). Swallowing
// into a fifth variant hides storage corruption behind a green app shell.

sealed class SessionBootstrap {
  const SessionBootstrap();
}

/// First run: no credentials, no facility cache. Onboarding flow drives.
final class BootFreshFirstRun extends SessionBootstrap {
  const BootFreshFirstRun();
}

/// Credentials + cookies both viable. Route directly to /home.
/// AuthState handover: Authenticated(facilitiesLoaded: false) when Epic 2 lands.
final class BootSessionLive extends SessionBootstrap {
  const BootSessionLive();
}

/// Credentials viable, cookies missing or undecryptable. Route to /home;
/// Epic 2's CredentialBanner (Story 2.7) recovers via stored credentials.
/// AuthState handover: Reauth.
final class BootCookiesMissing extends SessionBootstrap {
  const BootCookiesMissing();
}

/// Credentials missing AND a facility profile already exists in Drift.
/// Route via the credentials-missing recovery flow (FR14.5 / Epic 2 Story 2.8).
/// AuthState handover: AuthFailure(credentialsInvalid).
final class BootCredentialsMissing extends SessionBootstrap {
  const BootCredentialsMissing();
}
