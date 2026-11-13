import 'package:flutter/material.dart';
import '../../models/job_request_model.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../theme/app_colors.dart';

class RequestCard extends StatelessWidget {
  final JobRequestModel request;
  final VoidCallback onTap;
  final VoidCallback? onRateTap;
  final VoidCallback? onCloseTap;

  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.onRateTap,
    this.onCloseTap,
  });

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg) = switch (request.status) {
      'Active' => (AppColors.primary, AppColors.lightMint),
      'Completed' => (AppColors.statusBlue, AppColors.statusBlue.withAlpha(25)),
      _ => (AppColors.secondaryText, AppColors.border),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Pill(
                      text: context.tradeName(request.tradeCategory),
                      color: AppColors.darkGreen,
                      background: AppColors.primary.withAlpha(20),
                    ),
                    Text(
                      '• ${context.urgencyName(request.urgency)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    _Pill(
                      text: context.statusName(request.status),
                      color: statusColor,
                      background: statusBg,
                    ),
                  ],
                ),
                if (request.isContractorOrder) ...[
                  const SizedBox(height: 10),
                  _ContractorLine(request: request),
                ],
                const SizedBox(height: 10),
                Text(
                  request.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _buildFooterRow(context),
                if (request.isActive && onCloseTap != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        context.tr('Tap for details', 'تفصیل کے لیے ٹیپ کریں'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      TextButton(
                        onPressed: onCloseTap,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          context.tr('Close Job', 'کام بند کریں'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (request.status == 'Completed') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  _buildRatingRow(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterRow(BuildContext context) {
    final location = Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 14,
          color: AppColors.secondaryText,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            context.areaName(request.location),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
        ),
      ],
    );
    if (!request.isActive || request.isContractorOrder) return location;

    final count = request.interestedWorkers.length;
    final interested = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.people_outline_rounded,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            context.tr('$count interested', '$count دلچسپی رکھتے ہیں'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [location, const SizedBox(height: 4), interested],
          );
        }
        return Row(
          children: [
            Expanded(child: location),
            const SizedBox(width: 8),
            interested,
          ],
        );
      },
    );
  }

  Widget _buildRatingRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (request.ratingGiven != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: AppColors.ratingAccent,
              ),
              const SizedBox(width: 4),
              Text(
                context.tr(
                  'Rated ${request.ratingGiven}',
                  'ریٹنگ ${request.ratingGiven}',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          )
        else
          Text(
            context.tr('Job completed', 'کام مکمل ہو گیا'),
            style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
        if (request.ratingGiven == null && onRateTap != null)
          ElevatedButton.icon(
            onPressed: onRateTap,
            icon: const Icon(Icons.star_outline_rounded, size: 16),
            label: Text(
              context.tr('Rate Experience', 'تجربہ ریٹ کریں'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ratingAccent,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Sent to <shop> · Waiting for reply" and similar, for contractor orders.
class _ContractorLine extends StatelessWidget {
  final JobRequestModel request;

  const _ContractorLine({required this.request});

  @override
  Widget build(BuildContext context) {
    final shop =
        request.contractor?.businessName ?? context.tr('Contractor', 'ٹھیکیدار');
    final (text, color) = orderStatusText(context, request);
    return Row(
      children: [
        const Icon(Icons.storefront_rounded, size: 16, color: AppColors.darkGreen),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$shop · $text',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Where a contractor order stands, in words and a colour.
(String, Color) orderStatusText(BuildContext context, JobRequestModel job) {
  if (job.status == 'Completed') {
    return (context.tr('Completed', 'مکمل'), AppColors.statusBlue);
  }
  switch (job.orderStatus) {
    case OrderStatus.declined:
      return (context.tr('Declined', 'انکار کر دیا'), AppColors.statusRed);
    case OrderStatus.accepted:
      if (job.assignedTeam.isEmpty) {
        return (
          context.tr('Accepted · choosing workers', 'قبول · کاریگر منتخب ہو رہے ہیں'),
          AppColors.primary,
        );
      }
      final names = job.assignedTeam.map((w) => w.name).join(', ');
      return (
        context.tr('Sending: $names', 'بھیجے جا رہے ہیں: $names'),
        AppColors.primary,
      );
    case OrderStatus.pending:
    case null:
      if (job.status == 'Closed') {
        return (context.tr('Closed', 'بند'), AppColors.secondaryText);
      }
      return (
        context.tr('Waiting for reply', 'جواب کا انتظار'),
        AppColors.statusOrange,
      );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _Pill({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
