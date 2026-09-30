import 'dart:math' as math;
import 'dart:ui' as ui show Image;
import 'dart:ui' show Color, Offset;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../services/splash_renderer.dart';
import 'splash_format.dart';

/// Everything the preview and the exporter need, in output-pixel units.
///
/// [scale] is a plain multiplier on the source image's pixel size and
/// [offset] moves the image's centre away from the canvas centre.
class EditorState extends ChangeNotifier {
  SplashFormat _format = SplashFormat.large;
  img.Image? _image;
  ui.Image? _preview;
  String? _imagePath;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Color _backgroundColor = const Color(0xFFFFFFFF);
  bool _showOverlay = true;
  bool _tintEnabled = false;
  Color _tintColor = const Color(0xFF000000);

  SplashFormat get format => _format;
  img.Image? get image => _image;
  ui.Image? get preview => _preview;
  String? get imagePath => _imagePath;
  double get scale => _scale;
  Offset get offset => _offset;
  Color get backgroundColor => _backgroundColor;
  bool get showOverlay => _showOverlay;
  bool get tintEnabled => _tintEnabled;
  Color get tintColor => _tintColor;
  bool get hasImage => _image != null;

  /// Scale at which the whole image, corners included, fits in the circle.
  double get fitCircleScale {
    final image = _image;
    if (image == null) return 1.0;
    final diagonal = math.sqrt(
      image.width * image.width + image.height * image.height,
    );
    return _format.circleDiameter / diagonal;
  }

  /// Scale at which the image covers the whole canvas with no gaps.
  double get fillBackgroundScale {
    final image = _image;
    if (image == null) return 1.0;
    return _format.canvasSize / math.min(image.width, image.height);
  }

  /// Slider range: a bit below fit-in-circle up to a bit above fill.
  double get minScale => fitCircleScale * 0.5;
  double get maxScale => fillBackgroundScale * 1.5;

  void setImage(img.Image image, String path, {ui.Image? preview}) {
    _preview?.dispose();
    _image = image;
    _preview = preview;
    _imagePath = path;
    _offset = Offset.zero;
    _scale = fitCircleScale;
    notifyListeners();
  }

  /// Switches format while keeping the image's size and position relative
  /// to the canvas.
  void setFormat(SplashFormat format) {
    if (format == _format) return;
    final ratio = format.canvasSize / _format.canvasSize;
    _format = format;
    _scale *= ratio;
    _offset = _offset * ratio;
    notifyListeners();
  }

  void setScale(double scale) {
    _scale = scale.clamp(minScale, maxScale);
    notifyListeners();
  }

  void fitInCircle() => setScale(fitCircleScale);
  void fillBackground() => setScale(fillBackgroundScale);

  void setOffset(Offset offset) {
    _offset = offset;
    notifyListeners();
  }

  void centre() => setOffset(Offset.zero);

  /// Background is always opaque so the output has no alpha channel.
  void setBackgroundColor(Color color) {
    _backgroundColor = color.withAlpha(0xFF);
    notifyListeners();
  }

  /// Moves the image by [delta] output pixels.
  void nudge(Offset delta) => setOffset(_offset + delta);

  RenderRequest renderRequest(ExportType type) => RenderRequest(
    source: _image!,
    format: _format,
    scale: _scale,
    offsetX: _offset.dx,
    offsetY: _offset.dy,
    backgroundArgb: _backgroundColor.toARGB32(),
    type: type,
    tintArgb: _tintEnabled ? _tintColor.toARGB32() : null,
  );

  void setTintEnabled(bool enabled) {
    _tintEnabled = enabled;
    notifyListeners();
  }

  /// Picking a tint colour also turns the tint on.
  void setTintColor(Color color) {
    _tintColor = color.withAlpha(0xFF);
    _tintEnabled = true;
    notifyListeners();
  }

  void toggleOverlay() {
    _showOverlay = !_showOverlay;
    notifyListeners();
  }
}
