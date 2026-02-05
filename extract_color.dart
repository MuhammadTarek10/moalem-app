import 'dart:io';

import 'package:image/image.dart' as img;

void main() async {
  try {
    final file = File('assets/images/app_logo.png');
    if (!file.existsSync()) {
      print('FILE_NOT_FOUND');
      return;
    }
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      print('DECODE_ERROR');
      return;
    }

    var r = 0.0, g = 0.0, b = 0.0;
    var count = 0;

    // Sample pixels
    for (var y = 0; y < image.height; y += 10) {
      for (var x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        r += pixel.r;
        g += pixel.g;
        b += pixel.b;
        count++;
      }
    }

    if (count > 0) {
      final avgR = (r / count).round().clamp(0, 255);
      final avgG = (g / count).round().clamp(0, 255);
      final avgB = (b / count).round().clamp(0, 255);

      final hex =
          '#${avgR.toRadixString(16).padLeft(2, '0')}'
          '${avgG.toRadixString(16).padLeft(2, '0')}'
          '${avgB.toRadixString(16).padLeft(2, '0')}';
      print(hex.toUpperCase());
    } else {
      print('NO_PIXELS');
    }
  } catch (e) {
    print('ERROR: $e');
  }
}
