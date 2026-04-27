import 'package:prijavko/core/capture/capture_preference.dart';
import 'package:prijavko/core/capture/capture_preference_store.dart';

// In-memory CapturePreferenceStore for widget and unit tests.
// Allows asserting exactly which preference was saved after a user action.
class FakeCapturePreferenceStore extends CapturePreferenceStore {
  CapturePreference? savedPreference;

  @override
  Future<void> save(CapturePreference preference) async {
    savedPreference = preference;
  }

  @override
  Future<CapturePreference> load() async =>
      savedPreference ?? CapturePreference.manualOnly;
}
