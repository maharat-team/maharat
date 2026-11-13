import 'package:latlong2/latlong.dart';
import '../core/config/supabase_config.dart';
import '../models/verification_info.dart';
import '../models/worker_model.dart';
import 'storage_service.dart';

class WorkerApplication {
  final String trade;
  final String phone;
  final String bio;
  final int experienceYears;
  final int visitFee;
  final List<String> serviceAreas;
  final String cnicNumber;
  final LatLng? baseLocation;

  const WorkerApplication({
    required this.trade,
    required this.phone,
    required this.bio,
    required this.experienceYears,
    required this.visitFee,
    required this.serviceAreas,
    required this.cnicNumber,
    this.baseLocation,
  });
}

class WorkerService {
  static const selectColumns =
      '*, worker_photos(id, storage_path, created_at), '
      'reviews(id, customer_name, rating, comment, tags, created_at)';

  static WorkerModel parse(Map<String, dynamic> json) =>
      WorkerModel.fromJson(json, photoUrl: StorageService.workPhotoUrl);

  /// The approved directory. Search and filters run client-side on this list.
  Future<List<WorkerModel>> fetchDirectory() async {
    final rows = await SupabaseConfig.client
        .from('workers')
        .select(selectColumns)
        .eq('verification_status', 'approved')
        .order('rating_avg', ascending: false)
        .limit(200);
    return rows.map(parse).toList();
  }

  Future<WorkerModel?> fetchOwn(String userId) async {
    final row = await SupabaseConfig.client
        .from('workers')
        .select(selectColumns)
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : parse(row);
  }

  /// The latest identity check: status, face score and any rejection reason.
  Future<VerificationInfo?> fetchVerification(String userId) async {
    final row = await SupabaseConfig.client
        .from('cnic_verifications')
        .select('status, rejection_reason, rejection_code, face_match_score')
        .eq('worker_id', userId)
        .maybeSingle();
    return row == null ? null : VerificationInfo.fromJson(row);
  }

  /// Edits the fields a worker may change after registering.
  Future<void> updateProfile(String userId, Map<String, dynamic> fields) async {
    await SupabaseConfig.client.from('workers').update(fields).eq('id', userId);
  }

  Future<void> submitApplication(
    WorkerApplication application, {
    required String frontPath,
    required String backPath,
    required String selfiePath,
  }) async {
    await SupabaseConfig.client.rpc(
      'submit_worker_application',
      params: {
        'p_trade': application.trade,
        'p_phone': application.phone,
        'p_bio': application.bio,
        'p_experience_years': application.experienceYears,
        'p_visit_fee': application.visitFee,
        'p_service_areas': application.serviceAreas,
        'p_cnic_number': application.cnicNumber,
        'p_front_path': frontPath,
        'p_back_path': backPath,
        'p_selfie_path': selfiePath,
        'p_base_lat': application.baseLocation?.latitude,
        'p_base_lng': application.baseLocation?.longitude,
      },
    );
  }

  Future<void> setAvailability(String userId, bool isAvailable) async {
    await SupabaseConfig.client
        .from('workers')
        .update({'is_available_today': isAvailable})
        .eq('id', userId);
  }

  Future<WorkPhoto> addPhoto(String userId, String storagePath) async {
    final row = await SupabaseConfig.client
        .from('worker_photos')
        .insert({'worker_id': userId, 'storage_path': storagePath})
        .select('id')
        .single();
    return WorkPhoto(
      id: row['id'] as String,
      path: storagePath,
      url: StorageService.workPhotoUrl(storagePath),
    );
  }

  Future<void> deletePhoto(String photoId) async {
    await SupabaseConfig.client
        .from('worker_photos')
        .delete()
        .eq('id', photoId);
  }
}
