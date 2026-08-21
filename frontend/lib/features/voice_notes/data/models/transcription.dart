class Transcription {
  const Transcription({
    required this.transcript,
    required this.confidence,
    required this.durationSeconds,
    required this.processingMs,
  });

  final String transcript;
  final double confidence;
  final int durationSeconds;
  final int processingMs;

  factory Transcription.fromJson(Map<String, dynamic> json) => Transcription(
        transcript: json['transcript'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        durationSeconds: (json['duration_seconds'] as num).toInt(),
        processingMs: (json['processing_ms'] as num).toInt(),
      );
}

class VoiceNote {
  const VoiceNote({
    required this.id,
    required this.siteId,
    required this.transcript,
    required this.createdAt,
    this.userId,
    this.filePath,
  });

  final String id;
  final String siteId;
  final String transcript;
  final String createdAt;
  final String? userId;
  final String? filePath;

  bool get hasAudio => filePath != null && filePath!.isNotEmpty;




  String url(String baseUrl) => '$baseUrl/uploads/$filePath';

  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote(
        id: json['id'] as String,
        siteId: json['site_id'] as String,
        transcript: json['transcript'] as String,
        createdAt: (json['created_at'] as String?) ?? '',
        userId: json['user_id'] as String?,
        filePath: json['file_path'] as String?,
      );
}
