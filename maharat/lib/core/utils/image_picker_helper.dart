import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/l10n.dart';
import 'error_messages.dart';
import 'image_compressor.dart';

/// Asks for a source, then returns a compressed JPEG ready to upload.
/// Returns null if the user cancels. Shows a snackbar if the photo is unusable.
///
/// With [cameraOnly] the gallery is not offered, which is what a live selfie
/// for identity checks needs; [frontCamera] opens the selfie camera.
Future<Uint8List?> pickCompressedImage(
  BuildContext context, {
  int maxDimension = ImageCompressor.defaultMaxDimension,
  int maxBytes = ImageCompressor.defaultMaxBytes,
  bool cameraOnly = false,
  bool frontCamera = false,
}) async {
  final ImageSource? source = cameraOnly
      ? ImageSource.camera
      : await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(ctx.tr('Take a photo', 'تصویر کھینچیں')),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(
                    ctx.tr('Choose from gallery', 'گیلری سے منتخب کریں'),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
  if (source == null) return null;

  try {
    // The picker's own resize converts HEIC to JPEG on iOS and keeps the
    // Dart-side compression fast.
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
      imageQuality: 90,
      preferredCameraDevice: frontCamera ? CameraDevice.front : CameraDevice.rear,
    );
    if (file == null) return null;
    return await ImageCompressor.compress(
      await file.readAsBytes(),
      maxDimension: maxDimension,
      maxBytes: maxBytes,
    );
  } on ImageCompressionException {
    if (context.mounted) {
      _show(
        context,
        tr('That photo format is not supported.', 'یہ تصویر سپورٹ نہیں ہوتی۔'),
      );
    }
  } catch (error) {
    if (context.mounted) _show(context, friendlyError(error));
  }
  return null;
}

void _show(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
