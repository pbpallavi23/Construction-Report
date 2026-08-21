import 'package:flutter/foundation.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/models/assistant.dart';
import '../../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required this._storage,
  })  : _repo = repository;

  final AuthRepository _repo;
  final TokenStorage _storage;

  Assistant? _user;
  Assistant? get user => _user;

  bool _bootstrapping = true;

  bool get isBootstrapping => _bootstrapping;

  bool get isAuthenticated => _user != null && _storage.hasToken;

  bool _loginBusy = false;
  bool get isLoginBusy => _loginBusy;

  ApiFailure? _loginError;
  ApiFailure? get loginError => _loginError;

  String? get rememberedEmail => _storage.rememberedEmail;

  String? get localAvatarPath => _storage.avatarPath;

  bool get notificationsEnabled => _storage.notificationsEnabled;

  Future<void> setLocalAvatar(String? path) async {
    await _storage.saveAvatarPath(path);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _storage.saveNotificationsEnabled(enabled);
    notifyListeners();
  }

  Future<bool> updateProfile({String? fullName, String? phone}) async {
    try {
      _user = await _repo.updateProfile(fullName: fullName, phone: phone);
      notifyListeners();
      return true;
    } on ApiFailure {
      return false;
    }
  }

  Future<void> bootstrap() async {
    if (_storage.hasToken) {
      try {
        _user = await _repo.me();
      } on ApiFailure {
        await _storage.clearToken();
        _user = null;
      }
    }
    _bootstrapping = false;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
    required bool rememberDevice,
  }) async {
    _loginBusy = true;
    _loginError = null;
    notifyListeners();
    try {
      final result = await _repo.login(
        email: email.trim(),
        password: password,
        rememberDevice: rememberDevice,
      );
      await _storage.saveToken(result.token);
      await _storage.saveRememberedEmail(rememberDevice ? email.trim() : null);
      _user = result.assistant;
      _loginBusy = false;
      notifyListeners();
      return true;
    } on ApiFailure catch (e) {
      _loginError = e;
      _loginBusy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    await _storage.clearToken();
    await _storage.saveAvatarPath(null);
    _user = null;
    notifyListeners();
  }

  void onSessionExpired() {
    _user = null;
    _storage.clearToken();
    notifyListeners();
  }
}
