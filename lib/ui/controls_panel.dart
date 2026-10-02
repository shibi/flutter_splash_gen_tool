import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/editor_state.dart';
import '../models/canvas_format.dart';
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

  Future<Color> _pickColor(Color initial, String title) {
    return showColorPickerDialog(
      context,
      initial,
      pickersEnabled: const {
        ColorPickerType.primary: true,
        ColorPickerType.accent: false,
        ColorPickerType.wheel: true,
      },
      enableOpacity: false,
      showColorCode: true,
      colorCodeHasColor: true,
      heading: Text(title),
      actionButtons: const ColorPickerActionButtons(dialogActionButtons: true),
    );
  }

  Future<void> _pickBackground(EditorState state) async {
    state.setBackgroundColor(
      await _pickColor(state.backgroundColor, 'Background colour'),
    );
  }

  Future<void> _pickTint(EditorState state) async {
    final color = await _pickColor(state.tintColor, 'Foreground tint');
    // The dialog returns the starting colour on cancel; keep tint as it was.
    if (color != state.tintColor) state.setTintColor(color);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final theme = Theme.of(context);
    final hasImage = state.hasImage;
    final name = state.imagePath?.split(RegExp(r'[\\/]')).last;

    final layered = state.format == CanvasFormat.launcherIcon;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (layered) ...[
          Text('Foreground layer', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
        ],
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
        Text(
          state.formats.length > 1 ? 'Format' : 'Size',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (state.formats.length > 1)
          SegmentedButton<CanvasFormat>(
            segments: [
              for (final f in state.formats)
                ButtonSegment(value: f, label: Text(f.label)),
            ],
            selected: {state.format},
            onSelectionChanged: (s) => state.setFormat(s.first),
          )
        else
          Text('${state.format.label} px, ${_typeNames(state.format)} only'),
        if (state.format.circleDiameter case final circle?) ...[
          const SizedBox(height: 4),
          Text(
            state.format.squareGuide != null
                ? 'Safe zone: ${state.format.squareGuide} px rounded square with a $circle px circle inside'
                : 'Safe circle: $circle px',
            style: theme.textTheme.bodySmall,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              state.format.squareGuide != null
                  ? 'Show safe zone overlay'
                  : 'Show circle overlay',
            ),
            value: state.showOverlay,
            onChanged: (_) => state.toggleOverlay(),
          ),
        ],
        if (state.margins case final margins?) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Margins (px)', style: theme.textTheme.titleSmall),
              const Spacer(),
              TextButton(
                onPressed: margins == state.format.defaultMargins
                    ? null
                    : state.resetMargins,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MarginField(
                  label: 'Left',
                  value: margins.left,
                  onChanged: (v) => state.setMargins(margins.copyWith(left: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MarginField(
                  label: 'Right',
                  value: margins.right,
                  onChanged: (v) =>
                      state.setMargins(margins.copyWith(right: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MarginField(
                  label: 'Top',
                  value: margins.top,
                  onChanged: (v) => state.setMargins(margins.copyWith(top: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MarginField(
                  label: 'Bottom',
                  value: margins.bottom,
                  onChanged: (v) =>
                      state.setMargins(margins.copyWith(bottom: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Safe area: ${state.safeArea.width.round()} × ${state.safeArea.height.round()} px',
            style: theme.textTheme.bodySmall,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show margin overlay'),
            value: state.showOverlay,
            onChanged: (_) => state.toggleOverlay(),
          ),
        ],
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
              onPressed: hasImage ? state.fit : null,
              child: Text(
                state.format.circleDiameter != null
                    ? 'Fit in circle'
                    : 'Fit inside',
              ),
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
        Text(
          layered ? 'Background layer' : 'Background',
          style: theme.textTheme.titleSmall,
        ),
        if (state.format.allowsTransparentBackground)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Transparent background'),
            value: state.transparentBackground,
            onChanged: state.setTransparentBackground,
          )
        else
          const SizedBox(height: 8),
        _ColorTile(
          label: 'Background',
          color: state.backgroundColor,
          enabled: !state.transparentBackground,
          onTap: () => _pickBackground(state),
          onHex: state.setBackgroundColor,
        ),
        Text(
          state.transparentBackground
              ? 'The PNG keeps a transparent background.'
              : state.format.allowsTransparentBackground
              ? 'Transparent parts of the image show this colour.'
              : 'Transparent parts of the image show this colour. The exported file is always opaque.',
          style: theme.textTheme.bodySmall,
        ),
        const Divider(height: 32),
        Row(
          children: [
            Text('Foreground tint', style: theme.textTheme.titleSmall),
            const Spacer(),
            Switch(value: state.tintEnabled, onChanged: state.setTintEnabled),
          ],
        ),
        _ColorTile(
          label: 'Foreground',
          color: state.tintColor,
          enabled: state.tintEnabled,
          onTap: () => _pickTint(state),
          onHex: state.setTintColor,
        ),
        Text(
          'Recolours the whole image in one colour, keeping its shape and transparency.',
          style: theme.textTheme.bodySmall,
        ),
        const Divider(height: 32),
        Text('Export', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final type in state.format.exportTypes) ...[
              Expanded(
                child: FilledButton.tonal(
                  onPressed: hasImage && !_busy
                      ? () => _export(state, type)
                      : null,
                  child: Text('Export ${type.label}'),
                ),
              ),
              if (type != state.format.exportTypes.last)
                const SizedBox(width: 8),
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

/// Whole-pixel margin input. Shows the stored value again when the edit is
/// cleared or limited, so the field always matches the overlay.
class _MarginField extends StatefulWidget {
  const _MarginField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_MarginField> createState() => _MarginFieldState();
}

class _MarginFieldState extends State<_MarginField> {
  late final _controller = TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _sync();
    });
  }

  @override
  void didUpdateWidget(_MarginField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // While typing, only catch up when the value changed for another reason
    // (Reset, or a limit), so a half-typed or empty field isn't overwritten.
    if (!_focus.hasFocus ||
        (widget.value != oldWidget.value &&
            int.tryParse(_controller.text) != widget.value)) {
      _sync();
    }
  }

  void _sync() {
    final text = '${widget.value}';
    if (_controller.text != text) _controller.text = text;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: widget.label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (text) {
        final v = int.tryParse(text);
        if (v != null) widget.onChanged(v);
      },
      onSubmitted: (_) => _sync(),
    );
  }
}

String _typeNames(CanvasFormat format) =>
    format.exportTypes.map((t) => t.label).join(' / ');

/// Parses a hex colour typed as RRGGBB or RGB, with or without a leading
/// `#`. Returns an opaque colour, or null when the text isn't a full code.
Color? parseHexColor(String text) {
  var hex = text.trim().replaceFirst('#', '');
  if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
  if (hex.length != 6) return null;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}

String _hexOf(Color color) => (color.toARGB32() & 0xFFFFFF)
    .toRadixString(16)
    .padLeft(6, '0')
    .toUpperCase();

/// Colour swatch and an editable hex code. Tap the swatch or the palette
/// button for the picker, or type a code such as 355070 or #E56B6F.
class _ColorTile extends StatefulWidget {
  const _ColorTile({
    required this.label,
    required this.color,
    required this.onTap,
    required this.onHex,
    this.enabled = true,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final ValueChanged<Color> onHex;
  final bool enabled;

  @override
  State<_ColorTile> createState() => _ColorTileState();
}

class _ColorTileState extends State<_ColorTile> {
  late final _controller = TextEditingController(text: _hexOf(widget.color));
  final _focus = FocusNode();
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _sync();
    });
  }

  @override
  void didUpdateWidget(_ColorTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow the picker; while typing, only when the colour really changed
    // to something other than what is being typed.
    if (!_focus.hasFocus ||
        (widget.color != oldWidget.color &&
            parseHexColor(_controller.text) != widget.color)) {
      _sync();
    }
  }

  void _sync() {
    final hex = _hexOf(widget.color);
    if (_controller.text != hex) _controller.text = hex;
    if (_invalid) setState(() => _invalid = false);
  }

  void _onChanged(String text) {
    final color = parseHexColor(text);
    setState(() => _invalid = color == null && text.isNotEmpty);
    if (color != null && color != widget.color) widget.onHex(color);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Opacity(
      opacity: widget.enabled ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color,
                  border: Border.all(color: outline),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(7),
                ],
                decoration: InputDecoration(
                  labelText: '${widget.label} hex',
                  prefixText: '#',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  errorText: _invalid ? 'Use 6 hex digits' : null,
                ),
                onChanged: _onChanged,
                onSubmitted: (_) => _sync(),
              ),
            ),
            IconButton(
              tooltip: 'Pick ${widget.label.toLowerCase()} colour',
              icon: const Icon(Icons.palette_outlined),
              onPressed: widget.onTap,
            ),
          ],
        ),
      ),
    );
  }
}
