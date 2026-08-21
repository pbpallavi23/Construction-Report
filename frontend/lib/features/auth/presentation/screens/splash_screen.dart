import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fade;
  Timer? _timer;
  int _messageIndex = 0;

  static const _messages = [
    'Initializing secure site environment…',
    'Syncing project logs…',
    'Establishing encrypted link…',
    'Baxall Site Intelligence ready.',
  ];

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _timer = Timer.periodic(const Duration(milliseconds: 1400), (t) {
      if (!mounted) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _DottedBackground(),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 132),
                  AppSpacing.gapXl,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.smart_toy,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text('Site Assistant',
                          style: AppTypography.headlineMd
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                  AppSpacing.gapLg,
                  const SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: AppColors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                  AppSpacing.gapLg,
                  Text(
                    'POWERED BY AI',
                    style: AppTypography.labelLg.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      _messages[_messageIndex],
                      key: ValueKey(_messageIndex),
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              '© ${DateTime.now().year} Baxall Construction Ltd.',
              textAlign: TextAlign.center,
              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedBackground extends StatelessWidget {
  const _DottedBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.03,
        child: CustomPaint(painter: _DotPainter()),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  static const double _gap = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primaryContainer;
    for (double y = 0; y < size.height; y += _gap) {
      for (double x = 0; x < size.width; x += _gap) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
