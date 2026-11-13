import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

/// One bucket per purpose. Paths always begin with the owner's user id, which
/// is what the storage policies check.
class StorageService {
  static const workPhotosBucket = 'work-photos';
  static const jobPhotosBucket = 'job-photos';
  static const cnicBucket = 'cnic-documents';

  static const _jpeg = FileOptions(contentType: 'image/jpeg', upsert: false);

  SupabaseStorageClient get _storage => SupabaseConfig.client.storage;

  Future<String> _upload(
    String bucket,
    String userId,
    String name,
    Uint8List bytes,
  ) async {
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}_$name.jpg';
    await _storage.from(bucket).uploadBinary(path, bytes, fileOptions: _jpeg);
    return path;
  }

  Future<String> uploadWorkPhoto(String userId, Uint8List bytes) =>
      _upload(workPhotosBucket, userId, 'work', bytes);

  /// Best-effort: callers have already updated the database.
  Future<void> deleteWorkPhoto(String path) async {
    try {
      await _storage.from(workPhotosBucket).remove([path]);
    } catch (error) {
      debugPrint('Could not remove work photo $path: $error');
    }
  }

  Future<List<String>> uploadJobPhotos(
    String userId,
    List<Uint8List> photos,
  ) async {
    final paths = <String>[];
    try {
      for (var i = 0; i < photos.length; i++) {
        paths.add(await _upload(jobPhotosBucket, userId, 'job$i', photos[i]));
      }
      return paths;
    } catch (_) {
      await deleteJobPhotos(paths);
      rethrow;
    }
  }

  /// Best-effort cleanup: a failed delete must not mask the original error.
  Future<void> deleteJobPhotos(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _storage.from(jobPhotosBucket).remove(paths);
    } catch (error) {
      debugPrint('Could not remove job photos: $error');
    }
  }

  Future<String> uploadCnicDocument(
    String userId,
    String name,
    Uint8List bytes,
  ) => _upload(cnicBucket, userId, name, bytes);

  static String workPhotoUrl(String path) =>
      SupabaseConfig.client.storage.from(workPhotosBucket).getPublicUrl(path);

  /// Short-lived URLs for private job photos, keyed by path.
  Future<Map<String, String>> signJobPhotos(List<String> paths) async {
    if (paths.isEmpty) return const {};
    final results = await _storage
        .from(jobPhotosBucket)
        .createSignedUrlsResult(paths, 3600);
    return {
      for (final result in results)
        if (result is SignedUrlSuccess) result.path: result.signedUrl,
    };
  }
}
