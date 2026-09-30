import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:splash_genx/models/splash_format.dart';
import 'package:splash_genx/services/splash_renderer.dart';

img.Image _redSquareWithTransparentCorner() {
  final image = img.Image(width: 100, height: 100, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(255, 0, 0, 255));
  image.setPixelRgba(0, 0, 0, 0, 0, 0);
  return image;
}

RenderRequest _request({
  SplashFormat format = SplashFormat.large,
  double scale = 2,
  double dx = 0,
  double dy = 0,
  ExportType type = ExportType.png,
}) => RenderRequest(
  source: _redSquareWithTransparentCorner(),
  format: format,
  scale: scale,
  offsetX: dx,
  offsetY: dy,
  backgroundArgb: 0xFF0000FF,
  type: type,
);

void main() {
  for (final format in SplashFormat.values) {
    test('${format.label} PNG is exact size with no alpha', () {
      final bytes = renderSplashBytes(_request(format: format));
      final decoded = img.decodePng(bytes)!;
      expect(decoded.width, format.canvasSize);
      expect(decoded.height, format.canvasSize);
      expect(decoded.numChannels, 3);
    });
  }

  test('JPEG is exact size', () {
    final bytes = renderSplashBytes(_request(type: ExportType.jpeg));
    final decoded = img.decodeJpg(bytes)!;
    expect(decoded.width, 1152);
    expect(decoded.numChannels, 3);
  });

  test('image is centred on a solid background', () {
    final out = renderSplash(_request());
    // 100 px at scale 2 = 200 px centred: spans 476..676.
    expect(out.getPixel(576, 576).r, 255);
    expect(out.getPixel(470, 576).b, 255);
    expect(out.getPixel(470, 576).r, 0);
    // Transparent source pixels show the background, not black.
    expect(out.getPixel(476, 476).b, 255);
  });

  test('offset moves the image and clips at the edges', () {
    final out = renderSplash(_request(dx: 576, scale: 4));
    expect(out.width, 1152);
    expect(out.getPixel(1151, 576).r, 255);
    expect(out.getPixel(900, 576).r, 0);
  });

  test('image fully off-canvas leaves only background', () {
    final out = renderSplash(_request(dx: 5000));
    expect(out.getPixel(576, 576).b, 255);
    expect(out.getPixel(576, 576).r, 0);
  });
}
