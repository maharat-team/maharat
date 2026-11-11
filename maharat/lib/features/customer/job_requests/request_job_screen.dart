import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/image_picker_helper.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/location_widgets.dart';
import '../../../models/contractor_model.dart';
import '../../../state/app_state.dart';
import 'request_sent_screen.dart';

/// Posts a job to all matching workers, or as an order to one [contractor].
class RequestJobScreen extends StatefulWidget {
  final String? initialCategory;
  final ContractorModel? contractor;

  const RequestJobScreen({super.key, this.initialCategory, this.contractor});

  @override
  State<RequestJobScreen> createState() => _RequestJobScreenState();
}

class _RequestJobScreenState extends State<RequestJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();
  late String _selectedLocation;
  String _selectedUrgency = 'Today';
  LatLng? _point;
  String _addressDetails = '';

  static const _maxPhotos = 6;

  final List<Uint8List> _photos = [];
  bool _isSubmitting = false;

  List<String> get _trades {
    final shop = widget.contractor;
    if (shop == null) return AppConstants.categories.map((c) => c.nameEn).toList();
    return shop.trades;
  }

  @override
  void initState() {
    super.initState();
    final trades = _trades;
    final wanted = widget.initialCategory;
    _selectedCategory = wanted != null && trades.contains(wanted)
        ? wanted
        : trades.first;
    final user = Provider.of<AppState>(context, listen: false).currentUser;
    _selectedLocation =
        AppConstants.bahawalpurNeighbourhoods.contains(user.neighbourhood)
        ? user.neighbourhood
        : AppConstants.bahawalpurNeighbourhoods.first;
    _point = user.location;
    _addressDetails = user.addressDetails;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'You can attach up to 6 photos.',
              'آپ زیادہ سے زیادہ 6 تصاویر لگا سکتے ہیں۔',
            ),
          ),
        ),
      );
      return;
    }
    final photo = await pickCompressedImage(context);
    if (photo != null && mounted) setState(() => _photos.add(photo));
  }

  Future<void> _submitJobRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final job = await appState.createJobRequest(
        trade: _selectedCategory,
        description: _descriptionController.text.trim(),
        location: _selectedLocation,
        urgency: _selectedUrgency,
        photos: _photos,
        contractorId: widget.contractor?.id,
        point: _point,
        addressDetails: _addressDetails,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RequestSentScreen(request: job)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryText,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final shop = widget.contractor;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          shop == null
              ? context.tr('Request a Job', 'کام کی درخواست')
              : context.tr('Order from shop', 'دکان کو آرڈر'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shop != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.darkGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr(
                            'This order goes only to ${shop.businessName}. They will accept it and send a worker from their team.',
                            'یہ آرڈر صرف ${shop.businessName} کو جائے گا۔ وہ قبول کر کے اپنی ٹیم سے کاریگر بھیجیں گے۔',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkGreen,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _label(context.tr('1. What work is needed?', '1. کون سا کام چاہیے؟')),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _trades.map((trade) {
                  final info = AppConstants.categories.firstWhere(
                    (c) => c.nameEn == trade,
                    orElse: () => AppConstants.categories.first,
                  );
                  final isSelected = _selectedCategory == trade;
                  return ChoiceChip(
                    avatar: Icon(
                      info.icon,
                      size: 18,
                      color: isSelected ? AppColors.white : info.color,
                    ),
                    label: Text(context.tradeName(trade)),
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
                      if (val) setState(() => _selectedCategory = trade);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: context.tr('2. Describe the problem', '2. مسئلہ بیان کریں'),
                hint: context.tr(
                  'e.g. Switchboard sparking, UPS not charging, kitchen tap leaking...',
                  'مثلاً سوئچ بورڈ سے چنگاری، یو پی ایس چارج نہیں ہو رہا، کچن کا نلکا لیک...',
                ),
                controller: _descriptionController,
                maxLines: 4,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.tr(
                      'Please describe the work needed',
                      'براہ کرم کام کی تفصیل لکھیں',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _label(
                context.tr(
                  '3. Photos (optional)',
                  '3. تصاویر (اختیاری)',
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _addPhoto,
                    child: Container(
                      width: 90,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('Add Photo', 'تصویر لگائیں'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                margin: const EdgeInsetsDirectional.only(end: 8),
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: AppColors.lightMint,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Image.memory(
                                  _photos[index],
                                  fit: BoxFit.cover,
                                  height: 80,
                                ),
                              ),
                              PositionedDirectional(
                                top: 2,
                                end: 10,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _photos.removeAt(index)),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: AppColors.statusRed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _label(context.tr('4. Area in Bahawalpur', '4. بہاولپور میں علاقہ')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLocation,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.secondaryText,
                    ),
                    items: AppConstants.bahawalpurNeighbourhoods.map((area) {
                      return DropdownMenuItem<String>(
                        value: area,
                        child: Text(context.areaName(area)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLocation = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LocationField(
                label: context.tr(
                  'Exact location on map',
                  'نقشے پر درست مقام',
                ),
                value: _point,
                addressDetails: _addressDetails,
                onChanged: (picked) => setState(() {
                  _point = picked.point;
                  _addressDetails = picked.addressDetails;
                }),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'Only workers who respond (or the shop you order from) see the exact pin. Others see the area only.',
                  'درست پن صرف جواب دینے والے کاریگر (یا جس دکان کو آرڈر دیا) دیکھ سکتے ہیں۔ باقی صرف علاقہ دیکھتے ہیں۔',
                ),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              _label(context.tr('5. When do you need it?', '5. کب چاہیے؟')),
              Row(
                children: ['Today', 'Tomorrow', 'Any Day'].map((urgency) {
                  final isSelected = _selectedUrgency == urgency;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Center(child: Text(context.urgencyName(urgency))),
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
                        onSelected: (val) {
                          if (val) setState(() => _selectedUrgency = urgency);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),
              CustomButton(
                text: shop == null
                    ? context.tr('Send to Workers', 'کاریگروں کو بھیجیں')
                    : context.tr('Send Order', 'آرڈر بھیجیں'),
                icon: Icons.send_rounded,
                isLoading: _isSubmitting,
                onPressed: _submitJobRequest,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
