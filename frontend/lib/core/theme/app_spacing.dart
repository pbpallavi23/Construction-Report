import 'package:flutter/widgets.dart';

class AppSpacing {
  const AppSpacing._();

  static const double pageMargin = 20;

  static const double gutter = 16;

  static const double stackSm = 8;
  static const double stackMd = 16;
  static const double stackLg = 24;
  static const double stackXl = 32;

  static const double touchTargetMin = 48;
  static const double touchTargetLg = 56;

  static const Widget gapSm = SizedBox(height: stackSm, width: stackSm);
  static const Widget gapMd = SizedBox(height: stackMd, width: stackMd);
  static const Widget gapLg = SizedBox(height: stackLg, width: stackLg);
  static const Widget gapXl = SizedBox(height: stackXl, width: stackXl);
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;

  static const double md = 12;

  static const double lg = 16;

  static const double xl = 24;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}
