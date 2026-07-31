import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1D2A44);   // Biru Prabowo navy
  static const Color accentColor  = Color(0xFFA2CFFE);   // Biru langit
  static const Color errorColor   = Color(0xFFFF0000);   // Merah accent

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F9FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );
}
