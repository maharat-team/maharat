import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/contact_dialog.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/location_widgets.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../core/widgets/request_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/worker_card.dart';
import '../../../models/job_request_model.dart';
import '../../../models/worker_model.dart';
import '../../../state/app_state.dart';
import '../contractor_profile/contractor_profile_screen.dart';
import '../customer_main_screen.dart';
import '../reviews/rate_experience_screen.dart';
import '../worker_profile/worker_profile_screen.dart';

/// The customer's view of one of their jobs, kept live from [AppState].
class RequestSentScreen extends StatelessWidget {
  final JobRequestModel request;

  const RequestSentScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final job = appState.jobRequests.firstWhere(
      (j) => j.id == request.id,
      orElse: () => request,
    );
    final exact = job.exactLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          job.isContractorOrder
              ? context.tr('Order', 'آرڈر')
              : context.tr('Job Request', 'کام کی درخواست'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _goToRequests(Navigator.of(context)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: appState.refreshJobs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusBanner(job: job),
              const SizedBox(height: 20),
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
                      spacing: 8,
                      runSpacing: 6,
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
                            context.tradeName(job.tradeCategory),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ),
                        Text(
                          context.tr(
                            'When: ${context.urgencyName(job.urgency)}',
                            'کب: ${context.urgencyName(job.urgency)}',
                          ),
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
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            context.areaName(job.location),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    JobPhotoStrip(urls: job.photoUrls),
                  ],
                ),
              ),
              if (exact != null) ...[
                const SizedBox(height: 16),
                LocationPreviewCard(
                  point: exact,
                  addressDetails: job.addressDetails,
                  title: context.tr('Job location', 'کام کا مقام'),
                ),
              ],
              const SizedBox(height: 24),
              if (job.isContractorOrder)
                _ContractorSection(job: job)
              else
                _InterestedWorkersSection(job: job),
              const SizedBox(height: 28),
              ..._buildActions(context, appState, job),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    AppState appState,
    JobRequestModel job,
  ) {
    final canComplete = job.isActive &&
        (job.isContractorOrder
            ? job.orderStatus == OrderStatus.accepted &&
                  job.assignedTeam.isNotEmpty
            : job.interestedWorkers.isNotEmpty);

    return [
      if (canComplete) ...[
        CustomButton(
          text: context.tr('Mark Job Completed', 'کام مکمل کریں'),
          icon: Icons.task_alt_rounded,
          onPressed: () => _completeJob(context, appState, job),
        ),
        const SizedBox(height: 12),
      ],
      if (job.status == 'Completed' &&
          job.ratingGiven == null &&
          (job.isContractorOrder || job.assignedWorkerId != null)) ...[
        CustomButton(
          text: context.tr('Rate Experience', 'تجربہ ریٹ کریں'),
          icon: Icons.star_outline_rounded,
          backgroundColor: AppColors.ratingAccent,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RateExperienceScreen(jobRequest: job),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      Row(
        children: [
          if (job.isActive) ...[
            Expanded(
              child: CustomButton(
                text: context.tr('Close Request', 'درخواست بند کریں'),
                type: ButtonType.outline,
                textColor: AppColors.statusRed,
                backgroundColor: AppColors.statusRed,
                onPressed: () => _closeJob(context, appState, job),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: CustomButton(
              text: context.tr('My Requests', 'میری درخواستیں'),
              onPressed: () => _goToRequests(Navigator.of(context)),
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _closeJob(
    BuildContext context,
    AppState appState,
    JobRequestModel job,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final done = context.tr('Request closed.', 'درخواست بند ہو گئی۔');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('Close this request?', 'یہ درخواست بند کریں؟')),
        content: Text(
          ctx.tr(
            'Workers will no longer see it.',
            'کاریگر اسے مزید نہیں دیکھ سکیں گے۔',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('Cancel', 'منسوخ')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ctx.tr('Close', 'بند کریں'),
              style: const TextStyle(color: AppColors.statusRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await appState.closeJobRequest(job.id);
      messenger.showSnackBar(SnackBar(content: Text(done)));
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

    String? workerId;
    if (!job.isContractorOrder) {
      final worker = await showModalBottomSheet<WorkerModel>(
        context: context,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  ctx.tr('Who did this job?', 'یہ کام کس نے کیا؟'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final candidate in job.interestedWorkers)
                ListTile(
                  leading: const Icon(Icons.engineering_rounded),
                  title: Text(candidate.name),
                  subtitle: Text(ctx.tradeName(candidate.trade)),
                  onTap: () => Navigator.pop(ctx, candidate),
                ),
            ],
          ),
        ),
      );
      if (worker == null) return;
      workerId = worker.id;
    }

    try {
      await appState.completeJobRequest(job.id, workerId);
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => RateExperienceScreen(
            jobRequest: job.copyWith(
              status: 'Completed',
              assignedWorkerId: workerId,
            ),
          ),
        ),
      );
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
}

class _StatusBanner extends StatelessWidget {
  final JobRequestModel job;

  const _StatusBanner({required this.job});

  @override
  Widget build(BuildContext context) {
    final String title;
    final String body;
    final IconData icon;
    final Color color;

    if (job.status == 'Completed') {
      title = context.tr('Job completed', 'کام مکمل ہو گیا');
      body = context.tr(
        'Thank you for using Maharat.',
        'مہارت استعمال کرنے کا شکریہ۔',
      );
      icon = Icons.task_alt_rounded;
      color = AppColors.statusBlue;
    } else if (job.isContractorOrder) {
      final (text, statusColor) = orderStatusText(context, job);
      title = text;
      body = switch (job.orderStatus) {
        OrderStatus.pending => context.tr(
          'The shop has been notified and will reply soon.',
          'دکان کو اطلاع دے دی گئی ہے، جلد جواب آئے گا۔',
        ),
        OrderStatus.accepted => context.tr(
          'The shop accepted your order. You can call them or the workers below.',
          'دکان نے آرڈر قبول کر لیا ہے۔ آپ انہیں یا نیچے دیے کاریگروں کو کال کر سکتے ہیں۔',
        ),
        OrderStatus.declined => context.tr(
          'The shop could not take this order. Try another shop or post it to all workers.',
          'دکان یہ آرڈر نہیں لے سکی۔ کوئی اور دکان آزمائیں یا سب کاریگروں کو بھیجیں۔',
        ),
        null => '',
      };
      icon = Icons.storefront_rounded;
      color = statusColor;
    } else if (job.status == 'Closed') {
      title = context.tr('Request closed', 'درخواست بند ہے');
      body = '';
      icon = Icons.block_rounded;
      color = AppColors.secondaryText;
    } else {
      title = context.tr('Request sent', 'درخواست بھیج دی گئی');
      body = context.tr(
        'Verified ${context.tradeName(job.tradeCategory)}s serving ${context.areaName(job.location)} can now see it and respond.',
        '${context.areaName(job.location)} میں کام کرنے والے تصدیق شدہ ${context.tradeName(job.tradeCategory)} اب اسے دیکھ کر جواب دے سکتے ہیں۔',
      );
      icon = Icons.check_rounded;
      color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryText,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestedWorkersSection extends StatelessWidget {
  final JobRequestModel job;

  const _InterestedWorkersSection({required this.job});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.tr(
            'Interested workers (${job.interestedWorkers.length})',
            'دلچسپی رکھنے والے کاریگر (${job.interestedWorkers.length})',
          ),
        ),
        const SizedBox(height: 8),
        if (job.interestedWorkers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                if (job.isActive) ...[
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  job.isActive
                      ? context.tr(
                          'Waiting for workers to respond...',
                          'کاریگروں کے جواب کا انتظار...',
                        )
                      : context.tr('No responses.', 'کوئی جواب نہیں آیا۔'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                if (job.isActive) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                      'You will see them here as soon as they respond.',
                      'جواب دیتے ہی وہ یہاں نظر آئیں گے۔',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          for (final worker in job.interestedWorkers)
            WorkerCard(
              worker: worker,
              distanceKm: distanceBetween(
                job.exactLocation,
                worker.baseLocation,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorkerProfileScreen(worker: worker),
                ),
              ),
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
        if (appState.jobsStatus == LoadStatus.loading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _ContractorSection extends StatelessWidget {
  final JobRequestModel job;

  const _ContractorSection({required this.job});

  @override
  Widget build(BuildContext context) {
    final shop = job.contractor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: context.tr('Shop', 'دکان')),
        if (shop == null)
          Text(
            context.tr(
              'This shop is no longer available.',
              'یہ دکان اب دستیاب نہیں۔',
            ),
            style: const TextStyle(color: AppColors.secondaryText),
          )
        else
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.lightMint,
                child: Icon(Icons.storefront_rounded, color: AppColors.darkGreen),
              ),
              title: Text(
                shop.businessName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('★ ${shop.rating} · ${shop.ownerName}'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContractorProfileScreen(contractor: shop),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.call_outlined, color: AppColors.primary),
                onPressed: () => showContactDialog(
                  context,
                  name: shop.businessName,
                  phone: shop.phone,
                  isWhatsApp: false,
                ),
              ),
            ),
          ),
        if (job.assignedTeam.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionHeader(
            title: context.tr(
              'Workers being sent (${job.assignedTeam.length})',
              'بھیجے جانے والے کاریگر (${job.assignedTeam.length})',
            ),
          ),
          for (final worker in job.assignedTeam)
            WorkerCard(
              worker: worker,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorkerProfileScreen(worker: worker),
                ),
              ),
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
      ],
    );
  }
}
