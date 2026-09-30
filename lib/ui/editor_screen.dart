import 'package:flutter/material.dart';

import 'controls_panel.dart';
import 'preview_canvas.dart';

/// Main window: preview on the left, controls on the right.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Splash GenX')),
      body: const Row(
        children: [
          Expanded(child: PreviewCanvas()),
          VerticalDivider(width: 1),
          SizedBox(width: 320, child: ControlsPanel()),
        ],
      ),
    );
  }
}
