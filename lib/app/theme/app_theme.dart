import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      );
}
