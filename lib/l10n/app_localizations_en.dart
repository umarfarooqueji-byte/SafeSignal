// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SafeSignal';

  @override
  String get analyzeBtn => 'Check This Message';

  @override
  String get analyzing => 'Checking...';

  @override
  String get deepAnalyzing => 'Deep check in progress...';

  @override
  String get verdictScam => 'SCAM';

  @override
  String get verdictSafe => 'SAFE';

  @override
  String get verdictCaution => 'BE CAREFUL';

  @override
  String get whyTitle => 'WHY?';

  @override
  String get whatToDoTitle => 'WHAT TO DO?';

  @override
  String get disclaimer =>
      'SafeSignal is an assistant, not an authority. Report real fraud to 1930.';

  @override
  String get feedTitle => 'Daily Alerts';

  @override
  String get historyTitle => 'My Checks';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get textSizeLabel => 'Text Size';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get onboardingTitle1 => 'Stay Safe from Scams';

  @override
  String get onboardingDesc1 =>
      'Forward any suspicious message and we will check it for you.';

  @override
  String get onboardingTitle2 => 'Instant Verdict';

  @override
  String get onboardingDesc2 =>
      'Get a clear SCAM / SAFE / BE CAREFUL result in seconds.';

  @override
  String get onboardingTitle3 => 'Always Free';

  @override
  String get onboardingDesc3 =>
      'SafeSignal is completely free. No hidden charges.';

  @override
  String get disclaimerTitle => 'Important Disclaimer';

  @override
  String get disclaimerBody =>
      'SafeSignal helps you identify suspicious messages. For real fraud, always report on 1930 (National Cybercrime Helpline).';

  @override
  String get disclaimerAgree => 'I understand and agree';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get inputHint => 'Paste suspicious message here...';

  @override
  String get shareVerdict => 'Share with Family';

  @override
  String get feedbackCorrect => 'This was correct ✓';

  @override
  String get feedbackWrong => 'This seems wrong ✗';

  @override
  String get deepAnalysisBadge => 'Deep Analysis Used';

  @override
  String get trendNote => 'Trend Alert';

  @override
  String get noHistory => 'No checks yet. Send a message to get started.';

  @override
  String get noFeed => 'No alerts today. Check back tomorrow.';
}
