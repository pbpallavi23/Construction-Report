import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/data/repositories/site_repository.dart';
import '../../data/models/transcription.dart';
import '../../data/repositories/speech_repository.dart';
import '../controllers/voice_controller.dart';

class VoiceNotesScreen extends StatelessWidget {
  const VoiceNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VoiceController(
        speechRepository: context.read<SpeechRepository>(),
        siteRepository: context.read<SiteRepository>(),
      )..init(),
      child: const _VoiceView(),
    );
  }
}

class _VoiceView extends StatefulWidget {
  const _VoiceView();

  @override
  State<_VoiceView> createState() => _VoiceViewState();
}

class _VoiceViewState extends State<_VoiceView> {
  final _transcript = TextEditingController();
  VoiceController? _controller;
  bool _syncedThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = context.read<VoiceController>()..addListener(_sync);
    });
  }

  void _sync() {
    final c = _controller;
    if (c == null) return;
    if (c.stage == VoiceStage.listening) {
      _syncedThisSession = false;
    } else if (c.stage == VoiceStage.ready && !_syncedThisSession) {
      _transcript.text = c.transcript;
      _transcript.selection =
          TextSelection.collapsed(offset: _transcript.text.length);
      _syncedThisSession = true;
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_sync);
    _transcript.dispose();
    super.dispose();
  }

  void _toggleMic(VoiceController c) {
    if (c.stage == VoiceStage.listening) {
      c.stopListening();
    } else {
      c.startListening();
    }
  }

  Future<void> _save(VoiceController c) async {
    c.updateTranscript(_transcript.text);
    final ok = await c.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(ok ? 'Voice note saved.' : 'Could not save the note.'),
      ));
    if (ok) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = context.watch<VoiceController>();
    final listening = c.stage == VoiceStage.listening;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Notes'),
        backgroundColor: scheme.surfaceContainerLow,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin,
            AppSpacing.stackLg, AppSpacing.pageMargin, AppSpacing.stackXl),
        children: [
          Text('Capture site updates hands-free',
              style:
                  AppTypography.bodyLg.copyWith(color: scheme.onSurfaceVariant)),
          AppSpacing.gapLg,

          Container(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                _MicButton(
                  listening: listening,
                  enabled: c.stage != VoiceStage.unavailable &&
                      c.stage != VoiceStage.transcribing,
                  level: c.soundLevel,
                  onTap: () => _toggleMic(c),
                ),
                AppSpacing.gapMd,
                _statusLabel(context, c),
              ],
            ),
          ),
          AppSpacing.gapLg,

          if (c.message != null)
            Text(c.message!,
                style: AppTypography.bodyMd.copyWith(color: AppColors.danger)),

          if (listening) ...[
            Text('Recording…',
                style:
                    AppTypography.headlineMd.copyWith(color: scheme.primary)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Text(
                'Tap the mic again when you\'re done talking. '
                'We\'ll transcribe it right after.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLg.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ],

          if (c.stage == VoiceStage.transcribing) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: scheme.primary),
                ),
                const SizedBox(width: 10),
                Text('Transcribing your recording…',
                    style: AppTypography.headlineMd
                        .copyWith(color: scheme.primary)),
              ],
            ),
          ],

          if (c.stage == VoiceStage.ready) ...[
            Text('Transcription',
                style:
                    AppTypography.headlineMd.copyWith(color: scheme.primary)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: TextField(
                controller: _transcript,
                minLines: 4,
                maxLines: 10,
                style: AppTypography.bodyLg.copyWith(color: scheme.onSurface),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.all(AppSpacing.stackLg),
                ),
              ),
            ),
            AppSpacing.gapLg,
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Record again',
                    icon: Icons.mic_rounded,
                    onPressed: () => c.startListening(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SafetyButton(
                    label: 'Save Note',
                    icon: Icons.save_rounded,
                    busy: c.saving,
                    onPressed: () => _save(c),
                  ),
                ),
              ],
            ),
          ],

          AppSpacing.gapXl,
          _NotesHistory(controller: c),
        ],
      ),
    );
  }

  Widget _statusLabel(BuildContext context, VoiceController c) {
    final scheme = Theme.of(context).colorScheme;
    switch (c.stage) {
      case VoiceStage.listening:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.error, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text('RECORDING — tap to stop',
                style: AppTypography.labelLg.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
          ],
        );
      case VoiceStage.transcribing:
        return Text('Transcribing…',
            style: AppTypography.labelLg.copyWith(color: scheme.onSurfaceVariant));
      case VoiceStage.ready:
        return Text('Tap the mic to record again',
            style: AppTypography.labelMd.copyWith(color: scheme.onSurfaceVariant));
      case VoiceStage.unavailable:
        return Text('Microphone unavailable',
            style: AppTypography.labelLg.copyWith(color: AppColors.danger));
      case VoiceStage.idle:
        return Text('Tap the mic and start speaking',
            style: AppTypography.labelLg
                .copyWith(color: scheme.onSurfaceVariant));
    }
  }
}

class _NotesHistory extends StatelessWidget {
  const _NotesHistory({required this.controller});
  final VoiceController controller;

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
            Text('Recent voice notes',
                style: AppTypography.headlineMd.copyWith(color: scheme.primary)),
            if (controller.loadingNotes)
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
                onPressed: controller.loadNotes,
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (!controller.loadingNotes && controller.pastNotes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No voice notes for this site yet.',
                style: AppTypography.bodyMd
                    .copyWith(color: scheme.onSurfaceVariant)),
          )
        else
          ...controller.pastNotes.map(
            (note) => _NoteCard(
              note: note,
              isMine: currentUserId != null && note.userId == currentUserId,
              controller: controller,
            ),
          ),
      ],
    );
  }
}

class _NoteCard extends StatefulWidget {
  const _NoteCard({
    required this.note,
    required this.isMine,
    required this.controller,
  });
  final VoiceNote note;
  final bool isMine;
  final VoiceController controller;

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

enum _PlaybackState { idle, loading, playing, error }

class _NoteCardState extends State<_NoteCard> {
  final _player = AudioPlayer();
  _PlaybackState _playback = _PlaybackState.idle;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playback = _PlaybackState.idle);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_playback == _PlaybackState.playing) {
      await _player.pause();
      setState(() => _playback = _PlaybackState.idle);
      return;
    }
    setState(() => _playback = _PlaybackState.loading);
    try {
      await _player.play(UrlSource(widget.note.url(AppConfig.baseUrl)));
      if (mounted) setState(() => _playback = _PlaybackState.playing);
    } catch (_) {
      if (mounted) setState(() => _playback = _PlaybackState.error);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete voice note?'),
        content: const Text(
            'This removes the note (and its audio, if any) from the site '
            'record for everyone. This can\'t be undone.'),
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

    if (_playback == _PlaybackState.playing) {
      await _player.stop();
    }
    setState(() => _deleting = true);
    final ok = await widget.controller.deleteNote(widget.note.id);
    if (!mounted) return;
    setState(() => _deleting = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            widget.controller.deleteError ?? 'Could not delete the voice note.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final note = widget.note;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_rounded, size: 16, color: scheme.outline),
              const SizedBox(width: 6),
              Text(widget.isMine ? 'You' : 'Team member',
                  style: AppTypography.labelMd.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(_relativeTime(note.createdAt),
                  style: AppTypography.labelMd
                      .copyWith(color: scheme.outline)),
              const SizedBox(width: 4),
              if (_deleting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                InkWell(
                  onTap: _confirmDelete,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 18, color: scheme.outline),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(note.transcript,
              style: AppTypography.bodyMd.copyWith(color: scheme.onSurface)),
          if (note.hasAudio) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: _togglePlayback,
              borderRadius: AppRadius.lgAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    if (_playback == _PlaybackState.loading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: scheme.primary),
                      )
                    else
                      Icon(
                        _playback == _PlaybackState.playing
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: _playback == _PlaybackState.error
                            ? AppColors.danger
                            : scheme.primary,
                        size: 32,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _playback == _PlaybackState.error
                          ? 'Could not play audio'
                          : _playback == _PlaybackState.playing
                              ? 'Playing…'
                              : 'Play voice note',
                      style: AppTypography.labelMd.copyWith(
                        color: _playback == _PlaybackState.error
                            ? AppColors.danger
                            : scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.listening,
    required this.enabled,
    required this.level,
    required this.onTap,
  });
  final bool listening;
  final bool enabled;
  final double level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final halo = listening ? (96 + level.clamp(0, 10) * 6).toDouble() : 96.0;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: halo,
              height: halo,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: !enabled
                    ? AppColors.outline
                    : (listening ? AppColors.error : AppColors.primary),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.ambientShadow, blurRadius: 16),
                ],
              ),
              child: Icon(
                listening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
