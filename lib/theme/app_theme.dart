import 'package:flutter/material.dart';

/// Zanaatkar (Craft) Tasarım Sistemi ve Renk Mimarisi
/// Yapay zeka klişelerinden uzak, Linear ve Apple seviyesinde editoryal zarafet.
class AppColors {
  // --- Koyu Mod (Obsidian & Titanium) ---
  static const Color darkBg = Color(0xFF08090C);
  static const Color darkSurface = Color(0xFF12141A);
  static const Color darkSurfaceElevated = Color(0xFF181B23);
  static const Color darkBorder = Color(0xFF222631);
  static const Color darkBorderSubtle = Color(0x1AFFFFFF); // 10% beyaz saç teli

  static const Color darkTextPrimary = Color(0xFFF3F4F8);
  static const Color darkTextSecondary = Color(0xFF8E95A5);
  static const Color darkTextMuted = Color(0xFF565D6F);

  // --- Açık Mod (Swiss Minimal / Paper & Bone) ---
  static const Color lightBg = Color(0xFFF6F7F9);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceElevated = Color(0xFFECEEF2);
  static const Color lightBorder = Color(0xFFE0E3EB);
  static const Color lightBorderSubtle = Color(0x0F000000); // 6% siyah saç teli

  static const Color lightTextPrimary = Color(0xFF0C0E12);
  static const Color lightTextSecondary = Color(0xFF5E6575);
  static const Color lightTextMuted = Color(0xFF9BA2B2);

  // --- İmza Zanaat Vurguları (Luxury Fintech & Craft) ---
  // Saf Zümrüt (Fintech Güveni & Pozitif Bakiye)
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color emeraldMuted = Color(0x2610B981);

  // Titanyum Kehribar (Sabit Harcama / Dikkat)
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color amberMuted = Color(0x26F59E0B);

  // Cerrahi Buz Mavisi (Kredi Kartı / Modern Dokunuş)
  static const Color iceBlue = Color(0xFF0EA5E9);
  static const Color iceBlueDark = Color(0xFF0284C7);
  static const Color iceBlueMuted = Color(0x260EA5E9);

  // Güvenli Kırmızı (Silme / Aşım)
  static const Color crimson = Color(0xFFF43F5E);
  static const Color crimsonMuted = Color(0x26F43F5E);

  // Ana Uygulama Vurgusu (İmza Rengi)
  static const Color primary = Color(0xFF0EA5E9);
  static const Color primaryDark = Color(0xFF0284C7);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.lightSurface,
      ),
      dividerColor: AppColors.lightBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 0.8),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.darkSurface,
      ),
      dividerColor: AppColors.darkBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.8),
        ),
      ),
    );
  }
}
