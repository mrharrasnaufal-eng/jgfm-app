import 'package:flutter/material.dart';

class AppTheme {
  // === COLORS ===
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color card = Color(0xFF242424);
  static const Color divider = Color(0xFF333333);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textTertiary = Color(0xFF888888);
  static const Color accent = Color(0xFFFF2D55);
  static const Color secondary = Color(0xFF6C63FF);
  static const Color gold = Color(0xFFFFD700);
  static const Color success = Color(0xFF4CAF50);
  static const Color trending = Color(0xFFFF6B35);
  static const Color error = Color(0xFFFF4444);

  // === THEME DATA ===
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        primaryColor: accent,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: secondary,
          surface: surface,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: accent,
          unselectedItemColor: textTertiary,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 10),
        ),
        cardTheme: CardTheme(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: textPrimary,
          unselectedLabelColor: textTertiary,
          indicatorColor: accent,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 0.5,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: card,
          contentTextStyle: const TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
