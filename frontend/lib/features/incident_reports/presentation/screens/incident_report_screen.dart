import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../dashboard/data/repositories/site_repository.dart';
import '../../data/repositories/incident_report_repository.dart';
import '../controllers/incident_report_controller.dart';
import '../incident_field_specs.dart';

class IncidentReportScreen extends StatelessWidget {
  const IncidentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IncidentReportController(
        repository: context.read<IncidentReportRepository>(),
        siteRepository: context.read<SiteRepository>(),
      )..init(),
      child: const _IncidentReportView(),
    );
  }
}

class _IncidentReportView extends StatefulWidget {
  const _IncidentReportView();

  @override
  State<_IncidentReportView> createState() => _IncidentReportViewState();
}

class _IncidentReportViewState extends State<_IncidentReportView> {
  final Map<String, TextEditingController> _controllers = {};
  IncidentReportController? _bound;

  TextEditingController _controllerFor(String key) =>
      _controllers.putIfAbsent(key, () => TextEditingController());

  void _syncControllersFromFields(IncidentReportController c) {
    for (final section in incidentFormSections) {
      for (final spec in section.fields) {
        if (spec.type != IncidentFieldType.text &&
            spec.type != IncidentFieldType.multiline) {
          continue;
        }
        final ctrl = _controllerFor(spec.key);
        final value = c.fields[spec.key] ?? '';
        if (ctrl.text != value) ctrl.text = value;
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _onGenerate(IncidentReportController c) async {
    await c.generate();
    if (!mounted) return;
    _syncControllersFromFields(c);
    if (c.generateError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(c.generateError!.message)),
        );
    }
  }

  Future<void> _onApprove(IncidentReportController c) async {
    final missing = c.validate();
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Please complete: ${missing.join(', ')}')),
        );
      return;
    }
    final ok = await c.approve();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Incident report approved and saved.'
                : 'Could not save the report. Check the connection.',
          ),
        ),
      );
    if (ok) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = context.watch<IncidentReportController>();
    if (!identical(_bound, c) && c.hasGenerated) {
      _bound = c;
      _syncControllersFromFields(c);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Report'),
        backgroundColor: scheme.surfaceContainerLow,
      ),
      body: Builder(builder: (_) {
        if (c.site.isLoading && !c.site.hasData) {
          return const LoadingView(label: 'Preparing incident report…');
        }
        if (c.site.isError) {
          return ErrorView(failure: c.site.failure!, onRetry: c.init);
        }
        if (!c.hasGenerated) {
          return _GenerateStep(controller: c, onGenerate: () => _onGenerate(c));
        }
        return _ReviewForm(controller: c, controllerFor: _controllerFor);
      }),
      bottomNavigationBar: c.hasGenerated
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pageMargin),
                child: SafetyButton(
                  label: 'Approve & Save',
                  icon: Icons.check_circle_outline_rounded,
                  busy: c.approving,
                  onPressed: () => _onApprove(c),
                ),
              ),
            )
          : null,
    );
  }
}

class _GenerateStep extends StatelessWidget {
  const _GenerateStep({required this.controller, required this.onGenerate});
  final IncidentReportController controller;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin,
          AppSpacing.stackXl, AppSpacing.pageMargin, AppSpacing.stackXl),
      children: [
        Icon(Icons.auto_awesome_rounded, size: 56, color: scheme.primary),
        AppSpacing.gapMd,
        Text(
          'Auto-fill from site photos & voice notes',
          style: AppTypography.headlineMd.copyWith(color: scheme.primary),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapSm,
        Text(
          'The AI will read the pictures and voice notes already saved for '
          'this site and fill in what it can find. Anything it can\'t '
          'determine is left blank for you to complete. Nothing is saved '
          'until you review and approve it.',
          style: AppTypography.bodyMd.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapXl,
        PrimaryButton(
          label: 'GENERATE DRAFT',
          icon: Icons.auto_awesome_rounded,
          busy: controller.generating,
          onPressed: onGenerate,
        ),
        AppSpacing.gapMd,
        SecondaryButton(
          label: 'Start with a blank form instead',
          onPressed: controller.generating ? null : controller.startBlank,
        ),
      ],
    );
  }
}

class _ReviewForm extends StatelessWidget {
  const _ReviewForm({required this.controller, required this.controllerFor});
  final IncidentReportController controller;
  final TextEditingController Function(String key) controllerFor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin,
          AppSpacing.stackLg, AppSpacing.pageMargin, AppSpacing.stackXl),
      children: [
        _AiSummaryBanner(controller: controller),
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
                  _FieldWidget(
                    spec: spec,
                    controller: controller,
                    textController: (spec.type == IncidentFieldType.text ||
                            spec.type == IncidentFieldType.multiline)
                        ? controllerFor(spec.key)
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
          AppSpacing.gapLg,
        ],
      ],
    );
  }
}

class _AiSummaryBanner extends StatelessWidget {
  const _AiSummaryBanner({required this.controller});
  final IncidentReportController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = controller;
    final String message;
    final IconData icon;
    final Color color;
    if (!c.aiAvailable) {
      icon = Icons.info_outline_rounded;
      color = scheme.onSurfaceVariant;
      message = 'AI auto-fill wasn\'t available, so this form starts blank. '
          'Fill in what you can below.';
    } else if (c.usedPictureIds.isEmpty && c.usedNoteIds.isEmpty) {
      icon = Icons.info_outline_rounded;
      color = scheme.onSurfaceVariant;
      message = 'No pictures or voice notes were found for this site yet, '
          'so the form starts blank.';
    } else {
      icon = Icons.auto_awesome_rounded;
      color = AppColors.success;
      message = 'Filled from ${c.usedPictureIds.length} photo(s) and '
          '${c.usedNoteIds.length} voice note(s) on this site. Review every '
          'field before approving - blank fields need your input.';
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.labelLg.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldWidget extends StatelessWidget {
  const _FieldWidget({
    required this.spec,
    required this.controller,
    this.textController,
  });

  final IncidentFieldSpec spec;
  final IncidentReportController controller;
  final TextEditingController? textController;

  Widget _labelRow(BuildContext context, {required bool aiFilled}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(spec.label,
              style: AppTypography.labelLg.copyWith(color: scheme.onSurfaceVariant)),
        ),
        if (aiFilled)
          Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.success),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = controller.fields[spec.key];
    final aiFilled = controller.aiAvailable && value != null && value.isNotEmpty;

    switch (spec.type) {
      case IncidentFieldType.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelRow(context, aiFilled: aiFilled),
            const SizedBox(height: 4),
            TextField(
              controller: textController,
              decoration: const InputDecoration(hintText: 'Not recorded — tap to fill in'),
              onChanged: (v) => controller.setField(spec.key, v),
            ),
          ],
        );
      case IncidentFieldType.multiline:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelRow(context, aiFilled: aiFilled),
            const SizedBox(height: 4),
            TextField(
              controller: textController,
              minLines: 3,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(hintText: 'Not recorded — tap to fill in'),
              onChanged: (v) => controller.setField(spec.key, v),
            ),
          ],
        );
      case IncidentFieldType.dropdownYesNo:
        return _DropdownField(
          label: spec.label,
          value: value,
          aiFilled: aiFilled,
          options: yesNoOptions,
          display: (v) => v == 'yes' ? 'Yes' : 'No',
          onChanged: (v) => controller.setField(spec.key, v),
        );
      case IncidentFieldType.dropdownIncidentType:
        return _DropdownField(
          label: spec.label,
          value: value,
          aiFilled: aiFilled,
          options: controller.options.incidentTypes,
          display: titleCaseWords,
          onChanged: (v) {
            controller.setField(spec.key, v);


            final current = controller.fields['category'];
            final valid = controller.options.categories[v] ?? const [];
            if (current != null && !valid.contains(current)) {
              controller.setField('category', null);
            }
          },
        );
      case IncidentFieldType.dropdownCategory:
        final incidentType = controller.fields['incident_type'];
        final options = incidentType == null
            ? const <String>[]
            : controller.options.categories[incidentType] ?? const [];
        return _DropdownField(
          label: spec.label,
          value: value,
          aiFilled: aiFilled,
          options: options,
          display: (v) => v,
          enabled: options.isNotEmpty,
          hintWhenDisabled: 'Choose a type of incident first',
          onChanged: (v) => controller.setField(spec.key, v),
        );
      case IncidentFieldType.dropdownBodyPart:
        return _DropdownField(
          label: spec.label,
          value: value,
          aiFilled: aiFilled,
          options: controller.options.bodyParts,
          display: (v) => v,
          onChanged: (v) => controller.setField(spec.key, v),
        );
    }
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.aiFilled,
    required this.options,
    required this.display,
    required this.onChanged,
    this.enabled = true,
    this.hintWhenDisabled,
  });

  final String label;
  final String? value;
  final bool aiFilled;
  final List<String> options;
  final String Function(String) display;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String? hintWhenDisabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final validValue = options.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTypography.labelLg.copyWith(color: scheme.onSurfaceVariant)),
            ),
            if (aiFilled)
              Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.success),
          ],
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: validValue,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: enabled
                ? 'Not recorded — tap to select'
                : (hintWhenDisabled ?? 'Not available'),
          ),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(display(o))))
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
