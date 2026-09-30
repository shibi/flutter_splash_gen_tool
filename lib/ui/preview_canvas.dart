import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/editor_state.dart';

/// Square preview of the output canvas with the safe-circle overlay.
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
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.maxWidth;
              // Screen pixels per output pixel.
              final k = side / state.format.canvasSize;
              final circle = state.format.circleDiameter * k;
              final image = state.preview;
              return GestureDetector(
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
                          child: ColoredBox(color: state.backgroundColor),
                        ),
                        if (image != null)
                          Positioned(
                            left:
                                side / 2 +
                                (state.offset.dx -
                                        image.width * state.scale / 2) *
                                    k,
                            top:
                                side / 2 +
                                (state.offset.dy -
                                        image.height * state.scale / 2) *
                                    k,
                            width: image.width * state.scale * k,
                            height: image.height * state.scale * k,
                            child: RawImage(
                              image: image,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.medium,
                            ),
                          )
                        else
                          const Center(child: Text('Open an image to start')),
                        if (state.showOverlay)
                          Center(
                            child: IgnorePointer(
                              child: Container(
                                width: circle,
                                height: circle,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.redAccent,
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
                                border: Border.all(color: Colors.black26),
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
