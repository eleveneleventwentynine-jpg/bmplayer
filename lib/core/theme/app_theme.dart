import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.void1,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.pulseViolet,
        secondary: AppColors.driftAqua,
        tertiary: AppColors.flareCoral,
        surface: AppColors.void1,
        error: AppColors.danger,
      ),
      textTheme: AppType.textTheme(),
      splashFactory: InkSparkle.splashFactory,
      highlightColor: AppColors.glassFill,
      dividerColor: AppColors.glassBorder,
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: AppColors.pulseViolet,
        inactiveTrackColor: AppColors.glassBorderStrong,
        thumbColor: Colors.white,
        overlayColor: AppColors.pulseViolet.withOpacity(0.15),
        trackHeight: 3,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
