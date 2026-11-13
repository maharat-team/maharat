import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/job_request_model.dart';
import 'contractor_service.dart';
import 'storage_service.dart';
import 'worker_service.dart';

class JobService {
  JobService({StorageService? storage})
    : _storage = storage ?? StorageService();

  final StorageService _storage;

  // reviews links job_requests to contractors too, so the direct relation is
  // named to keep the embed unambiguous.
  static const _select =
      '*, job_interests(created_at, workers(${WorkerService.selectColumns})), '
      'reviews(rating, comment), '
      'job_locations(lat, lng, address_details), '
      'contractors!job_requests_contractor_id_fkey(*), '
      'job_assignments(assigned_at, workers(${WorkerService.selectColumns}))';

  SupabaseClient get _client => SupabaseConfig.client;

  JobRequestModel _parse(Map<String, dynamic> json) => JobRequestModel.fromJson(
    json,
    parseWorker: WorkerService.parse,
    parseContractor: ContractorService.parse,
  );

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
  /// Orders sent to a contractor are private to that contractor.
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
        .isFilter('contractor_id', null)
        .inFilter('location', serviceAreas)
        .neq('customer_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return _withPhotoUrls(rows.map(_parse).toList());
  }

  /// Orders customers sent to this contractor's shop.
  Future<List<JobRequestModel>> fetchContractorOrders(
    String contractorId,
  ) async {
    final rows = await _client
        .from('job_requests')
        .select(_select)
        .eq('contractor_id', contractorId)
        .order('created_at', ascending: false)
        .limit(100);
    return _withPhotoUrls(rows.map(_parse).toList());
  }

  /// Jobs a contractor has sent this worker to.
  Future<List<JobRequestModel>> fetchAssignedJobs(String workerId) async {
    final assignments = await _client
        .from('job_assignments')
        .select('job_id')
        .eq('worker_id', workerId)
        .order('assigned_at', ascending: false)
        .limit(50);
    final ids = assignments.map((a) => a['job_id'] as String).toList();
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('job_requests')
        .select(_select)
        .inFilter('id', ids)
        .order('created_at', ascending: false);
    return _withPhotoUrls(rows.map(_parse).toList());
  }

  /// Posts a job with its exact pin in one transaction.
  Future<JobRequestModel> create({
    required String trade,
    required String description,
    required String location,
    required String urgency,
    required List<String> photoPaths,
    String? contractorId,
    LatLng? point,
    String addressDetails = '',
  }) async {
    final id = await _client.rpc(
      'post_job',
      params: {
        'p_trade': trade,
        'p_description': description,
        'p_location': location,
        'p_urgency': JobRequestModel.urgencyToDb(urgency),
        'p_photo_paths': photoPaths,
        'p_contractor_id': contractorId,
        'p_lat': point?.latitude,
        'p_lng': point?.longitude,
        'p_address_details': addressDetails,
      },
    );
    final row = await _client
        .from('job_requests')
        .select(_select)
        .eq('id', id as String)
        .single();
    return (await _withPhotoUrls([_parse(row)])).first;
  }

  Future<void> close(String jobId) async {
    await _client
        .from('job_requests')
        .update({'status': 'closed'})
        .eq('id', jobId);
  }

  /// [workerId] is required for jobs sent to all workers and must be null for
  /// contractor orders, where the contractor's team did the work.
  Future<void> complete(String jobId, String? workerId) async {
    await _client
        .from('job_requests')
        .update({'status': 'completed', 'assigned_worker_id': ?workerId})
        .eq('id', jobId);
  }

  Future<void> expressInterest(String jobId, String workerId) async {
    await _client.from('job_interests').insert({
      'job_id': jobId,
      'worker_id': workerId,
    });
  }

  /// Calls [onChange] when jobs, interests, assignments or team invitations
  /// change. RLS scopes delivery, so users only hear about their own rows.
  Object subscribeToChanges(VoidCallback onChange) {
    void notify(PostgresChangePayload _) => onChange();
    return _client
        .channel('maharat-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'job_interests',
          callback: notify,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'job_requests',
          callback: notify,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'job_assignments',
          callback: notify,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'contractor_members',
          callback: notify,
        )
        .subscribe();
  }

  Future<void> unsubscribe(Object subscription) async {
    await _client.removeChannel(subscription as RealtimeChannel);
  }
}
