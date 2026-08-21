import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_failure.dart';
import '../../../dashboard/data/repositories/site_repository.dart';
import '../../data/models/ocr_result.dart';
import '../../data/repositories/ocr_repository.dart';

enum CaptureStage { ready, uploading, done, error }

class OcrController extends ChangeNotifier {
  OcrController({
    required OcrRepository ocrRepository,
    required SiteRepository siteRepository,
  })  : _ocr = ocrRepository,
        _sites = siteRepository;

  final OcrRepository _ocr;
  final SiteRepository _sites;
  final ImagePicker _picker = ImagePicker();

  CaptureStage stage = CaptureStage.ready;
  File? photo;
  String? errorMessage;

  String _siteId = '';

  List<Picture> pastPictures = [];
  bool loadingPictures = false;
  String? deleteError;
  final Set<String> _deletingIds = {};

  bool isDeleting(String pictureId) => _deletingIds.contains(pictureId);

  Future<void> init() async {
    try {
      final site = await _sites.activeSite();
      _siteId = site.siteId;
    } on ApiFailure {
      _siteId = '';
    }
    await loadPictures();
  }

  Future<void> loadPictures() async {
    if (_siteId.isEmpty) return;
    loadingPictures = true;
    notifyListeners();
    try {
      pastPictures = await _ocr.pictures(siteId: _siteId);
    } on ApiFailure {

    } finally {
      loadingPictures = false;
      notifyListeners();
    }
  }

  Future<void> capture({ImageSource source = ImageSource.camera}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked == null) {
        return;
      }
      photo = File(picked.path);
      stage = CaptureStage.uploading;
      errorMessage = null;
      notifyListeners();

      final bytes = await photo!.readAsBytes();
      if (_siteId.isEmpty) {
        final site = await _sites.activeSite();
        _siteId = site.siteId;
      }
      await _ocr.scan(
        imageBytes: bytes,
        filename: picked.name,
        siteId: _siteId,
      );

      stage = CaptureStage.done;
      notifyListeners();
      await loadPictures();
    } on ApiFailure catch (e) {
      errorMessage = e.message;
      stage = CaptureStage.error;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Could not save the photo: $e';
      stage = CaptureStage.error;
      notifyListeners();
    }
  }

  void reset() {
    stage = CaptureStage.ready;
    photo = null;
    errorMessage = null;
    notifyListeners();
  }



  Future<bool> deletePicture(String pictureId) async {
    _deletingIds.add(pictureId);
    deleteError = null;
    notifyListeners();
    try {
      await _ocr.deletePicture(pictureId);
      pastPictures.removeWhere((p) => p.id == pictureId);
      return true;
    } on ApiFailure catch (e) {
      deleteError = e.message;
      return false;
    } catch (e) {
      deleteError = 'Could not delete the photo: $e';
      return false;
    } finally {
      _deletingIds.remove(pictureId);
      notifyListeners();
    }
  }
}
