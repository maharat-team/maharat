import '../core/config/supabase_config.dart';

class ReviewService {
  /// Reviews either the worker of a job or the contractor of an order;
  /// exactly one of [workerId] and [contractorId] is set.
  Future<void> create({
    required String jobId,
    String? workerId,
    String? contractorId,
    required double rating,
    required String comment,
    required List<String> tags,
  }) async {
    await SupabaseConfig.client.from('reviews').insert({
      'job_id': jobId,
      'worker_id': ?workerId,
      'contractor_id': ?contractorId,
      'rating': rating,
      'comment': comment,
      'tags': tags,
    });
  }
}
