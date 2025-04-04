import 'package:flutter/material.dart';

// Unified Theme - Dark + Deep Purple Aesthetic
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF121212); // Jet black
  static const Color secondary = Color(0xFF1F1F1F); // Dark gray
  static const Color accent = Color(0xFF8B5CF6); // Deep Purple

  // Background Colors
  static const Color background = Color(0xFFFFFFFF); // White background for contrast
  static const Color surface = Color(0xFFF0F0F0); // Light surface for UI elements
  static const Color card = Color(0xFF2D2D2D); // Dark gray card for depth

  // Text Colors
  static const Color textPrimary = Color(0xFF000000); // Pure black text
  static const Color textSecondary = Color(0xFF4F4F4F); // Dark gray text
  static const Color textHint = Color(0xFFBFA5F9); // Muted lilac hint text

  // Borders and Dividers
  static const Color border = Color(0xFF3A3A3A); // Graphite gray
  static const Color divider = Color(0xFFE0E0E0); // Soft light divider

  // Status Colors
  static const Color success = Color(0xFF32CD32); // Neon green
  static const Color error = Color(0xFFD32F2F); // Deep red
  static const Color warning = Color(0xFFEAB308); // Goldenrod
  static const Color info = Color(0xFF3B82F6); // Blue info

  // Overlay Colors
  static const Color overlay = Color(0x99000000); // Transparent black overlay
  static const Color modalBackground = Color(0xFF121212); // Black modal bg

  // Interactive Colors
  static const Color buttonPrimary = Color(0xFF8B5CF6); // Deep Purple button
  static const Color buttonSecondary = Color(0xFF1F1F1F); // Dark secondary button
  static const Color buttonDisabled = Color(0xFF666666); // Gray disabled button

  // Shadows
  static const Color shadow = Color(0x30000000); // Light shadow

  // Helper Methods
  static Color accentWithOpacity(double opacity) => accent.withOpacity(opacity);
  static Color surfaceWithOpacity(double opacity) => surface.withOpacity(opacity);
  static Color textPrimaryWithOpacity(double opacity) => textPrimary.withOpacity(opacity);
  static Color textSecondaryWithOpacity(double opacity) => textSecondary.withOpacity(opacity);
}
