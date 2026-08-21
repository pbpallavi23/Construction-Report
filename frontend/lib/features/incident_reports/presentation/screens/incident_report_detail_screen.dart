import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/repositories/incident_report_repository.dart';
import '../controllers/incident_report_detail_controller.dart';
import '../incident_field_specs.dart';

class IncidentReportDetailScreen extends StatelessWidget {
  const IncidentReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IncidentReportDetailController(
        context.read<IncidentReportRepository>(),
      )..load(reportId),
      child: _IncidentReportDetailView(reportId: reportId),
    );
  }
}

class _IncidentReportDetailView extends StatelessWidget {
  const _IncidentReportDetailView({required this.reportId});
  final String reportId;

  Future<void> _confirmDelete(BuildContext context) async {
    final c = context.read<IncidentReportDetailController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete incident report?'),
        content: const Text(
            'This removes the report from the site record. This can\'t be '
            'undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await c.delete(reportId);
    if (!context.mounted) return;
    if (ok) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(c.deleteError ?? 'Could not delete the report.')),
      );
    }
  }

  Future<void> _export(BuildContext context) async {
    final c = context.read<IncidentReportDetailController>();
    final path = await c.exportPdf(reportId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(path != null
            ? 'Saved report PDF to $path'
            : (c.exportError ?? 'Could not download the report.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = context.watch<IncidentReportDetailController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Report'),
        backgroundColor: scheme.surfaceContainerLow,
        actions: [
          if (c.state.hasData) ...[
            IconButton(
              tooltip: 'Download PDF',
              icon: c.exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              onPressed: c.exporting ? null : () => _export(context),
            ),
            IconButton(
              tooltip: 'Delete report',
              icon: c.deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              onPressed: c.deleting ? null : () => _confirmDelete(context),
            ),
          ],
        ],
      ),
      body: Builder(builder: (_) {
        if (c.state.isLoading && !c.state.hasData) {
          return const LoadingView(label: 'Loading report…');
        }
        if (c.state.isError) {
          return ErrorView(
            failure: c.state.failure!,
            onRetry: () => c.load(reportId),
          );
        }
        final report = c.state.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin,
              AppSpacing.stackLg, AppSpacing.pageMargin, AppSpacing.stackXl),
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(report.reportDate,
                      style: AppTypography.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant)),
                ),
                StatusPill.success('Signed off'),
              ],
            ),
            AppSpacing.gapSm,
            Text(
              'This report is signed off — its fields are a locked record '
              'and cannot be edited. Use the PDF icon to download the '
              'official-format copy, or Delete to remove it.',
              style: AppTypography.labelMd.copyWith(color: scheme.onSurfaceVariant),
            ),
            AppSpacing.gapLg,
            for (final section in incidentFormSections) ...[
              Row(
                children: [
                  Icon(section.icon, color: scheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      section.title,
                      style: AppTypography.headlineMd.copyWith(color: scheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    for (final spec in section.fields) ...[
                      _ReadOnlyField(
                        label: spec.label,
                        value: displayFieldValue(spec, report.fields[spec.key]),
                        isBlank: (report.fields[spec.key] ?? '').isEmpty,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapLg,
            ],
          ],
        );
      }),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.isBlank,
  });

  final String label;
  final String value;
  final bool isBlank;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelLg.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMd.copyWith(
            color: isBlank ? scheme.outline : scheme.onSurface,
            fontStyle: isBlank ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}
