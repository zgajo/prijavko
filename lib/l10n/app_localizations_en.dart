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

  @override
  String get loginHeadline => 'eVisitor Sign-In';

  @override
  String get loginBody =>
      'Sign in once with your eVisitor credentials. Subsequent sessions will sign in automatically.';

  @override
  String get loginUsernameLabel => 'Username';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordToggleShow => 'Show password';

  @override
  String get loginPasswordToggleHide => 'Hide password';

  @override
  String get loginReassurance =>
      '🔒 Credentials are stored encrypted in Android Keystore.';

  @override
  String get loginSubmitButton => 'Sign in';

  @override
  String get loginCredentialsHint => 'Check your username and password.';

  @override
  String get loginNetworkError => 'No internet. Try again.';

  @override
  String get loginServerError => 'eVisitor is unavailable. Try again later.';

  @override
  String get loginContractBreakError =>
      'Update prijavko from Play Store and try again.';

  @override
  String get loginLockoutMessage =>
      'Too many failed attempts — wait 6 minutes.';

  @override
  String loginLockoutCountdownSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String secondsString = secondsNumberFormat.format(seconds);

    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$secondsString seconds remaining',
      one: '1 second remaining',
    );
    return '$_temp0';
  }
}
