import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/job_request_model.dart';
import 'storage_service.dart';
import 'worker_service.dart';

class JobService {
  JobService({StorageService? storage})
    : _storage = storage ?? StorageService();

  final StorageService _storage;

  static const _select =
      '*, job_interests(created_at, workers(${WorkerService.selectColumns})), '
      'reviews(rating, comment)';

  SupabaseClient get _client => SupabaseConfig.client;

  JobRequestModel _parse(Map<String, dynamic> json) =>
      JobRequestModel.fromJson(json, parseWorker: WorkerService.parse);

  Future<List<JobRequestModel>> _withPhotoUrls(
    List<JobRequestModel> jobs,
  ) async {
    final paths = jobs.expand((j) => j.photoPaths).toSet().toList();
    try {
      final urls = await _storage.signJobPhotos(paths);
      return jobs
          .map(
            (j) => j.copyWith(
              photoUrls: j.photoPaths
                  .map((p) => urls[p])
                  .whereType<String>()
                  .toList(),
            ),
          )
          .toList();
    } catch (error) {
      // Photos are supplementary; the job list is still useful without them.
      debugPrint('Could not sign job photos: $error');
      return jobs;
    }
  }

  Future<List<JobRequestModel>> fetchCustomerJobs(String userId) async {
    final rows = await _client
        .from('job_requests')
        .select(_select)
        .eq('customer_id', userId)
        .order('created_at', ascending: false)
        .limit(100);
    return _withPhotoUrls(rows.map(_parse).toList());
  }

  /// Open jobs in the worker's trade and service areas, excluding their own.
  Future<List<JobRequestModel>> fetchNearbyJobs({
    required String userId,
    required String trade,
    required List<String> serviceAreas,
  }) async {
    final rows = await _client
        .from('job_requests')
        .select(_select)
        .eq('status', 'active')
        .eq('trade', trade)
        .inFilter('location', serviceAreas)
        .neq('customer_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return _withPhotoUrls(rows.map(_parse).toList());
  }

  Future<JobRequestModel> create({
    required String trade,
    required String description,
    required String location,
    required String urgency,
    required List<String> photoPaths,
  }) async {
    final row = await _client
        .from('job_requests')
        .insert({
          'trade': trade,
          'description': description,
          'location': location,
          'urgency': JobRequestModel.urgencyToDb(urgency),
          'photo_paths': photoPaths,
        })
        .select(_select)
        .single();
    return (await _withPhotoUrls([_parse(row)])).first;
  }

  Future<void> close(String jobId) async {
    await _client
        .from('job_requests')
        .update({'status': 'closed'})
        .eq('id', jobId);
  }

  Future<void> complete(String jobId, String workerId) async {
    await _client
        .from('job_requests')
        .update({'status': 'completed', 'assigned_worker_id': workerId})
        .eq('id', jobId);
  }

  Future<void> expressInterest(String jobId, String workerId) async {
    await _client.from('job_interests').insert({
      'job_id': jobId,
      'worker_id': workerId,
    });
  }

  /// Calls [onChange] whenever a visible interest row appears. RLS scopes
  /// delivery, so a customer only hears about their own jobs.
  Object subscribeToInterests(VoidCallback onChange) {
    return _client
        .channel('job-interests')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'job_interests',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> unsubscribe(Object subscription) async {
    await _client.removeChannel(subscription as RealtimeChannel);
  }
}
