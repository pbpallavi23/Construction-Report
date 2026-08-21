import 'package:flutter/foundation.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/utils/view_state.dart';
import '../../../dashboard/data/models/site.dart';
import '../../../dashboard/data/repositories/site_repository.dart';
import '../../data/models/incident_report.dart';
import '../../data/repositories/incident_report_repository.dart';







class IncidentReportController extends ChangeNotifier {
  IncidentReportController({
    required IncidentReportRepository repository,
    required SiteRepository siteRepository,
  })  : _repo = repository,
        _sites = siteRepository;

  final IncidentReportRepository _repo;
  final SiteRepository _sites;

  ViewState<Site> site = const ViewState.idle();
  IncidentOptions options = IncidentOptions.empty;

  Map<String, String?> fields = {};
  bool hasGenerated = false;
  bool aiAvailable = false;
  List<String> usedPictureIds = [];
  List<String> usedNoteIds = [];

  bool generating = false;
  bool approving = false;
  ApiFailure? generateError;

  IncidentReport? approved;

  int get aiFilledFieldCount =>
      fields.values.where((v) => v != null && v.trim().isNotEmpty).length;

  Future<void> init() async {
    site = const ViewState.loading();
    notifyListeners();
    try {
      final results = await Future.wait([
        _sites.activeSite(),
        _repo.options(),
      ]);
      site = ViewState.success(results[0] as Site);
      options = results[1] as IncidentOptions;
    } on ApiFailure catch (e) {
      site = ViewState.error(e);
    }
    notifyListeners();
  }

  Future<void> generate() async {
    final siteId = site.data?.siteId;
    if (siteId == null) return;
    generating = true;
    generateError = null;
    notifyListeners();
    try {
      final draft = await _repo.generate(siteId);
      fields = draft.fields;
      aiAvailable = draft.aiAvailable;
      usedPictureIds = draft.usedPictureIds;
      usedNoteIds = draft.usedNoteIds;
      hasGenerated = true;
    } on ApiFailure catch (e) {
      generateError = e;
    } finally {
      generating = false;
      notifyListeners();
    }
  }


  void startBlank() {
    fields = {};
    aiAvailable = false;
    usedPictureIds = [];
    usedNoteIds = [];
    hasGenerated = true;
    notifyListeners();
  }

  void setField(String key, String? value) {
    final trimmed = value?.trim();
    fields[key] = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    notifyListeners();
  }

  List<String> validate() {
    final missing = <String>[];
    if ((fields['incident_type'] ?? '').isEmpty) {
      missing.add('Type of Incident');
    }
    if ((fields['description'] ?? '').isEmpty) {
      missing.add('Description of Incident');
    }
    return missing;
  }

  Future<bool> approve() async {
    final siteId = site.data?.siteId;
    if (siteId == null) return false;
    approving = true;
    notifyListeners();
    try {
      approved = await _repo.approve(siteId: siteId, fields: fields);
      return true;
    } on ApiFailure {
      return false;
    } finally {
      approving = false;
      notifyListeners();
    }
  }
}
