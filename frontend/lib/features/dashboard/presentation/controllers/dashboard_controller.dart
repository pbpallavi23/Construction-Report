import 'package:flutter/foundation.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/utils/view_state.dart';
import '../../data/models/site.dart';
import '../../data/repositories/site_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required SiteRepository siteRepository,
  }) : _sites = siteRepository;

  final SiteRepository _sites;

  ViewState<Site> site = const ViewState.idle();

  Future<void> load() async {
    site = const ViewState.loading();
    notifyListeners();
    try {
      final active = await _sites.activeSite();
      site = ViewState.success(active);
    } on ApiFailure catch (e) {
      site = ViewState.error(e);
    }
    notifyListeners();
  }
}
