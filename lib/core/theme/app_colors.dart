import 'package:flutter/material.dart';

/// bmplayer color system — "Ambient Bloom"
///
/// The app never sits on flat black. The background is always a soft
/// gradient between [void1] and [void2], tinted at runtime by whatever
/// color is extracted from the currently playing artwork (see
/// [AmbientBackground]). These are the fixed anchors everything else
/// is built from.
class AppColors {
  AppColors._();

  // Base "void" gradient — deep indigo-black, never pure #000.
  static const Color void1 = Color(0xFF0A0B14);
  static const Color void2 = Color(0xFF050609);

  // Glass surfaces.
  static const Color glassFill = Color(0x0FFFFFFF); // ~6% white
  static const Color glassFillStrong = Color(0x1AFFFFFF); // ~10% white
  static const Color glassBorder = Color(0x1FFFFFFF); // ~12% white
  static const Color glassBorderStrong = Color(0x33FFFFFF);

  // Accents.
  static const Color pulseViolet = Color(0xFF8B7FFF);
  static const Color driftAqua = Color(0xFF45E8D1);
  static const Color flareCoral = Color(0xFFFF7092);

  // Text.
  static const Color textPrimary = Color(0xFFF4F2FB);
  static const Color textMuted = Color(0xFF9591B0);
  static const Color textFaint = Color(0xFF615C7A);

  // Semantic.
  static const Color success = driftAqua;
  static const Color danger = Color(0xFFFF5C7A);

  static const LinearGradient voidGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [void1, void2],
  );

  static const LinearGradient pulseGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [pulseViolet, driftAqua],
  );

  static const LinearGradient flareGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [flareCoral, pulseViolet],
  );

  /// Given a color extracted from artwork, produce a muted, low-saturation
  /// version suitable for bleeding into the background without ever
  /// overpowering the glass surfaces sitting on top of it.
  static Color ambientTint(Color source) {
    final hsl = HSLColor.fromColor(source);
    return hsl
        .withSaturation((hsl.saturation * 0.55).clamp(0.0, 0.6))
        .withLightness((hsl.lightness * 0.35).clamp(0.05, 0.22))
        .toColor();
  }
}
