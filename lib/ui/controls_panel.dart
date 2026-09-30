import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/editor_state.dart';
import '../models/splash_format.dart';
import '../services/exporter.dart';
import '../services/image_loader.dart';
import '../services/splash_renderer.dart';

/// Format, scale, background and export controls.
class ControlsPanel extends StatefulWidget {
  const ControlsPanel({super.key});

  @override
  State<ControlsPanel> createState() => _ControlsPanelState();
}

class _ControlsPanelState extends State<ControlsPanel> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
    } catch (e) {
      _show('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _open(EditorState state) => _run(() async {
    final loaded = await pickImage();
    if (loaded == null) return;
    state.setImage(loaded.image, loaded.path, preview: loaded.preview);
  });

  Future<void> _export(EditorState state, ExportType type) => _run(() async {
    final path = await exportSplash(state.renderRequest(type));
    if (path != null) _show('Saved $path');
  });

  Future<void> _pickColor(EditorState state) async {
    final color = await showColorPickerDialog(
      context,
      state.backgroundColor,
      pickersEnabled: const {
        ColorPickerType.primary: true,
        ColorPickerType.accent: false,
        ColorPickerType.wheel: true,
      },
      enableOpacity: false,
      showColorCode: true,
      colorCodeHasColor: true,
      heading: const Text('Background colour'),
      actionButtons: const ColorPickerActionButtons(dialogActionButtons: true),
    );
    state.setBackgroundColor(color);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final theme = Theme.of(context);
    final hasImage = state.hasImage;
    final name = state.imagePath?.split(RegExp(r'[\\/]')).last;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: _busy ? null : () => _open(state),
          icon: const Icon(Icons.image_outlined),
          label: const Text('Open image'),
        ),
        if (name != null) ...[
          const SizedBox(height: 4),
          Text(
            '$name  (${state.image!.width} × ${state.image!.height})',
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 24),
        Text('Format', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<SplashFormat>(
          segments: [
            for (final f in SplashFormat.values)
              ButtonSegment(value: f, label: Text(f.label)),
          ],
          selected: {state.format},
          onSelectionChanged: (s) => state.setFormat(s.first),
        ),
        const SizedBox(height: 4),
        Text(
          'Safe circle: ${state.format.circleDiameter} px',
          style: theme.textTheme.bodySmall,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show circle overlay'),
          value: state.showOverlay,
          onChanged: (_) => state.toggleOverlay(),
        ),
        const Divider(height: 32),
        Row(
          children: [
            Text('Scale', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(hasImage ? '${(state.scale * 100).toStringAsFixed(1)}%' : ''),
          ],
        ),
        Slider(
          min: state.minScale,
          max: state.maxScale,
          value: state.scale.clamp(state.minScale, state.maxScale),
          onChanged: hasImage ? state.setScale : null,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: hasImage ? state.fitInCircle : null,
              child: const Text('Fit in circle'),
            ),
            OutlinedButton(
              onPressed: hasImage ? state.fillBackground : null,
              child: const Text('Fill background'),
            ),
            OutlinedButton(
              onPressed: hasImage ? state.centre : null,
              child: const Text('Centre'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Drag the image or use the arrow keys to move it.',
          style: theme.textTheme.bodySmall,
        ),
        const Divider(height: 32),
        Text('Background', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: state.backgroundColor,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          title: Text(
            '#${(state.backgroundColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
          ),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _pickColor(state),
        ),
        const Divider(height: 32),
        Text('Export', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final type in ExportType.values) ...[
              Expanded(
                child: FilledButton.tonal(
                  onPressed: hasImage && !_busy
                      ? () => _export(state, type)
                      : null,
                  child: Text('Export ${type.label}'),
                ),
              ),
              if (type != ExportType.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        if (_busy) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}
