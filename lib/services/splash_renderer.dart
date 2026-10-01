import 'dart:math' as math;
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
    this.transparentBackground = false,
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

  /// Leave the background transparent (PNG with alpha) instead of filling
  /// it with [backgroundArgb].
  final bool transparentBackground;

  /// When set, every pixel of the image takes this colour and keeps its own
  /// transparency, like a monochrome icon tint.
  final int? tintArgb;

  final int jpegQuality;
}

/// Builds the output canvas: the scaled image composited at its offset from
/// the centre, never the overlay. The background is a solid colour with no
/// alpha channel, or fully transparent when [RenderRequest.transparentBackground].
img.Image renderSplash(RenderRequest r) {
  final canvasWidth = r.format.width;
  final canvasHeight = r.format.height;
  final transparent =
      r.transparentBackground && r.format.allowsTransparentBackground;
  final canvas = img.Image(
    width: canvasWidth,
    height: canvasHeight,
    numChannels: transparent ? 4 : 3,
  );
  if (!transparent) {
    img.fill(
      canvas,
      color: img.ColorRgb8(
        (r.backgroundArgb >> 16) & 0xFF,
        (r.backgroundArgb >> 8) & 0xFF,
        r.backgroundArgb & 0xFF,
      ),
    );
  }

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
    // On an empty transparent canvas, copying the pixels as they are keeps
    // the image's own transparency.
    blend: transparent ? img.BlendMode.direct : img.BlendMode.alpha,
  );
  return canvas;
}

/// Resizes with colour weighted by alpha, so the colour hidden in fully
/// transparent pixels (often white) can't bleed into the edges as a halo.
///
/// Uses a separable Mitchell–Netravali cubic filter: smooth when enlarging,
/// so small logos don't turn blocky, and widened when shrinking so every
/// source pixel counts and edges don't break up into jaggies.
img.Image resizePremultiplied(img.Image source, int width, int height) {
  final sw = source.width;
  final sh = source.height;

  final src = Float32List(sw * sh * 4);
  var i = 0;
  for (var y = 0; y < sh; y++) {
    for (var x = 0; x < sw; x++, i += 4) {
      final p = source.getPixel(x, y);
      final a = p.aNormalized.toDouble();
      src[i] = p.rNormalized * a;
      src[i + 1] = p.gNormalized * a;
      src[i + 2] = p.bNormalized * a;
      src[i + 3] = a;
    }
  }

  // Rows first, then columns.
  final columns = _filterTaps(sw, width);
  final rows = _filterTaps(sh, height);
  final tmp = Float32List(width * sh * 4);
  for (var y = 0; y < sh; y++) {
    final srcRow = y * sw * 4;
    final dstRow = y * width * 4;
    for (var x = 0; x < width; x++) {
      _accumulate(src, srcRow, 4, columns[x], tmp, dstRow + x * 4);
    }
  }
  final out = Float32List(width * height * 4);
  for (var y = 0; y < height; y++) {
    final taps = rows[y];
    for (var x = 0; x < width; x++) {
      _accumulate(tmp, x * 4, width * 4, taps, out, (y * width + x) * 4);
    }
  }

  final result = img.Image(width: width, height: height, numChannels: 4);
  i = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++, i += 4) {
      final a = out[i + 3].clamp(0.0, 1.0);
      if (a == 0) {
        result.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }
      int channel(double v) => ((v / a).clamp(0.0, 1.0) * 255).round();
      result.setPixelRgba(
        x,
        y,
        channel(out[i]),
        channel(out[i + 1]),
        channel(out[i + 2]),
        (a * 255).round(),
      );
    }
  }
  return result;
}

/// Source indices and normalised weights for one output pixel.
typedef _Taps = ({Int32List index, Float32List weight});

/// Filter taps for resampling a line of [srcSize] pixels to [dstSize].
List<_Taps> _filterTaps(int srcSize, int dstSize) {
  final ratio = srcSize / dstSize;
  // When shrinking, stretch the filter to cover every source pixel.
  final stretch = math.max(1.0, ratio);
  final support = 2.0 * stretch;
  return List.generate(dstSize, (d) {
    final centre = (d + 0.5) * ratio - 0.5;
    final lo = (centre - support).ceil();
    final hi = (centre + support).floor();
    final count = hi - lo + 1;
    final index = Int32List(count);
    final weight = Float32List(count);
    var sum = 0.0;
    for (var k = 0; k < count; k++) {
      final s = lo + k;
      index[k] = s.clamp(0, srcSize - 1);
      final w = _mitchell((s - centre) / stretch);
      weight[k] = w;
      sum += w;
    }
    if (sum != 0) {
      for (var k = 0; k < count; k++) {
        weight[k] /= sum;
      }
    }
    return (index: index, weight: weight);
  });
}

/// Mitchell–Netravali cubic with B = C = 1/3.
double _mitchell(double x) {
  const b = 1 / 3;
  const c = 1 / 3;
  x = x.abs();
  if (x < 1) {
    return ((12 - 9 * b - 6 * c) * x * x * x +
            (-18 + 12 * b + 6 * c) * x * x +
            (6 - 2 * b)) /
        6;
  }
  if (x < 2) {
    return ((-b - 6 * c) * x * x * x +
            (6 * b + 30 * c) * x * x +
            (-12 * b - 48 * c) * x +
            (8 * b + 24 * c)) /
        6;
  }
  return 0;
}

/// Writes the weighted sum of RGBA pixels at [base] + index * [stride] into
/// [dst] at [at].
void _accumulate(
  Float32List src,
  int base,
  int stride,
  _Taps taps,
  Float32List dst,
  int at,
) {
  var r = 0.0, g = 0.0, b = 0.0, a = 0.0;
  final index = taps.index;
  final weight = taps.weight;
  for (var k = 0; k < index.length; k++) {
    final p = base + index[k] * stride;
    final w = weight[k];
    r += src[p] * w;
    g += src[p + 1] * w;
    b += src[p + 2] * w;
    a += src[p + 3] * w;
  }
  dst[at] = r;
  dst[at + 1] = g;
  dst[at + 2] = b;
  dst[at + 3] = a;
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
