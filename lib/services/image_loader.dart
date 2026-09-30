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
  final image = await compute(_decode, bytes);
  if (image == null) {
    throw FormatException('Unsupported or corrupt image: ${file.name}');
  }
  final preview = await _toUiImage(image);
  return LoadedImage(image: image, preview: preview, path: file.path);
}

img.Image? _decode(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  return img.bakeOrientation(decoded).convert(numChannels: 4);
}

Future<ui.Image> _toUiImage(img.Image image) async {
  final rgba = image
      .convert(format: img.Format.uint8, numChannels: 4)
      .getBytes(order: img.ChannelOrder.rgba);
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: image.width,
    height: image.height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  final frame = await codec.getNextFrame();
  return frame.image;
}
