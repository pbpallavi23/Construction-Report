import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/ai/data/repositories/ai_repository.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/camera_ocr/data/repositories/ocr_repository.dart';
import 'features/dashboard/data/repositories/site_repository.dart';
import 'features/incident_reports/data/repositories/incident_report_repository.dart';
import 'features/settings/presentation/controllers/theme_controller.dart';
import 'features/voice_notes/data/repositories/speech_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final storage = await TokenStorage.create();
  final apiClient = ApiClient(storage: storage);

  final authRepository = AuthRepository(apiClient);
  final deps = AppDependencies(
    apiClient: apiClient,
    storage: storage,
    authRepository: authRepository,
    siteRepository: SiteRepository(apiClient),
    incidentReportRepository: IncidentReportRepository(apiClient),
    ocrRepository: OcrRepository(apiClient),
    speechRepository: SpeechRepository(apiClient),
    aiRepository: AiRepository(apiClient),
  );

  final authController = AuthController(
    repository: authRepository,
    storage: storage,
  );
  final themeController = ThemeController(storage);

  apiClient.onUnauthorized = authController.onSessionExpired;

  await authController.bootstrap();

  runApp(BaxallApp(
    dependencies: deps,
    authController: authController,
    themeController: themeController,
  ));
}
