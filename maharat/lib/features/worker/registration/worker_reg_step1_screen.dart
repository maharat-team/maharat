import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/location_widgets.dart';
import '../../../state/app_state.dart';
import 'worker_reg_step2_screen.dart';

class WorkerRegStep1Screen extends StatefulWidget {
  const WorkerRegStep1Screen({super.key});

  @override
  State<WorkerRegStep1Screen> createState() => _WorkerRegStep1ScreenState();
}

class _WorkerRegStep1ScreenState extends State<WorkerRegStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedTrade;
  final TextEditingController _experienceController = TextEditingController();
  late final TextEditingController _phoneController;
  final TextEditingController _visitFeeController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final Set<String> _selectedServiceAreas = {};
  LatLng? _baseLocation;

  @override
  void initState() {
    super.initState();
    _selectedTrade = AppConstants.categories.first.nameEn;
    final user = Provider.of<AppState>(context, listen: false).currentUser;
    _phoneController = TextEditingController(
      text: PhoneUtils.display(user.phone),
    );
    if (AppConstants.bahawalpurNeighbourhoods.contains(user.neighbourhood)) {
      _selectedServiceAreas.add(user.neighbourhood);
    }
    _baseLocation = user.location;
  }

  @override
  void dispose() {
    _experienceController.dispose();
    _phoneController.dispose();
    _visitFeeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Please select at least one service area',
              'کم از کم ایک علاقہ منتخب کریں',
            ),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkerRegStep2Screen(
          trade: _selectedTrade,
          experienceYears: int.tryParse(_experienceController.text.trim()) ?? 1,
          phone: PhoneUtils.normalize(_phoneController.text)!,
          visitFee: int.tryParse(_visitFeeController.text.trim()) ?? 0,
          serviceAreas: _selectedServiceAreas.toList(),
          bio: _bioController.text.trim(),
          baseLocation: _baseLocation,
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryText,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Worker Registration (1/2)', 'کاریگر رجسٹریشن (1/2)')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Progress(step: 1),
              const SizedBox(height: 16),
              Text(
                context.tr('Your trade and services', 'آپ کا کام اور خدمات'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(
                  'Tell customers what you do so they can find you.',
                  'گاہکوں کو بتائیں آپ کیا کام کرتے ہیں تاکہ وہ آپ کو تلاش کر سکیں۔',
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 24),
              _label(context.tr('1. Main trade', '1. بنیادی کام')),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.categories.map((c) {
                  final isSelected = _selectedTrade == c.nameEn;
                  return ChoiceChip(
                    avatar: Icon(
                      c.icon,
                      size: 18,
                      color: isSelected ? AppColors.white : c.color,
                    ),
                    label: Text(context.tradeName(c.nameEn)),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.primaryText,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedTrade = c.nameEn);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final experienceField = CustomTextField(
                    label: context.tr('Experience (years)', 'تجربہ (سال)'),
                    hint: '8',
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.work_history_rounded,
                    validator: (val) {
                      final years = int.tryParse(val?.trim() ?? '');
                      if (years == null || years < 0 || years > 70) {
                        return context.tr('Required', 'ضروری ہے');
                      }
                      return null;
                    },
                  );
                  final visitFeeField = CustomTextField(
                    label: context.tr('Visit fee (Rs)', 'وزٹ فیس (روپے)'),
                    hint: context.tr('300 (0 = free)', '300 (0 = مفت)'),
                    controller: _visitFeeController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.payments_rounded,
                  );
                  if (constraints.maxWidth < 380) {
                    return Column(
                      children: [
                        experienceField,
                        const SizedBox(height: 16),
                        visitFeeField,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: experienceField),
                      const SizedBox(width: 12),
                      Expanded(child: visitFeeField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: context.tr('WhatsApp number', 'واٹس ایپ نمبر'),
                hint: '0300 1234567',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.chat_bubble_outline_rounded,
                validator: PhoneUtils.validate,
              ),
              const SizedBox(height: 20),
              _label(
                context.tr(
                  '4. Areas you serve in Bahawalpur',
                  '4. بہاولپور میں آپ کے علاقے',
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.bahawalpurNeighbourhoods.map((area) {
                  final isSelected = _selectedServiceAreas.contains(area);
                  return FilterChip(
                    label: Text(context.areaName(area)),
                    selected: isSelected,
                    selectedColor: AppColors.lightMint,
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.darkGreen
                          : AppColors.primaryText,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedServiceAreas.add(area);
                        } else {
                          _selectedServiceAreas.remove(area);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              LocationField(
                label: context.tr(
                  '5. Where you start from (optional)',
                  '5. آپ کہاں سے آتے ہیں (اختیاری)',
                ),
                value: _baseLocation,
                askDetails: false,
                onChanged: (picked) =>
                    setState(() => _baseLocation = picked.point),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'Customers only see an approximate area (about 1 km), used to show how far you are.',
                  'گاہک صرف تقریبی علاقہ (تقریباً 1 کلومیٹر) دیکھتے ہیں تاکہ فاصلہ معلوم ہو سکے۔',
                ),
                style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: context.tr('6. About your work', '6. اپنے کام کے بارے میں'),
                hint: context.tr(
                  'Your specialities, past work, tools...',
                  'آپ کی مہارت، پچھلا کام، اوزار...',
                ),
                controller: _bioController,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: context.tr('Next: Verify identity', 'اگلا: شناخت کی تصدیق'),
                icon: Icons.arrow_forward_rounded,
                onPressed: _goToStep2,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-step progress bar shared by the registration screens.
class _Progress extends StatelessWidget {
  final int step;

  const _Progress({required this.step});

  @override
  Widget build(BuildContext context) {
    Widget bar(bool done) => Expanded(
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: done ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
    return Row(
      children: [bar(true), const SizedBox(width: 8), bar(step >= 2)],
    );
  }
}

