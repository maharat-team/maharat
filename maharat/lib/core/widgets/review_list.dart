import 'package:flutter/material.dart';
import '../../models/review_model.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../theme/app_colors.dart';

/// Customer reviews with stars, date, comment and tags.
class ReviewList extends StatelessWidget {
  final List<ReviewModel> reviews;

  const ReviewList({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          context.tr('No reviews yet.', 'ابھی کوئی ریویو نہیں۔'),
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
        ),
      );
    }
    return Column(
      children: [
        for (final review in reviews)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      review.dateLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 16,
                      color: AppColors.ratingAccent,
                    ),
                  ),
                ),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    review.comment,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryText,
                      height: 1.4,
                    ),
                  ),
                ],
                if (review.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final tag in review.tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightMint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.tagName(tag),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
