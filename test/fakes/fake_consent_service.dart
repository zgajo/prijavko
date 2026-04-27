import 'package:prijavko/core/consent/consent_error.dart';
import 'package:prijavko/core/consent/consent_service.dart';
import 'package:prijavko/core/consent/consent_state.dart';
import 'package:prijavko/core/result/result.dart';

// WHY: UMP's ConsentInformation and ConsentForm are static-instance singletons
// backed by platform channels. They cannot be mocked without the test binding's
// platform-channel infrastructure, which couples unit tests to an emulator.
// An interface seam is cleaner: production code calls UMP, the fake skips it.
class FakeConsentService implements ConsentService {
  FakeConsentService({
    required ConsentState scriptedState,
    bool privacyOptionsRequired = false,
  })  : _scriptedState = scriptedState,
        _privacyOptionsRequired = privacyOptionsRequired;

  final ConsentState _scriptedState;
  final bool _privacyOptionsRequired;

  @override
  Future<ConsentState> gatherConsent() async => _scriptedState;

  @override
  Future<Result<void, ConsentError>> showPrivacyOptionsForm() async =>
      const Ok(null);

  @override
  Future<bool> isPrivacyOptionsRequired() async => _privacyOptionsRequired;

  @override
  Future<void> reset() async {}
}
