import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/editor_state.dart';
import 'controls_panel.dart';
import 'preview_canvas.dart';

/// Main window: preview on the left, controls on the right.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<EditorState>();
    void nudge(double dx, double dy) {
      if (state.hasImage) state.nudge(Offset(dx, dy));
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => nudge(-1, 0),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => nudge(1, 0),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => nudge(0, -1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => nudge(0, 1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () =>
            nudge(-10, 0),
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () =>
            nudge(10, 0),
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () =>
            nudge(0, -10),
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () =>
            nudge(0, 10),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(title: const Text('Splash GenX')),
          body: const Row(
            children: [
              Expanded(child: PreviewCanvas()),
              VerticalDivider(width: 1),
              SizedBox(width: 340, child: ControlsPanel()),
            ],
          ),
        ),
      ),
    );
  }
}
