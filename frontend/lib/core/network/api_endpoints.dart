class ApiEndpoints {
  const ApiEndpoints._();

  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  static const String sites = '/sites';
  static const String activeSite = '/sites/active';
  static String site(String id) => '/sites/$id';

  static const String profile = '/profile';
  static const String assistants = '/assistants';

  static const String ocrScan = '/ocr/scan';
  static const String pictures = '/pictures';
  static String picture(String id) => '/pictures/$id';
  static const String speechTranscribe = '/speech/transcribe';
  static const String speechNotes = '/speech/notes';
  static String speechNote(String id) => '/speech/notes/$id';
  static const String aiSuggestions = '/ai/suggestions';

  static const String incidentOptions = '/reports/incident/options';
  static const String incidentGenerate = '/reports/incident/generate';
  static const String incidentApprove = '/reports/incident/approve';
  static const String incidentReports = '/reports/incident';
  static String incidentReport(String id) => '/reports/incident/$id';
  static String incidentReportPdf(String id) => '/reports/incident/$id/pdf';
}
