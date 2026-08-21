import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF002046);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1B365D);
  static const Color onPrimaryContainer = Color(0xFF87A0CD);
  static const Color primaryFixed = Color(0xFFD6E3FF);
  static const Color primaryFixedDim = Color(0xFFAEC7F7);
  static const Color inversePrimary = Color(0xFFAEC7F7);

  static const Color secondary = Color(0xFF735C00);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFED65B);
  static const Color onSecondaryContainer = Color(0xFF745C00);

  static const Color tertiary = Color(0xFF162132);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF2B3648);
  static const Color onTertiaryContainer = Color(0xFF949FB4);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color background = Color(0xFFF7F9FB);
  static const Color onBackground = Color(0xFF191C1E);
  static const Color surface = Color(0xFFF7F9FB);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color surfaceVariant = Color(0xFFE0E3E5);
  static const Color onSurfaceVariant = Color(0xFF44474E);

  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6CF);

  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F3);

  static const Color success = Color(0xFF10B981);
  static const Color caution = Color(0xFFD4AF37);
  static const Color danger = Color(0xFFEF4444);

  static Color get ambientShadow => primary.withValues(alpha: 0.08);
}

class AppColorsDark {
  const AppColorsDark._();

  static const Color primary = Color(0xFFAEC7F7);
  static const Color onPrimary = Color(0xFF001B3D);
  static const Color primaryContainer = Color(0xFF1B365D);
  static const Color onPrimaryContainer = Color(0xFFD6E3FF);

  static const Color secondary = Color(0xFFE9C349);
  static const Color onSecondary = Color(0xFF241A00);
  static const Color secondaryContainer = Color(0xFF574500);
  static const Color onSecondaryContainer = Color(0xFFFFE088);

  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color background = Color(0xFF17253E);
  static const Color onBackground = Color(0xFFEAF1FB);
  static const Color surface = Color(0xFF17253E);
  static const Color onSurface = Color(0xFFEAF1FB);
  static const Color surfaceContainerLowest = Color(0xFF1F3050);
  static const Color surfaceContainerLow = Color(0xFF243656);
  static const Color surfaceContainer = Color(0xFF2A3D60);
  static const Color surfaceContainerHigh = Color(0xFF31466C);
  static const Color surfaceContainerHighest = Color(0xFF3A5078);
  static const Color surfaceVariant = Color(0xFF3E547C);
  static const Color onSurfaceVariant = Color(0xFFBCCBE2);

  static const Color outline = Color(0xFF7285A3);
  static const Color outlineVariant = Color(0xFF3D4E6E);
}
