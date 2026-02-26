import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kahoot-inspired Theme for the Kaheet Quiz App
class AppTheme {
  // ─── Kahoot Color Palette ─────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF46178F); // Deep purple
  static const Color accentColor = Color(0xFF7C3ED4); // Lighter purple
  static const Color hotPink = Color(0xFFFF3355); // Hot pink / accent
  static const Color secondaryColor = Color(0xFF26890C); // Emerald green
  static const Color tertiaryColor = Color(0xFFD89E00); // Amber
  static const Color errorColor = Color(0xFFE21B3C); // Error red

  // Answer button colors (same as Kahoot)
  static const Color answerRed = Color(0xFFE21B3C);
  static const Color answerBlue = Color(0xFF1368CE);
  static const Color answerYellow = Color(0xFFD89E00);
  static const Color answerGreen = Color(0xFF26890C);

  // Surface
  static const Color surfaceDark = Color(0xFF1A0533); // Very dark purple
  static const Color cardDark = Color(0xFF2A0E4A);
  static const Color surfaceLight = Color(0xFFF5F0FF);

  // Text
  static const Color textPrimary = Color(0xFF1E0A3C);
  static const Color textSecondary = Color(0xFF7B6B9C);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFBBAADD);

  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 32.0;

  // ─── Light Theme ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        surface: surfaceLight,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: surfaceLight,
      textTheme: _buildTextTheme(textPrimary),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: paddingL,
            vertical: paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: paddingL,
            vertical: paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
          side: const BorderSide(color: primaryColor, width: 2),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingM,
          vertical: paddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: Color(0xFFE2D6F5), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: Color(0xFFE2D6F5), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        shadowColor: primaryColor.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        color: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withValues(alpha: 0.1),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        selectedColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: hotPink,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: hotPink,
        linearTrackColor: Color(0xFFE2D6F5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        surface: surfaceDark,
        onSurface: textLight,
      ),
      scaffoldBackgroundColor: surfaceDark,
      textTheme: _buildTextTheme(textLight),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        color: cardDark,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  // ─── Gradient Helpers ─────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF46178F), Color(0xFF2A0E4A)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF46178F), Color(0xFF7C3ED4)],
  );

  static BoxDecoration get purpleBackground =>
      const BoxDecoration(gradient: primaryGradient);
}
