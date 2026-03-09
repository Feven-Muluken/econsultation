import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryDark = Color(0xFF07276B);
  static const Color primary = Color(0xFF0C326F);
  static const Color primaryMid = Color(0xFF0D41A2);
  static const Color primaryLight = Color(0xFF0F47AF);
  
  // Background & Surface
  static const Color background = Color(0xFFFAFCFF);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFE5E7EB);
  static const Color surfaceVariantLight =  Color(0xFFF5F5F5);
  
  // Text Colors
  static const Color primaryText = Color(0xFF111417);
  static const Color secondaryText = Color(0xFF647287);
  static const Color lightText = Color(0xFF475569);
  static const Color feedbackText = Color(0xFF4C739A);
  static const Color langTextSelected = Color(0xFF003366);
  static const Color langText = Color(0xFF4B5563);

  // Border & Input
  static const Color stroke = Color(0xFF749DED);
  static const Color inputFocused = Color(0xFFBED4FF);
  static const Color inputField = Color(0xFFEDF3FF);
  static const Color borderColor = Color(0xFFDCE0E5);
  static const Color borderSide = Color(0xFFF4F4F4);
  
  // Status Colors
  static const Color statusGreen = Color(0xFF15803D);
  static const Color statusGreenBg = Color(0xFFDCFCE7);
  static const Color statusGray = Color(0xFF647287);
  static const Color statusGrayBg = Color(0xFFF0F0F0);
  static const Color statusRed = Color(0xFFB91C1C);
  static const Color statusRedBg = Color(0xFFFEE2E2);
  
  // Gradient
  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      primaryDark, 
      primaryMid,
      // primaryLight
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static ThemeData get lightTheme {

    return ThemeData(

      // Typography system (Inter font family)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.75,
          height: 40 / 32,
          color: AppTheme.primaryText,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.75,
          height: 36 / 28,
          color: AppTheme.primaryText,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 32 / 24,
          color: AppTheme.surface,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.85,
          height: 28 / 22,
          color: AppTheme.surface,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 28 / 18,
          color: AppTheme.primaryText,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 28 / 18,
          color: AppTheme.primaryText,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 26 / 16,
          color: AppTheme.primaryText,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 24 / 16,
          color: AppTheme.secondaryText,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 24 / 14,
          color: AppTheme.primaryText,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 24 / 14,
          color: AppTheme.primaryText,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 21 / 14,
          color: AppTheme.secondaryText,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 18 / 12,
          color: AppTheme.secondaryText,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 18 / 12,
          color: AppTheme.lightText,
        ),
      ),

      // Input styles
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.all(17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDCE0E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F47AF), width: 2),
        ),
      ),

      // Button styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F47AF),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F47AF),
          side: const BorderSide(color: Color(0xFF0F47AF)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double full = 9999.0;
}

class AppFontSizes {
  static const double xs = 12.0;
  static const double sm = 14.0;
  static const double base = 16.0;
  static const double lg = 18.0;
  static const double xl = 22.0;
  static const double xxl = 32.0;
}