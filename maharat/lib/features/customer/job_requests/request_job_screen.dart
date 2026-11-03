import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/job_request_model.dart';
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

  // Voice note simulation state
  bool _hasVoiceNote = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;

  // Photo attachments simulation state
  final List<String> _attachedPhotoLabels = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.initialCategory ?? AppConstants.categories.first.nameEn;
    final appState = Provider.of<AppState>(context, listen: false);
    _selectedLocation = appState.currentUser.neighbourhood;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _hasVoiceNote = true;
        _recordingSeconds = 14;
      });
    } else {
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
    }
  }

  void _addPhoto() {
    setState(() {
      _attachedPhotoLabels.add('Photo ${_attachedPhotoLabels.length + 1}');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo attached successfully!')),
    );
  }

  void _submitJobRequest() {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      final newJob = JobRequestModel(
        id: 'job_${DateTime.now().millisecondsSinceEpoch}',
        customerName: appState.currentUser.name,
        customerPhone: appState.currentUser.phone,
        tradeCategory: _selectedCategory,
        description: _descriptionController.text.trim(),
        hasVoiceNote: _hasVoiceNote,
        photoUrls: _attachedPhotoLabels,
        location: _selectedLocation,
        urgency: _selectedUrgency,
        status: 'Active',
        createdAt: DateTime.now(),
        // Notify nearby workers simulation
        interestedWorkers: appState.workers
            .where(
              (w) => w.trade.toLowerCase() == _selectedCategory.toLowerCase(),
            )
            .take(2)
            .toList(),
      );

      appState.addJobRequest(newJob);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RequestSentScreen(request: newJob)),
      );
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

              // 3. Voice Message UI Simulation
              const Text(
                '3. Voice Note (Optional / اختیاری)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleRecording,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? AppColors.statusRed
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _isRecording
                          ? const Text(
                              'Recording audio message... Tap red button to stop.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.statusRed,
                              ),
                            )
                          : _hasVoiceNote
                          ? Row(
                              children: [
                                const Icon(
                                  Icons.graphic_eq_rounded,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Voice Note Recorded (0:${_recordingSeconds.toString().padLeft(2, '0')})',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkGreen,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.secondaryText,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _hasVoiceNote = false;
                                    });
                                  },
                                ),
                              ],
                            )
                          : const Text(
                              'Tap mic icon to record voice explanation in Urdu/English.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Photo Attachments UI Simulation
              const Text(
                '4. Photo Attachments (Optional)',
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
                        itemCount: _attachedPhotoLabels.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.lightMint,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.image_rounded,
                                      color: AppColors.darkGreen,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _attachedPhotoLabels[index],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _attachedPhotoLabels.removeAt(index);
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

              // 5. Location Selection
              const Text(
                '5. Location in Bahawalpur',
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

              // 6. Urgency Options
              const Text(
                '6. When do you need the service?',
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
