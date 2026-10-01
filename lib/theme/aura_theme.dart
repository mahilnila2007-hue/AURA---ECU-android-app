import 'package:flutter/material.dart';

/// Design tokens derived precisely from the requested Porsche Brake / Automotive palette:
/// - 202D36: Deep Charcoal / Graphite (Backgrounds, dark surfaces)
/// - 5C7896: Steel Slate Blue (Secondary accents, borders, muted indicators)
/// - 7598B9: Metallic Ice Blue (Primary active indicators, highlights, graphs)
/// - 3C0007: Deep Crimson / Dark Burgundy (Fault backgrounds, deep warning accents)
/// - 800C1F: Porsche Brake Caliper Red (Critical faults, emergency warnings, badges)
/// - 929CAA: Brushed Titanium Silver / Grey (Subdued text, inactive icons, gridlines)
class AuraColors {
  // Primary Palette from Image
  static const Color darkGraphite = Color(0xFF202D36);
  static const Color slateBlue = Color(0xFF5C7896);
  static const Color metallicIceBlue = Color(0xFF7598B9);
  static const Color deepCrimson = Color(0xFF3C0007);
  static const Color caliperRed = Color(0xFF800C1F);
  static const Color titaniumGrey = Color(0xFF929CAA);

  // Surface and Background layers
  static const Color bgDark = Color(0xFF0F161C); // Ultra dark chassis base
  static const Color bgSurface = Color(0xFF162027); // Dark card surface
  static const Color bgCard = Color(0xFF1B2630); // Elevated module container
  static const Color bgCardHover = Color(0xFF23323F);
  static const Color bgGlass = Color(0x33202D36); // Glassmorphism container
  
  // High-Tech Accents & Semantic Colors
  static const Color primaryCyan = Color(0xFF7598B9); // Active accent from palette
  static const Color electricCyan = Color(0xFF64D2FF); // Micro-accent highlight
  static const Color healthyGreen = Color(0xFF30D158); // Automotive ISO Green
  static const Color warningAmber = Color(0xFFFF9F0A); // ISO Automotive Amber
  static const Color criticalRed = Color(0xFF800C1F); // Caliper Red
  static const Color offlineGrey = Color(0xFF929CAA); // Titanium Grey

  // Text & Typography
  static const Color textPrimary = Color(0xFFF2F5F8);
  static const Color textSecondary = Color(0xFFB0BDC9);
  static const Color textMuted = Color(0xFF929CAA);
  static const Color textDark = Color(0xFF10151A);

  // Borders & Dividers
  static const Color borderSubtle = Color(0x335C7896);
  static const Color borderGlow = Color(0x667598B9);
  static const Color borderCritical = Color(0x66800C1F);
}

class AuraTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AuraColors.bgDark,
      primaryColor: AuraColors.metallicIceBlue,
      canvasColor: AuraColors.bgSurface,
      cardColor: AuraColors.bgCard,
      colorScheme: const ColorScheme.dark(
        primary: AuraColors.metallicIceBlue,
        secondary: AuraColors.slateBlue,
        surface: AuraColors.bgSurface,
        error: AuraColors.caliperRed,
        onPrimary: AuraColors.textDark,
        onSecondary: Colors.white,
        onSurface: AuraColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AuraColors.bgDark,
        foregroundColor: AuraColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AuraColors.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AuraColors.bgSurface,
        selectedItemColor: AuraColors.metallicIceBlue,
        unselectedItemColor: AuraColors.titaniumGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: AuraColors.bgCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AuraColors.borderSubtle, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AuraColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AuraColors.textPrimary),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AuraColors.textPrimary),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AuraColors.textPrimary),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AuraColors.textSecondary),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AuraColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AuraColors.textSecondary),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AuraColors.textMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: AuraColors.borderSubtle,
        thickness: 1,
        space: 16,
      ),
    );
  }
}
