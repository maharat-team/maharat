import '../core/config/supabase_config.dart';

class ReviewService {
  Future<void> create({
    required String jobId,
    required String workerId,
    required double rating,
    required String comment,
    required List<String> tags,
  }) async {
    await SupabaseConfig.client.from('reviews').insert({
      'job_id': jobId,
      'worker_id': workerId,
      'rating': rating,
      'comment': comment,
      'tags': tags,
    });
  }
}
