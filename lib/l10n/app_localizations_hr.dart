// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get welcomeHeadline => 'Dobrodošli u Prijavko';

  @override
  String get welcomeBody =>
      'Prijavko skenira putovnice i šalje podatke gostiju u eVisitor. Vaši podaci nikada ne napuštaju telefon osim prema eVisitoru. Nakon slanja, čuvaju se 3 dana kao sigurnosna kopija, a zatim se brišu.';

  @override
  String get welcomePrivacyPolicyLink => 'Pravila privatnosti';

  @override
  String get welcomeTermsOfServiceLink => 'Uvjeti korištenja';

  @override
  String get welcomeLinkConnector => ' i ';

  @override
  String get welcomeContinueButton => 'Nastavi';

  @override
  String get cameraPermissionHeadline => 'Pristup kameri';

  @override
  String get cameraPermissionBody =>
      'Kamera je potrebna za skeniranje MRZ koda s putovnica. Slike se ne pohranjuju ni ne šalju — obrada je potpuno na uređaju.';

  @override
  String get cameraPermissionAllowButton => 'Dopusti pristup';

  @override
  String get cameraPermissionSkipButton => 'Preskoči — ručni unos';
}
