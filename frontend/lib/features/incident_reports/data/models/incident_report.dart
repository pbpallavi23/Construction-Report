




Map<String, String?> _fieldsFromJson(dynamic raw) {
  final map = (raw as Map?) ?? {};
  return map.map((k, v) => MapEntry(k.toString(), v?.toString()));
}

class IncidentOptions {
  const IncidentOptions({
    required this.incidentTypes,
    required this.categories,
    required this.bodyParts,
    required this.fieldLabels,
  });

  final List<String> incidentTypes;
  final Map<String, List<String>> categories;
  final List<String> bodyParts;
  final Map<String, String> fieldLabels;

  factory IncidentOptions.fromJson(Map<String, dynamic> json) => IncidentOptions(
        incidentTypes: List<String>.from(json['incident_types'] as List? ?? []),
        categories: ((json['categories'] as Map?) ?? {}).map(
          (k, v) => MapEntry(k.toString(), List<String>.from(v as List)),
        ),
        bodyParts: List<String>.from(json['body_parts'] as List? ?? []),
        fieldLabels: ((json['field_labels'] as Map?) ?? {})
            .map((k, v) => MapEntry(k.toString(), v.toString())),
      );

  static const empty = IncidentOptions(
    incidentTypes: [],
    categories: {},
    bodyParts: [],
    fieldLabels: {},
  );
}



class IncidentDraft {
  const IncidentDraft({
    required this.siteId,
    required this.fields,
    required this.aiAvailable,
    required this.usedPictureIds,
    required this.usedNoteIds,
  });

  final String siteId;
  final Map<String, String?> fields;
  final bool aiAvailable;
  final List<String> usedPictureIds;
  final List<String> usedNoteIds;

  factory IncidentDraft.fromJson(Map<String, dynamic> json) => IncidentDraft(
        siteId: json['site_id'] as String,
        fields: _fieldsFromJson(json['fields']),
        aiAvailable: json['ai_available'] as bool? ?? false,
        usedPictureIds: List<String>.from(json['used_picture_ids'] as List? ?? []),
        usedNoteIds: List<String>.from(json['used_note_ids'] as List? ?? []),
      );
}


class IncidentReport {
  const IncidentReport({
    required this.id,
    required this.siteId,
    required this.status,
    required this.reportDate,
    required this.fields,
  });

  final String id;
  final String siteId;
  final String status;
  final String reportDate;
  final Map<String, String?> fields;

  factory IncidentReport.fromJson(Map<String, dynamic> json) => IncidentReport(
        id: json['id'] as String,
        siteId: json['site_id'] as String,
        status: (json['status'] as String?) ?? 'signed_off',
        reportDate: (json['report_date'] as String?) ?? '',
        fields: _fieldsFromJson(json['fields']),
      );
}
