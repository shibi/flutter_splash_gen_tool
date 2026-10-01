import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splash_genx/main.dart';

void main() {
  testWidgets('background tile opens the colour picker', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SplashGenXApp());
    await tester.tap(find.text('Create Splash Icon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#FFFFFF'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Background colour'), findsWidgets);
  });
}
