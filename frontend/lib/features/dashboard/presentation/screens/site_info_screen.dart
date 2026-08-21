import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/models/site.dart';
import '../../data/repositories/site_repository.dart';

class SiteInfoScreen extends StatefulWidget {
  const SiteInfoScreen({super.key});

  @override
  State<SiteInfoScreen> createState() => _SiteInfoScreenState();
}

class _SiteInfoScreenState extends State<SiteInfoScreen> {
  late SiteRepository _repo;
  ApiFailure? _error;
  bool _loading = true;
  Site? _site;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = context.read<SiteRepository>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final site = await _repo.activeSite();
      if (!mounted) return;
      setState(() {
        _site = site;
        _error = null;
        _loading = false;
      });
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Information'),
        actions: [
          if (_site != null)
            IconButton(
              tooltip: 'Edit site info',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editSite(_site!),
            ),
        ],
      ),
      body: Builder(builder: (context) {
        if (_loading) return const LoadingView(label: 'Loading site…');
        if (_error != null) {
          return ErrorView(failure: _error!, onRetry: _load);
        }
        final site = _site!;
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageMargin),
            children: [
              Text(site.siteName,
                  style: AppTypography.headlineXl
                      .copyWith(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 4),
              Text('Site ID: ${site.siteCode}',
                  style: AppTypography.labelLg.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              AppSpacing.gapLg,

              Text('SITE DETAILS',
                  style: AppTypography.labelLg.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              _InfoCard(children: [
                _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: site.address),
                _InfoRow(
                    icon: Icons.timeline_rounded,
                    label: 'Phase',
                    value: site.phase ?? 'Not set'),
                _InfoRow(
                    icon: Icons.my_location_rounded,
                    label: 'Coordinates',
                    value: (site.latitude != null && site.longitude != null)
                        ? '${site.latitude!.toStringAsFixed(4)}, ${site.longitude!.toStringAsFixed(4)}'
                        : 'Not set'),
                _InfoRow(
                    icon: Icons.flag_outlined,
                    label: 'Status',
                    value: site.status),
                if (site.assignedAssistant != null)
                  _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Site engineer',
                      value: site.assignedAssistant!.fullName),
              ]),
              AppSpacing.gapMd,
              Text(
                'Name, location, phase and coordinates are entered manually.',
                style: AppTypography.labelMd.copyWith(
                    color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _editSite(Site site) async {
    final nameCtl = TextEditingController(text: site.siteName);
    final addrCtl = TextEditingController(text: site.address);
    final phaseCtl = TextEditingController(text: site.phase ?? '');
    final latCtl =
        TextEditingController(text: site.latitude?.toString() ?? '');
    final lonCtl =
        TextEditingController(text: site.longitude?.toString() ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.pageMargin,
          right: AppSpacing.pageMargin,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.pageMargin,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit site information',
                  style: AppTypography.headlineMd.copyWith(
                      color: Theme.of(ctx).colorScheme.primary)),
              const SizedBox(height: 16),
              _field(nameCtl, 'Site name'),
              const SizedBox(height: 12),
              _field(addrCtl, 'Location / address'),
              const SizedBox(height: 12),
              _field(phaseCtl, 'Phase'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _field(latCtl, 'Latitude',
                          keyboard: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field(lonCtl, 'Longitude',
                          keyboard: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.touchTargetLg,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      try {
        await _repo.updateSite(
          site.siteId,
          siteName: nameCtl.text.trim(),
          address: addrCtl.text.trim(),
          phase: phaseCtl.text.trim(),
          latitude: double.tryParse(latCtl.text.trim()),
          longitude: double.tryParse(lonCtl.text.trim()),
        );
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
                const SnackBar(content: Text('Site information updated.')));
        }
      } on ApiFailure catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
    nameCtl.dispose();
    addrCtl.dispose();
    phaseCtl.dispose();
    latCtl.dispose();
    lonCtl.dispose();
  }

  Widget _field(TextEditingController c, String label,
          {TextInputType? keyboard}) =>
      TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, color: scheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(icon, color: scheme.primary),
      title: Text(label,
          style: AppTypography.labelMd.copyWith(color: scheme.onSurfaceVariant)),
      subtitle: Text(value,
          style: AppTypography.bodyLg.copyWith(
              color: scheme.onSurface, fontWeight: FontWeight.w600)),
    );
  }
}
