class AiSuggestion {
  const AiSuggestion({
    required this.title,
    required this.text,
    required this.confidence,
  });

  final String title;
  final String text;
  final double confidence;

  factory AiSuggestion.fromJson(Map<String, dynamic> json) => AiSuggestion(
        title: json['title'] as String,
        text: json['text'] as String,
        confidence: (json['confidence'] as num).toDouble(),
      );
}
