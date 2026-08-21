import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/site.dart';
import '../../data/repositories/site_repository.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/action_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          DashboardController(siteRepository: context.read<SiteRepository>())
            ..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();
    final user = context.watch<AuthController>().user;
    final siteState = controller.site;

    return Scaffold(
      appBar: AppTopBar(leadingInitials: user?.initials),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Builder(
          builder: (context) {
            if (siteState.isLoading && !siteState.hasData) {
              return const LoadingView(label: 'Loading site…');
            }
            if (siteState.isError) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: ErrorView(
                      failure: siteState.failure!,
                      onRetry: controller.load,
                    ),
                  ),
                ],
              );
            }
            final site = siteState.data;
            if (site == null) return const SizedBox.shrink();
            return _content(context, site);
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Site site) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageMargin,
        AppSpacing.stackLg,
        AppSpacing.pageMargin,
        AppSpacing.stackXl,
      ),
      children: [
        InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: () => context.push(AppRoutes.siteInfo),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(
                      label: 'ACTIVE SITE',
                      color: AppColors.primary,
                      showDot: false,
                      filled: true,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Site ID: ${site.siteCode}',
                      style: AppTypography.labelLg.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        site.siteName,
                        style: AppTypography.headlineXl.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: scheme.outline),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      site.address,
                      style: AppTypography.labelLg.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (site.phase != null) ...[AppSpacing.gapLg, _PhaseCard(site: site)],
        AppSpacing.gapXl,

        Text(
          'Quick Actions',
          style: AppTypography.headlineMd.copyWith(color: scheme.primary),
        ),
        AppSpacing.gapMd,
        ActionCard(
          icon: Icons.photo_camera_rounded,
          title: 'Capture Photo',
          subtitle: 'Instant site visual logs',
          onTap: () => context.go(AppRoutes.camera),
        ),
        AppSpacing.gapMd,
        ActionCard(
          icon: Icons.mic_rounded,
          title: 'Voice Notes',
          subtitle: 'Dictate field observations',
          onTap: () => context.push(AppRoutes.voiceNotes),
        ),
        AppSpacing.gapMd,
        ActionCard(
          icon: Icons.health_and_safety_rounded,
          title: 'Incident Reports',
          subtitle: 'AI-assisted drafting & sign-off',
          iconBg: AppColors.secondaryContainer,
          iconColor: AppColors.onSecondaryContainer,
          onTap: () => context.go(AppRoutes.incidentReports),
        ),
        AppSpacing.gapXl,
      ],
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.site});
  final Site site;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.ambientShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.timeline_rounded,
              color: AppColors.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PHASE',
                  style: AppTypography.labelMd.copyWith(
                    color: scheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  site.phase!,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
