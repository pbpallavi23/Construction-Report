import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/data/repositories/site_repository.dart';
import '../../data/models/ocr_result.dart';
import '../../data/repositories/ocr_repository.dart';
import '../controllers/ocr_controller.dart';

class CameraCaptureScreen extends StatelessWidget {
  const CameraCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OcrController(
        ocrRepository: context.read<OcrRepository>(),
        siteRepository: context.read<SiteRepository>(),
      )..init(),
      child: const _CameraView(),
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = context.watch<OcrController>();

    return Scaffold(
      appBar: const AppTopBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin,
            AppSpacing.stackLg, AppSpacing.pageMargin, AppSpacing.stackXl),
        children: [
          Text('Capture Photo',
              style: AppTypography.headlineXl.copyWith(color: scheme.primary)),
          const SizedBox(height: 4),
          Text('Photograph site progress, deliveries, or issues to attach to the site record.',
              style:
                  AppTypography.bodyMd.copyWith(color: scheme.onSurfaceVariant)),
          AppSpacing.gapLg,

          _Preview(controller: c),
          AppSpacing.gapLg,

          if (c.stage == CaptureStage.ready || c.stage == CaptureStage.error) ...[
            PrimaryButton(
              label: 'TAKE PHOTO',
              icon: Icons.photo_camera_rounded,
              onPressed: () => c.capture(source: ImageSource.camera),
            ),
            AppSpacing.gapMd,
            SecondaryButton(
              label: 'Choose from gallery',
              icon: Icons.photo_library_outlined,
              onPressed: () => c.capture(source: ImageSource.gallery),
            ),
            if (c.stage == CaptureStage.error && c.errorMessage != null) ...[
              AppSpacing.gapMd,
              Text(c.errorMessage!,
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.bodyMd.copyWith(color: AppColors.danger)),
            ],
          ],

          if (c.stage == CaptureStage.uploading) ...[
            const _UploadingBar(),
          ],

          if (c.stage == CaptureStage.done) ...[
            _DoneCard(controller: c),
          ],

          AppSpacing.gapXl,
          _PictureHistory(controller: c),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.controller});
  final OcrController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: controller.photo == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_camera_outlined,
                          size: 64, color: scheme.outline),
                      const SizedBox(height: 12),
                      Text('No photo yet',
                          style: AppTypography.bodyMd
                              .copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : Image.file(controller.photo!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _UploadingBar extends StatelessWidget {
  const _UploadingBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(999)),
          child: LinearProgressIndicator(
            minHeight: 8,
            backgroundColor: AppColors.surfaceContainer,
            valueColor: AlwaysStoppedAnimation(AppColors.secondary),
          ),
        ),
        const SizedBox(height: 8),
        Text('Saving photo to site record…',
            style: AppTypography.labelLg.copyWith(
                color: AppColors.primary, fontStyle: FontStyle.italic)),
      ],
    );
  }
}

class _PictureHistory extends StatelessWidget {
  const _PictureHistory({required this.controller});
  final OcrController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentUserId = context.watch<AuthController>().user?.assistantId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent photos',
                style: AppTypography.headlineMd.copyWith(color: scheme.primary)),
            if (controller.loadingPictures)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: scheme.primary),
              )
            else
              IconButton(
                tooltip: 'Refresh',
                icon: Icon(Icons.refresh_rounded, color: scheme.primary),
                onPressed: controller.loadPictures,
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (!controller.loadingPictures && controller.pastPictures.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No photos for this site yet.',
                style: AppTypography.bodyMd
                    .copyWith(color: scheme.onSurfaceVariant)),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.pastPictures.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, i) {
              final pic = controller.pastPictures[i];
              return _PictureThumb(
                picture: pic,
                isMine: currentUserId != null && pic.userId == currentUserId,
                controller: controller,
              );
            },
          ),
      ],
    );
  }
}

class _PictureThumb extends StatelessWidget {
  const _PictureThumb({
    required this.picture,
    required this.isMine,
    required this.controller,
  });
  final Picture picture;
  final bool isMine;
  final OcrController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: AppRadius.lgAll,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _PictureViewerScreen(
                  picture: picture,
                  isMine: isMine,
                  controller: controller,
                ),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  picture.url(AppConfig.baseUrl),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: scheme.primary),
                    );
                  },
                  errorBuilder: (context, error, stack) => Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: scheme.outline, size: 32),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isMine ? 'You' : 'Team member',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMd.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(_relativeTime(picture.createdAt),
                            style: AppTypography.labelMd
                                .copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PictureViewerScreen extends StatefulWidget {
  const _PictureViewerScreen({
    required this.picture,
    required this.isMine,
    required this.controller,
  });
  final Picture picture;
  final bool isMine;
  final OcrController controller;

  @override
  State<_PictureViewerScreen> createState() => _PictureViewerScreenState();
}

class _PictureViewerScreenState extends State<_PictureViewerScreen> {
  bool _deleting = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text(
            'This removes the photo from the site record for everyone. '
            'This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final ok = await widget.controller.deletePicture(widget.picture.id);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _deleting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          widget.controller.deleteError ?? 'Could not delete the photo.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.isMine ? 'You' : 'Team member'),
        actions: [
          if (_deleting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white70),
              ),
            )
          else
            IconButton(
              tooltip: 'Delete photo',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  widget.picture.url(AppConfig.baseUrl),
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const CircularProgressIndicator(color: Colors.white);
                  },
                  errorBuilder: (context, error, stack) => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          color: Colors.white54, size: 48),
                      SizedBox(height: 8),
                      Text('Could not load this image',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if ((widget.picture.caption ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Text(
                widget.picture.caption!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: Colors.white70),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

String _relativeTime(String isoTimestamp) {
  final parsed = DateTime.tryParse(isoTimestamp);
  if (parsed == null) return '';
  final diff = DateTime.now().toUtc().difference(parsed.toUtc());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${parsed.day}/${parsed.month}/${parsed.year}';
}

class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.controller});
  final OcrController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Photo saved to the site record.',
                    style: AppTypography.bodyLg
                        .copyWith(color: scheme.onSurface)),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Take another',
                icon: Icons.refresh_rounded,
                onPressed: controller.reset,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Done',
                onPressed: controller.reset,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
