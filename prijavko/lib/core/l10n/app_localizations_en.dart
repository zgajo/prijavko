// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Prijavko';

  @override
  String get tabHome => 'Home';

  @override
  String get tabQueue => 'Queue';

  @override
  String get tabHistory => 'History';

  @override
  String get tabSettings => 'Settings';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionSend => 'Send';

  @override
  String get actionDelete => 'Delete';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get onboardingHeadline => 'Set up your accommodation';

  @override
  String get offlineNoConnection => 'No network connection';

  @override
  String get routeCapture => 'Capture';

  @override
  String get routeReview => 'Review';

  @override
  String get routeConfirm => 'Confirm';
}
