import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/network/api_failure.dart';
import '../../../dashboard/data/repositories/site_repository.dart';
import '../../data/models/transcription.dart';
import '../../data/repositories/speech_repository.dart';




enum VoiceStage { idle, listening, transcribing, ready, unavailable }

class VoiceController extends ChangeNotifier {
  VoiceController({
    required SpeechRepository speechRepository,
    required SiteRepository siteRepository,
  })  : _speech = speechRepository,
        _sites = siteRepository;

  final SpeechRepository _speech;
  final SiteRepository _sites;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSub;

  String? _recordingPath;
  DateTime? _recordingStartedAt;

  VoiceStage stage = VoiceStage.idle;

  String transcript = '';
  double soundLevel = 0;
  bool saving = false;
  String? message;

  String _siteId = '';
  bool _disposed = false;

  List<VoiceNote> pastNotes = [];
  bool loadingNotes = false;
  String? deleteError;
  final Set<String> _deletingIds = {};

  bool isDeleting(String noteId) => _deletingIds.contains(noteId);

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  Future<void> init() async {
    try {
      final site = await _sites.activeSite();
      _siteId = site.siteId;
    } on ApiFailure {
      _siteId = '';
    }
    notifyListeners();
    await loadNotes();
  }

  Future<void> loadNotes() async {
    if (_siteId.isEmpty) return;
    loadingNotes = true;
    notifyListeners();
    try {
      pastNotes = await _speech.notes(siteId: _siteId);
    } on ApiFailure {

    } finally {
      loadingNotes = false;
      notifyListeners();
    }
  }






  Future<void> startListening() async {
    message = null;
    transcript = '';
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        stage = VoiceStage.unavailable;
        message = 'Microphone permission is required to record voice notes. '
            'Enable it in your device settings and try again.';
        notifyListeners();
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_note_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _recordingPath = path;
      _recordingStartedAt = DateTime.now();
      stage = VoiceStage.listening;
      notifyListeners();

      _amplitudeSub?.cancel();
      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 200))
          .listen((amp) {


        final normalized = ((amp.current + 45) / 45).clamp(0.0, 1.0);
        soundLevel = normalized * 10;
        notifyListeners();
      });
    } catch (e) {
      stage = VoiceStage.unavailable;
      message = 'Could not start recording: $e';
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    soundLevel = 0;

    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {

    }
    _recordingPath = path ?? _recordingPath;
    final durationSeconds = _recordingStartedAt == null
        ? 0
        : DateTime.now().difference(_recordingStartedAt!).inSeconds;

    if (_recordingPath == null) {
      stage = VoiceStage.idle;
      message = 'Recording failed. Please try again.';
      notifyListeners();
      return;
    }

    stage = VoiceStage.transcribing;
    notifyListeners();

    try {
      final bytes = await File(_recordingPath!).readAsBytes();
      final result = await _speech.transcribe(
        audioBytes: bytes,
        durationSeconds: durationSeconds,
      );
      transcript = result.transcript;
      message = null;
    } on ApiFailure catch (e) {


      message = 'Could not transcribe: ${e.message}';
    } catch (e) {
      message = 'Could not transcribe: $e';
    }
    stage = VoiceStage.ready;
    notifyListeners();
  }

  void updateTranscript(String value) {
    transcript = value;
  }

  Future<bool> save() async {
    if (_siteId.isEmpty || transcript.trim().isEmpty) return false;
    saving = true;
    notifyListeners();
    List<int>? audioBytes;
    final path = _recordingPath;
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          audioBytes = await file.readAsBytes();
        }
      } catch (_) {
        audioBytes = null;
      }
    }
    try {
      await _speech.saveNote(
        siteId: _siteId,
        transcript: transcript.trim(),
        audioBytes: audioBytes,
      );
      await loadNotes();
      await _cleanupRecording();
      stage = VoiceStage.idle;
      transcript = '';
      return true;
    } on ApiFailure {
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> _cleanupRecording() async {
    final path = _recordingPath;
    _recordingPath = null;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {

    }
  }



  Future<bool> deleteNote(String noteId) async {
    _deletingIds.add(noteId);
    deleteError = null;
    notifyListeners();
    try {
      await _speech.deleteNote(noteId);
      pastNotes.removeWhere((n) => n.id == noteId);
      return true;
    } on ApiFailure catch (e) {
      deleteError = e.message;
      return false;
    } catch (e) {
      deleteError = 'Could not delete the voice note: $e';
      return false;
    } finally {
      _deletingIds.remove(noteId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _amplitudeSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
