import 'package:flutter/material.dart';

// App Color Scheme
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1A1A1A);
  static const Color secondary = Color(0xFF2D2D2D);
  static const Color accent = Color(0xFF6C63FF);
  
  // Background Colors
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  
  // Utility Colors
  static const Color divider = Color(0xFF2D2D2D);
  static const Color error = Color(0xFFFF4B4B);
  
  // Opacity Colors
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color accentWithOpacity(double opacity) => accent.withOpacity(opacity);
  static Color surfaceWithOpacity(double opacity) => surface.withOpacity(opacity);
} 