import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/incident_report.dart';

class IncidentReportRepository {
  IncidentReportRepository(this._api);
  final ApiClient _api;

  Future<IncidentOptions> options() async {
    final data =
        await _api.get(ApiEndpoints.incidentOptions) as Map<String, dynamic>;
    return IncidentOptions.fromJson(data);
  }







  Future<IncidentDraft> generate(String siteId) async {
    final data = await _api.post(
      ApiEndpoints.incidentGenerate,
      data: {'site_id': siteId},
      receiveTimeout: const Duration(minutes: 3),
    ) as Map<String, dynamic>;
    return IncidentDraft.fromJson(data);
  }



  Future<IncidentReport> approve({
    required String siteId,
    required Map<String, String?> fields,
  }) async {
    final data = await _api.post(
      ApiEndpoints.incidentApprove,
      data: {'site_id': siteId, 'fields': fields},
    ) as Map<String, dynamic>;
    return IncidentReport.fromJson(data);
  }

  Future<List<IncidentReport>> list({String? siteId}) async {
    final data = await _api.get(
      ApiEndpoints.incidentReports,
      query: siteId == null ? null : {'site_id': siteId},
    ) as List;
    return data
        .map((e) => IncidentReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<IncidentReport> get(String id) async {
    final data =
        await _api.get(ApiEndpoints.incidentReport(id)) as Map<String, dynamic>;
    return IncidentReport.fromJson(data);
  }


  Future<void> delete(String id) async {
    await _api.delete(ApiEndpoints.incidentReport(id));
  }





  Future<List<int>> pdfBytes(String id) =>
      _api.getBytes(ApiEndpoints.incidentReportPdf(id));
}
