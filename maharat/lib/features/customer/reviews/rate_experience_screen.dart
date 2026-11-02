import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/job_request_model.dart';
import '../../../state/app_state.dart';

class RateExperienceScreen extends StatefulWidget {
  final JobRequestModel jobRequest;

  const RateExperienceScreen({super.key, required this.jobRequest});

  @override
  State<RateExperienceScreen> createState() => _RateExperienceScreenState();
}

class _RateExperienceScreenState extends State<RateExperienceScreen> {
  double _rating = 5.0;
  final Set<String> _selectedTags = {'On time', 'Clean work', 'Fair price'};
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    setState(() {
      _isSubmitting = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);

        // Find worker ID if available or default to first interested worker
        final workerId = widget.jobRequest.interestedWorkers.isNotEmpty
            ? widget.jobRequest.interestedWorkers.first.id
            : appState.workers.first.id;

        appState.addReviewToWorker(
          workerId: workerId,
          jobId: widget.jobRequest.id,
          rating: _rating,
          comment: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : 'Great service provided on time with excellent quality.',
          tags: _selectedTags.toList(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Review submitted successfully.'),
          ),
        );

        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final workerName =
        widget.jobRequest.assignedWorkerName ??
        (widget.jobRequest.interestedWorkers.isNotEmpty
            ? widget.jobRequest.interestedWorkers.first.name
            : 'Tradesperson');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rate Experience')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.lightMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.engineering_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How was your work with $workerName?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${widget.jobRequest.tradeCategory} • ${widget.jobRequest.location}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Interactive Star Rating Selector
            const Text(
              'Tap Stars to Rate',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1.0;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = starValue;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      starValue <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 42,
                      color: AppColors.ratingAccent,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              _getRatingText(_rating),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 28),

            // Review Tags Selection
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What went well? Select tags:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.reviewTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  selectedColor: AppColors.lightMint,
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.darkGreen
                        : AppColors.primaryText,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Written Comment Box
            CustomTextField(
              label: 'Written Review (Optional)',
              hint:
                  'Write your experience with the worker to help others in Bahawalpur...',
              controller: _commentController,
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            CustomButton(
              text: 'Submit Review',
              isLoading: _isSubmitting,
              onPressed: _submitReview,
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 5.0) return '5.0 - Excellent!';
    if (rating >= 4.0) return '4.0 - Very Good';
    if (rating >= 3.0) return '3.0 - Good';
    if (rating >= 2.0) return '2.0 - Fair';
    return '1.0 - Poor';
  }
}
