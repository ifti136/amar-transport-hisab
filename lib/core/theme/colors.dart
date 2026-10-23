import 'package:flutter/material.dart';
export 'app_theme.dart';

/// Colour constants for Amar Transport Hisab
/// Based on DESIGN.md tokens - Light Theme

class AppColors {
  // Primary - Deep Green
  static const primary = Color(0xFF1B5E20);
  static const primaryContainer = Color(0xFFE8F5E9);
  static const onPrimary = Color(0xFFFFFFFF);

  // Secondary - Deep Blue (for Cash)
  static const secondary = Color(0xFF0D47A1);
  static const secondaryContainer = Color(0xFFE3F2FD);
  static const onSecondary = Color(0xFFFFFFFF);

  // Tertiary - Deep Orange (for Warnings)
  static const tertiary = Color(0xFFE65100);
  static const tertiaryContainer = Color(0xFFFFF3E0);
  static const onTertiary = Color(0xFFFFFFFF);

  // Error
  static const error = Color(0xFFC62828);
  static const errorContainer = Color(0xFFFDEDEC);
  static const onError = Color(0xFFFFFFFF);

  // Success (Profit)
  static const success = Color(0xFF2E7D32);
  static const successContainer = Color(0xFFE8F5E9);
  static const onSuccess = Color(0xFFFFFFFF);

  // Warning (Expiry 7-30 days)
  static const warning = Color(0xFFEF6C00);
  static const warningContainer = Color(0xFFFFF3E0);
  static const onWarning = Color(0xFFFFFFFF);

  // Danger (Expiry ≤7 days, Negative Cash)
  static const danger = Color(0xFFC62828);
  static const dangerContainer = Color(0xFFFDEDEC);
  static const onDanger = Color(0xFFFFFFFF);

  // Surface
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF5F5F5);
  static const onSurface = Color(0xFF1A1A1A);
  static const onSurfaceVariant = Color(0xFF4A4A4A);

  // Outline
  static const outline = Color(0xFFBDBDBD);
  static const outlineVariant = Color(0xFFE0E0E0);

  // Background
  static const background = Color(0xFFFAFAFA);
  static const onBackground = Color(0xFF1A1A1A);

  // Expiry Badge Colors
  static const expiryGreen = Color(0xFF2E7D32); // >30 days
  static const expiryAmber = Color(0xFFEF6C00); // 7-30 days
  static const expiryRed = Color(0xFFC62828); // ≤7 days / expired

  // Chart Colors (Colour-blind safe - Okabe-Ito palette)
  static const chartGreen = Color(0xFF009E73); // Revenue
  static const chartRed = Color(0xFFD55E00); // Expense
  static const chartBlue = Color(0xFF0072B2); // Van 1
  static const chartOrange = Color(0xFFE69F00); // Van 2
  static const chartPurple = Color(0xFFCC79A7); // Van 3
  static const chartTeal = Color(0xFF009E73); // Profit
  static const chartVermillion = Color(0xFFD55E00); // Loss
}

extension ColorValuesExt on Color {
  Color withValues({double? alpha, double? red, double? green, double? blue}) {
    if (alpha != null) {
      return withOpacity(alpha.clamp(0.0, 1.0));
    }
    return this;
  }
}
