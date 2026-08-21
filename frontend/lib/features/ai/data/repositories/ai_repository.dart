import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ai_suggestion.dart';

class AiRepository {
  AiRepository(this._api);
  final ApiClient _api;

  Future<List<AiSuggestion>> suggestions({
    required String context,
    String? siteId,
    String? prompt,
  }) async {
    final data = await _api.post(ApiEndpoints.aiSuggestions, data: {
      'context': context,
      if (siteId != null) 'site_id': siteId,
      if (prompt != null) 'prompt': prompt,
    }) as Map<String, dynamic>;
    return ((data['suggestions'] as List?) ?? [])
        .map((e) => AiSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
