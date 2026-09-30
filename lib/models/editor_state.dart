import 'dart:math' as math;
import 'dart:ui' as ui show Image;
import 'dart:ui' show Color, Offset;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../services/splash_renderer.dart';
import 'canvas_format.dart';

/// Everything the preview and the exporter need, in output-pixel units.
///
/// [scale] is a plain multiplier on the source image's pixel size and
/// [offset] moves the image's centre away from the canvas centre.
class EditorState extends ChangeNotifier {
  EditorState({this.formats = CanvasFormat.splashFormats})
    : _format = formats.first;

  /// Formats the user can switch between on this page.
  final List<CanvasFormat> formats;

  CanvasFormat _format;
  img.Image? _image;
  ui.Image? _preview;
  String? _imagePath;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Color _backgroundColor = const Color(0xFFFFFFFF);
  bool _transparentBackground = false;
  bool _showOverlay = true;
  bool _tintEnabled = false;
  Color _tintColor = const Color(0xFF000000);

  CanvasFormat get format => _format;
  img.Image? get image => _image;
  ui.Image? get preview => _preview;
  String? get imagePath => _imagePath;
  double get scale => _scale;
  Offset get offset => _offset;
  Color get backgroundColor => _backgroundColor;

  /// True only when the user chose it and the format allows it.
  bool get transparentBackground =>
      _transparentBackground && _format.allowsTransparentBackground;
  bool get showOverlay => _showOverlay;
  bool get tintEnabled => _tintEnabled;
  Color get tintColor => _tintColor;
  bool get hasImage => _image != null;

  /// Scale at which the whole image fits: inside the safe circle, corners
  /// included, or inside the canvas when the format has no circle.
  double get fitScale {
    final image = _image;
    if (image == null) return 1.0;
    final circle = _format.circleDiameter;
    if (circle != null) {
      final diagonal = math.sqrt(
        image.width * image.width + image.height * image.height,
      );
      return circle / diagonal;
    }
    return math.min(_format.width / image.width, _format.height / image.height);
  }

  /// Scale at which the image covers the whole canvas with no gaps.
  double get fillBackgroundScale {
    final image = _image;
    if (image == null) return 1.0;
    return math.max(_format.width / image.width, _format.height / image.height);
  }

  /// Slider range: a bit below fit up to a bit above fill.
  double get minScale => fitScale * 0.5;
  double get maxScale => fillBackgroundScale * 1.5;

  void setImage(img.Image image, String path, {ui.Image? preview}) {
    _preview?.dispose();
    _image = image;
    _preview = preview;
    _imagePath = path;
    _offset = Offset.zero;
    _scale = fitScale;
    notifyListeners();
  }

  /// Switches format while keeping the image's size and position relative
  /// to the canvas.
  void setFormat(CanvasFormat format) {
    if (format == _format) return;
    final ratio = format.width / _format.width;
    _format = format;
    _scale *= ratio;
    _offset = _offset * ratio;
    notifyListeners();
  }

  void setScale(double scale) {
    _scale = scale.clamp(minScale, maxScale);
    notifyListeners();
  }

  void fit() => setScale(fitScale);
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
    transparentBackground: transparentBackground,
    type: type,
    tintArgb: _tintEnabled ? _tintColor.toARGB32() : null,
  );

  void setTransparentBackground(bool transparent) {
    _transparentBackground = transparent;
    notifyListeners();
  }

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
