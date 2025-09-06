import 'package:flutter/material.dart';

class AppColors {

  static const Color primaryGreen = Color(0xFF147810);
  static const Color lightGreen = Color(0xFF94C293);
  static const Color darkGreen = Color(0xFF0B570A);


  static const Color accent = Color(0xFF4CAF50);
  static const Color accentLight = Color(0xFF81C784);
  static const Color accentDark = Color(0xFF2E7D32);


  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);


  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFFFFFFFF);


  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);


  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);


  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowDark = Color(0x26000000);


  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryGreen, darkGreen],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0C6F08),
      Color(0xFFFFF8F8),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8F9FA),
    ],
  );


  static const Color chatBubbleUser = primaryGreen;
  static const Color chatBubbleOther = Color(0xFFE5E7EB);
  static const Color chatBackground = Color(0xFFF9FAFB);


  static const Color videoOverlay = Color(0x80000000);
  static const Color videoControls = Color(0xFFFFFFFF);


  static const Color sunny = Color(0xFFFFA726);
  static const Color cloudy = Color(0xFF90A4AE);
  static const Color rainy = Color(0xFF42A5F5);
  static const Color stormy = Color(0xFF5C6BC0);
}