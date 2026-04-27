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

  @override
  String get cameraPermissionPermanentlyDeniedMessage =>
      'Pristup kameri trajno odbijen. Otvorite postavke uređaja za dopuštenje.';

  @override
  String get cameraPermissionOpenSettingsButton => 'Postavke';

  @override
  String get loginHeadline => 'Prijava u eVisitor';

  @override
  String get loginBody =>
      'Prijavite se jednom s eVisitor podacima. Sljedeće sesije se prijavljuju automatski.';

  @override
  String get loginUsernameLabel => 'Korisničko ime';

  @override
  String get loginPasswordLabel => 'Lozinka';

  @override
  String get loginPasswordToggleShow => 'Prikaži lozinku';

  @override
  String get loginPasswordToggleHide => 'Sakrij lozinku';

  @override
  String get loginReassurance =>
      '🔒 Podaci se čuvaju šifrirano u Android Keystore-u';

  @override
  String get loginSubmitButton => 'Prijavi se';

  @override
  String get loginCredentialsHint => 'Provjerite korisničko ime i lozinku.';

  @override
  String get loginNetworkError => 'Nema interneta. Pokušajte ponovno.';

  @override
  String get loginServerError => 'eVisitor je nedostupan. Pokušajte kasnije.';

  @override
  String get loginContractBreakError =>
      'Ažurirajte prijavko iz Play Store-a i pokušajte ponovno.';

  @override
  String get loginLockoutMessage =>
      'Previše neuspješnih pokušaja — pričekajte 6 minuta.';

  @override
  String loginLockoutCountdownSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String secondsString = secondsNumberFormat.format(seconds);

    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Još $secondsString sekundi',
      few: 'Još $secondsString sekunde',
      one: 'Još 1 sekunda',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Postavke';

  @override
  String get settingsButtonTooltip => 'Postavke';

  @override
  String get settingsReplaceCredentialsLabel => 'Zamijeni podatke za prijavu';

  @override
  String get settingsCredentialsUpdatedSnackbar => 'Podaci ažurirani.';

  @override
  String get replaceCredentialsBanner =>
      'Zamjena podataka — stari objekti i nedoslani gosti ostaju.';

  @override
  String get replaceCredentialsSubmitButton => 'Spremi nove podatke';
}
