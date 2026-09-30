import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/editor_state.dart';
import '../models/splash_format.dart';

/// Format, scale, background and export controls.
class ControlsPanel extends StatelessWidget {
  const ControlsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: null, // Milestone 2: image picker.
          icon: const Icon(Icons.image_outlined),
          label: const Text('Open image'),
        ),
        const SizedBox(height: 24),
        Text('Format', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<SplashFormat>(
          segments: [
            for (final f in SplashFormat.values)
              ButtonSegment(value: f, label: Text(f.label)),
          ],
          selected: {state.format},
          onSelectionChanged: (s) => state.setFormat(s.first),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show circle overlay'),
          value: state.showOverlay,
          onChanged: (_) => state.toggleOverlay(),
        ),
      ],
    );
  }
}
