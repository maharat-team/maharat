import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/user_profile_model.dart';
import '../../../models/worker_model.dart';
import '../../../state/app_state.dart';
import '../registration/worker_reg_step1_screen.dart';
import '../../customer/customer_main_screen.dart';
import '../profile/worker_own_profile_screen.dart';

class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final worker = appState.workerProfile;
    final activeJobs = appState.nearbyJobRequests;
    final strengthChecks = [
      worker.bio.isNotEmpty,
      worker.workPhotos.isNotEmpty,
      worker.isCnicVerified,
      worker.reviewCount > 0,
    ];
    final profileStrength =
        strengthChecks.where((done) => done).length / strengthChecks.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tradesperson Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WorkerOwnProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: appState.refreshJobs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Availability Switch Card
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
                          width: 58,
                          height: 58,
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ),
                                  if (worker.isCnicVerified)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightMint,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'CNIC Verified',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                worker.trade,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),
                    // Availability Switch Toggle
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: worker.isAvailableToday
                                      ? AppColors.statusGreen
                                      : AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  worker.isAvailableToday
                                      ? 'Available for Jobs Today'
                                      : 'Currently Unavailable',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: worker.isAvailableToday
                                        ? AppColors.darkGreen
                                        : AppColors.secondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: worker.isAvailableToday,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await appState.toggleWorkerAvailability(val);
                            } catch (error) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(friendlyError(error))),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Statistics Grid (Jobs, Experience, Rating)
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.task_alt_rounded,
                    value: '${worker.completedJobsCount}',
                    label: 'Jobs Done',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.work_history_outlined,
                    value: '${worker.experienceYears}',
                    label: 'Years Exp.',
                    color: AppColors.whatsappGreen,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.star_rounded,
                    value: '${worker.rating}',
                    label: '${worker.reviewCount} Reviews',
                    color: AppColors.ratingAccent,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Profile Completion Progress Bar Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const title = Text(
                          'Profile Strength',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        );
                        final completion = Text(
                          '${(profileStrength * 100).round()}% Complete',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        );

                        if (constraints.maxWidth < 300) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              const SizedBox(height: 4),
                              completion,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            const Expanded(child: title),
                            const SizedBox(width: 8),
                            completion,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: profileStrength,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (!worker.isCnicVerified)
                _buildVerificationNotice(context, appState)
              else ...[
                // Nearby Job Requests
                SectionHeader(
                  title: 'Nearby Job Requests (${activeJobs.length})',
                  actionText: 'Filter',
                  onActionPressed: () {},
                ),
                const SizedBox(height: 8),

                if (activeJobs.isEmpty &&
                    appState.jobsStatus == LoadStatus.error)
                  ErrorRetryView(
                    message: appState.jobsError ?? 'Could not load jobs.',
                    onRetry: appState.refreshJobs,
                  )
                else if (activeJobs.isEmpty &&
                    appState.jobsStatus == LoadStatus.loading)
                  const LoadingView()
                else if (activeJobs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: AppColors.secondaryText,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No new job requests in your area right now.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeJobs.length,
                    itemBuilder: (context, index) {
                      final job = activeJobs[index];
                      final hasResponded = job.interestedWorkers.any(
                        (w) => w.id == worker.id,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    job.tradeCategory,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkGreen,
                                    ),
                                  ),
                                ),
                                Text(
                                  '• Needed ${job.urgency}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.secondaryText,
                                    ),
                                    const SizedBox(width: 2),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 140,
                                      ),
                                      child: Text(
                                        job.location,
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
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              job.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryText,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Customer: ${job.customerName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            JobPhotoStrip(urls: job.photoUrls),
                            const SizedBox(height: 14),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: hasResponded
                                        ? 'Interested Sent ✓'
                                        : 'I\'m Interested',
                                    type: hasResponded
                                        ? ButtonType.secondary
                                        : ButtonType.primary,
                                    onPressed: hasResponded
                                        ? null
                                        : () async {
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            try {
                                              await appState.workerRespondToJob(
                                                job.id,
                                              );
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Customer ${job.customerName} notified of your interest!',
                                                  ),
                                                ),
                                              );
                                            } catch (error) {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    friendlyError(error),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.secondaryText,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Job ignored.'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],

              const SizedBox(height: 24),

              // Switch to Customer Mode Button
              CustomButton(
                text: 'Switch to Customer Mode',
                type: ButtonType.outline,
                icon: Icons.search_rounded,
                onPressed: () {
                  appState.setUserRole(UserRole.customer);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const CustomerMainScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationNotice(BuildContext context, AppState appState) {
    final isRejected =
        appState.workerProfile.verificationStatus ==
        VerificationStatus.rejected;
    final reason = appState.rejectionReason;

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isRejected
            ? AppColors.statusRed.withAlpha(20)
            : AppColors.lightMint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRejected ? 'Verification Not Approved' : 'Verification In Review',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isRejected
                ? (reason ?? 'Please check your CNIC photos and submit again.')
                : 'We are checking your CNIC. Your profile and nearby jobs appear once you are approved. Pull down to refresh.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
          if (isRejected) ...[
            const SizedBox(height: 12),
            CustomButton(
              text: 'Submit Again',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WorkerRegStep1Screen(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
