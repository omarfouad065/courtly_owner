import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1DB954);
  static const Color primaryLight = Color(0xFF1ED760);
  static const Color primaryDark = Color(0xFF1AA34A);

  // Background Colors
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF2A2A2A);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(
    0xB3FFFFFF,
  ); // White with 70% opacity
  static const Color textDisabled = Color(0x80FFFFFF); // White with 50% opacity

  // Status Colors
  static const Color success = Color(0xFF1DB954);
  static const Color error = Colors.red;
  static const Color warning = Color(0xFFFFD700);

  // Icon Colors
  static const Color iconPrimary = Colors.white;
  static const Color iconSecondary = Colors.grey;

  // Border Colors
  static const Color border = Color(0xFF2A2A2A);
  static const Color divider = Color(0xFF2A2A2A);

  // Overlay Colors
  static const Color overlay = Color(0x80000000); // Black with 50% opacity
  static const Color shadow = Color(0x40000000); // Black with 25% opacity
}
