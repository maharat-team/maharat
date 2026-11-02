import 'worker_model.dart';

class JobRequestModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String tradeCategory;
  final String description;
  final bool hasVoiceNote;
  final List<String> photoUrls;
  final String location;
  final String urgency; // "Today", "Tomorrow", "Any Day"
  final String status; // "Active", "Completed", "Closed"
  final DateTime createdAt;
  final List<WorkerModel> interestedWorkers;
  final double? ratingGiven;
  final String? reviewComment;
  final String? assignedWorkerName;

  JobRequestModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.tradeCategory,
    required this.description,
    this.hasVoiceNote = false,
    this.photoUrls = const [],
    required this.location,
    required this.urgency,
    required this.status,
    required this.createdAt,
    this.interestedWorkers = const [],
    this.ratingGiven,
    this.reviewComment,
    this.assignedWorkerName,
  });

  JobRequestModel copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? tradeCategory,
    String? description,
    bool? hasVoiceNote,
    List<String>? photoUrls,
    String? location,
    String? urgency,
    String? status,
    DateTime? createdAt,
    List<WorkerModel>? interestedWorkers,
    double? ratingGiven,
    String? reviewComment,
    String? assignedWorkerName,
  }) {
    return JobRequestModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      tradeCategory: tradeCategory ?? this.tradeCategory,
      description: description ?? this.description,
      hasVoiceNote: hasVoiceNote ?? this.hasVoiceNote,
      photoUrls: photoUrls ?? this.photoUrls,
      location: location ?? this.location,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      interestedWorkers: interestedWorkers ?? this.interestedWorkers,
      ratingGiven: ratingGiven ?? this.ratingGiven,
      reviewComment: reviewComment ?? this.reviewComment,
      assignedWorkerName: assignedWorkerName ?? this.assignedWorkerName,
    );
  }
}
