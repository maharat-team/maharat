import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/image_picker_helper.dart';
import '../../../core/widgets/cnic_upload_card.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../services/worker_service.dart';
import '../../../state/app_state.dart';
import '../dashboard/worker_dashboard_screen.dart';

class WorkerRegStep2Screen extends StatefulWidget {
  final String trade;
  final int experienceYears;
  final String phone;
  final int visitFee;
  final List<String> serviceAreas;
  final String bio;

  const WorkerRegStep2Screen({
    super.key,
    required this.trade,
    required this.experienceYears,
    required this.phone,
    required this.visitFee,
    required this.serviceAreas,
    required this.bio,
  });

  @override
  State<WorkerRegStep2Screen> createState() => _WorkerRegStep2ScreenState();
}

class _WorkerRegStep2ScreenState extends State<WorkerRegStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  static final _cnicPattern = RegExp(r'^\d{5}-\d{7}-\d$');

  final TextEditingController _cnicController = TextEditingController();

  Uint8List? _front;
  Uint8List? _back;
  Uint8List? _selfie;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  /// ID documents keep more detail than other photos so they stay legible.
  Future<Uint8List?> _pickDocument() =>
      pickCompressedImage(context, maxDimension: 2000, maxBytes: 1200 * 1024);

  Future<void> _submitForVerification() async {
    if (!_formKey.currentState!.validate()) return;

    final front = _front;
    final back = _back;
    final selfie = _selfie;
    if (front == null || back == null || selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload all 3 verification photos (Front, Back, Selfie)',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.registerWorker(
        WorkerApplication(
          trade: widget.trade,
          phone: widget.phone,
          bio: widget.bio,
          experienceYears: widget.experienceYears,
          visitFee: widget.visitFee,
          serviceAreas: widget.serviceAreas,
          cnicNumber: _cnicController.text.trim(),
        ),
        front: front,
        back: back,
        selfie: selfie,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submitted! We will review your CNIC shortly.'),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WorkerDashboardScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('CNIC Verification (2/2)')),
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
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Step 2: CNIC Verification',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload your CNIC & selfie to get the Verified Badge in Bahawalpur.',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 20),

              // Strict Privacy Notice Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightMint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: AppColors.darkGreen,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Privacy Notice: Your CNIC information is strictly used for internal safety verification and is NEVER made public to customers.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGreen,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // CNIC Input
              CustomTextField(
                label: 'CNIC Number',
                hint: '31202-1234567-1',
                controller: _cnicController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.badge_rounded,
                validator: (val) {
                  if (val == null || !_cnicPattern.hasMatch(val.trim())) {
                    return 'Enter your CNIC as 31202-1234567-1';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // CNIC Front Photo
              CnicUploadCard(
                title: '1. CNIC Front Photo',
                subtitle: 'Front side showing CNIC number & clear photo',
                icon: Icons.badge_outlined,
                isUploaded: _front != null,
                onTap: () async {
                  final photo = await _pickDocument();
                  if (photo != null && mounted) {
                    setState(() => _front = photo);
                  }
                },
              ),

              // CNIC Back Photo
              CnicUploadCard(
                title: '2. CNIC Back Photo',
                subtitle: 'Back side showing address and barcode',
                icon: Icons.branding_watermark_outlined,
                isUploaded: _back != null,
                onTap: () async {
                  final photo = await _pickDocument();
                  if (photo != null && mounted) {
                    setState(() => _back = photo);
                  }
                },
              ),

              // Selfie with CNIC Photo
              CnicUploadCard(
                title: '3. Selfie with CNIC',
                subtitle: 'Clear portrait photo holding your CNIC card',
                icon: Icons.camera_front_rounded,
                isUploaded: _selfie != null,
                onTap: () async {
                  final photo = await _pickDocument();
                  if (photo != null && mounted) {
                    setState(() => _selfie = photo);
                  }
                },
              ),

              const SizedBox(height: 20),

              CustomButton(
                text: 'Submit for Verification',
                icon: Icons.verified_user_rounded,
                isLoading: _isSubmitting,
                onPressed: _submitForVerification,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
