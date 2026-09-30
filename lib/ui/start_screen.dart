import 'package:flutter/material.dart';

import '../models/canvas_format.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';
import 'theme_toggle.dart';

/// Landing page. Each tool gets a button here; more can be added later.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icon/app_icon.png',
                        width: 128,
                        height: 128,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Splash GenX',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tools for Flutter splash screens',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _PaletteStrip(),
                      const SizedBox(height: 32),
                      _ToolButton(
                        icon: Icons.auto_awesome,
                        label: 'Create Splash Icon',
                        builder: (_) => const EditorScreen(
                          title: 'Create Splash Icon',
                          formats: CanvasFormat.splashFormats,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ToolButton(
                        icon: Icons.branding_watermark_outlined,
                        label: 'Create Branding Logo',
                        builder: (_) => const EditorScreen(
                          title: 'Create Branding Logo',
                          formats: [CanvasFormat.branding],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Developer: shibinpr',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.builder,
  });

  final IconData icon;
  final String label;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: builder)),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

/// Thin bar showing the brand palette.
class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip();

  static const _colors = [
    Palette.navy,
    Palette.plum,
    Palette.rose,
    Palette.coral,
    Palette.peach,
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: 200,
        height: 6,
        child: Row(
          children: [
            for (final c in _colors) Expanded(child: ColoredBox(color: c)),
          ],
        ),
      ),
    );
  }
}
