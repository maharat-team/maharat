import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/user_profile_model.dart';
import '../../../state/app_state.dart';
import '../../onboarding/language_selection_screen.dart';
import '../../worker/dashboard/worker_dashboard_screen.dart';
import '../../worker/registration/worker_reg_step1_screen.dart';

class CustomerProfileTab extends StatefulWidget {
  const CustomerProfileTab({super.key});

  @override
  State<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<CustomerProfileTab> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Profile'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.lightMint,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.neighbourhood,
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
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                    ),
                    onPressed: () => _openEditProfileDialog(context, appState),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Mode Switch Card: Join as Tradesperson
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.engineering_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Are you a Tradesperson?',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Offer your service to Bahawalpur households. 100% free with 0% commission.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.lightMint,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    text: user.isWorkerRegistered
                        ? 'Switch to Worker Dashboard'
                        : 'Join as a Tradesperson',
                    type: ButtonType.secondary,
                    onPressed: () {
                      if (user.isWorkerRegistered) {
                        appState.setUserRole(UserRole.worker);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const WorkerDashboardScreen(),
                          ),
                          (route) => false,
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WorkerRegStep1Screen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings Section
            const Text(
              'Settings & Preferences',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 10),

            _buildTile(
              icon: Icons.translate_rounded,
              title: 'Language',
              subtitle: user.language,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LanguageSelectionScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildTile(
              icon: Icons.my_location_rounded,
              title: 'My Neighbourhood',
              subtitle: user.neighbourhood,
              onTap: () => _openAreaSelectorDialog(context, appState),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job Response Alerts',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        Text(
                          'Receive WhatsApp / push notifications when workers respond',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _notificationsEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _notificationsEnabled = val;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Support & Info Section
            const Text(
              'Support & Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 10),

            _buildTile(
              icon: Icons.chat_outlined,
              title: 'Help on WhatsApp',
              subtitle: 'Customer support helpline',
              iconColor: AppColors.whatsappGreen,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Opening Maharat WhatsApp Support (+92 300 0000000)...',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildTile(
              icon: Icons.info_outline_rounded,
              title: 'About Maharat',
              subtitle: 'Free Bahawalpur tradespeople discovery platform',
              onTap: () => _openAboutDialog(context),
            ),

            const SizedBox(height: 32),

            // Logout Button
            CustomButton(
              text: 'Log Out',
              type: ButtonType.outline,
              textColor: AppColors.statusRed,
              backgroundColor: AppColors.statusRed,
              icon: Icons.logout_rounded,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  // MaharatApp returns to onboarding when the session ends.
                  await appState.signOut();
                } catch (error) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(friendlyError(error))),
                  );
                }
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
  }) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }

  void _openEditProfileDialog(BuildContext context, AppState appState) {
    final nameCtrl = TextEditingController(text: appState.currentUser.name);
    final phoneCtrl = TextEditingController(text: appState.currentUser.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await appState.updateProfile(
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text(friendlyError(error))),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _openAreaSelectorDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Your Neighbourhood'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppConstants.bahawalpurNeighbourhoods.length,
            itemBuilder: (context, index) {
              final area = AppConstants.bahawalpurNeighbourhoods[index];
              return ListTile(
                title: Text(area),
                trailing: appState.currentUser.neighbourhood == area
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  try {
                    await appState.updateProfile(neighbourhood: area);
                  } catch (error) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(friendlyError(error))),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _openAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.handyman_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('About Maharat (مهارت)'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maharat is a community service platform dedicated to connecting households with verified local tradespeople in Bahawalpur, Pakistan.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              '• 100% Free for customers & workers.\n'
              '• 0% Commission on all jobs.\n'
              '• Direct WhatsApp & phone contact.\n'
              '• CNIC verification process for trusted tradespeople.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.darkGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
