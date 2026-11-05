import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/image_picker_helper.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../state/app_state.dart';
import 'request_sent_screen.dart';

class RequestJobScreen extends StatefulWidget {
  final String? initialCategory;

  const RequestJobScreen({super.key, this.initialCategory});

  @override
  State<RequestJobScreen> createState() => _RequestJobScreenState();
}

class _RequestJobScreenState extends State<RequestJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();
  late String _selectedLocation;
  String _selectedUrgency = 'Today'; // Today, Tomorrow, Any Day

  static const _maxPhotos = 6;

  final List<Uint8List> _photos = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.initialCategory ?? AppConstants.categories.first.nameEn;
    final appState = Provider.of<AppState>(context, listen: false);
    final home = appState.currentUser.neighbourhood;
    _selectedLocation = AppConstants.bahawalpurNeighbourhoods.contains(home)
        ? home
        : AppConstants.bahawalpurNeighbourhoods.first;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can attach up to 6 photos.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Request a Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Category Selection
              const Text(
                '1. Select Required Tradesperson',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.categories.map((c) {
                  final isSelected = _selectedCategory == c.nameEn;
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
                          _selectedCategory = c.nameEn;
                        });
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // 2. Describe Problem
              CustomTextField(
                label: '2. Describe the Problem',
                hint:
                    'e.g. Living room switchboard sparking, UPS battery not charging, or kitchen tap leak...',
                controller: _descriptionController,
                maxLines: 4,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a description of the work needed';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // 3. Photo Attachments
              const Text(
                '3. Photo Attachments (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
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
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add Photo',
                            style: TextStyle(
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
                                margin: const EdgeInsets.only(right: 8),
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
                              Positioned(
                                top: 2,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _photos.removeAt(index);
                                    });
                                  },
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

              // 4. Location Selection
              const Text(
                '4. Location in Bahawalpur',
                style: TextStyle(
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
                    value: _selectedLocation,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.secondaryText,
                    ),
                    items: AppConstants.bahawalpurNeighbourhoods.map((area) {
                      return DropdownMenuItem<String>(
                        value: area,
                        child: Text(area),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedLocation = val;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Urgency Options
              const Text(
                '5. When do you need the service?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: ['Today', 'Tomorrow', 'Any Day'].map((urgency) {
                  final isSelected = _selectedUrgency == urgency;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Center(child: Text(urgency)),
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
                          if (val) {
                            setState(() {
                              _selectedUrgency = urgency;
                            });
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 36),

              CustomButton(
                text: 'Send Job Request to Workers',
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
