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
}
