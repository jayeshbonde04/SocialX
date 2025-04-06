import 'package:flutter/material.dart';

// Unified Theme - Dark + Deep Purple Aesthetic
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF00BCD4); // Cyan
  static const Color secondary = Color(0xFF26C6DA); // Light Cyan
  static const Color accent = Color(0xFF00BCD4); // Cyan

  // Background Colors
  static const Color background = Color(0xFFFFFFFF); // Pure white
  static const Color surface = Color(0xFFF5F5F5); // Light gray surface
  static const Color card = Color(0xFFFFFFFF); // White card

  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // Near black
  static const Color textSecondary = Color(0xFF757575); // Medium gray
  static const Color textHint = Color(0xFFBDBDBD); // Light gray hint

  // Borders and Dividers
  static const Color border = Color(0xFFE0E0E0); // Light gray border
  static const Color divider = Color(0xFFEEEEEE); // Very light gray divider

  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Material Green
  static const Color error = Color(0xFFF44336); // Material Red
  static const Color warning = Color(0xFFFFC107); // Material Amber
  static const Color info = Color(0xFF00BCD4); // Cyan

  // Overlay Colors
  static const Color overlay = Color(0x52000000); // Semi-transparent black
  static const Color modalBackground = Color(0xFFFFFFFF); // White modal background

  // Interactive Colors
  static const Color buttonPrimary = Color(0xFF00BCD4); // Cyan
  static const Color buttonSecondary = Color(0xFFE0E0E0); // Light gray
  static const Color buttonDisabled = Color(0xFFBDBDBD); // Medium gray

  // Shadows
  static const Color shadow = Color(0x1A000000); // Very light shadow

  // Helper Methods
  static Color accentWithOpacity(double opacity) => accent.withOpacity(opacity);
  static Color surfaceWithOpacity(double opacity) => surface.withOpacity(opacity);
  static Color textPrimaryWithOpacity(double opacity) => textPrimary.withOpacity(opacity);
  static Color textSecondaryWithOpacity(double opacity) => textSecondary.withOpacity(opacity);
}
