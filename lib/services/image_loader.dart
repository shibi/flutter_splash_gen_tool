import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class LoadedImage {
  const LoadedImage({
    required this.image,
    required this.preview,
    required this.path,
  });

  /// Full-resolution pixels used for export.
  final img.Image image;

  /// Same pixels as a GPU image for the on-screen preview.
  final ui.Image preview;

  final String path;
}

const _imageTypes = XTypeGroup(
  label: 'Images',
  extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'],
);

/// Shows the open dialog and decodes the chosen file. Returns null when the
/// user cancels; throws [FormatException] if the file can't be decoded.
Future<LoadedImage?> pickImage() async {
  final file = await openFile(acceptedTypeGroups: [_imageTypes]);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final decoded = await compute(_decode, bytes);
  if (decoded == null) {
    throw FormatException('Unsupported or corrupt image: ${file.name}');
  }
  final (image, pixels) = decoded;
  final preview = await _toUiImage(pixels, image.width, image.height);
  return LoadedImage(image: image, preview: preview, path: file.path);
}

(img.Image, Uint8List)? _decode(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final image = img.bakeOrientation(decoded).convert(numChannels: 4);
  return (image, premultipliedRgba(image));
}

/// 8-bit RGBA bytes with colour multiplied by alpha, the layout Flutter's
/// [ui.PixelFormat.rgba8888] expects. Without this, transparent pixels that
/// store a colour (often white) would show up as that colour in the preview.
Uint8List premultipliedRgba(img.Image image) {
  final rgba = image
      .convert(format: img.Format.uint8, numChannels: 4)
      .getBytes(order: img.ChannelOrder.rgba);
  for (var i = 0; i < rgba.length; i += 4) {
    final a = rgba[i + 3];
    if (a == 255) continue;
    rgba[i] = (rgba[i] * a + 127) ~/ 255;
    rgba[i + 1] = (rgba[i + 1] * a + 127) ~/ 255;
    rgba[i + 2] = (rgba[i + 2] * a + 127) ~/ 255;
  }
  return rgba;
}

Future<ui.Image> _toUiImage(Uint8List rgba, int width, int height) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: width,
    height: height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  final frame = await codec.getNextFrame();
  return frame.image;
}
