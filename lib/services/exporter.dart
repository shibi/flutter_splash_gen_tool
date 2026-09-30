import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import 'splash_renderer.dart';

/// Renders in a background isolate, asks where to save and writes the file.
/// Returns the saved path, or null if the user cancelled.
Future<String?> exportSplash(RenderRequest request) async {
  final type = request.type;
  final location = await getSaveLocation(
    suggestedName: 'splash_${request.format.canvasSize}.${type.extension}',
    acceptedTypeGroups: [
      XTypeGroup(
        label: type.label,
        extensions: type == ExportType.png ? ['png'] : ['jpg', 'jpeg'],
      ),
    ],
  );
  if (location == null) return null;

  var path = location.path;
  final lower = path.toLowerCase();
  final hasExtension = type == ExportType.png
      ? lower.endsWith('.png')
      : lower.endsWith('.jpg') || lower.endsWith('.jpeg');
  if (!hasExtension) path = '$path.${type.extension}';

  final bytes = await compute(renderSplashBytes, request);
  await File(path).writeAsBytes(bytes);
  return path;
}
