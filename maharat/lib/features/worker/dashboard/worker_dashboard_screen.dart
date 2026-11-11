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
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/contractor_model.dart';
import '../../../models/job_request_model.dart';
import '../../../models/worker_model.dart';
import '../../../state/app_state.dart';
import '../../settings/settings_screen.dart';
import '../../verification/verification_result_screen.dart';
import '../profile/worker_own_profile_screen.dart';
import '../registration/worker_reg_step2_screen.dart';

class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final worker = appState.workerProfile;
    final nearby = appState.nearbyJobRequests;
    final assigned = appState.assignedJobs.where((j) => j.isActive).toList();
    final invites = appState.pendingInvites;
    final strengthChecks = [
      worker.bio.isNotEmpty,
      worker.workPhotos.isNotEmpty,
      worker.isCnicVerified,
      worker.reviewCount > 0,
      worker.baseLocation != null,
    ];
    final profileStrength =
        strengthChecks.where((done) => done).length / strengthChecks.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Worker Dashboard', 'کاریگر ڈیش بورڈ')),
        actions: [
          IconButton(
            tooltip: context.tr('My profile', 'میری پروفائل'),
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkerOwnProfileScreen()),
            ),
          ),
          IconButton(
            tooltip: context.tr('Settings', 'سیٹنگز'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
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
              _HeaderCard(worker: worker),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatCard(
                    icon: Icons.task_alt_rounded,
                    value: '${worker.completedJobsCount}',
                    label: context.tr('Jobs done', 'مکمل کام'),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.work_history_outlined,
                    value: '${worker.experienceYears}',
                    label: context.tr('Years exp.', 'سال تجربہ'),
                    color: AppColors.whatsappGreen,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.star_rounded,
                    value: '${worker.rating}',
                    label: context.tr(
                      '${worker.reviewCount} reviews',
                      '${worker.reviewCount} ریویوز',
                    ),
                    color: AppColors.ratingAccent,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _StrengthCard(strength: profileStrength),
              const SizedBox(height: 24),
              if (!worker.isCnicVerified)
                _VerificationNotice(appState: appState)
              else ...[
                if (invites.isNotEmpty) ...[
                  SectionHeader(
                    title: context.tr('Team invitations', 'ٹیم کی دعوتیں'),
                  ),
                  for (final invite in invites) _InviteCard(invite: invite),
                  const SizedBox(height: 16),
                ],
                if (assigned.isNotEmpty) ...[
                  SectionHeader(
                    title: context.tr(
                      'Sent by your contractor (${assigned.length})',
                      'آپ کے ٹھیکیدار کی طرف سے (${assigned.length})',
                    ),
                  ),
                  for (final job in assigned) _AssignedJobCard(job: job),
                  const SizedBox(height: 16),
                ],
                SectionHeader(
                  title: context.tr(
                    'Jobs near you (${nearby.length})',
                    'آپ کے قریب کام (${nearby.length})',
                  ),
                ),
                const SizedBox(height: 8),
                if (nearby.isEmpty && appState.jobsStatus == LoadStatus.error)
                  ErrorRetryView(
                    message:
                        appState.jobsError ??
                        context.tr('Could not load jobs.', 'کام لوڈ نہیں ہو سکے۔'),
                    onRetry: appState.refreshJobs,
                  )
                else if (nearby.isEmpty &&
                    appState.jobsStatus == LoadStatus.loading)
                  const LoadingView()
                else if (nearby.isEmpty)
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
                        const Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr(
                            'No new jobs in your areas right now. Pull down to refresh.',
                            'ابھی آپ کے علاقوں میں کوئی نیا کام نہیں۔ ریفریش کے لیے نیچے کھینچیں۔',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final job in nearby)
                    _NearbyJobCard(job: job, worker: worker),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final WorkerModel worker;

  const _HeaderCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
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
                    worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
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
                    Text(
                      worker.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.tradeName(worker.trade),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (worker.isCnicVerified)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                context.tr('Verified', 'تصدیق شدہ'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                            ],
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
          const SizedBox(height: 12),
          Row(
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
              Expanded(
                child: Text(
                  worker.isAvailableToday
                      ? context.tr('Available for jobs today', 'آج کام کے لیے دستیاب')
                      : context.tr('Not available today', 'آج دستیاب نہیں'),
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
    );
  }
}

class _StrengthCard extends StatelessWidget {
  final double strength;

  const _StrengthCard({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Profile strength', 'پروفائل کی مضبوطی'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              Text(
                '${(strength * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          if (strength < 1) ...[
            const SizedBox(height: 6),
            Text(
              context.tr(
                'Add a bio, work photos and your location to get more jobs.',
                'زیادہ کام کے لیے تعارف، کام کی تصاویر اور اپنا مقام شامل کریں۔',
              ),
              style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerificationNotice extends StatelessWidget {
  final AppState appState;

  const _VerificationNotice({required this.appState});

  @override
  Widget build(BuildContext context) {
    final info = appState.workerVerification;
    final isRejected =
        appState.workerProfile.verificationStatus == VerificationStatus.rejected;

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
            isRejected
                ? context.tr('Not verified yet', 'ابھی تصدیق نہیں ہوئی')
                : context.tr('Verification pending', 'تصدیق زیر التوا'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isRejected
                ? verificationReason(context, info?.code, info?.reason)
                : context.tr(
                    'Your documents are saved. Run the check to get verified, then jobs near you will appear here.',
                    'آپ کی دستاویزات محفوظ ہیں۔ تصدیق کریں، پھر آپ کے قریب کے کام یہاں نظر آئیں گے۔',
                  ),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
          if (info?.score != null && info!.score! > 0) ...[
            const SizedBox(height: 6),
            Text(
              context.tr(
                'Last face match: ${info.score!.round()}%',
                'پچھلی مماثلت: ${info.score!.round()}%',
              ),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          CustomButton(
            text: isRejected
                ? context.tr('Retake photos', 'تصاویر دوبارہ لیں')
                : context.tr('Check now', 'ابھی تصدیق کریں'),
            icon: isRejected
                ? Icons.camera_alt_rounded
                : Icons.verified_user_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => isRejected
                      ? WorkerRegStep2Screen.retry(appState.workerProfile)
                      : const VerificationResultScreen(contractor: false),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatefulWidget {
  final TeamMembership invite;

  const _InviteCard({required this.invite});

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Provider.of<AppState>(
        context,
        listen: false,
      ).respondToTeamInvite(widget.invite.contractorId, accept);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.invite.contractor;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront_rounded, color: AppColors.darkGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(
                      '${shop?.businessName ?? 'A shop'} wants you in their team',
                      '${shop?.businessName ?? 'ایک دکان'} آپ کو اپنی ٹیم میں شامل کرنا چاہتی ہے',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'They can send you to their customers\' jobs. You can leave the team any time.',
                'وہ آپ کو اپنے گاہکوں کے کام پر بھیج سکیں گے۔ آپ کسی بھی وقت ٹیم چھوڑ سکتے ہیں۔',
              ),
              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: context.tr('Decline', 'انکار'),
                    type: ButtonType.outline,
                    height: 42,
                    onPressed: _busy ? null : () => _respond(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    text: context.tr('Join team', 'ٹیم میں شامل ہوں'),
                    height: 42,
                    isLoading: _busy,
                    onPressed: () => _respond(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignedJobCard extends StatelessWidget {
  final JobRequestModel job;

  const _AssignedJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final exact = job.exactLocation;
    final phone = job.customerPhone;
    final appState = Provider.of<AppState>(context, listen: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              '${job.contractor?.businessName ?? 'Your contractor'} sent you',
              '${job.contractor?.businessName ?? 'آپ کے ٹھیکیدار'} نے آپ کو بھیجا ہے',
            ),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${context.tradeName(job.tradeCategory)} · ${context.urgencyName(job.urgency)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(job.description, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Customer: ${job.customerName} · ${context.areaName(job.location)}',
              'گاہک: ${job.customerName} · ${context.areaName(job.location)}',
            ),
            style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
          JobPhotoStrip(urls: job.photoUrls),
          if (exact != null) ...[
            const SizedBox(height: 12),
            LocationPreviewCard(
              point: exact,
              addressDetails: job.addressDetails,
              from: appState.myLocation,
            ),
          ],
          if (phone != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: context.tr('Call customer', 'گاہک کو کال'),
                    icon: Icons.call_outlined,
                    height: 44,
                    onPressed: () => showContactDialog(
                      context,
                      name: job.customerName,
                      phone: phone,
                      isWhatsApp: false,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    text: context.tr('WhatsApp', 'واٹس ایپ'),
                    icon: Icons.chat_bubble_outline_rounded,
                    height: 44,
                    backgroundColor: AppColors.whatsappGreen,
                    onPressed: () => showContactDialog(
                      context,
                      name: job.customerName,
                      phone: phone,
                      isWhatsApp: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NearbyJobCard extends StatelessWidget {
  final JobRequestModel job;
  final WorkerModel worker;

  const _NearbyJobCard({required this.job, required this.worker});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final hasResponded = job.interestedWorkers.any((w) => w.id == worker.id);
    final km = distanceBetween(appState.myLocation, job.mapLocation);
    final exact = job.exactLocation;
    final approx = job.approxLocation;

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                '• ${context.urgencyName(job.urgency)}',
                style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
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
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      km == null
                          ? context.areaName(job.location)
                          : '${context.areaName(job.location)} · ${context.distance(km)}',
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
          const SizedBox(height: 8),
          Text(
            context.tr('Customer: ${job.customerName}', 'گاہک: ${job.customerName}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
          JobPhotoStrip(urls: job.photoUrls),
          if (exact != null) ...[
            const SizedBox(height: 12),
            LocationPreviewCard(
              point: exact,
              addressDetails: job.addressDetails,
              from: appState.myLocation,
            ),
          ] else if (approx != null) ...[
            const SizedBox(height: 12),
            LocationPreviewCard(
              point: approx,
              isExact: false,
              from: appState.myLocation,
              title: context.tr(
                'Approximate area · exact pin after you respond',
                'تقریبی علاقہ · جواب کے بعد درست پن',
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          CustomButton(
            text: hasResponded
                ? context.tr('Interest sent ✓', 'دلچسپی بھیج دی ✓')
                : context.tr("I'm interested", 'مجھے دلچسپی ہے'),
            type: hasResponded ? ButtonType.secondary : ButtonType.primary,
            onPressed: hasResponded
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final sent = context.tr(
                      '${job.customerName} has been told you are interested. They can now call you.',
                      '${job.customerName} کو آپ کی دلچسپی کی اطلاع دے دی گئی۔ وہ اب آپ کو کال کر سکتے ہیں۔',
                    );
                    try {
                      await appState.workerRespondToJob(job.id);
                      messenger.showSnackBar(SnackBar(content: Text(sent)));
                    } catch (error) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(friendlyError(error))),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
