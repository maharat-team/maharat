import 'review_model.dart';

enum VerificationStatus { pending, approved, rejected }

class WorkPhoto {
  final String id;
  final String path;
  final String url;

  const WorkPhoto({required this.id, required this.path, required this.url});
}

class WorkerModel {
  final String id;
  final String name;
  final String trade; // e.g. Electrician, Plumber, Mason
  final String phone;
  final double rating;
  final int reviewCount;
  final int experienceYears;
  final int visitFee; // 0 for Free
  final String neighbourhood;
  final List<String> serviceAreas;
  final String bio;
  final VerificationStatus verificationStatus;
  final bool isAvailableToday;
  final List<WorkPhoto> workPhotos;
  final List<ReviewModel> reviews;
  final int completedJobsCount;

  WorkerModel({
    required this.id,
    required this.name,
    required this.trade,
    required this.phone,
    required this.rating,
    required this.reviewCount,
    required this.experienceYears,
    required this.visitFee,
    required this.neighbourhood,
    required this.serviceAreas,
    required this.bio,
    required this.verificationStatus,
    required this.isAvailableToday,
    required this.workPhotos,
    required this.reviews,
    required this.completedJobsCount,
  });

  bool get isCnicVerified => verificationStatus == VerificationStatus.approved;

  factory WorkerModel.empty() => WorkerModel(
    id: '',
    name: '',
    trade: '',
    phone: '',
    rating: 0,
    reviewCount: 0,
    experienceYears: 0,
    visitFee: 0,
    neighbourhood: '',
    serviceAreas: const [],
    bio: '',
    verificationStatus: VerificationStatus.pending,
    isAvailableToday: false,
    workPhotos: const [],
    reviews: const [],
    completedJobsCount: 0,
  );

  /// [photoUrl] resolves a storage path to a displayable URL.
  factory WorkerModel.fromJson(
    Map<String, dynamic> json, {
    required String Function(String path) photoUrl,
  }) {
    int newestFirst(Map<String, dynamic> a, Map<String, dynamic> b) =>
        '${b['created_at']}'.compareTo('${a['created_at']}');

    final photos = List<Map<String, dynamic>>.from(
      json['worker_photos'] as List? ?? const [],
    )..sort(newestFirst);
    final reviews = List<Map<String, dynamic>>.from(
      json['reviews'] as List? ?? const [],
    )..sort(newestFirst);

    return WorkerModel(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? '',
      trade: json['trade'] as String,
      phone: json['phone'] as String,
      rating: (json['rating_avg'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      experienceYears: json['experience_years'] as int,
      visitFee: json['visit_fee'] as int,
      neighbourhood: json['neighbourhood'] as String,
      serviceAreas: List<String>.from(json['service_areas'] as List),
      bio: json['bio'] as String? ?? '',
      verificationStatus: VerificationStatus.values.byName(
        json['verification_status'] as String,
      ),
      isAvailableToday: json['is_available_today'] as bool,
      workPhotos: photos.map((p) {
        final path = p['storage_path'] as String;
        return WorkPhoto(
          id: p['id'] as String,
          path: path,
          url: photoUrl(path),
        );
      }).toList(),
      reviews: reviews.map(ReviewModel.fromJson).toList(),
      completedJobsCount: json['completed_jobs_count'] as int,
    );
  }

  WorkerModel copyWith({
    String? name,
    bool? isAvailableToday,
    List<WorkPhoto>? workPhotos,
  }) {
    return WorkerModel(
      id: id,
      name: name ?? this.name,
      trade: trade,
      phone: phone,
      rating: rating,
      reviewCount: reviewCount,
      experienceYears: experienceYears,
      visitFee: visitFee,
      neighbourhood: neighbourhood,
      serviceAreas: serviceAreas,
      bio: bio,
      verificationStatus: verificationStatus,
      isAvailableToday: isAvailableToday ?? this.isAvailableToday,
      workPhotos: workPhotos ?? this.workPhotos,
      reviews: reviews,
      completedJobsCount: completedJobsCount,
    );
  }
}
