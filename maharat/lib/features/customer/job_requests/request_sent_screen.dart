import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/worker_card.dart';
import '../../../models/job_request_model.dart';
import '../../../models/worker_model.dart';
import '../../../state/app_state.dart';
import '../customer_main_screen.dart';
import '../worker_profile/worker_profile_screen.dart';

class RequestSentScreen extends StatelessWidget {
  final JobRequestModel request;

  const RequestSentScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // Retrieve live updated request from app state
    final liveRequest = appState.jobRequests.firstWhere(
      (j) => j.id == request.id,
      orElse: () => request,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Job Request Sent'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const CustomerMainScreen(initialTabIndex: 2),
              ),
              (route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightMint,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request Sent Successfully!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '12+ ${liveRequest.tradeCategory}s in ${liveRequest.location} have been notified.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Request Details Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
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
                          liveRequest.tradeCategory,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                      Text(
                        'Urgency: ${liveRequest.urgency}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    liveRequest.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        liveRequest.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  JobPhotoStrip(urls: liveRequest.photoUrls),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Interested Workers List
            SectionHeader(
              title:
                  'Interested Workers (${liveRequest.interestedWorkers.length})',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Live Responses',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.statusGreen,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            if (liveRequest.interestedWorkers.isEmpty)
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
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Waiting for tradespeople to respond...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Workers in your neighbourhood will reach out shortly.',
                      style: TextStyle(
                        fontSize: 12,
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
                itemCount: liveRequest.interestedWorkers.length,
                itemBuilder: (context, index) {
                  final worker = liveRequest.interestedWorkers[index];
                  return WorkerCard(
                    worker: worker,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorkerProfileScreen(worker: worker),
                        ),
                      );
                    },
                    onWhatsAppTap: () =>
                        _openContactDialog(context, worker, true),
                    onCallTap: () => _openContactDialog(context, worker, false),
                  );
                },
              ),

            const SizedBox(height: 32),

            if (liveRequest.status == 'Active' &&
                liveRequest.interestedWorkers.isNotEmpty) ...[
              CustomButton(
                text: 'Mark Job Completed',
                icon: Icons.task_alt_rounded,
                onPressed: () => _completeJob(context, appState, liveRequest),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Close Job Request',
                    type: ButtonType.outline,
                    textColor: AppColors.statusRed,
                    backgroundColor: AppColors.statusRed,
                    onPressed: () => _closeJob(context, appState, liveRequest),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'My Requests',
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) =>
                              const CustomerMainScreen(initialTabIndex: 2),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _closeJob(
    BuildContext context,
    AppState appState,
    JobRequestModel job,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await appState.closeJobRequest(job.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Job request closed.')),
      );
      _goToRequests(navigator);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  Future<void> _completeJob(
    BuildContext context,
    AppState appState,
    JobRequestModel job,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final worker = await showModalBottomSheet<WorkerModel>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Who did this job?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            for (final candidate in job.interestedWorkers)
              ListTile(
                leading: const Icon(Icons.engineering_rounded),
                title: Text(candidate.name),
                subtitle: Text(candidate.trade),
                onTap: () => Navigator.pop(ctx, candidate),
              ),
          ],
        ),
      ),
    );
    if (worker == null) return;

    try {
      await appState.completeJobRequest(job.id, worker.id);
      _goToRequests(navigator);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  void _goToRequests(NavigatorState navigator) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const CustomerMainScreen(initialTabIndex: 2),
      ),
      (route) => false,
    );
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
