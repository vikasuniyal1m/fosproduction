import 'package:flutter/material.dart';

/// App Colors Utility
/// Centralized color management - Change once, affects entire app
class AppColors {
  // Primary Colors (Green Theme - Matching Logo)
  static const Color primary = Color(0xFF0B5306); // Green - Matching logo
  static const Color primaryDark = Color(0xFF084003);
  static const Color primaryLight = Color(0xFF0E6A08);
  
  // Secondary Red Colors (kept for error states)
  static const Color pinkAccent = Color(0xFFEF4444); // Red
  static const Color pinkLight = Color(0xFFFEE2E2);
  static const Color redAccent = Color(0xFFEF4444);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF10B981); // Green
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryLight = Color(0xFF34D399);
  
  // Accent Colors
  static const Color accent = Color(0xFFF59E0B); // Amber
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFBBF24);
  
  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1F2937);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundGrey = Color(0xFFF3F4F6);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textBlack = Color(0xFF000000);
  
  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFF3F4F6);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Status Light Colors (for backgrounds)
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color infoLight = Color(0xFFDBEAFE);
  
  // Button Colors
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color buttonDisabled = Color(0xFFD1D5DB);
  static const Color buttonText = textWhite;
  
  // Card Colors
  static const Color cardBackground = background;
  static const Color cardShadowColor = Color(0x1A000000);
  static const Color shadow = Color(0x1A000000); // Alias for cardShadowColor
  
  // Bottom Navigation
  static const Color bottomNavBackground = background;
  static const Color bottomNavSelected = primary;
  static const Color bottomNavUnselected = textSecondary;
  
  // Input Field Colors
  static const Color inputBackground = background;
  static const Color inputBorder = border;
  static const Color inputBorderFocused = primary;
  static const Color inputError = error;
  
  // Divider
  static const Color divider = border;
  
  // Overlay
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow Colors
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: cardShadowColor,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}

