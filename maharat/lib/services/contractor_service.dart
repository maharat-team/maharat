import 'package:latlong2/latlong.dart';
import '../core/config/supabase_config.dart';
import '../models/contractor_model.dart';
import '../models/verification_info.dart';
import 'storage_service.dart';
import 'worker_service.dart';

class ContractorApplication {
  final String businessName;
  final String phone;
  final List<String> trades;
  final String bio;
  final List<String> serviceAreas;
  final String shopAddress;
  final LatLng? location;
  final String cnicNumber;

  const ContractorApplication({
    required this.businessName,
    required this.phone,
    required this.trades,
    required this.bio,
    required this.serviceAreas,
    required this.shopAddress,
    required this.location,
    required this.cnicNumber,
  });

  ContractorApplication withCnic(String number) => ContractorApplication(
    businessName: businessName,
    phone: phone,
    trades: trades,
    bio: bio,
    serviceAreas: serviceAreas,
    shopAddress: shopAddress,
    location: location,
    cnicNumber: number,
  );
}

class ContractorService {
  static const selectColumns =
      '*, contractor_members(status, workers(*)), '
      'reviews(id, customer_name, rating, comment, tags, created_at)';

  static ContractorModel parse(Map<String, dynamic> json) =>
      ContractorModel.fromJson(
        json,
        photoUrl: StorageService.workPhotoUrl,
        parseWorker: WorkerService.parse,
      );

  /// Verified shops, best rated first.
  Future<List<ContractorModel>> fetchDirectory() async {
    final rows = await SupabaseConfig.client
        .from('contractors')
        .select(selectColumns)
        .eq('verification_status', 'approved')
        .order('rating_avg', ascending: false)
        .limit(100);
    return rows.map(parse).toList();
  }

  Future<ContractorModel?> fetchOwn(String userId) async {
    final row = await SupabaseConfig.client
        .from('contractors')
        .select(selectColumns)
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : parse(row);
  }

  Future<VerificationInfo?> fetchVerification(String userId) async {
    final row = await SupabaseConfig.client
        .from('contractor_verifications')
        .select('status, rejection_reason, rejection_code, face_match_score')
        .eq('contractor_id', userId)
        .maybeSingle();
    return row == null ? null : VerificationInfo.fromJson(row);
  }

  Future<void> submitApplication(
    ContractorApplication application, {
    required String? shopPhotoPath,
    required String frontPath,
    required String backPath,
    required String selfiePath,
  }) async {
    await SupabaseConfig.client.rpc(
      'submit_contractor_application',
      params: {
        'p_business_name': application.businessName,
        'p_phone': application.phone,
        'p_trades': application.trades,
        'p_bio': application.bio,
        'p_service_areas': application.serviceAreas,
        'p_shop_address': application.shopAddress,
        'p_lat': application.location?.latitude,
        'p_lng': application.location?.longitude,
        'p_shop_photo_path': shopPhotoPath,
        'p_cnic_number': application.cnicNumber,
        'p_front_path': frontPath,
        'p_back_path': backPath,
        'p_selfie_path': selfiePath,
      },
    );
  }

  Future<void> update(String userId, Map<String, dynamic> fields) async {
    await SupabaseConfig.client
        .from('contractors')
        .update(fields)
        .eq('id', userId);
  }

  // Team

  /// Everyone invited to or working in this contractor's team.
  Future<List<TeamMembership>> fetchTeam(String contractorId) async {
    final rows = await SupabaseConfig.client
        .from('contractor_members')
        .select('*, workers(*)')
        .eq('contractor_id', contractorId)
        .order('created_at', ascending: false);
    return rows
        .map(
          (row) => TeamMembership(
            contractorId: row['contractor_id'] as String,
            workerId: row['worker_id'] as String,
            isActive: row['status'] == 'active',
            createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
            worker: row['workers'] == null
                ? null
                : WorkerService.parse(row['workers'] as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  /// This worker's invitations and the teams they belong to.
  Future<List<TeamMembership>> fetchMemberships(String workerId) async {
    final rows = await SupabaseConfig.client
        .from('contractor_members')
        .select('*, contractors(*)')
        .eq('worker_id', workerId)
        .order('created_at', ascending: false);
    return rows
        .map(
          (row) => TeamMembership(
            contractorId: row['contractor_id'] as String,
            workerId: row['worker_id'] as String,
            isActive: row['status'] == 'active',
            createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
            contractor: row['contractors'] == null
                ? null
                : parse(row['contractors'] as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  /// Returns the invited worker's name.
  Future<String> inviteMember(String phone) async {
    final name = await SupabaseConfig.client.rpc(
      'invite_team_member',
      params: {'p_phone': phone},
    );
    return name as String;
  }

  Future<void> respondToInvite(String contractorId, bool accept) async {
    await SupabaseConfig.client.rpc(
      'respond_to_team_invite',
      params: {'p_contractor_id': contractorId, 'p_accept': accept},
    );
  }

  Future<void> removeMembership(String contractorId, String workerId) async {
    await SupabaseConfig.client.rpc(
      'remove_team_membership',
      params: {'p_contractor_id': contractorId, 'p_worker_id': workerId},
    );
  }

  // Orders

  Future<void> respondToOrder(String jobId, bool accept) async {
    await SupabaseConfig.client.rpc(
      'respond_to_order',
      params: {'p_job_id': jobId, 'p_accept': accept},
    );
  }

  Future<void> assignTeam(String jobId, List<String> workerIds) async {
    await SupabaseConfig.client.rpc(
      'assign_order_team',
      params: {'p_job_id': jobId, 'p_worker_ids': workerIds},
    );
  }
}
