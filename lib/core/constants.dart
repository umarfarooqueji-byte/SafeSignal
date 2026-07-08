class AppConstants {
  // API
  static const String apiBaseUrl = 'http://10.0.2.2:8000'; // Android emulator → localhost
  static const String apiBaseUrlRelease = 'https://your-backend.onrender.com';
  static const String meshApiKey = 'rsk_01KWZPS01XCAEBYCY1DRW95DJ3';
  static const String newsDataApiKey = 'pub_e05c3973afe94ea896b036203e7fa757';

  // Supabase (fill in after Supabase project setup)
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // AI Confidence Thresholds
  static const double confidenceGate = 0.80; // below this → escalate to Tier-2
  static const double highConfidence = 0.90;

  // Verdicts
  static const String verdictScam = 'SCAM';
  static const String verdictSafe = 'LIKELY_SAFE';
  static const String verdictUncertain = 'UNCERTAIN';

  // Hive Box Names
  static const String hiveHistoryBox = 'check_history';
  static const String hiveAlertsBox = 'daily_alerts';
  static const String hiveSettingsBox = 'settings';

  // SharedPreferences Keys
  static const String prefLanguage = 'language_pref';
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefTextScale = 'text_scale';
  static const String prefNotifications = 'notifications_enabled';

  // Cybercrime Helpline
  static const String cyberHelpline = '1930';

  // Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int deepAnalysisTimeoutSeconds = 60;

  // Feed
  static const int feedPageSize = 20;
  static const int historyPageSize = 50;
}
