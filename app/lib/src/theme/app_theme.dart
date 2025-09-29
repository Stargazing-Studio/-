import 'package:flutter/material.dart';

class DaoYanTheme {
  const DaoYanTheme._();

  static ThemeData buildTheme() {
    const primaryColor = Color(0xFF5C6BC0);
    const secondaryColor = Color(0xFF26A69A);
    const backgroundColor = Color(0xFF0E0F1A);

    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: const Color(0xFF161828),
        surfaceContainerHighest: const Color(0xFF1B1E30),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFFE0E5FF),
        surfaceTint: primaryColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'NotoSansSC',
        bodyColor: const Color(0xFFE0E5FF),
        displayColor: const Color(0xFFE0E5FF),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0x331C1F33),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0x661C2140),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
