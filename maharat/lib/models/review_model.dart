import '../core/utils/date_utils.dart';

class ReviewModel {
  final String id;
  final String customerName;
  final double rating;
  final String comment;
  final List<String> tags;

  /// A fixed label, used when [createdAt] is unknown (tests, fixtures).
  final String date;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.tags,
    this.date = '',
    this.createdAt,
  });

  /// Worked out when shown, so it follows the current language.
  String get dateLabel {
    final created = createdAt;
    return created == null ? date : relativeDate(created);
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      customerName: json['customer_name'] as String? ?? '',
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List? ?? const []),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
