import 'package:flutter/material.dart';

class AppTheme {
  // Verdict Colors
  static const Color scamRed = Color(0xFFD32F2F);
  static const Color scamRedLight = Color(0xFFFFEBEE);
  static const Color cautionYellow = Color(0xFFF9A825);
  static const Color cautionYellowLight = Color(0xFFFFFDE7);
  static const Color safeGreen = Color(0xFF388E3C);
  static const Color safeGreenLight = Color(0xFFE8F5E9);

  // Brand Colors
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color surfaceColor = Color(0xFFF8FAFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF21262D);

  // Text Sizes (scale-able)
  static const double textSizeNormal = 1.0;
  static const double textSizeBada = 1.2;
  static const double textSizeSabseBada = 1.5;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: surfaceColor,
    ),
    fontFamily: 'Roboto',
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: darkBackground,
    ),
    scaffoldBackgroundColor: darkBackground,
    fontFamily: 'Roboto',
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
  );

  // Helper: get verdict color
  static Color verdictColor(String verdict) {
    switch (verdict.toUpperCase()) {
      case 'SCAM':
        return scamRed;
      case 'LIKELY_SAFE':
        return safeGreen;
      default:
        return cautionYellow;
    }
  }

  static Color verdictBgColor(String verdict) {
    switch (verdict.toUpperCase()) {
      case 'SCAM':
        return scamRedLight;
      case 'LIKELY_SAFE':
        return safeGreenLight;
      default:
        return cautionYellowLight;
    }
  }

  static String verdictEmoji(String verdict) {
    switch (verdict.toUpperCase()) {
      case 'SCAM':
        return '🔴';
      case 'LIKELY_SAFE':
        return '🟢';
      default:
        return '🟡';
    }
  }
}
