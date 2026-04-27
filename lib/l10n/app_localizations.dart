import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hr'),
  ];

  /// Welcome screen headline
  ///
  /// In en, this message translates to:
  /// **'Welcome to Prijavko'**
  String get welcomeHeadline;

  /// Welcome screen body explaining data handling
  ///
  /// In en, this message translates to:
  /// **'Prijavko scans passports and sends guest data to eVisitor. Your data never leaves your phone except to eVisitor. After submission, it is kept 3 days as a safety buffer, then deleted.'**
  String get welcomeBody;

  /// Tappable text linking to prijavko.hr/privacy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get welcomePrivacyPolicyLink;

  /// Tappable text linking to prijavko.hr/terms
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get welcomeTermsOfServiceLink;

  /// Connector between Privacy Policy and Terms of Service links
  ///
  /// In en, this message translates to:
  /// **' & '**
  String get welcomeLinkConnector;

  /// Primary CTA on welcome screen, navigates to camera permission
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get welcomeContinueButton;

  /// Camera permission screen headline
  ///
  /// In en, this message translates to:
  /// **'Camera Access'**
  String get cameraPermissionHeadline;

  /// Camera permission rationale explaining why camera is needed and privacy assurance
  ///
  /// In en, this message translates to:
  /// **'The camera is needed to scan passport MRZ codes. Photos are never stored or sent — processing is entirely on-device.'**
  String get cameraPermissionBody;

  /// Primary CTA requesting camera permission from the OS
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get cameraPermissionAllowButton;

  /// Secondary CTA skipping camera permission and using manual entry path
  ///
  /// In en, this message translates to:
  /// **'Skip — manual entry'**
  String get cameraPermissionSkipButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hr':
      return AppLocalizationsHr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
