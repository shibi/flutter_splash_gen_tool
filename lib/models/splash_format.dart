/// Android 12+ splash icon sizes documented by flutter_native_splash.
enum SplashFormat {
  /// Icon without an icon background.
  large(canvasSize: 1152, circleDiameter: 768, label: '1152 × 1152'),

  /// Icon with an icon background.
  small(canvasSize: 960, circleDiameter: 640, label: '960 × 960');

  const SplashFormat({
    required this.canvasSize,
    required this.circleDiameter,
    required this.label,
  });

  /// Output width and height in pixels.
  final int canvasSize;

  /// Diameter in pixels of the safe circle the icon must fit within.
  final int circleDiameter;

  final String label;
}
