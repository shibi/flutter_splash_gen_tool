import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:splash_genx/main.dart';
import 'package:splash_genx/models/editor_state.dart';
import 'package:splash_genx/models/splash_format.dart';

void main() {
  test('formats match the Flutter splash sizes', () {
    expect(SplashFormat.large.canvasSize, 1152);
    expect(SplashFormat.large.circleDiameter, 768);
    expect(SplashFormat.small.canvasSize, 960);
    expect(SplashFormat.small.circleDiameter, 640);
  });

  test('scale range spans fit-in-circle to fill-background', () {
    final state = EditorState()
      ..setImage(img.Image(width: 400, height: 300), 'a.png');
    expect(state.fitCircleScale, closeTo(768 / 500, 1e-9));
    expect(state.fillBackgroundScale, closeTo(1152 / 300, 1e-9));
    expect(state.minScale, lessThan(state.fitCircleScale));
    expect(state.maxScale, greaterThan(state.fillBackgroundScale));
    state.fillBackground();
    expect(state.scale, state.fillBackgroundScale);
  });

  test('switching format keeps relative size', () {
    final state = EditorState()
      ..setImage(img.Image(width: 400, height: 300), 'a.png');
    state.setFormat(SplashFormat.small);
    expect(state.scale, closeTo(state.fitCircleScale, 1e-9));
  });

  testWidgets('app starts with empty preview', (tester) async {
    await tester.pumpWidget(const SplashGenXApp());
    expect(find.text('Open an image to start'), findsOneWidget);
    expect(find.text('1152 × 1152'), findsOneWidget);
  });
}
