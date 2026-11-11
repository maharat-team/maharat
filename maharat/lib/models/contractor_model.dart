import 'package:latlong2/latlong.dart';
import '../core/utils/geo.dart';
import 'review_model.dart';
import 'worker_model.dart';

/// A shop owner who takes orders and sends workers from their team.
class ContractorModel {
  final String id;
  final String businessName;
  final String ownerName;
  final String phone;
  final List<String> trades;
  final String bio;
  final String neighbourhood;
  final List<String> serviceAreas;
  final String shopAddress;
  final LatLng? location;
  final String? shopPhotoUrl;
  final bool isAcceptingOrders;
  final VerificationStatus verificationStatus;
  final double rating;
  final int reviewCount;
  final int completedJobsCount;

  /// Active team members. Empty when not loaded.
  final List<WorkerModel> team;
  final List<ReviewModel> reviews;

  const ContractorModel({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.trades,
    required this.bio,
    required this.neighbourhood,
    required this.serviceAreas,
    required this.shopAddress,
    required this.location,
    required this.shopPhotoUrl,
    required this.isAcceptingOrders,
    required this.verificationStatus,
    required this.rating,
    required this.reviewCount,
    required this.completedJobsCount,
    this.team = const [],
    this.reviews = const [],
  });

  bool get isVerified => verificationStatus == VerificationStatus.approved;

  /// [photoUrl] resolves a storage path; [parseWorker] builds team members.
  factory ContractorModel.fromJson(
    Map<String, dynamic> json, {
    required String Function(String path) photoUrl,
    required WorkerModel Function(Map<String, dynamic>) parseWorker,
  }) {
    final members = List<Map<String, dynamic>>.from(
      json['contractor_members'] as List? ?? const [],
    );
    final reviews = List<Map<String, dynamic>>.from(
      json['reviews'] as List? ?? const [],
    )..sort((a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'));
    final shopPhoto = json['shop_photo_path'] as String?;

    return ContractorModel(
      id: json['id'] as String,
      businessName: json['business_name'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      trades: List<String>.from(json['trades'] as List? ?? const []),
      bio: json['bio'] as String? ?? '',
      neighbourhood: json['neighbourhood'] as String? ?? '',
      serviceAreas: List<String>.from(
        json['service_areas'] as List? ?? const [],
      ),
      shopAddress: json['shop_address'] as String? ?? '',
      location: latLngOrNull(json['lat'], json['lng']),
      shopPhotoUrl: shopPhoto == null ? null : photoUrl(shopPhoto),
      isAcceptingOrders: json['is_accepting_orders'] as bool? ?? true,
      verificationStatus: VerificationStatus.values.byName(
        json['verification_status'] as String? ?? 'approved',
      ),
      rating: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      completedJobsCount: json['completed_jobs_count'] as int? ?? 0,
      team: members
          .where((m) => m['status'] == 'active' && m['workers'] != null)
          .map((m) => parseWorker(m['workers'] as Map<String, dynamic>))
          .toList(),
      reviews: reviews.map(ReviewModel.fromJson).toList(),
    );
  }

  ContractorModel copyWith({bool? isAcceptingOrders}) {
    return ContractorModel(
      id: id,
      businessName: businessName,
      ownerName: ownerName,
      phone: phone,
      trades: trades,
      bio: bio,
      neighbourhood: neighbourhood,
      serviceAreas: serviceAreas,
      shopAddress: shopAddress,
      location: location,
      shopPhotoUrl: shopPhotoUrl,
      isAcceptingOrders: isAcceptingOrders ?? this.isAcceptingOrders,
      verificationStatus: verificationStatus,
      rating: rating,
      reviewCount: reviewCount,
      completedJobsCount: completedJobsCount,
      team: team,
      reviews: reviews,
    );
  }
}

/// A worker's place in a contractor's team, seen from either side.
class TeamMembership {
  final String contractorId;
  final String workerId;
  final bool isActive;
  final DateTime createdAt;

  /// Filled when listing a contractor's team.
  final WorkerModel? worker;

  /// Filled when listing a worker's invitations and teams.
  final ContractorModel? contractor;

  const TeamMembership({
    required this.contractorId,
    required this.workerId,
    required this.isActive,
    required this.createdAt,
    this.worker,
    this.contractor,
  });

  bool get isInvite => !isActive;
}
