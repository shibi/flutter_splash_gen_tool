import '../services/splash_renderer.dart' show ExportType;

/// Output canvases the app can produce.
enum CanvasFormat {
  /// Android 12+ splash icon without an icon background.
  splashLarge(
    width: 1152,
    height: 1152,
    circleDiameter: 768,
    label: '1152 × 1152',
    fileName: 'splash_1152',
  ),

  /// Android 12+ splash icon with an icon background.
  splashSmall(
    width: 960,
    height: 960,
    circleDiameter: 640,
    label: '960 × 960',
    fileName: 'splash_960',
  ),

  /// Splash branding image shown at the bottom of the splash screen.
  branding(
    width: 800,
    height: 320,
    label: '800 × 320',
    fileName: 'branding_800x320',
    exportTypes: [ExportType.png],
    allowsTransparentBackground: true,
    defaultMargins: Margins(left: 60, top: 50, right: 60, bottom: 50),
  );

  const CanvasFormat({
    required this.width,
    required this.height,
    required this.label,
    required this.fileName,
    this.circleDiameter,
    this.exportTypes = ExportType.values,
    this.allowsTransparentBackground = false,
    this.defaultMargins,
  });

  static const splashFormats = [splashLarge, splashSmall];

  /// Output size in pixels.
  final int width;
  final int height;

  /// Diameter of the safe circle the icon must fit within, or null when the
  /// format has no circle guide.
  final int? circleDiameter;

  final String label;

  /// Suggested file name, without extension.
  final String fileName;

  final List<ExportType> exportTypes;

  /// Whether the user may export with a transparent background instead of
  /// a solid colour. Splash icons must stay opaque.
  final bool allowsTransparentBackground;

  /// Starting margins of the rectangle guide the logo should stay inside,
  /// or null when the format has no rectangle guide.
  final Margins? defaultMargins;
}

/// Distances in output pixels from each canvas edge to the safe rectangle.
class Margins {
  const Margins({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;

  Margins copyWith({int? left, int? top, int? right, int? bottom}) => Margins(
    left: left ?? this.left,
    top: top ?? this.top,
    right: right ?? this.right,
    bottom: bottom ?? this.bottom,
  );

  @override
  bool operator ==(Object other) =>
      other is Margins &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);
}
