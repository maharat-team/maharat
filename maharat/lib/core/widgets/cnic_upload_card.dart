import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

/// A tap target for one identity photo, showing the photo once taken.
class CnicUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Uint8List? photo;
  final VoidCallback onTap;

  /// Shown on the empty card, e.g. "Opens the front camera".
  final String? actionHint;

  const CnicUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.photo,
    required this.onTap,
    this.actionHint,
  });

  @override
  Widget build(BuildContext context) {
    final image = photo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 8),
          Material(
            color: image == null ? AppColors.white : AppColors.lightMint,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 128,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: image == null ? AppColors.border : AppColors.primary,
                    width: image == null ? 1.5 : 2,
                  ),
                ),
                child: image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 36, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text(
                            actionHint ??
                                context.tr(
                                  'Tap to take or choose a photo',
                                  'تصویر لینے یا منتخب کرنے کے لیے ٹیپ کریں',
                                ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                image,
                                width: 140,
                                height: 108,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  context.tr('Photo added', 'تصویر لگ گئی'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                                Text(
                                  context.tr('Tap to retake', 'دوبارہ لینے کے لیے ٹیپ کریں'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
