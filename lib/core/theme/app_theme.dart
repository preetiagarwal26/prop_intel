import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.gold,
        onPrimary: AppColors.ink,
        primaryContainer: AppColors.goldLight,
        onPrimaryContainer: AppColors.ink,
        secondary: AppColors.ink2,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: AppColors.text1,
        onSurfaceVariant: AppColors.text2,
        outline: AppColors.text3,
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: AppColors.dangerBg,
        onErrorContainer: AppColors.dangerText,
        tertiary: AppColors.warn,
        tertiaryContainer: AppColors.warnBg,
        onTertiaryContainer: AppColors.warnText,
      ),
    );

    final sans = GoogleFonts.dmSansTextTheme(base.textTheme);
    final serif = GoogleFonts.dmSerifDisplayTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: sans.copyWith(
        headlineLarge: serif.headlineLarge?.copyWith(
          color: AppColors.text1,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: serif.headlineMedium?.copyWith(
          color: AppColors.text1,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: serif.headlineSmall?.copyWith(
          color: AppColors.text1,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: serif.titleLarge?.copyWith(
          color: AppColors.text1,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        titleMedium: sans.titleMedium?.copyWith(
          color: AppColors.text1,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        titleSmall: sans.titleSmall?.copyWith(
          color: AppColors.text1,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        bodyLarge: sans.bodyLarge?.copyWith(color: AppColors.text1, fontSize: 14),
        bodyMedium: sans.bodyMedium?.copyWith(color: AppColors.text1, fontSize: 14),
        bodySmall: sans.bodySmall?.copyWith(color: AppColors.text2, fontSize: 12),
        labelSmall: sans.labelSmall?.copyWith(
          color: AppColors.text3,
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text1,
        titleTextStyle: serif.titleLarge?.copyWith(
          color: AppColors.text1,
          fontSize: 26,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text2,
          side: const BorderSide(color: AppColors.text3, width: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldDark,
          textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        labelStyle: GoogleFonts.dmSans(color: AppColors.text3, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.ink,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.notificationDot,
        textColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),
    );
  }
}
