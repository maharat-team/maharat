import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/contact_dialog.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/location_widgets.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../core/widgets/request_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/job_request_model.dart';
import '../../../state/app_state.dart';

/// One order: accept or decline it, then choose who from the team to send.
class ContractorOrderScreen extends StatefulWidget {
  final String orderId;

  const ContractorOrderScreen({super.key, required this.orderId});

  @override
  State<ContractorOrderScreen> createState() => _ContractorOrderScreenState();
}

class _ContractorOrderScreenState extends State<ContractorOrderScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseTeam(AppState appState, JobRequestModel order) async {
    final team = appState.activeTeam;
    if (team.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Your team is empty. Invite workers from the Team tab first.',
              'آپ کی ٹیم خالی ہے۔ پہلے ٹیم ٹیب سے کاریگر شامل کریں۔',
            ),
          ),
        ),
      );
      return;
    }
    final selected = order.assignedTeam.map((w) => w.id).toSet();
    final chosen = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ctx.tr('Who will go?', 'کون جائے گا؟'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final worker in team)
                        CheckboxListTile(
                          value: selected.contains(worker.id),
                          onChanged: (on) => setSheet(
                            () => on == true
                                ? selected.add(worker.id)
                                : selected.remove(worker.id),
                          ),
                          title: Text(worker.name),
                          subtitle: Text(
                            '${ctx.tradeName(worker.trade)}${worker.isAvailableToday ? '' : ' · ${ctx.tr('not available today', 'آج دستیاب نہیں')}'}',
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                CustomButton(
                  text: ctx.tr('Send these workers', 'یہ کاریگر بھیجیں'),
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(ctx, selected),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;
    await _run(
      () => appState.assignOrderTeam(order.id, chosen.toList()),
      context.tr(
        'Workers sent. The customer can see who is coming.',
        'کاریگر بھیج دیے گئے۔ گاہک دیکھ سکتا ہے کون آ رہا ہے۔',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final matches = appState.contractorOrders.where((o) => o.id == widget.orderId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(context.tr('This order is no longer available.', 'یہ آرڈر اب دستیاب نہیں۔')),
        ),
      );
    }
    final order = matches.first;
    final (statusText, statusColor) = orderStatusText(context, order);
    final exact = order.exactLocation;
    final phone = order.customerPhone;
    final pending = order.isActive && order.orderStatus == OrderStatus.pending;
    final accepted = order.isActive && order.orderStatus == OrderStatus.accepted;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('Order details', 'آرڈر کی تفصیل'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              statusText,
              style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.tradeName(order.tradeCategory)} · ${context.urgencyName(order.urgency)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(order.description, style: const TextStyle(height: 1.5)),
                  JobPhotoStrip(urls: order.photoUrls),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(
                      'Customer: ${order.customerName}',
                      'گاہک: ${order.customerName}',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    context.areaName(order.location),
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                  if (phone != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: context.tr('Call', 'کال'),
                            icon: Icons.call_outlined,
                            height: 42,
                            type: ButtonType.outline,
                            onPressed: () => showContactDialog(
                              context,
                              name: order.customerName,
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
                            height: 42,
                            backgroundColor: AppColors.whatsappGreen,
                            onPressed: () => showContactDialog(
                              context,
                              name: order.customerName,
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
            ),
          ),
          if (exact != null) ...[
            const SizedBox(height: 16),
            LocationPreviewCard(
              point: exact,
              addressDetails: order.addressDetails,
              from: appState.contractorProfile?.location,
            ),
          ],
          if (order.assignedTeam.isNotEmpty) ...[
            const SizedBox(height: 20),
            SectionHeader(title: context.tr('Workers sent', 'بھیجے گئے کاریگر')),
            for (final worker in order.assignedTeam)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.lightMint,
                  child: Icon(Icons.engineering_rounded, color: AppColors.darkGreen),
                ),
                title: Text(worker.name),
                subtitle: Text(context.tradeName(worker.trade)),
              ),
          ],
          const SizedBox(height: 24),
          if (pending)
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: context.tr('Decline', 'انکار'),
                    type: ButtonType.outline,
                    textColor: AppColors.statusRed,
                    backgroundColor: AppColors.statusRed,
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => appState.respondToOrder(order.id, false),
                            context.tr('Order declined.', 'آرڈر سے انکار کر دیا۔'),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: context.tr('Accept', 'قبول کریں'),
                    isLoading: _busy,
                    onPressed: () => _run(
                      () => appState.respondToOrder(order.id, true),
                      context.tr(
                        'Order accepted. Now choose who to send.',
                        'آرڈر قبول ہو گیا۔ اب منتخب کریں کس کو بھیجنا ہے۔',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (accepted)
            CustomButton(
              text: order.assignedTeam.isEmpty
                  ? context.tr('Choose workers to send', 'بھیجنے کے لیے کاریگر منتخب کریں')
                  : context.tr('Change workers', 'کاریگر تبدیل کریں'),
              icon: Icons.group_add_rounded,
              isLoading: _busy,
              onPressed: () => _chooseTeam(appState, order),
            ),
        ],
      ),
    );
  }
}
