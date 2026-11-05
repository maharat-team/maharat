import '../core/utils/date_utils.dart';

class ReviewModel {
  final String id;
  final String customerName;
  final double rating;
  final String comment;
  final List<String> tags;
  final String date;

  ReviewModel({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.tags,
    required this.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      customerName: json['customer_name'] as String? ?? '',
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List? ?? const []),
      date: relativeDate(
        DateTime.parse(json['created_at'] as String).toLocal(),
      ),
    );
  }
}
