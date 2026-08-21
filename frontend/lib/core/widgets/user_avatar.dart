import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.radius,
    this.initials,
    this.imagePath,
  });

  final double radius;
  final String? initials;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = imagePath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      backgroundImage: hasImage ? FileImage(File(path)) : null,
      child: hasImage
          ? null
          : Text(
              initials ?? 'B',
              style: AppTypography.headlineMd.copyWith(
                color: Colors.white,
                fontSize: radius * 0.7,
              ),
            ),
    );
  }
}
