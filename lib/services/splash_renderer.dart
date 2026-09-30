import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/canvas_format.dart';

enum ExportType {
  png('png', 'PNG'),
  jpeg('jpg', 'JPEG');

  const ExportType(this.extension, this.label);

  final String extension;
  final String label;
}

/// Everything needed to render the final file. Plain values only so it can
/// be sent to a background isolate.
class RenderRequest {
  const RenderRequest({
    required this.source,
    required this.format,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.backgroundArgb,
    required this.type,
    this.tintArgb,
    this.jpegQuality = 95,
  });

  final img.Image source;
  final CanvasFormat format;
  final double scale;
  final double offsetX;
  final double offsetY;
  final int backgroundArgb;
  final ExportType type;

  /// When set, every pixel of the image takes this colour and keeps its own
  /// transparency, like a monochrome icon tint.
  final int? tintArgb;

  final int jpegQuality;
}

/// Builds the output canvas: solid background, the scaled image composited
/// at its offset from the centre, no alpha channel and no overlay.
img.Image renderSplash(RenderRequest r) {
  final canvasWidth = r.format.width;
  final canvasHeight = r.format.height;
  final canvas = img.Image(
    width: canvasWidth,
    height: canvasHeight,
    numChannels: 3,
  );
  img.fill(
    canvas,
    color: img.ColorRgb8(
      (r.backgroundArgb >> 16) & 0xFF,
      (r.backgroundArgb >> 8) & 0xFF,
      r.backgroundArgb & 0xFF,
    ),
  );

  final width = (r.source.width * r.scale).round();
  final height = (r.source.height * r.scale).round();
  if (width < 1 || height < 1) return canvas;

  final left = (canvasWidth / 2 + r.offsetX - width / 2).round();
  final top = (canvasHeight / 2 + r.offsetY - height / 2).round();
  final x0 = left.clamp(0, canvasWidth);
  final y0 = top.clamp(0, canvasHeight);
  final x1 = (left + width).clamp(0, canvasWidth);
  final y1 = (top + height).clamp(0, canvasHeight);
  if (x1 <= x0 || y1 <= y0) return canvas;

  final resized = resizePremultiplied(r.source, width, height);
  final tint = r.tintArgb;
  if (tint != null) applyTint(resized, tint);
  img.compositeImage(
    canvas,
    resized,
    dstX: x0,
    dstY: y0,
    dstW: x1 - x0,
    dstH: y1 - y0,
    srcX: x0 - left,
    srcY: y0 - top,
    srcW: x1 - x0,
    srcH: y1 - y0,
  );
  return canvas;
}

/// Resizes with colour weighted by alpha, so the colour hidden in fully
/// transparent pixels (often white) can't bleed into the edges as a halo.
img.Image resizePremultiplied(img.Image source, int width, int height) {
  final premultiplied = source.convert(
    format: img.Format.float32,
    numChannels: 4,
  );
  for (final p in premultiplied) {
    final a = p.a;
    p
      ..r = p.r * a
      ..g = p.g * a
      ..b = p.b * a;
  }
  final resized = img.copyResize(
    premultiplied,
    width: width,
    height: height,
    interpolation: img.Interpolation.cubic,
  );
  for (final p in resized) {
    final a = p.a.clamp(0.0, 1.0);
    p.a = a;
    if (a == 0) {
      p
        ..r = 0
        ..g = 0
        ..b = 0;
      continue;
    }
    p
      ..r = (p.r / a).clamp(0.0, 1.0)
      ..g = (p.g / a).clamp(0.0, 1.0)
      ..b = (p.b / a).clamp(0.0, 1.0);
  }
  return resized.convert(format: img.Format.uint8);
}

/// Replaces the colour of every pixel with [argb], keeping each pixel's alpha.
void applyTint(img.Image image, int argb) {
  final red = (argb >> 16) & 0xFF;
  final green = (argb >> 8) & 0xFF;
  final blue = argb & 0xFF;
  final max = image.maxChannelValue;
  for (final p in image) {
    p
      ..r = red * max / 255
      ..g = green * max / 255
      ..b = blue * max / 255;
  }
}

/// Renders and encodes to PNG (RGB) or JPEG.
Uint8List renderSplashBytes(RenderRequest r) {
  final canvas = renderSplash(r);
  return switch (r.type) {
    ExportType.png => img.encodePng(canvas),
    ExportType.jpeg => img.encodeJpg(canvas, quality: r.jpegQuality),
  };
}
