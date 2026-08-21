class OcrField {
  const OcrField({required this.label, required this.value});
  final String label;
  final String value;

  factory OcrField.fromJson(Map<String, dynamic> json) =>
      OcrField(label: json['label'] as String, value: json['value'] as String);
}

class Picture {
  const Picture({
    required this.id,
    required this.siteId,
    required this.filePath,
    required this.createdAt,
    this.userId,
    this.caption,
  });

  final String id;
  final String siteId;
  final String filePath;
  final String createdAt;
  final String? userId;
  final String? caption;




  String url(String baseUrl) => '$baseUrl/uploads/$filePath';

  factory Picture.fromJson(Map<String, dynamic> json) => Picture(
    id: json['id'] as String,
    siteId: json['site_id'] as String,
    filePath: json['file_path'] as String,
    createdAt: (json['created_at'] as String?) ?? '',
    userId: json['user_id'] as String?,
    caption: json['caption'] as String?,
  );
}

class OcrResult {
  const OcrResult({
    required this.documentType,
    required this.rawText,
    required this.fields,
    required this.confidence,
    required this.processingMs,
  });

  final String documentType;
  final String rawText;
  final List<OcrField> fields;
  final double confidence;
  final int processingMs;

  factory OcrResult.fromJson(Map<String, dynamic> json) => OcrResult(
    documentType: json['document_type'] as String,
    rawText: (json['raw_text'] as String?) ?? '',
    fields: ((json['fields'] as List?) ?? [])
        .map((e) => OcrField.fromJson(e as Map<String, dynamic>))
        .toList(),
    confidence: (json['confidence'] as num).toDouble(),
    processingMs: (json['processing_ms'] as num).toInt(),
  );
}
