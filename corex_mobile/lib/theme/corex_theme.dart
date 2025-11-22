import 'package:flutter/material.dart';

class CorexTheme {
  // Couleurs COREX
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkBlack = Color(0xFF212121);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: primaryGreen,
          secondary: darkBlack,
          surface: white,
        ),
        scaffoldBackgroundColor: lightGrey,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
        ),
      );
}
