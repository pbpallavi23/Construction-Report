import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/models/incident_report.dart';
import '../../data/repositories/incident_report_repository.dart';
import '../controllers/incident_reports_list_controller.dart';
import '../incident_field_specs.dart';

class IncidentReportsListScreen extends StatelessWidget {
  const IncidentReportsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IncidentReportsListController(
        context.read<IncidentReportRepository>(),
      )..load(),
      child: const _IncidentReportsListView(),
    );
  }
}

class _IncidentReportsListView extends StatelessWidget {
  const _IncidentReportsListView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = context.watch<IncidentReportsListController>();

    return Scaffold(
      appBar: const AppTopBar(),
      body: RefreshIndicator(
        onRefresh: c.load,
        child: Builder(builder: (_) {
          if (c.state.isLoading && !c.state.hasData) {
            return const LoadingView(label: 'Loading incident reports…');
          }
          if (c.state.isError) {
            return ListView(children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.7,
                child: ErrorView(failure: c.state.failure!, onRetry: c.load),
              ),
            ]);
          }
          final reports = c.state.data ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin,
                AppSpacing.stackLg, AppSpacing.pageMargin, AppSpacing.stackXl),
            children: [
              Text('Incident Reports',
                  style:
                      AppTypography.headlineXl.copyWith(color: scheme.primary)),
              const SizedBox(height: 4),
              Text('AI-assisted reports approved for this account',
                  style: AppTypography.bodyMd
                      .copyWith(color: scheme.onSurfaceVariant)),
              AppSpacing.gapLg,
              PrimaryButton(
                label: 'NEW INCIDENT REPORT',
                icon: Icons.auto_awesome_rounded,
                onPressed: () async {
                  await context.push(AppRoutes.newIncidentReport);
                  if (context.mounted) c.load();
                },
              ),
              AppSpacing.gapLg,
              if (reports.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: EmptyView(
                    icon: Icons.health_and_safety_outlined,
                    title: 'No incident reports yet',
                    message:
                        'Approved incident reports for this site will appear here.',
                  ),
                )
              else
                ...reports.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                      child: _IncidentReportCard(
                        report: r,
                        isDeleting: c.isDeleting(r.id),
                        onTap: () => context.push(
                          AppRoutes.incidentReportDetail,
                          extra: r.id,
                        ),
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete incident report?'),
                              content: const Text(
                                  'This removes the report from the site '
                                  'record. This can\'t be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.danger),
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true || !context.mounted) return;
                          final ok = await c.delete(r.id);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(c.deleteError ??
                                    'Could not delete the report.'),
                              ),
                            );
                          }
                        },
                      ),
                    )),
            ],
          );
        }),
      ),
    );
  }
}

class _IncidentReportCard extends StatelessWidget {
  const _IncidentReportCard({
    required this.report,
    required this.onTap,
    required this.onDelete,
    required this.isDeleting,
  });
  final IncidentReport report;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final incidentType = report.fields['incident_type'];
    final category = report.fields['category'];
    final description = report.fields['description'];

    return InkWell(
      borderRadius: AppRadius.lgAll,
      onTap: onTap,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(report.reportDate,
                      style: AppTypography.labelLg
                          .copyWith(color: scheme.onSurfaceVariant)),
                ),
                StatusPill.success('Signed off'),
                const SizedBox(width: 4),
                if (isDeleting)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 18, color: scheme.outline),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              incidentType == null
                  ? 'Type not recorded'
                  : titleCaseWords(incidentType),
              style: AppTypography.bodyMd.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (category != null) ...[
              const SizedBox(height: 4),
              Text(category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMd
                      .copyWith(color: scheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 10),
            Text(
              (description == null || description.isEmpty)
                  ? 'No description recorded.'
                  : description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.visibility_outlined, size: 14, color: scheme.outline),
                const SizedBox(width: 4),
                Text('Tap to view full report',
                    style: AppTypography.labelMd.copyWith(color: scheme.outline)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
