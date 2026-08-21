import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool showDot;
  final bool filled;

  factory StatusPill.success(String label, {bool showDot = true}) =>
      StatusPill(label: label, color: AppColors.success, showDot: showDot);
  factory StatusPill.caution(String label, {bool showDot = true}) =>
      StatusPill(label: label, color: AppColors.caution, showDot: showDot);
  factory StatusPill.danger(String label, {bool showDot = true}) =>
      StatusPill(label: label, color: AppColors.danger, showDot: showDot);
  factory StatusPill.neutral(String label, {bool showDot = true}) =>
      StatusPill(label: label, color: AppColors.outline, showDot: showDot);

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.labelLg.copyWith(
              color: fg,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
