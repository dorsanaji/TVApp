import 'package:flutter/material.dart';

/// Colour tokens.
///
/// The five [progress] colours are not decoration — they are prescribed by
/// FR-11 and each carries a defined meaning. They live here so the mapping is
/// stated once and cannot drift between screens.
abstract final class AppColors {
  const AppColors._();

  static const seed = Color(0xFF6C4CE0);

  static const darkBackground = Color(0xFF0E0E14);
  static const darkSurface = Color(0xFF1A1A24);
  static const darkSurfaceVariant = Color(0xFF24242F);

  static const lightBackground = Color(0xFFF7F7FA);
  static const lightSurface = Color(0xFFFFFFFF);

  static const star = Color(0xFFFFC107);
  static const spoilerVeil = Color(0xFF2A2A38);

  /// FR-11 progress-bar colours. See `WatchProgressBar` for the decision rule.
  static const progressNone = Color(0xFF1C1C24); // بی‌رنگ یا مشکی
  static const progressOngoing = Color(0xFF35C759); // سبز
  static const progressCompleted = Color(0xFF9B59F6); // بنفش
  static const progressDropped = Color(0xFFE5484D); // قرمز
  static const progressPartial = Color(0xFFF5C518); // زرد
}
