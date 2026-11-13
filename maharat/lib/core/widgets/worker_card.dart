import 'package:flutter/material.dart';
import '../../models/worker_model.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../theme/app_colors.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback onTap;
  final VoidCallback onWhatsAppTap;
  final VoidCallback onCallTap;

  /// Kilometres from the viewer, when both locations are known.
  final double? distanceKm;

  const WorkerCard({
    super.key,
    required this.worker,
    required this.onTap,
    required this.onWhatsAppTap,
    required this.onCallTap,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar / Initials
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.lightMint,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withAlpha(50),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(worker.name),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Details
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                  child: Row(
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
                          const SizedBox(height: 4),
                          Text(
                            context.tradeName(worker.trade),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: AppColors.ratingAccent,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${worker.rating}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '(${worker.reviewCount})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                '•',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              Text(
                                context.yearsExperience(worker.experienceYears),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                distanceKm == null
                                    ? context.areaName(worker.neighbourhood)
                                    : '${context.areaName(worker.neighbourhood)} · '
                                          '${context.distance(distanceKm!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              size: 14,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                worker.visitFee == 0
                                    ? context.visitFee(0)
                                    : context.tr(
                                        'Visit fee: Rs. ${worker.visitFee}',
                                        'وزٹ فیس: ${worker.visitFee} روپے',
                                      ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: worker.visitFee == 0
                                      ? AppColors.primary
                                      : AppColors.primaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                    final actions = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: onWhatsAppTap,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.whatsappGreen.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.whatsappGreen.withAlpha(80),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 16,
                                  color: AppColors.whatsappGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.tr('WhatsApp', 'واٹس ایپ'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.whatsappGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onCallTap,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.call_outlined,
                              size: 18,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    );

                    if (constraints.maxWidth < 360) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          details,
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: actions,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: 8),
                        actions,
                      ],
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'W';
  }
}
