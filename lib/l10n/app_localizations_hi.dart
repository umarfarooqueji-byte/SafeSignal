// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'SafeSignal';

  @override
  String get analyzeBtn => 'Yeh Message Check Karo';

  @override
  String get analyzing => 'Jaanch ho rahi hai...';

  @override
  String get deepAnalyzing => 'Gehri jaanch ho rahi hai...';

  @override
  String get verdictScam => 'SCAM HAI';

  @override
  String get verdictSafe => 'SAFE HAI';

  @override
  String get verdictCaution => 'SAVDHAN RAHO';

  @override
  String get whyTitle => 'KYUN?';

  @override
  String get whatToDoTitle => 'AB KYA KARO?';

  @override
  String get disclaimer =>
      'SafeSignal ek assistant hai, authority nahi. Asli fraud 1930 pe report karo.';

  @override
  String get feedTitle => 'Roz ke Alerts';

  @override
  String get historyTitle => 'Meri Jaanchein';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Bhasha';

  @override
  String get textSizeLabel => 'Akshar Ka Aakaar';

  @override
  String get notificationsLabel => 'Suchnayen';

  @override
  String get onboardingTitle1 => 'Scam Se Bachao';

  @override
  String get onboardingDesc1 =>
      'Koi bhi shak wala message bhejein aur hum check karenge.';

  @override
  String get onboardingTitle2 => 'Turant Nateeja';

  @override
  String get onboardingDesc2 =>
      'Kuch hi seconds mein SCAM / SAFE / SAVDHAN ka jawab milega.';

  @override
  String get onboardingTitle3 => 'Bilkul Muft';

  @override
  String get onboardingDesc3 =>
      'SafeSignal poori tarah muft hai. Koi chupi fees nahi.';

  @override
  String get disclaimerTitle => 'Zaroori Baat';

  @override
  String get disclaimerBody =>
      'SafeSignal shak wale messages pehchanne mein madad karta hai. Asli fraud ke liye 1930 (National Cybercrime Helpline) pe zaroor call karein.';

  @override
  String get disclaimerAgree => 'Mujhe samajh aa gaya, main sahamat hoon';

  @override
  String get getStarted => 'Shuru Karein';

  @override
  String get next => 'Aage';

  @override
  String get inputHint => 'Shak wala message yahan chipkayen...';

  @override
  String get shareVerdict => 'Parivaar ke saath share karein';

  @override
  String get feedbackCorrect => 'Yeh sahi tha ✓';

  @override
  String get feedbackWrong => 'Yeh galat lag raha ✗';

  @override
  String get deepAnalysisBadge => 'Gehri Jaanch Ki Gayi';

  @override
  String get trendNote => 'Trend Alert';

  @override
  String get noHistory =>
      'Abhi tak koi jaanch nahi. Message bhejkar shuru karein.';

  @override
  String get noFeed => 'Aaj koi alert nahi. Kal dobara dekhein.';
}
