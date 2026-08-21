import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum _ButtonVariant { primary, secondary, safety }

class _BaseButton extends StatefulWidget {
  const _BaseButton({
    required this.label,
    required this.onPressed,
    required this.variant,
    this.icon,
    this.busy = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final _ButtonVariant variant;
  final IconData? icon;
  final bool busy;
  final bool expand;

  @override
  State<_BaseButton> createState() => _BaseButtonState();
}

class _BaseButtonState extends State<_BaseButton> {
  double _scale = 1;

  void _setPressed(bool pressed) {
    if (widget.onPressed == null || widget.busy) return;
    setState(() => _scale = pressed ? 0.96 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null && !widget.busy;

    late final Color bg;
    late final Color fg;
    BorderSide side = BorderSide.none;

    switch (widget.variant) {
      case _ButtonVariant.primary:
        bg = scheme.primary;
        fg = scheme.onPrimary;
        break;
      case _ButtonVariant.secondary:
        bg = scheme.surfaceContainerLowest;
        fg = scheme.primary;
        side = BorderSide(color: scheme.primary, width: 2);
        break;
      case _ButtonVariant.safety:
        bg = AppColors.secondaryContainer;
        fg = AppColors.onSecondaryContainer;
        break;
    }

    final child = AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lgAll,
            side: side,
          ),
          elevation: widget.variant == _ButtonVariant.secondary ? 0 : 2,
          shadowColor: AppColors.ambientShadow,
          child: InkWell(
            borderRadius: AppRadius.lgAll,
            onTap: enabled ? widget.onPressed : null,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: SizedBox(
              height: AppSpacing.touchTargetLg,
              child: Center(
                child: widget.busy
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(fg),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.label,
                              style: AppTypography.buttonText.copyWith(color: fg)),
                          if (widget.icon != null) ...[
                            const SizedBox(width: 8),
                            Icon(widget.icon, color: fg, size: 22),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    return widget.expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) => _BaseButton(
        label: label,
        onPressed: onPressed,
        variant: _ButtonVariant.primary,
        icon: icon,
        busy: busy,
        expand: expand,
      );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) => _BaseButton(
        label: label,
        onPressed: onPressed,
        variant: _ButtonVariant.secondary,
        icon: icon,
        busy: busy,
        expand: expand,
      );
}

class SafetyButton extends StatelessWidget {
  const SafetyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) => _BaseButton(
        label: label,
        onPressed: onPressed,
        variant: _ButtonVariant.safety,
        icon: icon,
        busy: busy,
        expand: expand,
      );
}
