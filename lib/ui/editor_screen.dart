import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/canvas_format.dart';
import '../models/editor_state.dart';
import 'controls_panel.dart';
import 'preview_canvas.dart';
import 'theme_toggle.dart';

/// Editor page: preview on the left, controls on the right. Each page gets
/// its own [EditorState] limited to [formats].
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key, required this.title, required this.formats});

  final String title;
  final List<CanvasFormat> formats;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorState(formats: formats),
      child: _EditorView(title: title),
    );
  }
}

class _EditorView extends StatelessWidget {
  const _EditorView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final state = context.read<EditorState>();

    // Arrow keys move the image, except while typing in a text field.
    KeyEventResult onKey(FocusNode node, KeyEvent event) {
      if (event is KeyUpEvent || !state.hasImage) {
        return KeyEventResult.ignored;
      }
      final typing =
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<EditableText>() !=
          null;
      if (typing) return KeyEventResult.ignored;
      final step = HardwareKeyboard.instance.isShiftPressed ? 10.0 : 1.0;
      final delta = switch (event.logicalKey) {
        LogicalKeyboardKey.arrowLeft => Offset(-step, 0),
        LogicalKeyboardKey.arrowRight => Offset(step, 0),
        LogicalKeyboardKey.arrowUp => Offset(0, -step),
        LogicalKeyboardKey.arrowDown => Offset(0, step),
        _ => null,
      };
      if (delta == null) return KeyEventResult.ignored;
      state.nudge(delta);
      return KeyEventResult.handled;
    }

    return Focus(
      autofocus: true,
      onKeyEvent: onKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: const [ThemeToggleButton(), SizedBox(width: 8)],
        ),
        body: const Row(
          children: [
            Expanded(child: PreviewCanvas()),
            VerticalDivider(width: 1),
            SizedBox(width: 340, child: ControlsPanel()),
          ],
        ),
      ),
    );
  }
}
