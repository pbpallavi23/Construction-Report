import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ActionCard extends StatefulWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconBg,
    this.iconColor,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconBg;
  final Color? iconColor;
  final String? badge;

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final chipBg = widget.iconBg ??
        (dark ? AppColorsDark.primary : scheme.primaryContainer);
    final chipFg = widget.iconColor ??
        (dark ? AppColorsDark.onPrimary : AppColors.onPrimaryContainer);
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(



          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: AppColors.ambientShadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: dark
                      ? Border.all(color: chipFg.withValues(alpha: 0.25), width: 1)
                      : null,
                ),
                child: Icon(widget.icon, color: chipFg, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.title,
                        style: AppTypography.headlineMd
                            .copyWith(color: scheme.primary)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: AppTypography.labelMd
                            .copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (widget.badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(widget.badge!,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSecondary,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ] else
                Icon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}