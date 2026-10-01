import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/canvas_format.dart';
import '../models/editor_state.dart';
import '../theme/app_theme.dart';

/// Preview of the output canvas, with the format's guides: safe circle,
/// rounded safe square, or margin rectangle.
///
/// The overlay is drawn here only; the exporter never sees it. Drag the
/// image to move it.
class PreviewCanvas extends StatelessWidget {
  const PreviewCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: AspectRatio(
          aspectRatio: state.format.width / state.format.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              // Screen pixels per output pixel.
              final k = width / state.format.width;
              final circleDiameter = state.format.circleDiameter;
              final image = state.preview;
              final margins = state.margins;
              return GestureDetector(
                // Take focus back from a text field so arrow keys move the
                // image again.
                onPanDown: (_) => Focus.maybeOf(context)?.requestFocus(),
                onPanUpdate: state.hasImage
                    ? (d) => state.nudge(d.delta / k)
                    : null,
                child: MouseRegion(
                  cursor: state.hasImage
                      ? SystemMouseCursors.move
                      : MouseCursor.defer,
                  child: ClipRect(
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: state.transparentBackground
                              ? const _Checkerboard()
                              : ColoredBox(color: state.backgroundColor),
                        ),
                        if (image != null)
                          Positioned(
                            left:
                                width / 2 +
                                (state.offset.dx -
                                        image.width * state.scale / 2) *
                                    k,
                            top:
                                height / 2 +
                                (state.offset.dy -
                                        image.height * state.scale / 2) *
                                    k,
                            width: image.width * state.scale * k,
                            height: image.height * state.scale * k,
                            child: RawImage(
                              image: image,
                              fit: BoxFit.fill,
                              color: state.tintEnabled ? state.tintColor : null,
                              colorBlendMode: BlendMode.srcIn,
                              filterQuality: FilterQuality.high,
                            ),
                          )
                        else
                          Center(
                            child: Text(
                              'Open an image to start',
                              // Readable on the canvas colour in either theme.
                              style: TextStyle(
                                color:
                                    state.transparentBackground ||
                                        state.backgroundColor
                                                .computeLuminance() >
                                            0.5
                                    ? Colors.black54
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        if (state.showOverlay &&
                            state.format.squareGuide != null)
                          Center(
                            child: IgnorePointer(
                              child: Container(
                                width: state.format.squareGuide! * k,
                                height: state.format.squareGuide! * k,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    CanvasFormat.squareGuideRadius * k,
                                  ),
                                  border: Border.all(
                                    color: Palette.plum,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (state.showOverlay && circleDiameter != null)
                          Center(
                            child: IgnorePointer(
                              child: Container(
                                width: circleDiameter * k,
                                height: circleDiameter * k,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Palette.coral,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (state.showOverlay && margins != null)
                          // Depends only on the margins, never on the image.
                          Positioned(
                            left: margins.left * k,
                            top: margins.top * k,
                            right: margins.right * k,
                            bottom: margins.bottom * k,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Palette.coral,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Grey checkerboard that marks a transparent background in the preview.
class _Checkerboard extends StatelessWidget {
  const _Checkerboard();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _CheckerboardPainter());
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  static const _cell = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final dark = Paint()..color = const Color(0xFFD9D9D9);
    for (var y = 0; y * _cell < size.height; y++) {
      for (var x = y.isEven ? 0 : 1; x * _cell < size.width; x += 2) {
        canvas.drawRect(
          Rect.fromLTWH(x * _cell, y * _cell, _cell, _cell),
          dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPainter oldDelegate) => false;
}
