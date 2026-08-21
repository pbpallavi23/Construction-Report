import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/camera_ocr/presentation/screens/camera_capture_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/site_info_screen.dart';
import '../../features/incident_reports/presentation/screens/incident_report_detail_screen.dart';
import '../../features/incident_reports/presentation/screens/incident_report_screen.dart';
import '../../features/incident_reports/presentation/screens/incident_reports_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/voice_notes/presentation/screens/voice_notes_screen.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter(this._auth);
  final AuthController _auth;

  static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  late final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: _auth,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) => AppShell(navigationShell: navShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.incidentReports,
              builder: (_, __) => const IncidentReportsListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.camera,
              builder: (_, __) => const CameraCaptureScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (_, __) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRoutes.newIncidentReport,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const IncidentReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.incidentReportDetail,
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            IncidentReportDetailScreen(reportId: state.extra as String),
      ),
      GoRoute(
        path: AppRoutes.voiceNotes,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const VoiceNotesScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.siteInfo,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SiteInfoScreen(),
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;

    if (_auth.isBootstrapping) {
      return loc == AppRoutes.splash ? null : AppRoutes.splash;
    }

    final loggedIn = _auth.isAuthenticated;
    final onAuthScreen = loc == AppRoutes.login || loc == AppRoutes.splash;

    if (!loggedIn) return onAuthScreen ? (loc == AppRoutes.splash ? AppRoutes.login : null) : AppRoutes.login;
    if (loggedIn && onAuthScreen) return AppRoutes.home;
    return null;
  }
}
