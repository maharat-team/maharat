import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../core/widgets/contact_dialog.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/contractor_model.dart';
import '../../../state/app_state.dart';

/// The shop's workers. Verified Maharat workers are invited by mobile number
/// and join once they accept.
class ContractorTeamTab extends StatelessWidget {
  const ContractorTeamTab({super.key});

  Future<void> _invite(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('Invite a worker', 'کاریگر کو دعوت دیں')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ctx.tr(
                'Enter the mobile number the worker registered with on Maharat. They must be verified.',
                'وہ موبائل نمبر درج کریں جس سے کاریگر مہارت پر رجسٹرڈ ہے۔ کاریگر کا تصدیق شدہ ہونا ضروری ہے۔',
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '0300 1234567',
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('Cancel', 'منسوخ')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(ctx.tr('Send invite', 'دعوت بھیجیں')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (phone == null || phone.trim().isEmpty) return;
    try {
      final name = await appState.inviteTeamMember(phone);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Invitation sent to $name. They will appear once they accept.',
              '$name کو دعوت بھیج دی گئی۔ قبول کرنے کے بعد وہ یہاں نظر آئیں گے۔',
            ),
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  Future<void> _remove(BuildContext context, TeamMembership member) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          ctx.tr(
            'Remove ${member.worker?.name ?? 'this worker'}?',
            '${member.worker?.name ?? 'اس کاریگر'} کو ہٹائیں؟',
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
              ctx.tr('Remove', 'ہٹائیں'),
              style: const TextStyle(color: AppColors.statusRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await appState.removeTeamMember(member.workerId);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final team = appState.team;
    final active = team.where((m) => m.isActive).toList();
    final invited = team.where((m) => m.isInvite).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('My Team', 'میری ٹیم'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _invite(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(context.tr('Invite worker', 'کاریگر شامل کریں')),
      ),
      body: RefreshIndicator(
        onRefresh: appState.refreshJobs,
        child: team.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 80),
                  EmptyStateView(
                    icon: Icons.groups_outlined,
                    title: context.tr('No workers yet', 'ابھی کوئی کاریگر نہیں'),
                    subtitle: context.tr(
                      'Invite verified Maharat workers by their mobile number. You can then send them to your orders.',
                      'تصدیق شدہ کاریگروں کو ان کے موبائل نمبر سے دعوت دیں، پھر انہیں آرڈرز پر بھیجیں۔',
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  for (final member in active)
                    _MemberTile(
                      member: member,
                      onRemove: () => _remove(context, member),
                    ),
                  if (invited.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                      child: Text(
                        context.tr('Waiting to accept', 'قبول کرنے کا انتظار'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                    for (final member in invited)
                      _MemberTile(
                        member: member,
                        onRemove: () => _remove(context, member),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final TeamMembership member;
  final VoidCallback onRemove;

  const _MemberTile({required this.member, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final worker = member.worker;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: member.isActive
              ? AppColors.lightMint
              : AppColors.border,
          child: Icon(
            member.isActive
                ? Icons.engineering_rounded
                : Icons.hourglass_top_rounded,
            color: AppColors.darkGreen,
          ),
        ),
        title: Text(worker?.name ?? '—'),
        subtitle: worker == null
            ? null
            : Text(
                [
                  context.tradeName(worker.trade),
                  '★ ${worker.rating}',
                  if (member.isActive)
                    worker.isAvailableToday
                        ? context.tr('available today', 'آج دستیاب')
                        : context.tr('not available', 'دستیاب نہیں'),
                ].join(' · '),
              ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'remove') onRemove();
            if (value == 'call' && worker != null) {
              showContactDialog(
                context,
                name: worker.name,
                subtitle: PhoneUtils.display(worker.phone),
                phone: worker.phone,
                isWhatsApp: false,
              );
            }
          },
          itemBuilder: (ctx) => [
            if (worker != null)
              PopupMenuItem(value: 'call', child: Text(ctx.tr('Call', 'کال'))),
            PopupMenuItem(
              value: 'remove',
              child: Text(
                member.isActive
                    ? ctx.tr('Remove from team', 'ٹیم سے ہٹائیں')
                    : ctx.tr('Cancel invite', 'دعوت منسوخ کریں'),
                style: const TextStyle(color: AppColors.statusRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
