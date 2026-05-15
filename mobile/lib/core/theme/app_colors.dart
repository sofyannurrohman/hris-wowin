import 'package:flutter/material.dart';

class AppColors {
  // Primary Corporate Green - Elegant Emerald
  static const Color primaryGreen = Color(0xFF059669); 
  static const Color primaryGreenLight = Color(0xFF10B981);
  static const Color primaryGreenDark = Color(0xFF064E3B);
  
  // Backwards compatibility for now (mapping red to green)
  static const Color primaryRed = primaryGreen; 
  static const Color primaryRedLight = primaryGreenLight; 

  // Premium Gradients
  static const List<Color> primaryGradient = [Color(0xFF059669), Color(0xFF064E3B)];
  static const List<Color> accentGradient = [Color(0xFF10B981), Color(0xFF059669)];

  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF); // Pure white surface
  static const Color backgroundAlt = Color(0xFFFBFBFB); // Very light gray

  // Text - Slate palette for professional look
  static const Color textPrimary = Color(0xFF1E293B); 
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Greyscale
  static const Color grayBorder = Color(0xFFE2E8F0);
  static const Color grayLight = Color(0xFFF1F5F9);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);
}
