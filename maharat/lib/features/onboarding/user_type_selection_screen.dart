import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../models/user_profile_model.dart';
import '../../state/app_state.dart';
import 'email_auth_screen.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  UserRole _selectedRole = UserRole.customer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48.0,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'How will you use Maharat?',
                          'آپ مہارت کیسے استعمال کریں گے؟',
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(
                          'You can switch later from your profile.',
                          'آپ بعد میں پروفائل سے تبدیل کر سکتے ہیں۔',
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildRoleCard(
                        role: UserRole.customer,
                        title: context.tr('I need a worker', 'مجھے کاریگر چاہیے'),
                        description: context.tr(
                          'Find a plumber, electrician, carpenter, AC technician and more near you in Bahawalpur.',
                          'بہاولپور میں اپنے قریب پلمبر، الیکٹریشن، بڑھئی، اے سی ٹیکنیشن وغیرہ تلاش کریں۔',
                        ),
                        icon: Icons.search_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        role: UserRole.worker,
                        title: context.tr('I am a worker', 'میں کاریگر ہوں'),
                        description: context.tr(
                          'Offer your skills to local households. 0% commission, direct calls.',
                          'مقامی گھرانوں کو اپنی خدمات پیش کریں۔ کوئی کمیشن نہیں، براہ راست کالز۔',
                        ),
                        icon: Icons.engineering_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        role: UserRole.contractor,
                        title: context.tr(
                          'I run a shop / I am a contractor',
                          'میری دکان ہے / میں ٹھیکیدار ہوں',
                        ),
                        description: context.tr(
                          'Get your shop verified, receive orders and send workers from your team.',
                          'اپنی دکان کی تصدیق کروائیں، آرڈر وصول کریں اور اپنی ٹیم سے کاریگر بھیجیں۔',
                        ),
                        icon: Icons.storefront_rounded,
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: context.tr('Continue', 'آگے بڑھیں'),
                        onPressed: () {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          appState.setUserRole(_selectedRole);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EmailAuthScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.lightMint : AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? AppColors.primary : AppColors.secondaryText,
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
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.secondaryText,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: AppColors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
