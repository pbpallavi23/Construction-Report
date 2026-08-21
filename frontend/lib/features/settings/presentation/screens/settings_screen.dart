import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthController>();
    final theme = context.watch<ThemeController>();
    final user = auth.user;

    return Scaffold(
      appBar: const AppTopBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageMargin,
          AppSpacing.stackLg,
          AppSpacing.pageMargin,
          AppSpacing.stackXl,
        ),
        children: [
          Text(
            'Settings',
            style: AppTypography.headlineXl.copyWith(color: scheme.primary),
          ),
          AppSpacing.gapLg,

          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              onTap: () => context.push(AppRoutes.profile),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      radius: 28,
                      initials: user?.initials,
                      imagePath: auth.localAvatarPath,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Baxall User',
                            style: AppTypography.headlineMd.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                          Text(
                            user?.role ?? 'Site Engineer',
                            style: AppTypography.bodyMd.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          if (user?.email != null)
                            Text(
                              user!.email,
                              style: AppTypography.labelMd.copyWith(
                                color: scheme.outline,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: scheme.outline),
                  ],
                ),
              ),
            ),
          ),
          AppSpacing.gapLg,

          _SettingsGroup(
            title: 'Preferences',
            children: [
              _SwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark mode',
                subtitle: 'Optimised for night shifts',
                value: theme.isDark,
                onChanged: theme.toggleDark,
              ),
              _NavTile(
                icon: Icons.language_rounded,
                title: 'Language',
                trailing: 'English (UK)',
                onTap: () {},
              ),
            ],
          ),
          AppSpacing.gapLg,

          SizedBox(
            width: double.infinity,
            height: AppSpacing.touchTargetLg,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger, width: 2),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.lgAll,
                ),
              ),
              onPressed: () => _confirmLogout(context, auth),
              icon: const Icon(Icons.logout_rounded),
              label: Text('Sign out', style: AppTypography.buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthController auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access the site.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) await auth.logout();
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.labelLg.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(height: 1, color: scheme.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: scheme.primary),
      title: Text(
        title,
        style: AppTypography.bodyLg.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTypography.labelMd.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: scheme.primary),
      title: Text(
        title,
        style: AppTypography.bodyLg.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: AppTypography.labelMd.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: scheme.outline),
        ],
      ),
      onTap: onTap,
    );
  }
}
