import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/location_widgets.dart';
import '../../../state/app_state.dart';

/// Lets a registered worker update what customers see, without redoing the
/// identity check. The trade is fixed because it was verified with them.
class EditWorkerProfileScreen extends StatefulWidget {
  const EditWorkerProfileScreen({super.key});

  @override
  State<EditWorkerProfileScreen> createState() =>
      _EditWorkerProfileScreenState();
}

class _EditWorkerProfileScreenState extends State<EditWorkerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  late final TextEditingController _bio;
  late final TextEditingController _experience;
  late final TextEditingController _visitFee;
  late final Set<String> _areas;
  LatLng? _base;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final worker = Provider.of<AppState>(context, listen: false).workerProfile;
    _phone = TextEditingController(text: PhoneUtils.display(worker.phone));
    _bio = TextEditingController(text: worker.bio);
    _experience = TextEditingController(text: '${worker.experienceYears}');
    _visitFee = TextEditingController(text: '${worker.visitFee}');
    _areas = worker.serviceAreas.toSet();
    _base = worker.baseLocation;
  }

  @override
  void dispose() {
    _phone.dispose();
    _bio.dispose();
    _experience.dispose();
    _visitFee.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saved = context.tr('Profile updated.', 'پروفائل اپ ڈیٹ ہو گئی۔');
    try {
      await Provider.of<AppState>(context, listen: false).updateWorkerProfile(
        phone: _phone.text,
        bio: _bio.text,
        experienceYears: int.tryParse(_experience.text.trim()) ?? 0,
        visitFee: int.tryParse(_visitFee.text.trim()) ?? 0,
        serviceAreas: AppConstants.bahawalpurNeighbourhoods
            .where(_areas.contains)
            .toList(),
        baseLocation: _base,
      );
      messenger.showSnackBar(SnackBar(content: Text(saved)));
      navigator.pop();
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('Edit profile', 'پروفائل میں ترمیم'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: context.tr('WhatsApp number', 'واٹس ایپ نمبر'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.chat_bubble_outline_rounded,
                validator: PhoneUtils.validate,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: context.tr('Experience (years)', 'تجربہ (سال)'),
                      controller: _experience,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final years = int.tryParse(val?.trim() ?? '');
                        return years == null || years < 0 || years > 70
                            ? context.tr('0 to 70', '0 سے 70')
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: context.tr('Visit fee (Rs)', 'وزٹ فیس (روپے)'),
                      controller: _visitFee,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final fee = int.tryParse(val?.trim() ?? '');
                        return fee == null || fee < 0
                            ? context.tr('Enter a number', 'نمبر درج کریں')
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: context.tr('About your work', 'اپنے کام کے بارے میں'),
                controller: _bio,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Areas you serve', 'آپ کے علاقے'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 16),
              LocationField(
                label: context.tr('Where you start from', 'آپ کہاں سے آتے ہیں'),
                value: _base,
                askDetails: false,
                onChanged: (picked) => setState(() => _base = picked.point),
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: context.tr('Save changes', 'تبدیلیاں محفوظ کریں'),
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
