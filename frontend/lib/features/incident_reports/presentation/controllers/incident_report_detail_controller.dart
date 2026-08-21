import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/utils/view_state.dart';
import '../../data/repositories/incident_report_repository.dart';
import '../../data/models/incident_report.dart';

class IncidentReportDetailController extends ChangeNotifier {
  IncidentReportDetailController(this._repo);
  final IncidentReportRepository _repo;

  ViewState<IncidentReport> state = const ViewState.idle();

  bool deleting = false;
  String? deleteError;

  bool exporting = false;
  String? exportError;
  String? exportedFilePath;

  Future<void> load(String id) async {
    state = const ViewState.loading();
    notifyListeners();
    try {
      state = ViewState.success(await _repo.get(id));
    } on ApiFailure catch (e) {
      state = ViewState.error(e);
    }
    notifyListeners();
  }



  Future<bool> delete(String id) async {
    deleting = true;
    deleteError = null;
    notifyListeners();
    try {
      await _repo.delete(id);
      return true;
    } on ApiFailure catch (e) {
      deleteError = e.message;
      return false;
    } catch (e) {
      deleteError = 'Could not delete the report: $e';
      return false;
    } finally {
      deleting = false;
      notifyListeners();
    }
  }




  Future<String?> exportPdf(String id) async {
    exporting = true;
    exportError = null;
    exportedFilePath = null;
    notifyListeners();
    try {
      final bytes = await _repo.pdfBytes(id);
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/Incident_Report_$id.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      exportedFilePath = path;
      return path;
    } on ApiFailure catch (e) {
      exportError = e.message;
      return null;
    } catch (e) {
      exportError = 'Could not download the report: $e';
      return null;
    } finally {
      exporting = false;
      notifyListeners();
    }
  }
}
