import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 96,
    this.showWordmark = true,
    this.showTagline = true,
  });

  final double size;
  final bool showWordmark;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size * 0.72,
          child: CustomPaint(
            painter: _MarkPainter(dark: scheme.brightness == Brightness.dark),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 12),
          Text(
            'BAXALL',
            style: AppTypography.headlineLg.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontSize: size * 0.26,
            ),
          ),
        ],
        if (showTagline) ...[
          const SizedBox(height: 2),
          Text(
            'Buildings built on teamwork',
            style: AppTypography.labelMd.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({this.dark = false});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final navy = Paint()
      ..color = dark ? AppColorsDark.primary : AppColors.primary;
    final navyLight = Paint()
      ..color = dark ? AppColorsDark.primaryContainer : AppColors.primaryContainer;
    final gold = Paint()..color = AppColors.secondaryContainer;

    final left = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.5, 0)
      ..lineTo(w * 0.5, h)
      ..close();
    canvas.drawPath(left, navy);

    final right = Path()
      ..moveTo(w * 0.5, h)
      ..lineTo(w * 0.5, 0)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(right, navyLight);

    final peak = Path()
      ..moveTo(w * 0.32, h)
      ..lineTo(w * 0.5, h * 0.34)
      ..lineTo(w * 0.68, h)
      ..close();
    canvas.drawPath(peak, gold);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
