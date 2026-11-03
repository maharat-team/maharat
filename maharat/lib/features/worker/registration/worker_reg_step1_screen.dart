import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'worker_reg_step2_screen.dart';

class WorkerRegStep1Screen extends StatefulWidget {
  const WorkerRegStep1Screen({super.key});

  @override
  State<WorkerRegStep1Screen> createState() => _WorkerRegStep1ScreenState();
}

class _WorkerRegStep1ScreenState extends State<WorkerRegStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedTrade;
  final TextEditingController _experienceController = TextEditingController(
    text: '6',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '+92 300 1234567',
  );
  final TextEditingController _visitFeeController = TextEditingController(
    text: '300',
  );
  final TextEditingController _bioController = TextEditingController(
    text:
        'Experienced tradesperson offering reliable services across Bahawalpur.',
  );

  final Set<String> _selectedServiceAreas = {
    'Model Town A',
    'Model Town B',
    'Satellite Town',
  };

  @override
  void initState() {
    super.initState();
    _selectedTrade = AppConstants.categories.first.nameEn;
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
    if (_formKey.currentState!.validate()) {
      if (_selectedServiceAreas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select at least one service area in Bahawalpur',
            ),
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkerRegStep2Screen(
            trade: _selectedTrade,
            experienceYears:
                int.tryParse(_experienceController.text.trim()) ?? 1,
            phone: _phoneController.text.trim(),
            visitFee: int.tryParse(_visitFeeController.text.trim()) ?? 0,
            serviceAreas: _selectedServiceAreas.toList(),
            bio: _bioController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tradesperson Registration (1/2)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Step 1: Trade & Service Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Provide details about your profession so customers can find you.',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 24),

              // 1. Select Trade
              const Text(
                '1. Select Primary Trade',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
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
                    label: Text(c.nameEn),
                    selected: isSelected,
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
                      if (val) {
                        setState(() {
                          _selectedTrade = c.nameEn;
                        });
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // 2. Experience Years & Visit Fee Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final experienceField = CustomTextField(
                    label: 'Experience (Years)',
                    hint: '8',
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.work_history_rounded,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      return null;
                    },
                  );
                  final visitFeeField = CustomTextField(
                    label: 'Visit Fee (Rs)',
                    hint: '300 (or 0 for Free)',
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
                    children: [
                      Expanded(child: experienceField),
                      const SizedBox(width: 12),
                      Expanded(child: visitFeeField),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // 3. WhatsApp Number
              CustomTextField(
                label: 'WhatsApp Phone Number',
                hint: '+92 300 1234567',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.chat_bubble_outline_rounded,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // 4. Service Areas in Bahawalpur
              const Text(
                '4. Select Service Areas in Bahawalpur',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.bahawalpurNeighbourhoods.map((area) {
                  final isSelected = _selectedServiceAreas.contains(area);
                  return FilterChip(
                    label: Text(area),
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

              // 5. Short Bio / Experience Summary
              CustomTextField(
                label: '5. Work Bio / Description',
                hint: 'Describe your specialties, past work, and tools used...',
                controller: _bioController,
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              CustomButton(
                text: 'Next: Step 2 CNIC Verification',
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
