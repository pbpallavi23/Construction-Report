import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConfig {
  const AppConfig._();

  static const String appName = 'Baxall Site Assistant';

  static const String apiPrefix = '/api/v1';

  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {
      return 'http://localhost:8000';
    }
    return 'http://localhost:8000';
  }

  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static const String demoEmail = 'j.smith@baxall.co.uk';
  static const String demoPassword = 'baxall123';
}
