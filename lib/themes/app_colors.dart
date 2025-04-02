import 'package:flutter/material.dart';

// App Color Scheme
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1E293B); // Lighter dark blue-gray
  static const Color secondary =
      Color(0xFF2D3748); // Slightly lighter secondary
  static const Color accent =
      Color(0xFF60A5FA); // Bright blue for interactive elements

  // Background Colors
  static const Color background = Color(0xFF111827); // Dark background
  static const Color surface = Color(0xFF1F2937); // Lighter surface color
  static const Color card = Color(0xFF1E293B); // Card background

  // Text Colors
  static const Color textPrimary =
      Color(0xFFF3F4F6); // Light gray for primary text
  static const Color textSecondary =
      Color(0xFF9CA3AF); // Medium gray for secondary text
  static const Color textHint = Color(0xFF6B7280); // Hint text color

  // Border and Divider Colors
  static const Color border = Color(0xFF374151); // Dark gray for borders
  static const Color divider = Color(0xFF374151); // Dark gray for dividers

  // Status Colors
  static const Color success = Color(0xFF10B981); // Green for success
  static const Color error = Color(0xFFEF4444); // Red for errors
  static const Color warning = Color(0xFFF59E0B); // Yellow for warnings
  static const Color info = Color(0xFF3B82F6); // Blue for info

  // Overlay Colors
  static const Color overlay = Color(0x80000000); // Semi-transparent black
  static const Color modalBackground = Color(0xFF1F2937); // Modal background

  // Interactive Colors
  static const Color buttonPrimary = Color(0xFF60A5FA); // Primary button color
  static const Color buttonSecondary =
      Color(0xFF374151); // Secondary button color
  static const Color buttonDisabled =
      Color(0xFF4B5563); // Disabled button color

  // Shadow Colors
  static const Color shadow = Color(0x40000000); // Shadow color with opacity

  // Helper Methods
  static Color accentWithOpacity(double opacity) => accent.withOpacity(opacity);
  static Color surfaceWithOpacity(double opacity) =>
      surface.withOpacity(opacity);
  static Color textPrimaryWithOpacity(double opacity) =>
      textPrimary.withOpacity(opacity);
  static Color textSecondaryWithOpacity(double opacity) =>
      textSecondary.withOpacity(opacity);
}
