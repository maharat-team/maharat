import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
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

  Future<void> _submitReview() async {
    final job = widget.jobRequest;
    if (!job.isContractorOrder && job.assignedWorkerId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.addReview(
        job: job,
        rating: _rating,
        comment: _commentController.text.trim(),
        tags: _selectedTags.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Thank you! Your review has been submitted.',
              'شکریہ! آپ کا ریویو جمع ہو گیا۔',
            ),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.jobRequest;
    final workerName = job.isContractorOrder
        ? (job.contractor?.businessName ?? context.tr('the shop', 'دکان'))
        : (job.assignedWorkerName ??
              context.tr('your tradesperson', 'آپ کے کاریگر'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('Rate Experience', 'تجربہ ریٹ کریں'))),
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
                    context.tr(
                      'How was your work with $workerName?',
                      '$workerName کے ساتھ آپ کا تجربہ کیسا رہا؟',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${context.tradeName(job.tradeCategory)} • ${context.areaName(job.location)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Interactive Star Rating Selector
            Text(
              context.tr('Tap stars to rate', 'ریٹنگ کے لیے ستاروں پر ٹیپ کریں'),
              style: const TextStyle(
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
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      starValue <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 40,
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
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                context.tr('What went well?', 'کیا اچھا رہا؟'),
                style: const TextStyle(
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
                  label: Text(context.tagName(tag)),
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
              label: context.tr('Written review (optional)', 'تحریری ریویو (اختیاری)'),
              hint: context.tr(
                'Share your experience to help others in Bahawalpur...',
                'بہاولپور کے دوسرے لوگوں کی مدد کے لیے اپنا تجربہ لکھیں...',
              ),
              controller: _commentController,
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            CustomButton(
              text: context.tr('Submit Review', 'ریویو جمع کریں'),
              isLoading: _isSubmitting,
              onPressed: _submitReview,
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 5.0) return context.tr('5.0 - Excellent!', '5.0 - بہترین!');
    if (rating >= 4.0) return context.tr('4.0 - Very good', '4.0 - بہت اچھا');
    if (rating >= 3.0) return context.tr('3.0 - Good', '3.0 - اچھا');
    if (rating >= 2.0) return context.tr('2.0 - Fair', '2.0 - ٹھیک');
    return context.tr('1.0 - Poor', '1.0 - خراب');
  }
}
