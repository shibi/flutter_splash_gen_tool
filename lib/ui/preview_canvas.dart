import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/editor_state.dart';

/// Square preview of the output canvas with the safe-circle overlay.
///
/// The overlay is drawn here only; the exporter never sees it.
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
              final circle =
                  side * state.format.circleDiameter / state.format.canvasSize;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: state.backgroundColor,
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                  if (!state.hasImage) const Text('Open an image to start'),
                  if (state.showOverlay)
                    IgnorePointer(
                      child: Container(
                        width: circle,
                        height: circle,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent, width: 2),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
