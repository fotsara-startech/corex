import 'package:flutter/material.dart';

class CorexTheme {
  // Couleurs COREX principales
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkBlack = Color(0xFF212121);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);

  // Couleurs foncées pour le dashboard
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color darkRed = Color(0xFFB71C1C);
  static const Color darkOrange = Color(0xFFE65100);
  static const Color darkPurple = Color(0xFF4A148C);
  static const Color darkTeal = Color(0xFF004D40);
  static const Color darkIndigo = Color(0xFF1A237E);
  static const Color darkBrown = Color(0xFF3E2723);

  // Couleurs de fond foncées pour les cartes
  static const Color cardDarkGreen = Color(0xFF2E7D32);
  static const Color cardDarkBlue = Color(0xFF1565C0);
  static const Color cardDarkRed = Color(0xFFD32F2F);
  static const Color cardDarkOrange = Color(0xFFFF6F00);
  static const Color cardDarkPurple = Color(0xFF7B1FA2);
  static const Color cardDarkTeal = Color(0xFF00695C);
  static const Color cardDarkIndigo = Color(0xFF303F9F);
  static const Color cardDarkBrown = Color(0xFF5D4037);

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
