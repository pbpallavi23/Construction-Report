import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/transcription.dart';

class SpeechRepository {
  SpeechRepository(this._api);
  final ApiClient _api;

  Future<Transcription> transcribe({
    List<int>? audioBytes,
    int? durationSeconds,
  }) async {
    final form = FormData.fromMap({
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    });
    if (audioBytes != null) {
      form.files.add(MapEntry(
        'file',
        MultipartFile.fromBytes(audioBytes, filename: 'note.m4a'),
      ));
    }
    final data =
        await _api.postMultipart(ApiEndpoints.speechTranscribe, data: form)
            as Map<String, dynamic>;
    return Transcription.fromJson(data);
  }

  Future<VoiceNote> saveNote({
    required String siteId,
    required String transcript,
    List<int>? audioBytes,
    String audioFilename = 'note.m4a',
  }) async {
    Map<String, dynamic> data;
    if (audioBytes != null) {


      final form = FormData.fromMap({
        'site_id': siteId,
        'transcript': transcript,
      });
      form.files.add(MapEntry(
        'file',
        MultipartFile.fromBytes(audioBytes, filename: audioFilename),
      ));
      data = await _api.postMultipart(ApiEndpoints.speechNotes, data: form)
          as Map<String, dynamic>;
    } else {
      data = await _api.post(ApiEndpoints.speechNotes, data: {
        'site_id': siteId,
        'transcript': transcript,
      }) as Map<String, dynamic>;
    }
    return VoiceNote.fromJson(data);
  }

  Future<List<VoiceNote>> notes({String? siteId}) async {
    final data = await _api.get(
      ApiEndpoints.speechNotes,
      query: siteId == null ? null : {'site_id': siteId},
    ) as List;
    return data
        .map((e) => VoiceNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteNote(String noteId) async {
    await _api.delete(ApiEndpoints.speechNote(noteId));
  }
}
