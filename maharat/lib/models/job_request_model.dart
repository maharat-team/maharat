import 'worker_model.dart';

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
  });

  static String urgencyToDb(String label) =>
      _urgencyLabels.entries.firstWhere((e) => e.value == label).key;

  /// [parseWorker] builds a worker from the embedded row.
  factory JobRequestModel.fromJson(
    Map<String, dynamic> json, {
    required WorkerModel Function(Map<String, dynamic>) parseWorker,
  }) {
    final interests = List<Map<String, dynamic>>.from(
      json['job_interests'] as List? ?? const [],
    )..sort((a, b) => '${a['created_at']}'.compareTo('${b['created_at']}'));

    // reviews.job_id is unique, so PostgREST may embed one object, not a list.
    final embedded = json['reviews'];
    final review = embedded is List
        ? (embedded.isEmpty ? null : embedded.first as Map<String, dynamic>)
        : embedded as Map<String, dynamic>?;

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
    );
  }
}
