import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Background off-white / cream color
  static const Color backgroundCream = Color(0xFFFEFCF0);

  /// Primary brand teal (LearnXtra text & outlines)
  static const Color primaryTeal = Color(0xFF026C86);

  /// Light teal / cyan accent (key top + outlines)
  static const Color cyanAccent = Color(0xFF03B8CC);

  /// Orange book page (left page)
  static const Color orangePage = Color(0xFFFE9344);

  /// Yellow book page (right page)
  static const Color yellowPage = Color(0xFFFEDA4D);

  /// Coral red accent (inner page shadow / depth)
  static const Color coralRed = Color(0xFFFA6B5C);

  /// Dark gray-blue (tagline text)
  static const Color textDark = Color(0xFF344F5A);

  /// Muted gray-teal (secondary soft accents)
  static const Color mutedTeal = Color(0xFF93A7A6);

  // Neutral colors (Retained for App Structure)
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color.fromARGB(255, 0, 73, 92);
  static const Color gray900 = Color.fromARGB(255, 0, 63, 79);

  // Semantic colors (Mapped to new colors or retained if specific map unavailable)
  static const Color success =
      Color(0xFF10B981); // Keeping green for success as it wasn't specified
  static const Color error = coralRed;
  static const Color warning = orangePage;
  static const Color info = primaryTeal;
}
