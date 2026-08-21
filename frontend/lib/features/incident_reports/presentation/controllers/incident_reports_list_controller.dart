import 'package:flutter/foundation.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/utils/view_state.dart';
import '../../data/models/incident_report.dart';
import '../../data/repositories/incident_report_repository.dart';

class IncidentReportsListController extends ChangeNotifier {
  IncidentReportsListController(this._repo);
  final IncidentReportRepository _repo;

  ViewState<List<IncidentReport>> state = const ViewState.idle();

  String? deleteError;
  final Set<String> _deletingIds = {};

  bool isDeleting(String reportId) => _deletingIds.contains(reportId);

  Future<void> load() async {
    state = const ViewState.loading();
    notifyListeners();
    try {
      state = ViewState.success(await _repo.list());
    } on ApiFailure catch (e) {
      state = ViewState.error(e);
    }
    notifyListeners();
  }



  Future<bool> delete(String reportId) async {
    _deletingIds.add(reportId);
    deleteError = null;
    notifyListeners();
    try {
      await _repo.delete(reportId);
      final current = state.data;
      if (current != null) {
        state = ViewState.success(
          current.where((r) => r.id != reportId).toList(),
        );
      }
      return true;
    } on ApiFailure catch (e) {
      deleteError = e.message;
      return false;
    } catch (e) {
      deleteError = 'Could not delete the report: $e';
      return false;
    } finally {
      _deletingIds.remove(reportId);
      notifyListeners();
    }
  }
}
