import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/work_photo_gallery.dart';
import '../../../models/worker_model.dart';

class WorkerProfileScreen extends StatelessWidget {
  final WorkerModel worker;

  const WorkerProfileScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Worker Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Profile link for ${worker.name} copied!'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Profile Summary Card
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
                      // Avatar Container
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
                            _getInitials(worker.name),
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    worker.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              worker.trade,
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
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'CNIC Verified Tradesperson',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
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
                  // Key Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.star_rounded,
                          iconColor: AppColors.ratingAccent,
                          title: '${worker.rating}',
                          subtitle: '${worker.reviewCount} reviews',
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.work_history_rounded,
                          iconColor: AppColors.primary,
                          title: '${worker.experienceYears} Years',
                          subtitle: 'Experience',
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.payments_rounded,
                          iconColor: AppColors.darkGreen,
                          title: worker.visitFee == 0
                              ? 'Free'
                              : 'Rs. ${worker.visitFee}',
                          subtitle: 'Visit Fee',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // No Commission Information Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightMint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.darkGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No Commission Platform: Call or WhatsApp ${worker.name} directly to negotiate rates and schedule service.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGreen,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bio / About
            const SectionHeader(title: 'About Tradesperson'),
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
                    : 'Professional ${worker.trade} based in ${worker.neighbourhood}, Bahawalpur.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryText,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Service Areas
            const SectionHeader(title: 'Service Areas in Bahawalpur'),
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
                  label: Text(area),
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

            // Work Photo Gallery
            const SectionHeader(title: 'Sample Work Gallery'),
            const SizedBox(height: 8),
            WorkPhotoGallery(photos: worker.workPhotos),

            const SizedBox(height: 20),

            // Customer Reviews Section
            SectionHeader(title: 'Customer Reviews (${worker.reviews.length})'),
            const SizedBox(height: 8),
            if (worker.reviews.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'No written reviews yet.',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: worker.reviews.length,
                itemBuilder: (context, index) {
                  final review = worker.reviews[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review.customerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            Text(
                              review.date,
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
                            (starIndex) => Icon(
                              starIndex < review.rating.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 16,
                              color: AppColors.ratingAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review.comment,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryText,
                            height: 1.4,
                          ),
                        ),
                        if (review.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: review.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightMint,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 80), // bottom space for fixed action bar
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
                text: 'WhatsApp',
                icon: Icons.chat_bubble_outline_rounded,
                backgroundColor: AppColors.whatsappGreen,
                onPressed: () => _openContactDialog(context, isWhatsApp: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Call Worker',
                icon: Icons.call_outlined,
                onPressed: () => _openContactDialog(context, isWhatsApp: false),
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'W';
  }

  void _openContactDialog(BuildContext context, {required bool isWhatsApp}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isWhatsApp ? Icons.chat_bubble_rounded : Icons.call_rounded,
              color: isWhatsApp ? AppColors.whatsappGreen : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(isWhatsApp ? 'WhatsApp Contact' : 'Direct Call'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect directly with ${worker.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Phone Number: ${worker.phone}',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Maharat platform is free for everyone. Deal directly with tradesperson.',
                style: TextStyle(fontSize: 12, color: AppColors.darkGreen),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isWhatsApp
                  ? AppColors.whatsappGreen
                  : AppColors.primary,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              contactWorker(
                context,
                phone: worker.phone,
                isWhatsApp: isWhatsApp,
              );
            },
            child: Text(isWhatsApp ? 'Open WhatsApp' : 'Call Now'),
          ),
        ],
      ),
    );
  }
}
