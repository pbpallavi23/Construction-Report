import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _kToken = 'auth_token';
  static const _kRememberedEmail = 'remembered_email';
  static const _kThemeMode = 'theme_mode';
  static const _kAvatarPath = 'avatar_path';
  static const _kNotifications = 'notifications_enabled';

  static Future<TokenStorage> create() async =>
      TokenStorage(await SharedPreferences.getInstance());

  String? get token => _prefs.getString(_kToken);
  bool get hasToken => (token ?? '').isNotEmpty;

  Future<void> saveToken(String token) => _prefs.setString(_kToken, token);
  Future<void> clearToken() => _prefs.remove(_kToken);

  String? get rememberedEmail => _prefs.getString(_kRememberedEmail);
  Future<void> saveRememberedEmail(String? email) async {
    if (email == null || email.isEmpty) {
      await _prefs.remove(_kRememberedEmail);
    } else {
      await _prefs.setString(_kRememberedEmail, email);
    }
  }

  String get themeMode => _prefs.getString(_kThemeMode) ?? 'system';
  Future<void> saveThemeMode(String mode) => _prefs.setString(_kThemeMode, mode);

  String? get avatarPath => _prefs.getString(_kAvatarPath);
  Future<void> saveAvatarPath(String? path) async {
    if (path == null || path.isEmpty) {
      await _prefs.remove(_kAvatarPath);
    } else {
      await _prefs.setString(_kAvatarPath, path);
    }
  }

  bool get notificationsEnabled => _prefs.getBool(_kNotifications) ?? true;
  Future<void> saveNotificationsEnabled(bool enabled) =>
      _prefs.setBool(_kNotifications, enabled);

  Future<void> clearAll() async {
    await _prefs.remove(_kToken);
    await _prefs.remove(_kAvatarPath);
  }
}
