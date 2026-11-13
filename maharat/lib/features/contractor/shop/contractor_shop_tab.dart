import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/location_widgets.dart';
import '../../../core/widgets/review_list.dart';
import '../../../core/widgets/section_header.dart';
import '../../../state/app_state.dart';
import '../../customer/contractor_profile/contractor_profile_screen.dart';
import '../../settings/settings_screen.dart';

/// The shop's own overview: whether it takes orders, stats, and settings.
class ContractorShopTab extends StatelessWidget {
  const ContractorShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final shop = appState.contractorProfile;
    if (shop == null) return const SizedBox.shrink();
    final location = shop.location;
    final activeOrders = appState.contractorOrders.where((o) => o.isActive);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(shop.businessName),
        actions: [
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
        onRefresh: appState.refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: SwitchListTile(
                value: shop.isAcceptingOrders,
                activeTrackColor: AppColors.primary,
                title: Text(
                  shop.isAcceptingOrders
                      ? context.tr('Taking orders', 'آرڈر لے رہے ہیں')
                      : context.tr('Not taking orders', 'آرڈر نہیں لے رہے'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  context.tr(
                    'Turn off when your team is fully booked.',
                    'جب ٹیم مصروف ہو تو بند کر دیں۔',
                  ),
                ),
                onChanged: (on) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await appState.setAcceptingOrders(on);
                  } catch (error) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(friendlyError(error))),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(
                  value: '${activeOrders.length}',
                  label: context.tr('Open orders', 'جاری آرڈرز'),
                  icon: Icons.receipt_long_rounded,
                ),
                const SizedBox(width: 10),
                _Stat(
                  value: '${appState.activeTeam.length}',
                  label: context.tr('Workers', 'کاریگر'),
                  icon: Icons.groups_rounded,
                ),
                const SizedBox(width: 10),
                _Stat(
                  value: '${shop.rating}',
                  label: context.tr(
                    '${shop.reviewCount} reviews',
                    '${shop.reviewCount} ریویوز',
                  ),
                  icon: Icons.star_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.visibility_outlined, color: AppColors.primary),
                title: Text(
                  context.tr('See your shop as customers do', 'اپنی دکان گاہک کی نظر سے دیکھیں'),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ContractorProfileScreen(contractor: shop),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(title: context.tr('Services', 'خدمات')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final trade in shop.trades)
                  Chip(label: Text(context.tradeName(trade))),
              ],
            ),
            if (location != null) ...[
              const SizedBox(height: 16),
              SectionHeader(title: context.tr('Shop location', 'دکان کا مقام')),
              LocationPreviewCard(
                point: location,
                title: shop.shopAddress.isEmpty ? null : shop.shopAddress,
              ),
            ],
            const SizedBox(height: 16),
            SectionHeader(
              title: context.tr(
                'Customer reviews (${shop.reviews.length})',
                'گاہکوں کے ریویوز (${shop.reviews.length})',
              ),
            ),
            ReviewList(reviews: shop.reviews),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _Stat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
