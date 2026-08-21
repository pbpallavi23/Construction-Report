import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../routing/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'user_avatar.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title = 'Baxall Construction',
    this.leadingInitials,
  });

  final String title;
  final String? leadingInitials;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.touchTargetLg + 8);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthController>();
    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 1,
      shadowColor: AppColors.ambientShadow,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageMargin,
            vertical: 6,
          ),
          child: Row(
            children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.push(AppRoutes.profile),
                child: UserAvatar(
                  radius: 20,
                  initials: leadingInitials ?? auth.user?.initials,
                  imagePath: auth.localAvatarPath,
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineLg.copyWith(color: scheme.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
