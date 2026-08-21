import '../../../auth/data/models/assistant.dart';

class Site {
  const Site({
    required this.siteId,
    required this.siteName,
    required this.siteCode,
    required this.address,
    required this.status,
    this.phase,
    this.assignedAssistant,
    this.latitude,
    this.longitude,
  });

  final String siteId;
  final String siteName;
  final String siteCode;
  final String address;
  final String status;
  final String? phase;
  final Assistant? assignedAssistant;

  final double? latitude;
  final double? longitude;

  factory Site.fromJson(Map<String, dynamic> json) => Site(
        siteId: json['site_id'] as String,
        siteName: json['site_name'] as String,
        siteCode: json['site_code'] as String,
        address: json['address'] as String,
        status: (json['status'] as String?) ?? 'active',
        phase: json['phase'] as String?,
        assignedAssistant: json['assigned_assistant'] == null
            ? null
            : Assistant.fromJson(
                json['assigned_assistant'] as Map<String, dynamic>),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
