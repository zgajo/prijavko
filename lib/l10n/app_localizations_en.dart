// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeHeadline => 'Welcome to Prijavko';

  @override
  String get welcomeBody =>
      'Prijavko scans passports and sends guest data to eVisitor. Your data never leaves your phone except to eVisitor. After submission, it is kept 3 days as a safety buffer, then deleted.';

  @override
  String get welcomePrivacyPolicyLink => 'Privacy Policy';

  @override
  String get welcomeTermsOfServiceLink => 'Terms of Service';

  @override
  String get welcomeLinkConnector => ' & ';

  @override
  String get welcomeContinueButton => 'Continue';

  @override
  String get cameraPermissionHeadline => 'Camera Access';

  @override
  String get cameraPermissionBody =>
      'The camera is needed to scan passport MRZ codes. Photos are never stored or sent — processing is entirely on-device.';

  @override
  String get cameraPermissionAllowButton => 'Allow access';

  @override
  String get cameraPermissionSkipButton => 'Skip — manual entry';

  @override
  String get cameraPermissionPermanentlyDeniedMessage =>
      'Camera access permanently denied. Open device Settings to allow it.';

  @override
  String get cameraPermissionOpenSettingsButton => 'Settings';
}
