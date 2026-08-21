import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit details',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editDetails(context, auth),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin,
            AppSpacing.stackLg, AppSpacing.pageMargin, AppSpacing.stackXl),
        children: [
          Center(
            child: Stack(
              children: [
                UserAvatar(
                  radius: 56,
                  initials: user?.initials,
                  imagePath: auth.localAvatarPath,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: scheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _changePhoto(context, auth),
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: Icon(Icons.photo_camera_rounded,
                            size: 20, color: scheme.onPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => _changePhoto(context, auth),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Change profile picture'),
            ),
          ),
          AppSpacing.gapLg,

          _InfoGroup(children: [
            _InfoRow(
                icon: Icons.badge_outlined,
                label: 'Full name',
                value: user?.fullName ?? '—'),
            _InfoRow(
                icon: Icons.work_outline_rounded,
                label: 'Role',
                value: user?.role ?? '—'),
            _InfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: user?.email ?? '—'),
            _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: (user?.phone?.isNotEmpty ?? false)
                    ? user!.phone!
                    : 'Not set'),
          ]),
        ],
      ),
    );
  }

  Future<void> _changePhoto(BuildContext context, AuthController auth) async {
    final scheme = Theme.of(context).colorScheme;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_rounded, color: scheme.primary),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: scheme.primary),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (auth.localAvatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger),
                title: const Text('Remove photo',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    if (choice == 'remove') {
      await auth.setLocalAvatar(null);
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        await auth.setLocalAvatar(picked.path);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('Could not access the camera or gallery.')));
      }
    }
  }

  Future<void> _editDetails(BuildContext context, AuthController auth) async {
    final nameCtl = TextEditingController(text: auth.user?.fullName ?? '');
    final phoneCtl = TextEditingController(text: auth.user?.phone ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Full name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtl,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      final ok = await auth.updateProfile(
        fullName: nameCtl.text.trim(),
        phone: phoneCtl.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(ok ? 'Profile updated.' : 'Could not update profile.')));
      }
    }
    nameCtl.dispose();
    phoneCtl.dispose();
  }
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(icon, color: scheme.primary),
      title: Text(label,
          style: AppTypography.labelMd.copyWith(color: scheme.onSurfaceVariant)),
      subtitle: Text(value,
          style: AppTypography.bodyLg.copyWith(
              color: scheme.onSurface, fontWeight: FontWeight.w600)),
    );
  }
}
