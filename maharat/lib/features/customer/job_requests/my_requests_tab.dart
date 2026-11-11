import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/request_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/job_request_model.dart';
import '../../../state/app_state.dart';
import '../reviews/rate_experience_screen.dart';
import 'request_job_screen.dart';
import 'request_sent_screen.dart';

class MyRequestsTab extends StatefulWidget {
  const MyRequestsTab({super.key});

  @override
  State<MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends State<MyRequestsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final activeList = appState.activeJobRequests;
    final completedList = appState.completedJobRequests;
    final closedList = appState.closedJobRequests;

    final unratedCompleted = completedList
        .where(
          (j) =>
              j.ratingGiven == null &&
              (j.isContractorOrder || j.assignedWorkerId != null),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('My Requests', 'میری درخواستیں')),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RequestJobScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.secondaryText,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              text: context.tr(
                'Active (${activeList.length})',
                'جاری (${activeList.length})',
              ),
            ),
            Tab(
              text: context.tr(
                'Completed (${completedList.length})',
                'مکمل (${completedList.length})',
              ),
            ),
            Tab(
              text: context.tr(
                'Closed (${closedList.length})',
                'بند (${closedList.length})',
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Pending Review Banner (if any completed job has no rating yet)
          if (unratedCompleted.isNotEmpty)
            GestureDetector(
              onTap: () {
                _openRateScreen(context, unratedCompleted.first);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppColors.ratingAccent.withAlpha(25),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.ratingAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr(
                          'Please rate your recent ${unratedCompleted.first.tradeCategory} service.',
                          'براہ کرم اپنی حالیہ ${context.tradeName(unratedCompleted.first.tradeCategory)} سروس کو ریٹ کریں۔',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    Text(
                      context.tr('Rate Now', 'ابھی ریٹ کریں'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList(
                  activeList,
                  context.tr(
                    'No active requests right now.',
                    'ابھی کوئی جاری درخواست نہیں۔',
                  ),
                ),
                _buildRequestList(
                  completedList,
                  context.tr('No completed jobs yet.', 'ابھی کوئی کام مکمل نہیں ہوا۔'),
                ),
                _buildRequestList(
                  closedList,
                  context.tr('No closed requests.', 'کوئی بند درخواست نہیں۔'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RequestJobScreen()));
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('New Request', 'نئی درخواست')),
      ),
    );
  }

  Future<void> _closeRequest(BuildContext context, String jobId) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final closed = context.tr('Request closed.', 'درخواست بند ہو گئی۔');
    try {
      await appState.closeJobRequest(jobId);
      messenger.showSnackBar(SnackBar(content: Text(closed)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  Widget _buildRequestList(
    List<JobRequestModel> requests,
    String emptyMessage,
  ) {
    final appState = Provider.of<AppState>(context);
    if (requests.isEmpty && appState.jobRequests.isEmpty) {
      if (appState.jobsStatus == LoadStatus.loading ||
          appState.jobsStatus == LoadStatus.idle) {
        return const LoadingView();
      }
      if (appState.jobsStatus == LoadStatus.error) {
        return ErrorRetryView(
          message:
              appState.jobsError ??
              context.tr(
                'Could not load your requests.',
                'آپ کی درخواستیں لوڈ نہیں ہو سکیں۔',
              ),
          onRetry: appState.refreshJobs,
        );
      }
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.secondaryText.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: appState.refreshJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return RequestCard(
            request: request,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RequestSentScreen(request: request),
                ),
              );
            },
            onCloseTap: request.status == 'Active'
                ? () => _closeRequest(context, request.id)
                : null,
            onRateTap:
                request.status == 'Completed' &&
                    request.ratingGiven == null &&
                    (request.isContractorOrder ||
                        request.assignedWorkerId != null)
                ? () => _openRateScreen(context, request)
                : null,
          );
        },
      ),
    );
  }

  void _openRateScreen(BuildContext context, JobRequestModel request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RateExperienceScreen(jobRequest: request),
      ),
    );
  }
}
