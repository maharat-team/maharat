import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/location_widgets.dart';
import '../../routes/session_router.dart';
import '../../state/app_state.dart';

/// Shown once after first sign-in to collect what the app needs to operate.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _neighbourhood;
  LatLng? _location;
  String _addressDetails = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AppState>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone);
    _neighbourhood =
        AppConstants.bahawalpurNeighbourhoods.contains(user.neighbourhood)
        ? user.neighbourhood
        : null;
    _location = user.location;
    _addressDetails = user.addressDetails;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_neighbourhood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Please select your neighbourhood',
              'براہ کرم اپنا علاقہ منتخب کریں',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.updateProfile(
        name: _nameController.text,
        phone: _phoneController.text,
        neighbourhood: _neighbourhood,
      );
      final location = _location;
      if (location != null) {
        await appState.updateMyLocation(location, _addressDetails);
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destinationFor(appState)),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Complete Your Profile', 'اپنی پروفائل مکمل کریں'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    'Workers and customers see your name on jobs and reviews.',
                    'کاریگر اور گاہک آپ کا نام کاموں اور ریویوز پر دیکھتے ہیں۔',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: context.tr('Full Name', 'پورا نام'),
                  hint: context.tr('Your name', 'آپ کا نام'),
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? context.tr('Please enter your name', 'براہ کرم اپنا نام درج کریں')
                      : null,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: context.tr('Mobile Number', 'موبائل نمبر'),
                  hint: '0300 1234567',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_rounded,
                  validator: PhoneUtils.validate,
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr(
                    'Neighbourhood in Bahawalpur',
                    'بہاولپور میں آپ کا علاقہ',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _neighbourhood,
                      hint: Text(context.tr('Select', 'منتخب کریں')),
                      isExpanded: true,
                      items: AppConstants.bahawalpurNeighbourhoods
                          .map(
                            (area) => DropdownMenuItem<String>(
                              value: area,
                              child: Text(context.areaName(area)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _neighbourhood = val),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                LocationField(
                  label: context.tr(
                    'Home location on map (optional)',
                    'نقشے پر گھر کا مقام (اختیاری)',
                  ),
                  value: _location,
                  addressDetails: _addressDetails,
                  onChanged: (picked) => setState(() {
                    _location = picked.point;
                    _addressDetails = picked.addressDetails;
                  }),
                ),
                const SizedBox(height: 40),
                CustomButton(
                  text: context.tr('Continue', 'آگے بڑھیں'),
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
