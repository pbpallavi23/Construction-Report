import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/ai/data/repositories/ai_repository.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/camera_ocr/data/repositories/ocr_repository.dart';
import 'features/dashboard/data/repositories/site_repository.dart';
import 'features/incident_reports/data/repositories/incident_report_repository.dart';
import 'features/settings/presentation/controllers/theme_controller.dart';
import 'features/voice_notes/data/repositories/speech_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.apiClient,
    required this.storage,
    required this.authRepository,
    required this.siteRepository,
    required this.incidentReportRepository,
    required this.ocrRepository,
    required this.speechRepository,
    required this.aiRepository,
  });

  final ApiClient apiClient;
  final TokenStorage storage;
  final AuthRepository authRepository;
  final SiteRepository siteRepository;
  final IncidentReportRepository incidentReportRepository;
  final OcrRepository ocrRepository;
  final SpeechRepository speechRepository;
  final AiRepository aiRepository;
}

class BaxallApp extends StatefulWidget {
  const BaxallApp({
    super.key,
    required this.dependencies,
    required this.authController,
    required this.themeController,
  });

  final AppDependencies dependencies;
  final AuthController authController;
  final ThemeController themeController;

  @override
  State<BaxallApp> createState() => _BaxallAppState();
}

class _BaxallAppState extends State<BaxallApp> {
  late final AppRouter _appRouter = AppRouter(widget.authController);

  @override
  Widget build(BuildContext context) {
    final d = widget.dependencies;
    return MultiProvider(
      providers: [
        Provider.value(value: d.authRepository),
        Provider.value(value: d.siteRepository),
        Provider.value(value: d.incidentReportRepository),
        Provider.value(value: d.ocrRepository),
        Provider.value(value: d.speechRepository),
        Provider.value(value: d.aiRepository),
        ChangeNotifierProvider.value(value: widget.authController),
        ChangeNotifierProvider.value(value: widget.themeController),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp.router(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
