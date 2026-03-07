import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Couleurs iOS-inspired
  static const Color primaryPurple = Color(0xFF8B7DFF);
  static const Color secondaryBlue = Color(0xFF007AFF);
  static const Color successGreen = Color(0xFF34C759);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color errorRed = Color(0xFFFF3B30);
  
  // Backgrounds iOS
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightCard = Colors.white;
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color darkElevated = Color(0xFF2C2C2E);
  
  // Shadows iOS-like
  static List<BoxShadow> softShadow(bool isDark) => [
    BoxShadow(
      color: isDark 
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> cardShadow(bool isDark) => [
    BoxShadow(
      color: isDark 
        ? Colors.black.withOpacity(0.4)
        : Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryPurple,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: primaryPurple,
      secondary: secondaryBlue,
      surface: lightCard,
      background: lightBackground,
      error: errorRed,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: const IconThemeData(color: Colors.black87),
      titleTextStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.4,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: lightCard,
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        letterSpacing: 0.4,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        letterSpacing: 0.36,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        letterSpacing: 0.35,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        letterSpacing: 0.38,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        letterSpacing: 0.15,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        letterSpacing: -0.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Colors.black54,
        letterSpacing: -0.2,
      ),
      labelLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.4,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryPurple,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: secondaryBlue,
      surface: darkCard,
      background: darkBackground,
      error: errorRed,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.4,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: darkCard,
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.4,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.36,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.35,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.38,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.15,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        letterSpacing: -0.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
        letterSpacing: -0.2,
      ),
      labelLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.4,
      ),
    ),
  );
}
