import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baxall_construction_app/core/theme/app_theme.dart';
import 'package:baxall_construction_app/core/widgets/app_buttons.dart';
import 'package:baxall_construction_app/core/widgets/status_pill.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('PrimaryButton shows its label and fires onPressed',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(PrimaryButton(
      label: 'SIGN IN',
      onPressed: () => tapped = true,
    )));

    expect(find.text('SIGN IN'), findsOneWidget);
    await tester.tap(find.text('SIGN IN'));
    expect(tapped, isTrue);
  });

  testWidgets('PrimaryButton in busy state shows a spinner, not the label',
      (tester) async {
    await tester.pumpWidget(_wrap(const PrimaryButton(
      label: 'LOADING',
      busy: true,
      onPressed: null,
    )));

    expect(find.text('LOADING'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('StatusPill renders its label', (tester) async {
    await tester.pumpWidget(_wrap(StatusPill.success('Active')));
    expect(find.text('Active'), findsOneWidget);
  });
}
