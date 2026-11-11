import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../models/job_request_model.dart';
import '../../models/worker_model.dart';
import '../../state/app_state.dart';
import '../settings/settings_screen.dart';
import '../verification/verification_result_screen.dart';
import 'orders/contractor_orders_tab.dart';
import 'registration/contractor_reg_step2_screen.dart';
import 'shop/contractor_shop_tab.dart';
import 'team/contractor_team_tab.dart';

class ContractorMainScreen extends StatefulWidget {
  const ContractorMainScreen({super.key});

  @override
  State<ContractorMainScreen> createState() => _ContractorMainScreenState();
}

class _ContractorMainScreenState extends State<ContractorMainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final shop = appState.contractorProfile;

    if (shop == null || !shop.isVerified) {
      return _PendingShopScreen(appState: appState);
    }

    final newOrders = appState.contractorOrders
        .where((o) => o.isActive && o.orderStatus == OrderStatus.pending)
        .length;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          ContractorOrdersTab(),
          ContractorTeamTab(),
          ContractorShopTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: AppColors.lightMint,
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: newOrders > 0,
              label: Text('$newOrders'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: context.tr('Orders', 'آرڈرز'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
            label: context.tr('Team', 'ٹیم'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront_rounded),
            label: context.tr('Shop', 'دکان'),
          ),
        ],
      ),
    );
  }
}

/// Shown until the shop owner's identity check passes.
class _PendingShopScreen extends StatelessWidget {
  final AppState appState;

  const _PendingShopScreen({required this.appState});

  @override
  Widget build(BuildContext context) {
    final shop = appState.contractorProfile;
    final info = appState.contractorVerification;
    final rejected = shop?.verificationStatus == VerificationStatus.rejected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(shop?.businessName ?? context.tr('My Shop', 'میری دکان')),
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
        onRefresh: appState.refreshJobs,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              rejected ? Icons.gpp_bad_rounded : Icons.hourglass_top_rounded,
              size: 64,
              color: rejected ? AppColors.statusRed : AppColors.statusOrange,
            ),
            const SizedBox(height: 16),
            Text(
              rejected
                  ? context.tr('Shop not verified yet', 'دکان کی ابھی تصدیق نہیں ہوئی')
                  : context.tr('Verification pending', 'تصدیق زیر التوا'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              rejected
                  ? verificationReason(context, info?.code, info?.reason)
                  : context.tr(
                      'Run the identity check to make your shop visible to customers.',
                      'اپنی دکان گاہکوں کو دکھانے کے لیے شناخت کی تصدیق کریں۔',
                    ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (shop != null)
              CustomButton(
                text: rejected
                    ? context.tr('Retake photos', 'تصاویر دوبارہ لیں')
                    : context.tr('Check now', 'ابھی تصدیق کریں'),
                icon: rejected
                    ? Icons.camera_alt_rounded
                    : Icons.verified_user_rounded,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => rejected
                        ? ContractorRegStep2Screen.retry(shop)
                        : const VerificationResultScreen(contractor: true),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
