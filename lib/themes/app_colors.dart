import 'package:flutter/material.dart';

// Black, White & Yellow Theme for Social Media App
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF121212); // Jet black
  static const Color secondary = Color(0xFF1F1F1F); // Cool dark gray
  static const Color accent = Color(0xFFFFD700); // Vibrant yellow

  // Background Colors
  static const Color background = Color(0xFFFFFFFF); // Pure white
  static const Color surface = Color(0xFFF7F7F7); // Soft gray
  static const Color card = Color(0xFF2D2D2D); // Smooth dark gray

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // Bright white
  static const Color textSecondary = Color(0xFFCCCCCC); // Soft light gray
  static const Color textHint = Color(0xFFE6C200); // Muted yellow

  // Border and Divider Colors
  static const Color border = Color(0xFF3A3A3A); // Graphite gray
  static const Color divider = Color(0xFF3A3A3A); // Graphite gray

  // Status Colors
  static const Color success = Color(0xFF32CD32); // Neon green
  static const Color error = Color(0xFFFF4444); // Fire red
  static const Color warning = Color(0xFFEAB308); // Deep goldenrod
  static const Color info = Color(0xFF3B82F6); // Bright blue

  // Overlay Colors
  static const Color overlay = Color(0x99000000); // Dark overlay
  static const Color modalBackground = Color(0xFF121212); // Rich black

  // Interactive Colors
  static const Color buttonPrimary = Color(0xFFFFD700); // Strong yellow
  static const Color buttonSecondary = Color(0xFF1F1F1F); // Dark charcoal
  static const Color buttonDisabled = Color(0xFF666666); // Neutral gray

  // Shadow Colors
  static const Color shadow = Color(0x30000000); // Deep black shadow

  // Helper Methods
  static Color accentWithOpacity(double opacity) => accent.withOpacity(opacity);
  static Color surfaceWithOpacity(double opacity) => surface.withOpacity(opacity);
  static Color textPrimaryWithOpacity(double opacity) => textPrimary.withOpacity(opacity);
  static Color textSecondaryWithOpacity(double opacity) => textSecondary.withOpacity(opacity);
}
