// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appTitle => 'Prijavko';

  @override
  String get tabHome => 'Početna';

  @override
  String get tabQueue => 'Red';

  @override
  String get tabHistory => 'Povijest';

  @override
  String get tabSettings => 'Postavke';

  @override
  String get actionConfirm => 'Potvrdi';

  @override
  String get actionCancel => 'Odustani';

  @override
  String get actionRetry => 'Pokušaj ponovno';

  @override
  String get actionSend => 'Pošalji';

  @override
  String get actionDelete => 'Obriši';

  @override
  String get errorGeneric => 'Dogodila se greška. Pokušajte ponovno.';
}
