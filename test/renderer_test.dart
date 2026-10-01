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
  bool transparent = false,
}) => RenderRequest(
  source: _redSquareWithTransparentCorner(),
  format: format,
  scale: scale,
  offsetX: dx,
  offsetY: dy,
  backgroundArgb: 0xFF0000FF,
  type: type,
  tintArgb: tint,
  transparentBackground: transparent,
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
    expect(out.width, 800);
    expect(out.height, 320);
    // 100 px at scale 2 = 200 px centred on (400, 160).
    expect(out.getPixel(400, 160).r, 255);
    expect(out.getPixel(280, 160).r, 0);
  });

  test('branding can export a transparent PNG', () {
    final bytes = renderSplashBytes(
      _request(format: CanvasFormat.branding, transparent: true),
    );
    final out = img.decodePng(bytes)!;
    expect(out.width, 800);
    expect(out.numChannels, 4);
    // Outside the image: fully transparent.
    expect(out.getPixel(10, 10).a, 0);
    // In the image's transparent corner: mostly see-through.
    expect(out.getPixel(300, 60).a, lessThan(128));
    // Inside the image: opaque red.
    final inside = out.getPixel(400, 160);
    expect([inside.r, inside.g, inside.b, inside.a], [255, 0, 0, 255]);
  });

  test('margin rectangle is never drawn into the output', () {
    final out = renderSplash(
      _request(format: CanvasFormat.branding, scale: 0.5),
    );
    // Background blue all along the margin edges.
    for (final (x, y) in [(60, 160), (740, 160), (400, 50), (400, 270)]) {
      final p = out.getPixel(x, y);
      expect([p.r, p.g, p.b], [0, 0, 255]);
    }
  });

  test('upscaling is smooth, with no blocky steps', () {
    // Black left half, white right half, 4 px wide, enlarged 16 times.
    final source = img.Image(width: 4, height: 1, numChannels: 4);
    for (var x = 0; x < 4; x++) {
      final v = x < 2 ? 0 : 255;
      source.setPixelRgba(x, 0, v, v, v, 255);
    }
    final out = resizePremultiplied(source, 64, 1);
    final row = [for (var x = 0; x < 64; x++) out.getPixel(x, 0).r.toInt()];
    // Brightness rises steadily across the edge instead of jumping.
    final edge = row.sublist(20, 44);
    for (var i = 1; i < edge.length; i++) {
      expect(edge[i], greaterThanOrEqualTo(edge[i - 1]));
      expect(edge[i] - edge[i - 1], lessThan(64));
    }
    expect(row.first, lessThan(10));
    expect(row.last, greaterThan(245));
  });

  test('shrinking keeps a thin line continuous', () {
    // A 1 px diagonal line shrunk 10 times must not break into dots.
    final source = img.Image(width: 1000, height: 1000, numChannels: 4);
    for (var i = 0; i < 1000; i++) {
      source.setPixelRgba(i, i, 255, 255, 255, 255);
    }
    final out = resizePremultiplied(source, 100, 100);
    for (var i = 2; i < 98; i++) {
      expect(out.getPixel(i, i).a, greaterThan(0), reason: 'pixel $i');
    }
  });

  test('splash formats ignore the transparent option', () {
    final bytes = renderSplashBytes(_request(transparent: true));
    expect(img.decodePng(bytes)!.numChannels, 3);
  });
}
