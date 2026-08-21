import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ocr_result.dart';

class OcrRepository {
  OcrRepository(this._api);
  final ApiClient _api;

  Future<OcrResult> scan(
      {List<int>? imageBytes, String? filename, String? siteId}) async {
    final form = FormData();
    if (imageBytes != null) {
      form.files.add(MapEntry(
        'file',
        MultipartFile.fromBytes(imageBytes, filename: filename ?? 'scan.jpg'),
      ));
    }
    if (siteId != null && siteId.isNotEmpty) {
      form.fields.add(MapEntry('site_id', siteId));
    }
    final data =
        await _api.postMultipart(ApiEndpoints.ocrScan, data: form)
            as Map<String, dynamic>;
    return OcrResult.fromJson(data);
  }

  Future<List<Picture>> pictures({String? siteId}) async {
    final data = await _api.get(
      ApiEndpoints.pictures,
      query: siteId == null ? null : {'site_id': siteId},
    ) as List;
    return data
        .map((e) => Picture.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deletePicture(String pictureId) async {
    await _api.delete(ApiEndpoints.picture(pictureId));
  }
}
