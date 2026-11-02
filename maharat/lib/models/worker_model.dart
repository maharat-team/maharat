import 'review_model.dart';

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
  final bool isCnicVerified;
  final bool isAvailableToday;
  final List<String> workPhotos;
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
    required this.isCnicVerified,
    required this.isAvailableToday,
    required this.workPhotos,
    required this.reviews,
    required this.completedJobsCount,
  });

  WorkerModel copyWith({
    String? id,
    String? name,
    String? trade,
    String? phone,
    double? rating,
    int? reviewCount,
    int? experienceYears,
    int? visitFee,
    String? neighbourhood,
    List<String>? serviceAreas,
    String? bio,
    bool? isCnicVerified,
    bool? isAvailableToday,
    List<String>? workPhotos,
    List<ReviewModel>? reviews,
    int? completedJobsCount,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      trade: trade ?? this.trade,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      experienceYears: experienceYears ?? this.experienceYears,
      visitFee: visitFee ?? this.visitFee,
      neighbourhood: neighbourhood ?? this.neighbourhood,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      bio: bio ?? this.bio,
      isCnicVerified: isCnicVerified ?? this.isCnicVerified,
      isAvailableToday: isAvailableToday ?? this.isAvailableToday,
      workPhotos: workPhotos ?? this.workPhotos,
      reviews: reviews ?? this.reviews,
      completedJobsCount: completedJobsCount ?? this.completedJobsCount,
    );
  }
}
