import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D6E6E),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F4EF),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w600),
    ),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5BBDBB),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0E1214),
  );
}
