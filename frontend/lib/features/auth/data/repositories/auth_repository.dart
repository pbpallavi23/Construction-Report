import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/assistant.dart';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<({String token, Assistant assistant})> login({
    required String email,
    required String password,
    bool rememberDevice = true,
  }) async {
    final data = await _api.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
      'remember_device': rememberDevice,
    }) as Map<String, dynamic>;

    return (
      token: data['access_token'] as String,
      assistant: Assistant.fromJson(data['assistant'] as Map<String, dynamic>),
    );
  }

  Future<Assistant> me() async {
    final data = await _api.get(ApiEndpoints.me) as Map<String, dynamic>;
    return Assistant.fromJson(data);
  }

  Future<Assistant> profile() async {
    final data = await _api.get(ApiEndpoints.profile) as Map<String, dynamic>;
    return Assistant.fromJson(data);
  }

  Future<Assistant> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final data = await _api.patch(ApiEndpoints.profile, data: {
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }) as Map<String, dynamic>;
    return Assistant.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {
    }
  }
}
