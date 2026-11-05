import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageCompressionException implements Exception {
  const ImageCompressionException();
}

class _Job {
  final Uint8List bytes;
  final int maxDimension;
  final int maxBytes;
  const _Job(this.bytes, this.maxDimension, this.maxBytes);
}

/// Resizes and re-encodes photos to JPEG before upload.
///
/// Re-encoding also drops EXIF metadata, so GPS coordinates embedded by phone
/// cameras never reach the server. Runs off the UI thread.
class ImageCompressor {
  static const int defaultMaxDimension = 1600;
  static const int defaultMaxBytes = 700 * 1024;

  static Future<Uint8List> compress(
    Uint8List bytes, {
    int maxDimension = defaultMaxDimension,
    int maxBytes = defaultMaxBytes,
  }) => compute(_run, _Job(bytes, maxDimension, maxBytes));

  static Uint8List _run(_Job job) {
    final decoded = img.decodeImage(job.bytes);
    if (decoded == null) throw const ImageCompressionException();

    var image = img.bakeOrientation(decoded);
    if (image.width > job.maxDimension || image.height > job.maxDimension) {
      image = image.width >= image.height
          ? img.copyResize(image, width: job.maxDimension)
          : img.copyResize(image, height: job.maxDimension);
    }
    if (image.hasAlpha) {
      final background = img.Image(width: image.width, height: image.height);
      img.fill(background, color: img.ColorRgb8(255, 255, 255));
      image = img.compositeImage(background, image);
    }
    image.exif = img.ExifData();

    late Uint8List encoded;
    for (final quality in const [82, 72, 62, 52, 42]) {
      encoded = img.encodeJpg(image, quality: quality);
      if (encoded.length <= job.maxBytes) break;
    }
    return encoded;
  }
}
