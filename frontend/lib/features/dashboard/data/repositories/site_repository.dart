import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/site.dart';

class SiteRepository {
  SiteRepository(this._api);
  final ApiClient _api;

  Future<Site> activeSite() async {
    final data = await _api.get(ApiEndpoints.activeSite) as Map<String, dynamic>;
    return Site.fromJson(data);
  }

  Future<List<Site>> sites({bool mine = false}) async {
    final data = await _api.get(
      ApiEndpoints.sites,
      query: mine ? {'mine': true} : null,
    ) as List;
    return data
        .map((e) => Site.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Site> site(String id) async {
    final data = await _api.get(ApiEndpoints.site(id)) as Map<String, dynamic>;
    return Site.fromJson(data);
  }

  Future<Site> updateSite(
    String id, {
    String? siteName,
    String? address,
    String? phase,
    double? latitude,
    double? longitude,
  }) async {
    final data = await _api.patch(ApiEndpoints.site(id), data: {
      if (siteName != null) 'site_name': siteName,
      if (address != null) 'address': address,
      if (phase != null) 'phase': phase,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    }) as Map<String, dynamic>;
    return Site.fromJson(data);
  }
}
