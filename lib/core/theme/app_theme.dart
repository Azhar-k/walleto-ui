import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF263238);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color debitColor = Colors.red;
  static const Color creditColor = Colors.green;
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // Summary Screen Colors
  static const Color summaryBackgroundColor = Color(
    0xFFEEEEEE,
  ); // Colors.grey[200]
  static const Color summaryTextColor = Colors.black87;
  static const Color summaryLabelColor = Colors.black54;

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
