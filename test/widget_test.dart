import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:splash_genx/main.dart';
import 'package:splash_genx/models/editor_state.dart';
import 'package:splash_genx/models/canvas_format.dart';
import 'package:splash_genx/services/splash_renderer.dart';

void main() {
  test('formats match the Flutter splash sizes', () {
    expect(CanvasFormat.splashLarge.width, 1152);
    expect(CanvasFormat.splashLarge.circleDiameter, 768);
    expect(CanvasFormat.splashSmall.width, 960);
    expect(CanvasFormat.splashSmall.circleDiameter, 640);
  });

  test('scale range spans fit-in-circle to fill-background', () {
    final state = EditorState()
      ..setImage(img.Image(width: 400, height: 300), 'a.png');
    expect(state.fitScale, closeTo(768 / 500, 1e-9));
    expect(state.fillBackgroundScale, closeTo(1152 / 300, 1e-9));
    expect(state.minScale, lessThan(state.fitScale));
    expect(state.maxScale, greaterThan(state.fillBackgroundScale));
    state.fillBackground();
    expect(state.scale, state.fillBackgroundScale);
  });

  test('branding is 840 x 240 PNG only with no circle', () {
    expect(CanvasFormat.branding.width, 840);
    expect(CanvasFormat.branding.height, 240);
    expect(CanvasFormat.branding.circleDiameter, isNull);
    expect(CanvasFormat.branding.exportTypes, [ExportType.png]);
  });

  test('branding scale fits inside and fills the wide canvas', () {
    final state = EditorState(formats: const [CanvasFormat.branding])
      ..setImage(img.Image(width: 400, height: 300), 'a.png');
    expect(state.fitScale, closeTo(240 / 300, 1e-9));
    expect(state.fillBackgroundScale, closeTo(840 / 400, 1e-9));
  });

  test('switching format keeps relative size', () {
    final state = EditorState()
      ..setImage(img.Image(width: 400, height: 300), 'a.png');
    state.setFormat(CanvasFormat.splashSmall);
    expect(state.scale, closeTo(state.fitScale, 1e-9));
  });

  testWidgets('start page opens the create page', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SplashGenXApp());
    expect(find.text('Developer: shibinpr'), findsOneWidget);

    await tester.tap(find.text('Create Splash Icon'));
    await tester.pumpAndSettle();
    expect(find.text('Open an image to start'), findsOneWidget);
    expect(find.text('Transparent background'), findsNothing);
    expect(find.text('1152 × 1152'), findsOneWidget);
  });

  testWidgets('start page opens the branding page', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SplashGenXApp());
    await tester.tap(find.text('Create Branding Logo'));
    await tester.pumpAndSettle();
    expect(find.text('840 × 240 px, PNG only'), findsOneWidget);
    expect(find.text('Export PNG'), findsOneWidget);
    expect(find.text('Export JPEG'), findsNothing);
    expect(find.text('Show circle overlay'), findsNothing);

    await tester.tap(find.text('Transparent background'));
    await tester.pump();
    expect(
      find.text('The PNG keeps a transparent background.'),
      findsOneWidget,
    );
  });
}
