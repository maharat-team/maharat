import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_picker_helper.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/location_widgets.dart';
import '../../../services/contractor_service.dart';
import '../../../state/app_state.dart';
import 'contractor_reg_step2_screen.dart';

/// Shop details for a contractor. Step 2 verifies the owner's identity.
class ContractorRegStep1Screen extends StatefulWidget {
  const ContractorRegStep1Screen({super.key});

  @override
  State<ContractorRegStep1Screen> createState() =>
      _ContractorRegStep1ScreenState();
}

class _ContractorRegStep1ScreenState extends State<ContractorRegStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  late final TextEditingController _phone;
  final _address = TextEditingController();
  final _bio = TextEditingController();
  final Set<String> _trades = {};
  final Set<String> _areas = {};
  LatLng? _location;
  Uint8List? _shopPhoto;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AppState>(context, listen: false).currentUser;
    _phone = TextEditingController(text: PhoneUtils.display(user.phone));
    if (AppConstants.bahawalpurNeighbourhoods.contains(user.neighbourhood)) {
      _areas.add(user.neighbourhood);
    }
  }

  @override
  void dispose() {
    _businessName.dispose();
    _phone.dispose();
    _address.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    if (_trades.isEmpty) {
      _showError(
        context.tr(
          'Select at least one service your shop offers',
          'کم از کم ایک خدمت منتخب کریں جو آپ کی دکان دیتی ہے',
        ),
      );
      return;
    }
    if (_areas.isEmpty) {
      _showError(
        context.tr('Select at least one area you serve', 'کم از کم ایک علاقہ منتخب کریں'),
      );
      return;
    }
    if (_location == null) {
      _showError(
        context.tr(
          'Place your shop on the map so customers can find it',
          'اپنی دکان نقشے پر لگائیں تاکہ گاہک اسے تلاش کر سکیں',
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContractorRegStep2Screen(
          details: ContractorApplication(
            businessName: _businessName.text.trim(),
            phone: PhoneUtils.normalize(_phone.text)!,
            trades: AppConstants.categories
                .map((c) => c.nameEn)
                .where(_trades.contains)
                .toList(),
            bio: _bio.text.trim(),
            serviceAreas: AppConstants.bahawalpurNeighbourhoods
                .where(_areas.contains)
                .toList(),
            shopAddress: _address.text.trim(),
            location: _location,
            cnicNumber: '',
          ),
          shopPhoto: _shopPhoto,
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
    final photo = _shopPhoto;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Shop Registration (1/2)', 'دکان کی رجسٹریشن (1/2)')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Your shop', 'آپ کی دکان'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(
                  'Customers send orders to your shop. You choose which worker from your team to send.',
                  'گاہک آپ کی دکان کو آرڈر بھیجتے ہیں۔ آپ فیصلہ کرتے ہیں کہ ٹیم سے کون سا کاریگر بھیجنا ہے۔',
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: context.tr('Shop / business name', 'دکان / کاروبار کا نام'),
                hint: context.tr('e.g. Al-Madina Electric Works', 'مثلاً المدینہ الیکٹرک ورکس'),
                controller: _businessName,
                prefixIcon: Icons.storefront_rounded,
                validator: (val) => (val?.trim().length ?? 0) < 2
                    ? context.tr('Enter your shop name', 'دکان کا نام درج کریں')
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: context.tr('Shop phone / WhatsApp', 'دکان کا فون / واٹس ایپ'),
                hint: '0300 1234567',
                controller: _phone,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.call_outlined,
                validator: PhoneUtils.validate,
              ),
              const SizedBox(height: 20),
              _label(context.tr('Services you offer', 'آپ کی خدمات')),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in AppConstants.categories)
                    FilterChip(
                      avatar: Icon(c.icon, size: 18, color: c.color),
                      label: Text(context.tradeName(c.nameEn)),
                      selected: _trades.contains(c.nameEn),
                      selectedColor: AppColors.lightMint,
                      checkmarkColor: AppColors.primary,
                      onSelected: (on) => setState(
                        () => on ? _trades.add(c.nameEn) : _trades.remove(c.nameEn),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _label(context.tr('Areas you serve', 'آپ کے علاقے')),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final area in AppConstants.bahawalpurNeighbourhoods)
                    FilterChip(
                      label: Text(context.areaName(area)),
                      selected: _areas.contains(area),
                      selectedColor: AppColors.lightMint,
                      checkmarkColor: AppColors.primary,
                      onSelected: (on) => setState(
                        () => on ? _areas.add(area) : _areas.remove(area),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: context.tr('Shop address', 'دکان کا پتہ'),
                hint: context.tr('Shop no., market, road', 'دکان نمبر، مارکیٹ، سڑک'),
                controller: _address,
                prefixIcon: Icons.signpost_outlined,
                validator: (val) => (val?.trim().isEmpty ?? true)
                    ? context.tr('Enter the shop address', 'دکان کا پتہ درج کریں')
                    : null,
              ),
              const SizedBox(height: 16),
              LocationField(
                label: context.tr('Shop on the map', 'نقشے پر دکان'),
                value: _location,
                askDetails: false,
                required: true,
                onChanged: (picked) => setState(() => _location = picked.point),
              ),
              const SizedBox(height: 20),
              _label(context.tr('Shop photo (optional)', 'دکان کی تصویر (اختیاری)')),
              Material(
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    final picked = await pickCompressedImage(context);
                    if (picked != null && mounted) {
                      setState(() => _shopPhoto = picked);
                    }
                  },
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: photo == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.primary,
                                size: 32,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.tr(
                                  'A photo of your shop front builds trust',
                                  'دکان کے سامنے کی تصویر سے اعتماد بڑھتا ہے',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          )
                        : Image.memory(photo, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: context.tr('About your shop (optional)', 'دکان کا تعارف (اختیاری)'),
                hint: context.tr(
                  'Years in business, team size, specialities...',
                  'کاروبار کے سال، ٹیم کا سائز، خصوصیات...',
                ),
                controller: _bio,
                maxLines: 3,
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: context.tr('Next: Verify identity', 'اگلا: شناخت کی تصدیق'),
                icon: Icons.arrow_forward_rounded,
                onPressed: _next,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
