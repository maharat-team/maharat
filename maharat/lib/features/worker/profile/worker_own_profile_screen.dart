import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/image_picker_helper.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../core/widgets/review_list.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/work_photo_gallery.dart';
import '../../../state/app_state.dart';
import 'edit_worker_profile_screen.dart';

class WorkerOwnProfileScreen extends StatelessWidget {
  const WorkerOwnProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final worker = appState.workerProfile;
    final teams = appState.myTeams;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('My Worker Profile', 'میری کاریگر پروفائل')),
        actions: [
          if (appState.hasWorkerProfile)
            IconButton(
              tooltip: context.tr('Edit', 'ترمیم'),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EditWorkerProfileScreen(),
                ),
              ),
            ),
        ],
      ),
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
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: AppColors.lightMint,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            worker.name.isNotEmpty
                                ? worker.name[0].toUpperCase()
                                : 'W',
                            style: const TextStyle(
                              fontSize: 28,
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            Text(
                              context.tradeName(worker.trade),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              PhoneUtils.display(worker.phone),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (worker.isCnicVerified) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightMint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr(
                                'CNIC & face verified',
                                'شناختی کارڈ اور چہرہ تصدیق شدہ',
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(title: context.tr('About my work', 'میرے کام کے بارے میں')),
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
                worker.bio.isEmpty
                    ? context.tr(
                        'Add a few lines about your work. Customers trust detailed profiles.',
                        'اپنے کام کے بارے میں چند سطریں لکھیں۔ گاہک تفصیلی پروفائل پر بھروسہ کرتے ہیں۔',
                      )
                    : worker.bio,
                style: TextStyle(
                  fontSize: 14,
                  color: worker.bio.isEmpty
                      ? AppColors.secondaryText
                      : AppColors.primaryText,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(title: context.tr('Areas I serve', 'میرے علاقے')),
            const SizedBox(height: 6),
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
                );
              }).toList(),
            ),
            if (teams.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionHeader(title: context.tr('My teams', 'میری ٹیمیں')),
              for (final team in teams)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.darkGreen,
                    ),
                    title: Text(
                      team.contractor?.businessName ??
                          context.tr('Contractor', 'ٹھیکیدار'),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await appState.leaveTeam(team.contractorId);
                        } catch (error) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(friendlyError(error))),
                          );
                        }
                      },
                      child: Text(
                        context.tr('Leave', 'چھوڑ دیں'),
                        style: const TextStyle(color: AppColors.statusRed),
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 24),
            SectionHeader(
              title: context.tr(
                'Work photos (${worker.workPhotos.length}/${AppConstants.maxWorkPhotos})',
                'کام کی تصاویر (${worker.workPhotos.length}/${AppConstants.maxWorkPhotos})',
              ),
            ),
            const SizedBox(height: 8),
            WorkPhotoGallery(
              photos: worker.workPhotos,
              onAdd: () async {
                final photo = await pickCompressedImage(context);
                if (photo != null) await appState.addWorkPhoto(photo);
              },
              onDelete: appState.deleteWorkPhoto,
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: context.tr(
                'Customer reviews (${worker.reviews.length})',
                'گاہکوں کے ریویوز (${worker.reviews.length})',
              ),
            ),
            const SizedBox(height: 8),
            ReviewList(reviews: worker.reviews),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
