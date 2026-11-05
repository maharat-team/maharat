import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/worker_card.dart';
import '../../../core/widgets/request_card.dart';
import '../../../state/app_state.dart';
import '../worker_profile/worker_profile_screen.dart';
import '../job_requests/request_job_screen.dart';
import '../job_requests/request_sent_screen.dart';

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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Assalam o Alaikum',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'السلام علیکم',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                          ],
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
                              user.neighbourhood,
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
                            alignment: Alignment.centerRight,
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

                // Banner: 0% Commission & Free Platform
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.darkGreen, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.verified_user_rounded,
                                  size: 14,
                                  color: AppColors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Free & Direct',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'بہاولپور',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightMint,
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Direct Contact with Local Workers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'No commission, no hidden charges. Call or WhatsApp tradespeople directly.',
                        style: TextStyle(
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
                              text: 'Request a Job',
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
                              text: 'Browse All',
                              type: ButtonType.secondary,
                              icon: Icons.search_rounded,
                              onPressed: onNavigateToFind,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Active Job Request Summary Section
                if (activeRequests.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Active Job Request',
                    actionText: 'View All (${activeRequests.length})',
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

                // Service Categories Grid
                SectionHeader(
                  title: 'Service Categories',
                  actionText: 'See All',
                  onActionPressed: onNavigateToFind,
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth < 300 ? 2 : 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 122,
                      ),
                      itemCount: AppConstants.categories.length,
                      itemBuilder: (context, index) {
                        final category = AppConstants.categories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RequestJobScreen(
                                  initialCategory: category.nameEn,
                                ),
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
                                Text(
                                  category.nameEn,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryText,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  category.nameUrdu,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.secondaryText,
                                    fontFamily: 'NotoSansArabic',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Verified Workers Nearby
                SectionHeader(
                  title: 'Top Verified Workers',
                  actionText: 'View Directory',
                  onActionPressed: onNavigateToFind,
                ),
                const SizedBox(height: 8),
                if (workers.isEmpty)
                  _buildWorkersPlaceholder(appState)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: workers.length > 4 ? 4 : workers.length,
                    itemBuilder: (context, index) {
                      final worker = workers[index];
                      return WorkerCard(
                        worker: worker,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  WorkerProfileScreen(worker: worker),
                            ),
                          );
                        },
                        onWhatsAppTap: () =>
                            _openContactDialog(context, worker, true),
                        onCallTap: () =>
                            _openContactDialog(context, worker, false),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkersPlaceholder(AppState appState) {
    switch (appState.workersStatus) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorRetryView(
          message: appState.workersError ?? 'Could not load workers.',
          onRetry: appState.refreshWorkers,
        );
      case LoadStatus.ready:
        return const EmptyStateView(
          icon: Icons.engineering_outlined,
          title: 'No verified workers yet',
          subtitle:
              'Post a job and we will show it to tradespeople as they join.',
        );
    }
  }

  void _openContactDialog(BuildContext context, worker, bool isWhatsApp) {
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
              'Connect directly with ${worker.name} (${worker.trade})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Phone: ${worker.phone}',
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
                'Remember: Maharat charges 0% commission. Deal directly with the worker.',
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
