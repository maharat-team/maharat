import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/contact_dialog.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/location_widgets.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../core/widgets/review_list.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/contractor_model.dart';
import '../../../state/app_state.dart';
import '../job_requests/request_job_screen.dart';
import '../worker_profile/worker_profile_screen.dart';

class ContractorProfileScreen extends StatelessWidget {
  final ContractorModel contractor;

  const ContractorProfileScreen({super.key, required this.contractor});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isOwnShop = appState.currentUser.id == contractor.id;
    final photo = contractor.shopPhotoUrl;
    final location = contractor.location;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('Shop Profile', 'دکان کی پروفائل'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (photo != null)
                        NetworkPhoto(url: photo, width: 76, height: 76)
                      else
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.lightMint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 36,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contractor.businessName,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr(
                                'Owner: ${contractor.ownerName}',
                                'مالک: ${contractor.ownerName}',
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
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
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _Stat(
                        icon: Icons.star_rounded,
                        color: AppColors.ratingAccent,
                        value: '${contractor.rating}',
                        label: context.tr(
                          '${contractor.reviewCount} reviews',
                          '${contractor.reviewCount} ریویوز',
                        ),
                      ),
                      _Stat(
                        icon: Icons.groups_rounded,
                        color: AppColors.primary,
                        value: '${contractor.team.length}',
                        label: context.tr('Workers', 'کاریگر'),
                      ),
                      _Stat(
                        icon: Icons.task_alt_rounded,
                        color: AppColors.darkGreen,
                        value: '${contractor.completedJobsCount}',
                        label: context.tr('Jobs done', 'مکمل کام'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(title: context.tr('Services', 'خدمات')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final trade in contractor.trades)
                  Chip(
                    label: Text(context.tradeName(trade)),
                    backgroundColor: AppColors.lightMint,
                    side: BorderSide.none,
                  ),
              ],
            ),
            if (contractor.bio.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionHeader(title: context.tr('About the shop', 'دکان کے بارے میں')),
              Text(
                contractor.bio,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
            const SizedBox(height: 20),
            SectionHeader(title: context.tr('Areas served', 'خدمت کے علاقے')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final area in contractor.serviceAreas)
                  Chip(
                    avatar: const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    label: Text(context.areaName(area)),
                    backgroundColor: AppColors.white,
                  ),
              ],
            ),
            if (location != null) ...[
              const SizedBox(height: 20),
              SectionHeader(title: context.tr('Shop location', 'دکان کا مقام')),
              LocationPreviewCard(
                point: location,
                title: contractor.shopAddress.isEmpty
                    ? null
                    : contractor.shopAddress,
                from: appState.myLocation,
              ),
            ],
            if (contractor.team.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionHeader(title: context.tr('Team', 'ٹیم')),
              for (final worker in contractor.team)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.lightMint,
                      child: Icon(
                        Icons.engineering_rounded,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    title: Text(worker.name),
                    subtitle: Text(
                      '${context.tradeName(worker.trade)} · ★ ${worker.rating}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkerProfileScreen(worker: worker),
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            SectionHeader(
              title: context.tr(
                'Customer reviews (${contractor.reviews.length})',
                'گاہکوں کے ریویوز (${contractor.reviews.length})',
              ),
            ),
            ReviewList(reviews: contractor.reviews),
          ],
        ),
      ),
      bottomSheet: isOwnShop
          ? null
          : Container(
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
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: context.tr('Call', 'کال'),
                      onPressed: () => showContactDialog(
                        context,
                        name: contractor.businessName,
                        phone: contractor.phone,
                        isWhatsApp: false,
                      ),
                      icon: const Icon(Icons.call_outlined),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: context.tr('WhatsApp', 'واٹس ایپ'),
                      onPressed: () => showContactDialog(
                        context,
                        name: contractor.businessName,
                        phone: contractor.phone,
                        isWhatsApp: true,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: context.tr('Send Order', 'آرڈر بھیجیں'),
                        icon: Icons.send_rounded,
                        onPressed: contractor.isAcceptingOrders
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RequestJobScreen(contractor: contractor),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
