import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Type system for bmplayer.
///
/// Three roles, never mixed:
///  - Display (Outfit): titles, track names, big numbers — geometric,
///    confident, used with restraint (headlines only, never body copy).
///  - Body (Inter): everything a person reads — descriptions, labels,
///    list rows.
///  - Utility (JetBrains Mono): timestamps, bitrate, codec, file size —
///    technical metadata gets a technical typeface so it reads as data,
///    not prose.
class AppType {
  AppType._();

  static TextTheme textTheme() {
    final display = GoogleFonts.outfitTextTheme();
    final body = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
        height: 1.05,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
        height: 1.1,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      ),
      titleMedium: display.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.textFaint,
      ),
    );
  }

  /// Monospace utility style for metadata chips (e.g. "320 kbps", "04:12").
  static TextStyle mono({
    double size = 12,
    Color color = AppColors.textMuted,
    FontWeight weight = FontWeight.w500,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: 0.2,
    );
  }
}
