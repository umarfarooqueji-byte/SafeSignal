import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('hi'),
  ];

  /// App name
  ///
  /// In en, this message translates to:
  /// **'SafeSignal'**
  String get appName;

  /// Button to analyze message
  ///
  /// In en, this message translates to:
  /// **'Check This Message'**
  String get analyzeBtn;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get analyzing;

  /// No description provided for @deepAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Deep check in progress...'**
  String get deepAnalyzing;

  /// No description provided for @verdictScam.
  ///
  /// In en, this message translates to:
  /// **'SCAM'**
  String get verdictScam;

  /// No description provided for @verdictSafe.
  ///
  /// In en, this message translates to:
  /// **'SAFE'**
  String get verdictSafe;

  /// No description provided for @verdictCaution.
  ///
  /// In en, this message translates to:
  /// **'BE CAREFUL'**
  String get verdictCaution;

  /// No description provided for @whyTitle.
  ///
  /// In en, this message translates to:
  /// **'WHY?'**
  String get whyTitle;

  /// No description provided for @whatToDoTitle.
  ///
  /// In en, this message translates to:
  /// **'WHAT TO DO?'**
  String get whatToDoTitle;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'SafeSignal is an assistant, not an authority. Report real fraud to 1930.'**
  String get disclaimer;

  /// No description provided for @feedTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Alerts'**
  String get feedTitle;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'My Checks'**
  String get historyTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @textSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSizeLabel;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Stay Safe from Scams'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Forward any suspicious message and we will check it for you.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Instant Verdict'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Get a clear SCAM / SAFE / BE CAREFUL result in seconds.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Always Free'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'SafeSignal is completely free. No hidden charges.'**
  String get onboardingDesc3;

  /// No description provided for @disclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Important Disclaimer'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'SafeSignal helps you identify suspicious messages. For real fraud, always report on 1930 (National Cybercrime Helpline).'**
  String get disclaimerBody;

  /// No description provided for @disclaimerAgree.
  ///
  /// In en, this message translates to:
  /// **'I understand and agree'**
  String get disclaimerAgree;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @inputHint.
  ///
  /// In en, this message translates to:
  /// **'Paste suspicious message here...'**
  String get inputHint;

  /// No description provided for @shareVerdict.
  ///
  /// In en, this message translates to:
  /// **'Share with Family'**
  String get shareVerdict;

  /// No description provided for @feedbackCorrect.
  ///
  /// In en, this message translates to:
  /// **'This was correct ✓'**
  String get feedbackCorrect;

  /// No description provided for @feedbackWrong.
  ///
  /// In en, this message translates to:
  /// **'This seems wrong ✗'**
  String get feedbackWrong;

  /// No description provided for @deepAnalysisBadge.
  ///
  /// In en, this message translates to:
  /// **'Deep Analysis Used'**
  String get deepAnalysisBadge;

  /// No description provided for @trendNote.
  ///
  /// In en, this message translates to:
  /// **'Trend Alert'**
  String get trendNote;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No checks yet. Send a message to get started.'**
  String get noHistory;

  /// No description provided for @noFeed.
  ///
  /// In en, this message translates to:
  /// **'No alerts today. Check back tomorrow.'**
  String get noFeed;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
