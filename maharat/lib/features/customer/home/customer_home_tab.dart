import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/contact_dialog.dart';
import '../../../core/widgets/contractor_card.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/request_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/worker_card.dart';
import '../../../state/app_state.dart';
import '../contractor_profile/contractor_profile_screen.dart';
import '../job_requests/request_job_screen.dart';
import '../job_requests/request_sent_screen.dart';
import '../worker_profile/worker_profile_screen.dart';

class CustomerHomeTab extends StatelessWidget {
  final VoidCallback onNavigateToFind;
  final VoidCallback onNavigateToRequests;

  const CustomerHomeTab({
    super.key,
    required this.onNavigateToFind,
    required this.onNavigateToRequests,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final activeRequests = appState.activeJobRequests;
    final workers = appState.workers;
    final contractors = appState.contractors;
    final here = appState.myLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: appState.refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Greeting
                LayoutBuilder(
                  builder: (context, constraints) {
                    final greeting = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Assalam o Alaikum', 'السلام علیکم'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    );
                    final locationPill = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * 0.55,
                            ),
                            child: Text(
                              context.areaName(user.neighbourhood),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (constraints.maxWidth < 380) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          greeting,
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: locationPill,
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: greeting),
                        locationPill,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                _buildBanner(context),

                const SizedBox(height: 24),

                if (activeRequests.isNotEmpty) ...[
                  SectionHeader(
                    title: context.tr('Active Job Request', 'جاری درخواست'),
                    actionText: context.tr(
                      'View All (${activeRequests.length})',
                      'سب دیکھیں (${activeRequests.length})',
                    ),
                    onActionPressed: onNavigateToRequests,
                  ),
                  RequestCard(
                    request: activeRequests.first,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RequestSentScreen(request: activeRequests.first),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                SectionHeader(
                  title: context.tr('Service Categories', 'خدمات کی اقسام'),
                  actionText: context.tr('See All', 'سب دیکھیں'),
                  onActionPressed: onNavigateToFind,
                ),
                const SizedBox(height: 8),
                _buildCategories(context),

                if (contractors.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: context.tr(
                      'Verified Shops & Contractors',
                      'تصدیق شدہ دکانیں اور ٹھیکیدار',
                    ),
                    actionText: context.tr('View All', 'سب دیکھیں'),
                    onActionPressed: onNavigateToFind,
                  ),
                  const SizedBox(height: 8),
                  for (final shop in contractors.take(3))
                    ContractorCard(
                      contractor: shop,
                      distanceKm: distanceBetween(here, shop.location),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ContractorProfileScreen(contractor: shop),
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 24),

                SectionHeader(
                  title: context.tr('Top Verified Workers', 'بہترین تصدیق شدہ کاریگر'),
                  actionText: context.tr('View Directory', 'ڈائریکٹری دیکھیں'),
                  onActionPressed: onNavigateToFind,
                ),
                const SizedBox(height: 8),
                if (workers.isEmpty)
                  _buildWorkersPlaceholder(context, appState)
                else
                  for (final worker in workers.take(4))
                    WorkerCard(
                      worker: worker,
                      distanceKm: distanceBetween(here, worker.baseLocation),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WorkerProfileScreen(worker: worker),
                          ),
                        );
                      },
                      onWhatsAppTap: () => showContactDialog(
                        context,
                        name: worker.name,
                        subtitle: context.tradeName(worker.trade),
                        phone: worker.phone,
                        isWhatsApp: true,
                      ),
                      onCallTap: () => showContactDialog(
                        context,
                        name: worker.name,
                        subtitle: context.tradeName(worker.trade),
                        phone: worker.phone,
                        isWhatsApp: false,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkGreen, AppColors.primary],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 14,
                  color: AppColors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr('Free & Direct', 'مفت اور براہ راست'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(
              'Direct Contact with Local Workers',
              'مقامی کاریگروں سے براہ راست رابطہ',
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr(
              'No commission, no hidden charges. Call or WhatsApp tradespeople directly.',
              'کوئی کمیشن نہیں، کوئی چھپی فیس نہیں۔ کاریگروں کو براہ راست کال یا واٹس ایپ کریں۔',
            ),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.lightMint,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: context.tr('Request a Job', 'کام کی درخواست'),
                  icon: Icons.add_task_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RequestJobScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: context.tr('Browse All', 'سب دیکھیں'),
                  type: ButtonType.secondary,
                  icon: Icons.search_rounded,
                  onPressed: onNavigateToFind,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth < 300 ? 2 : 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 112,
          ),
          itemCount: AppConstants.categories.length,
          itemBuilder: (context, index) {
            final category = AppConstants.categories[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        RequestJobScreen(initialCategory: category.nameEn),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: category.color.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category.icon,
                        size: 26,
                        color: category.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        context.tradeName(category.nameEn),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkersPlaceholder(BuildContext context, AppState appState) {
    switch (appState.workersStatus) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorRetryView(
          message:
              appState.workersError ??
              context.tr('Could not load workers.', 'کاریگر لوڈ نہیں ہو سکے۔'),
          onRetry: appState.refreshWorkers,
        );
      case LoadStatus.ready:
        return EmptyStateView(
          icon: Icons.engineering_outlined,
          title: context.tr(
            'No verified workers yet',
            'ابھی کوئی تصدیق شدہ کاریگر نہیں',
          ),
          subtitle: context.tr(
            'Post a job and we will show it to tradespeople as they join.',
            'کام پوسٹ کریں، ہم اسے نئے آنے والے کاریگروں کو دکھائیں گے۔',
          ),
        );
    }
  }
}
