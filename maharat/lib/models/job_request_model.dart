import 'package:latlong2/latlong.dart';
import '../core/utils/geo.dart';
import 'contractor_model.dart';
import 'worker_model.dart';

/// A contractor's reply to an order sent to their shop.
enum OrderStatus { pending, accepted, declined }

class JobRequestModel {
  final String id;
  final String customerId;
  final String customerName;
  final String tradeCategory;
  final String description;
  final List<String> photoPaths;
  final List<String> photoUrls;
  final String location;
  final String urgency; // "Today", "Tomorrow", "Any Day"
  final String status; // "Active", "Completed", "Closed"
  final DateTime createdAt;
  final List<WorkerModel> interestedWorkers;
  final double? ratingGiven;
  final String? reviewComment;
  final String? assignedWorkerId;

  /// Set when the job was sent to one contractor instead of all workers.
  final String? contractorId;
  final OrderStatus? orderStatus;
  final ContractorModel? contractor;

  /// Workers the contractor sent.
  final List<WorkerModel> assignedTeam;

  /// Rounded (about 1 km) point, visible to anyone who can see the job.
  final LatLng? approxLocation;

  /// The exact pin, visible only to the people working the job.
  final LatLng? exactLocation;
  final String addressDetails;

  /// Shared with the contractor and their workers on contractor orders.
  final String? customerPhone;

  static const _urgencyLabels = {
    'today': 'Today',
    'tomorrow': 'Tomorrow',
    'any_day': 'Any Day',
  };
  static const _statusLabels = {
    'active': 'Active',
    'completed': 'Completed',
    'closed': 'Closed',
  };

  JobRequestModel({
    required this.id,
    this.customerId = '',
    required this.customerName,
    required this.tradeCategory,
    required this.description,
    this.photoPaths = const [],
    this.photoUrls = const [],
    required this.location,
    required this.urgency,
    required this.status,
    required this.createdAt,
    this.interestedWorkers = const [],
    this.ratingGiven,
    this.reviewComment,
    this.assignedWorkerId,
    this.contractorId,
    this.orderStatus,
    this.contractor,
    this.assignedTeam = const [],
    this.approxLocation,
    this.exactLocation,
    this.addressDetails = '',
    this.customerPhone,
  });

  static String urgencyToDb(String label) =>
      _urgencyLabels.entries.firstWhere((e) => e.value == label).key;

  bool get isContractorOrder => contractorId != null;
  bool get isActive => status == 'Active';

  /// The best point known for this job.
  LatLng? get mapLocation => exactLocation ?? approxLocation;

  /// PostgREST embeds one-to-one relations as an object and others as a list.
  static Map<String, dynamic>? _single(Object? embedded) {
    if (embedded is List) {
      return embedded.isEmpty ? null : embedded.first as Map<String, dynamic>;
    }
    return embedded as Map<String, dynamic>?;
  }

  /// [parseWorker] and [parseContractor] build the embedded rows.
  factory JobRequestModel.fromJson(
    Map<String, dynamic> json, {
    required WorkerModel Function(Map<String, dynamic>) parseWorker,
    ContractorModel Function(Map<String, dynamic>)? parseContractor,
  }) {
    final interests = List<Map<String, dynamic>>.from(
      json['job_interests'] as List? ?? const [],
    )..sort((a, b) => '${a['created_at']}'.compareTo('${b['created_at']}'));
    final assignments = List<Map<String, dynamic>>.from(
      json['job_assignments'] as List? ?? const [],
    );

    final review = _single(json['reviews']);
    final exact = _single(json['job_locations']);
    final contractorRow = _single(json['contractors']);
    final orderStatus = json['contractor_status'] as String?;

    return JobRequestModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String? ?? '',
      tradeCategory: json['trade'] as String,
      description: json['description'] as String,
      photoPaths: List<String>.from(json['photo_paths'] as List? ?? const []),
      location: json['location'] as String,
      urgency: _urgencyLabels[json['urgency']] ?? 'Any Day',
      status: _statusLabels[json['status']] ?? 'Active',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      // A worker can disappear from the embed if they lose approval.
      interestedWorkers: interests
          .where((i) => i['workers'] != null)
          .map((i) => parseWorker(i['workers'] as Map<String, dynamic>))
          .toList(),
      ratingGiven: (review?['rating'] as num?)?.toDouble(),
      reviewComment: review?['comment'] as String?,
      assignedWorkerId: json['assigned_worker_id'] as String?,
      contractorId: json['contractor_id'] as String?,
      orderStatus: orderStatus == null
          ? null
          : OrderStatus.values.byName(orderStatus),
      contractor: contractorRow == null || parseContractor == null
          ? null
          : parseContractor(contractorRow),
      assignedTeam: assignments
          .where((a) => a['workers'] != null)
          .map((a) => parseWorker(a['workers'] as Map<String, dynamic>))
          .toList(),
      approxLocation: latLngOrNull(json['approx_lat'], json['approx_lng']),
      exactLocation: exact == null
          ? null
          : latLngOrNull(exact['lat'], exact['lng']),
      addressDetails: exact?['address_details'] as String? ?? '',
      customerPhone: json['customer_phone'] as String?,
    );
  }

  String? get assignedWorkerName {
    for (final worker in interestedWorkers) {
      if (worker.id == assignedWorkerId) return worker.name;
    }
    return null;
  }

  JobRequestModel copyWith({
    List<String>? photoUrls,
    String? status,
    List<WorkerModel>? interestedWorkers,
    double? ratingGiven,
    String? reviewComment,
    String? assignedWorkerId,
    OrderStatus? orderStatus,
    List<WorkerModel>? assignedTeam,
  }) {
    return JobRequestModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      tradeCategory: tradeCategory,
      description: description,
      photoPaths: photoPaths,
      photoUrls: photoUrls ?? this.photoUrls,
      location: location,
      urgency: urgency,
      status: status ?? this.status,
      createdAt: createdAt,
      interestedWorkers: interestedWorkers ?? this.interestedWorkers,
      ratingGiven: ratingGiven ?? this.ratingGiven,
      reviewComment: reviewComment ?? this.reviewComment,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      contractorId: contractorId,
      orderStatus: orderStatus ?? this.orderStatus,
      contractor: contractor,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      approxLocation: approxLocation,
      exactLocation: exactLocation,
      addressDetails: addressDetails,
      customerPhone: customerPhone,
    );
  }
}
