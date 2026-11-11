import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/widgets/custom_button.dart';
import '../../models/user_profile_model.dart';
import '../../state/app_state.dart';
import '../contractor/contractor_main_screen.dart';
import '../contractor/registration/contractor_reg_step1_screen.dart';
import '../customer/customer_main_screen.dart';
import '../location/location_picker_screen.dart';
import '../onboarding/language_selection_screen.dart';
import '../worker/dashboard/worker_dashboard_screen.dart';
import '../worker/registration/worker_reg_step1_screen.dart';

/// Moves the user into [role], registering first when they have not yet.
void switchRole(BuildContext context, UserRole role) {
  final appState = Provider.of<AppState>(context, listen: false);
  final user = appState.currentUser;
  final navigator = Navigator.of(context);

  void goTo(Widget screen) {
    appState.setUserRole(role);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  switch (role) {
    case UserRole.customer:
      goTo(const CustomerMainScreen());
    case UserRole.worker:
      if (user.isWorkerRegistered) {
        goTo(const WorkerDashboardScreen());
      } else {
        navigator.push(
          MaterialPageRoute(builder: (_) => const WorkerRegStep1Screen()),
        );
      }
    case UserRole.contractor:
      if (user.isContractorRegistered) {
        goTo(const ContractorMainScreen());
      } else {
        navigator.push(
          MaterialPageRoute(builder: (_) => const ContractorRegStep1Screen()),
        );
      }
  }
}

/// Profile, language, location, mode switching and account controls. Used
/// as the customer's Profile tab ([embedded]) and as a page elsewhere.
class SettingsScreen extends StatelessWidget {
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: !embedded,
        title: Text(context.tr('Profile & Settings', 'پروفائل اور سیٹنگز')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileCard(user: user),
            const SizedBox(height: 24),
            _SectionTitle(context.tr('Use Maharat as', 'مہارت کس طرح استعمال کریں')),
            const SizedBox(height: 10),
            _RoleSwitcher(user: user),
            const SizedBox(height: 24),
            _SectionTitle(context.tr('Settings', 'سیٹنگز')),
            const SizedBox(height: 10),
            SettingsTile(
              icon: Icons.translate_rounded,
              title: context.tr('Language', 'زبان'),
              subtitle: user.language == AppLanguage.urdu ? 'اردو' : 'English',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LanguageSelectionScreen(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SettingsTile(
              icon: Icons.location_city_rounded,
              title: context.tr('My neighbourhood', 'میرا علاقہ'),
              subtitle: user.neighbourhood.isEmpty
                  ? context.tr('Not set', 'منتخب نہیں')
                  : context.areaName(user.neighbourhood),
              onTap: () => _chooseNeighbourhood(context, appState),
            ),
            const SizedBox(height: 10),
            SettingsTile(
              icon: Icons.home_work_outlined,
              title: context.tr('Home location on map', 'نقشے پر گھر کا مقام'),
              subtitle: user.location == null
                  ? context.tr(
                      'Not set: add it for distances and faster visits',
                      'منتخب نہیں: فاصلے اور جلد پہنچنے کے لیے شامل کریں',
                    )
                  : (user.addressDetails.isNotEmpty
                        ? user.addressDetails
                        : context.tr('Pin saved', 'پن محفوظ ہے')),
              onTap: () => _chooseLocation(context, appState),
            ),
            const SizedBox(height: 24),
            _SectionTitle(context.tr('About', 'معلومات')),
            const SizedBox(height: 10),
            SettingsTile(
              icon: Icons.info_outline_rounded,
              title: context.tr('About Maharat', 'مہارت کے بارے میں'),
              subtitle: context.tr(
                'Free platform for Bahawalpur tradespeople',
                'بہاولپور کے کاریگروں کے لیے مفت پلیٹ فارم',
              ),
              onTap: () => _showAbout(context),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: context.tr('Log Out', 'لاگ آؤٹ'),
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
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _confirmDelete(context, appState),
                child: Text(
                  context.tr('Delete my account', 'میرا اکاؤنٹ ختم کریں'),
                  style: const TextStyle(color: AppColors.statusRed),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseNeighbourhood(
    BuildContext context,
    AppState appState,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final area = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.tr('Select your neighbourhood', 'اپنا علاقہ منتخب کریں')),
        children: [
          for (final area in AppConstants.bahawalpurNeighbourhoods)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, area),
              child: Row(
                children: [
                  Expanded(child: Text(ctx.areaName(area))),
                  if (appState.currentUser.neighbourhood == area)
                    const Icon(Icons.check_rounded, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
    if (area == null) return;
    try {
      await appState.updateProfile(neighbourhood: area);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  Future<void> _chooseLocation(BuildContext context, AppState appState) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = context.tr('Location saved.', 'مقام محفوظ ہو گیا۔');
    final picked = await LocationPickerScreen.open(
      context,
      initial: appState.currentUser.location,
      initialDetails: appState.currentUser.addressDetails,
      title: context.tr('Home location', 'گھر کا مقام'),
    );
    if (picked == null) return;
    try {
      await appState.updateMyLocation(picked.point, picked.addressDetails);
      messenger.showSnackBar(SnackBar(content: Text(saved)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.handyman_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(ctx.tr('About Maharat', 'مہارت کے بارے میں')),
          ],
        ),
        content: Text(
          ctx.tr(
            'Maharat connects households in Bahawalpur with verified local tradespeople and contractors.\n\n'
                '• Free for customers, workers and shops\n'
                '• 0% commission\n'
                '• Direct calls and WhatsApp\n'
                '• Automatic CNIC and face verification',
            'مہارت بہاولپور کے گھرانوں کو تصدیق شدہ مقامی کاریگروں اور ٹھیکیداروں سے جوڑتا ہے۔\n\n'
                '• گاہکوں، کاریگروں اور دکانوں کے لیے مفت\n'
                '• کوئی کمیشن نہیں\n'
                '• براہ راست کال اور واٹس ایپ\n'
                '• خودکار شناختی کارڈ اور چہرے کی تصدیق',
          ),
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('Close', 'بند کریں')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState appState) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('Delete your account?', 'اکاؤنٹ ختم کریں؟')),
        content: Text(
          ctx.tr(
            'This permanently deletes your profile, job requests, reviews you wrote, and any worker or shop profile. It cannot be undone.',
            'اس سے آپ کی پروفائل، کام کی درخواستیں، آپ کے لکھے ریویوز اور کاریگر یا دکان کی پروفائل ہمیشہ کے لیے ختم ہو جائیں گی۔ یہ واپس نہیں ہو سکتا۔',
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
              ctx.tr('Delete', 'ختم کریں'),
              style: const TextStyle(color: AppColors.statusRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await appState.deleteAccount();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfileModel user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.lightMint,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  PhoneUtils.display(user.phone),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr('Edit', 'ترمیم'),
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => _editProfile(context),
          ),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final nameCtrl = TextEditingController(text: appState.currentUser.name);
    final phoneCtrl = TextEditingController(
      text: PhoneUtils.display(appState.currentUser.phone),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(ctx.tr('Edit profile', 'پروفائل میں ترمیم')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: ctx.tr('Full Name', 'پورا نام'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: ctx.tr('Mobile Number', 'موبائل نمبر'),
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
            child: Text(ctx.tr('Save', 'محفوظ کریں')),
          ),
        ],
      ),
    );
  }
}

class _RoleSwitcher extends StatelessWidget {
  final UserProfileModel user;

  const _RoleSwitcher({required this.user});

  @override
  Widget build(BuildContext context) {
    Widget option(UserRole role, IconData icon, String title, String? note) {
      final selected = user.userRole == role;
      return Expanded(
        child: Material(
          color: selected ? AppColors.lightMint : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: selected ? null : () => switchRole(context, role),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: selected ? AppColors.primary : AppColors.secondaryText,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  if (note != null)
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final join = context.tr('Join', 'شامل ہوں');
    return Row(
      children: [
        option(
          UserRole.customer,
          Icons.search_rounded,
          context.tr('Customer', 'گاہک'),
          null,
        ),
        const SizedBox(width: 8),
        option(
          UserRole.worker,
          Icons.engineering_rounded,
          context.tr('Worker', 'کاریگر'),
          user.isWorkerRegistered ? null : join,
        ),
        const SizedBox(width: 8),
        option(
          UserRole.contractor,
          Icons.storefront_rounded,
          context.tr('Contractor', 'ٹھیکیدار'),
          user.isContractorRegistered ? null : join,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryText,
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
}
