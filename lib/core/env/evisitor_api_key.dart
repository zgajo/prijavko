// WHY a separate file from evisitor_env.dart: `EvisitorEnv` controls transport
// switching (prod/test/fake); the apikey is a credential-shaped secret that is
// orthogonal to environment selection. A dev can run
// `--dart-define=EVISITOR_ENV=test` against a `prod` apikey, and vice-versa
// during a spike.
//
// Week-1 spike outcome dependency: the apikey scope (vendor-wide vs per-account)
// is gated on the HTZ registration flow (PRD §FR5). Until confirmed, the const
// is injected at build time and saved alongside credentials in CredentialStore
// for consistency with the existing 3-field contract.
//
// Build-time injection:
//   flutter build appbundle --dart-define=EVISITOR_API_KEY=<key>
//
// WHY `defaultValue: ''` (not throw): the `EVISITOR_ENV=fake` path bypasses the
// apikey entirely (the fake adapter ignores the field). A throwing default would
// break every integration test. Production hardness comes from the
// EvisitorApiClient — see AC2.4.
//
// Forced-update trigger: if the apikey is ever rotated, bump the min-version
// JSON (Story 9.4) so hosts on the old build are prompted to update. Mirrors
// `cert_pins.dart` §Forced-update trigger date convention.

const String evisitorApiKey = String.fromEnvironment(
  'EVISITOR_API_KEY',
  defaultValue: '',
);
