import 'dart:math' as math;
import 'dart:ui' as ui show Image;
import 'dart:ui' show Color, Offset, Rect;

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
    : _format = formats.first,
      _margins = formats.first.defaultMargins;

  /// Formats the user can switch between on this page.
  final List<CanvasFormat> formats;

  CanvasFormat _format;
  Margins? _margins;
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

  /// Margins of the rectangle guide, or null when the format has none.
  Margins? get margins => _margins;

  /// The area inside the margins in output pixels, or the whole canvas when
  /// the format has no margins.
  Rect get safeArea {
    final m = _margins;
    final w = _format.width.toDouble();
    final h = _format.height.toDouble();
    if (m == null) return Rect.fromLTWH(0, 0, w, h);
    return Rect.fromLTRB(
      m.left.toDouble(),
      m.top.toDouble(),
      w - m.right,
      h - m.bottom,
    );
  }

  /// Offset that puts the image's centre on the centre of [safeArea].
  Offset get _safeCentreOffset =>
      safeArea.center - Offset(_format.width / 2, _format.height / 2);

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
    final area = safeArea;
    return math.min(area.width / image.width, area.height / image.height);
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
    _offset = _safeCentreOffset;
    _scale = fitScale;
    notifyListeners();
  }

  /// Switches format while keeping the image's size and position relative
  /// to the canvas.
  void setFormat(CanvasFormat format) {
    if (format == _format) return;
    final ratio = format.width / _format.width;
    _format = format;
    _margins = format.defaultMargins;
    _scale *= ratio;
    _offset = _offset * ratio;
    notifyListeners();
  }

  void setScale(double scale) {
    _scale = scale.clamp(minScale, maxScale);
    notifyListeners();
  }

  /// Fits the whole image inside the circle or margins. With margins it
  /// also centres the image in them, since that is the area that matters.
  void fit() {
    if (_margins != null) _offset = _safeCentreOffset;
    setScale(fitScale);
  }

  void fillBackground() => setScale(fillBackgroundScale);

  void setOffset(Offset offset) {
    _offset = offset;
    notifyListeners();
  }

  /// Centres the image on the canvas, or in the margins when there are some.
  void centre() =>
      setOffset(_margins != null ? _safeCentreOffset : Offset.zero);

  /// Changes one or more margins. Margins stay at 0 or more, and opposite
  /// margins always leave at least [minSafeSize] pixels between them; an edit
  /// that would break that is limited by the margin opposite it.
  ///
  /// Only the rectangle guide changes; the image stays where it is.
  void setMargins(Margins margins) {
    if (_margins == null) return;
    (int, int) pair(int start, int end, int size) {
      final e = math.max(0, end);
      final s = start.clamp(0, math.max(0, size - minSafeSize - e)).toInt();
      return (s, e.clamp(0, size - minSafeSize - s).toInt());
    }

    final (left, right) = pair(margins.left, margins.right, _format.width);
    final (top, bottom) = pair(margins.top, margins.bottom, _format.height);
    final next = Margins(left: left, top: top, right: right, bottom: bottom);
    if (next == _margins) return;
    _margins = next;
    notifyListeners();
  }

  void resetMargins() {
    final defaults = _format.defaultMargins;
    if (defaults == null || defaults == _margins) return;
    _margins = defaults;
    notifyListeners();
  }

  static const minSafeSize = 10;

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
