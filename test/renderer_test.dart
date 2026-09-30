import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:splash_genx/models/canvas_format.dart';
import 'package:splash_genx/services/splash_renderer.dart';

img.Image _redSquareWithTransparentCorner() {
  final image = img.Image(width: 100, height: 100, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(255, 0, 0, 255));
  // Transparent pixel that stores white, as many exported PNGs do.
  image.setPixelRgba(0, 0, 255, 255, 255, 0);
  return image;
}

RenderRequest _request({
  CanvasFormat format = CanvasFormat.splashLarge,
  double scale = 2,
  double dx = 0,
  double dy = 0,
  ExportType type = ExportType.png,
  int? tint,
}) => RenderRequest(
  source: _redSquareWithTransparentCorner(),
  format: format,
  scale: scale,
  offsetX: dx,
  offsetY: dy,
  backgroundArgb: 0xFF0000FF,
  type: type,
  tintArgb: tint,
);

void main() {
  for (final format in CanvasFormat.values) {
    test('${format.label} PNG is exact size with no alpha', () {
      final bytes = renderSplashBytes(_request(format: format));
      final decoded = img.decodePng(bytes)!;
      expect(decoded.width, format.width);
      expect(decoded.height, format.height);
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
    // Transparent source pixels show the background, not their stored white.
    final corner = out.getPixel(476, 476);
    expect([corner.r, corner.g, corner.b], [0, 0, 255]);
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

  test('tint recolours the image and keeps transparency', () {
    final out = renderSplash(_request(tint: 0xFF00FF00));
    final inside = out.getPixel(576, 576);
    expect([inside.r, inside.g, inside.b], [0, 255, 0]);
    final corner = out.getPixel(476, 476);
    expect([corner.r, corner.g, corner.b], [0, 0, 255]);
  });

  test('transparent white does not leave a halo when scaled up', () {
    final source = img.Image(width: 20, height: 20, numChannels: 4);
    img.fill(source, color: img.ColorRgba8(255, 255, 255, 0));
    img.fillRect(
      source,
      x1: 5,
      y1: 5,
      x2: 14,
      y2: 14,
      color: img.ColorRgba8(255, 0, 0, 255),
    );
    final out = renderSplash(
      RenderRequest(
        source: source,
        format: CanvasFormat.splashSmall,
        scale: 10,
        offsetX: 0,
        offsetY: 0,
        backgroundArgb: 0xFF000000,
        type: ExportType.png,
      ),
    );
    // Red on black: any green or blue would be white bleeding in.
    for (final p in out) {
      expect(p.g, 0);
      expect(p.b, 0);
    }
  });

  test('branding image is centred on a wide canvas', () {
    final out = renderSplash(_request(format: CanvasFormat.branding));
    expect(out.width, 840);
    expect(out.height, 240);
    // 100 px at scale 2 = 200 px centred on (420, 120).
    expect(out.getPixel(420, 120).r, 255);
    expect(out.getPixel(300, 120).r, 0);
  });
}
