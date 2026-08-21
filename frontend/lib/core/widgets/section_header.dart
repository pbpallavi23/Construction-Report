import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.style,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: (style ?? AppTypography.headlineLg).copyWith(color: scheme.primary),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
