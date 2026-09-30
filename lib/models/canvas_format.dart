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
    width: 840,
    height: 240,
    label: '840 × 240',
    fileName: 'branding_840x240',
    exportTypes: [ExportType.png],
  );

  const CanvasFormat({
    required this.width,
    required this.height,
    required this.label,
    required this.fileName,
    this.circleDiameter,
    this.exportTypes = ExportType.values,
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
}
