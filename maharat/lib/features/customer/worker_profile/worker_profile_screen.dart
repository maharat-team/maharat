import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/contact_dialog.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/review_list.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/work_photo_gallery.dart';
import '../../../models/worker_model.dart';
import '../../../state/app_state.dart';

class WorkerProfileScreen extends StatelessWidget {
  final WorkerModel worker;

  const WorkerProfileScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final km = distanceBetween(appState.myLocation, worker.baseLocation);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('Worker Profile', 'کاریگر کی پروفائل'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.lightMint,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _initials(worker.name),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tradeName(worker.trade),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (worker.isCnicVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightMint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        context.tr(
                                          'CNIC & face verified',
                                          'شناختی کارڈ اور چہرہ تصدیق شدہ',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.darkGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.star_rounded,
                          iconColor: AppColors.ratingAccent,
                          title: '${worker.rating}',
                          subtitle: context.tr(
                            '${worker.reviewCount} reviews',
                            '${worker.reviewCount} ریویوز',
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.work_history_rounded,
                          iconColor: AppColors.primary,
                          title: context.tr(
                            '${worker.experienceYears} years',
                            '${worker.experienceYears} سال',
                          ),
                          subtitle: context.tr('Experience', 'تجربہ'),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.payments_rounded,
                          iconColor: AppColors.darkGreen,
                          title: worker.visitFee == 0
                              ? context.tr('Free', 'مفت')
                              : context.tr(
                                  'Rs. ${worker.visitFee}',
                                  '${worker.visitFee} روپے',
                                ),
                          subtitle: context.tr('Visit fee', 'وزٹ فیس'),
                        ),
                      ),
                    ],
                  ),
                  if (km != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.tr(
                            'About ${context.distance(km)}',
                            'تقریباً ${context.distance(km)}',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(title: context.tr('About', 'تعارف')),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                worker.bio.isNotEmpty
                    ? worker.bio
                    : context.tr(
                        'Professional ${worker.trade} based in ${worker.neighbourhood}, Bahawalpur.',
                        '${context.areaName(worker.neighbourhood)}، بہاولپور میں پیشہ ور ${context.tradeName(worker.trade)}۔',
                      ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryText,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(title: context.tr('Service areas', 'خدمت کے علاقے')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: worker.serviceAreas.map((area) {
                return Chip(
                  avatar: const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  label: Text(context.areaName(area)),
                  backgroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryText,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SectionHeader(title: context.tr('Work photos', 'کام کی تصاویر')),
            const SizedBox(height: 8),
            WorkPhotoGallery(photos: worker.workPhotos),
            const SizedBox(height: 20),
            SectionHeader(
              title: context.tr(
                'Customer reviews (${worker.reviews.length})',
                'گاہکوں کے ریویوز (${worker.reviews.length})',
              ),
            ),
            const SizedBox(height: 8),
            ReviewList(reviews: worker.reviews),
            const SizedBox(height: 80), // space for the fixed action bar
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: context.tr('WhatsApp', 'واٹس ایپ'),
                icon: Icons.chat_bubble_outline_rounded,
                backgroundColor: AppColors.whatsappGreen,
                onPressed: () => showContactDialog(
                  context,
                  name: worker.name,
                  subtitle: context.tradeName(worker.trade),
                  phone: worker.phone,
                  isWhatsApp: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: context.tr('Call', 'کال کریں'),
                icon: Icons.call_outlined,
                onPressed: () => showContactDialog(
                  context,
                  name: worker.name,
                  subtitle: context.tradeName(worker.trade),
                  phone: worker.phone,
                  isWhatsApp: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'W';
  }
}
