import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const forest = Color(0xff244b41);
  static const cream = Color(0xfff7f6f0);
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: forest,
      primary: forest,
      surface: cream,
    ),
    scaffoldBackgroundColor: cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      foregroundColor: forest,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xffe4e7de)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
    ),
  );
}
