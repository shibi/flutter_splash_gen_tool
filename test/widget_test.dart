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

  test('branding is 800 x 320 PNG only with margins and no circle', () {
    expect(CanvasFormat.branding.width, 800);
    expect(CanvasFormat.branding.height, 320);
    expect(CanvasFormat.branding.circleDiameter, isNull);
    expect(CanvasFormat.branding.exportTypes, [ExportType.png]);
    expect(
      CanvasFormat.branding.defaultMargins,
      const Margins(left: 60, top: 50, right: 60, bottom: 50),
    );
    expect(CanvasFormat.splashLarge.defaultMargins, isNull);
  });

  test('branding fits inside the margins and fills the canvas', () {
    final state = EditorState(formats: const [CanvasFormat.branding])
      ..setImage(img.Image(width: 400, height: 300), 'a.png');
    expect(state.safeArea, const Rect.fromLTRB(60, 50, 740, 270));
    expect(state.fitScale, closeTo(220 / 300, 1e-9));
    expect(state.fillBackgroundScale, closeTo(800 / 400, 1e-9));
  });

  test('editing margins moves only the rectangle, not the image', () {
    final state = EditorState(formats: const [CanvasFormat.branding])
      ..setImage(img.Image(width: 400, height: 300), 'a.png');
    final scale = state.scale;
    final offset = state.offset;
    state.setMargins(state.margins!.copyWith(left: 100, bottom: 20));
    expect(
      state.margins,
      const Margins(left: 100, top: 50, right: 60, bottom: 20),
    );
    expect(state.safeArea, const Rect.fromLTRB(100, 50, 740, 300));
    expect(state.scale, scale);
    expect(state.offset, offset);

    // Fit and Centre use the area inside the margins.
    state.fit();
    expect(state.offset, const Offset(20, 15));
    expect(state.scale, closeTo(250 / 300, 1e-9));

    state.resetMargins();
    expect(state.margins, CanvasFormat.branding.defaultMargins);
    state.centre();
    expect(state.offset, Offset.zero);
  });

  test('margins never cross or go negative', () {
    final state = EditorState(formats: const [CanvasFormat.branding]);
    state.setMargins(state.margins!.copyWith(left: 5000));
    expect(state.margins!.left, 800 - EditorState.minSafeSize - 60);
    expect(state.safeArea.width, EditorState.minSafeSize);
    state.setMargins(state.margins!.copyWith(top: -10));
    expect(state.margins!.top, 0);
  });

  test('splash formats have no margins', () {
    final state = EditorState();
    expect(state.margins, isNull);
    state.setMargins(const Margins(left: 1, top: 1, right: 1, bottom: 1));
    expect(state.margins, isNull);
  });

  test('launcher icon is a 1024 opaque PNG with a 66% safe zone', () {
    const f = CanvasFormat.launcherIcon;
    expect([f.width, f.height], [1024, 1024]);
    expect(f.squareGuide, 676);
    expect(f.circleDiameter, 676);
    expect(f.exportTypes, [ExportType.png]);
    expect(f.allowsTransparentBackground, isFalse);
    expect(f.defaultMargins, isNull);

    final state = EditorState(formats: const [f])
      ..setImage(img.Image(width: 400, height: 300), 'a.png')
      ..setTransparentBackground(true);
    expect(state.transparentBackground, isFalse);
    expect(state.fitScale, closeTo(676 / 500, 1e-9));
    expect(state.fillBackgroundScale, closeTo(1024 / 300, 1e-9));
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
    expect(find.text('800 × 320 px, PNG only'), findsOneWidget);
    expect(find.text('Show circle overlay'), findsNothing);
    expect(find.text('Show margin overlay'), findsOneWidget);
    expect(find.text('Safe area: 680 × 220 px'), findsOneWidget);

    // Typing a margin resizes the safe area right away.
    await tester.enterText(find.widgetWithText(TextField, 'Left'), '100');
    await tester.pump();
    expect(find.text('Safe area: 640 × 220 px'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('Safe area: 680 × 220 px'), findsOneWidget);
    expect(find.widgetWithText(TextField, '60'), findsNWidgets(2));

    final panel = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    final transparent = find.text('Transparent background');
    await tester.scrollUntilVisible(transparent, 200, scrollable: panel);
    await tester.tap(transparent);
    await tester.pump();
    expect(
      find.text('The PNG keeps a transparent background.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Export PNG'),
      200,
      scrollable: panel,
    );
    expect(find.text('Export JPEG'), findsNothing);
  });

  testWidgets('start page opens the launcher icon page', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SplashGenXApp());
    await tester.tap(find.text('Flutter Launcher Icon'));
    await tester.pumpAndSettle();
    expect(find.text('1024 × 1024 px, PNG only'), findsOneWidget);
    expect(find.text('Foreground layer'), findsOneWidget);
    expect(find.text('Background layer'), findsOneWidget);
    expect(find.text('Show safe zone overlay'), findsOneWidget);
    expect(find.text('Transparent background'), findsNothing);
    expect(find.text('Fit in circle'), findsOneWidget);
  });
}
