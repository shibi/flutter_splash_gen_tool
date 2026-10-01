import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:splash_genx/services/image_loader.dart';

void main() {
  test(
    'preview pixels are premultiplied so transparent white is invisible',
    () {
      final image = img.Image(width: 3, height: 1, numChannels: 4)
        ..setPixelRgba(0, 0, 255, 255, 255, 0)
        ..setPixelRgba(1, 0, 255, 0, 0, 255)
        ..setPixelRgba(2, 0, 200, 100, 50, 128);
      final bytes = premultipliedRgba(image);
      expect(bytes.sublist(0, 4), [0, 0, 0, 0]);
      expect(bytes.sublist(4, 8), [255, 0, 0, 255]);
      expect(bytes.sublist(8, 12), [100, 50, 25, 128]);
    },
  );

  test('16-bit images are converted to 8-bit', () {
    final image = img.Image(
      width: 1,
      height: 1,
      numChannels: 4,
      format: img.Format.uint16,
    )..setPixelRgba(0, 0, 65535, 0, 0, 65535);
    expect(premultipliedRgba(image), [255, 0, 0, 255]);
  });
}
