import 'package:flutter/material.dart';

/// Tema visual Tripmo — disamakan dengan web app (tema gelap, aksen ungu).
/// Sumber warna: resources/views/layouts/app.blade.php pada proyek Laravel.
class AppColors {
  AppColors._();

  static const bg = Color(0xFF181818);
  static const bg2 = Color(0xFF222222);
  static const bg3 = Color(0xFF2A2A2A);

  static const border = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const border2 = Color(0x21FFFFFF); // rgba(255,255,255,0.13)

  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFFF0F0F0);
  static const text2 = Color(0xFF9A9A9A);
  static const text3 = Color(0xFF5A5A5A);

  static const purple = Color(0xFF7C5CFC);
  static const purpleHover = Color(0xFF6A4DE8);
  static const purpleBg = Color(0x267C5CFC); // rgba(124,92,252,0.15)

  static const red = Color(0xFFE84040);
  static const green = Color(0xFF22C55E);
  static const star = Color(0xFFFBBF24);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const fontFamily = 'PlusJakartaSans'; // fallback ke default jika font belum dipasang

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.purple,
        secondary: AppColors.purple,
        surface: AppColors.bg2,
        error: AppColors.red,
        onPrimary: Colors.white,
        onSurface: AppColors.text,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardColor: AppColors.bg2,
      dividerColor: AppColors.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg3,
        hintStyle: const TextStyle(color: AppColors.text3),
        labelStyle: const TextStyle(color: AppColors.text2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.purple),
        errorBorder: _inputBorder(AppColors.red),
        focusedErrorBorder: _inputBorder(AppColors.red),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.bg3,
          disabledForegroundColor: AppColors.text3,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.purple),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.bg3,
        contentTextStyle: TextStyle(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg,
        selectedItemColor: AppColors.purple,
        unselectedItemColor: AppColors.text3,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );
}
