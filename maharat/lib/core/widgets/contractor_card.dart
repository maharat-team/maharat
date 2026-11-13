import 'package:flutter/material.dart';
import '../../models/contractor_model.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../theme/app_colors.dart';

/// A shop in the contractor directory.
class ContractorCard extends StatelessWidget {
  final ContractorModel contractor;
  final VoidCallback onTap;
  final double? distanceKm;

  const ContractorCard({
    super.key,
    required this.contractor,
    required this.onTap,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final photo = contractor.shopPhotoUrl;
    final trades = contractor.trades.map(context.tradeName).join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: AppColors.lightMint,
                    child: photo == null
                        ? const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.darkGreen,
                            size: 30,
                          )
                        : Image.network(
                            photo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.storefront_rounded,
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
                              contractor.businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trades,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: AppColors.ratingAccent,
                              ),
                              Text(
                                ' ${contractor.rating} (${contractor.reviewCount})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            context.tr(
                              '${contractor.team.length} workers',
                              '${contractor.team.length} کاریگر',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          Text(
                            distanceKm == null
                                ? context.areaName(contractor.neighbourhood)
                                : context.distance(distanceKm!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      if (!contractor.isAcceptingOrders) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.tr(
                            'Not taking orders right now',
                            'ابھی آرڈر نہیں لے رہے',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusOrange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
