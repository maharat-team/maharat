import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/worker_model.dart';
import '../../../services/worker_service.dart';
import '../../../state/app_state.dart';
import '../../verification/identity_documents_section.dart';
import '../../verification/verification_result_screen.dart';

class WorkerRegStep2Screen extends StatefulWidget {
  final String trade;
  final int experienceYears;
  final String phone;
  final int visitFee;
  final List<String> serviceAreas;
  final String bio;
  final LatLng? baseLocation;

  const WorkerRegStep2Screen({
    super.key,
    required this.trade,
    required this.experienceYears,
    required this.phone,
    required this.visitFee,
    required this.serviceAreas,
    required this.bio,
    this.baseLocation,
  });

  /// Retaking the photos after a failed check keeps the saved profile.
  WorkerRegStep2Screen.retry(WorkerModel worker, {super.key})
    : trade = worker.trade,
      experienceYears = worker.experienceYears,
      phone = worker.phone,
      visitFee = worker.visitFee,
      serviceAreas = worker.serviceAreas,
      bio = worker.bio,
      baseLocation = worker.baseLocation;

  @override
  State<WorkerRegStep2Screen> createState() => _WorkerRegStep2ScreenState();
}

class _WorkerRegStep2ScreenState extends State<WorkerRegStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _documents = IdentityDocuments();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _documents.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_documents.hasAllPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Please add all 3 photos: CNIC front, back and selfie',
              'براہ کرم تینوں تصاویر لگائیں: شناختی کارڈ کا سامنا، پچھلا رخ اور سیلفی',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
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
          cnicNumber: _documents.cnicNumber,
          baseLocation: widget.baseLocation,
        ),
        front: _documents.front!,
        back: _documents.back!,
        selfie: _documents.selfie!,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const VerificationResultScreen(contractor: false),
        ),
        (route) => false,
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
      appBar: AppBar(
        title: Text(context.tr('Identity Check (2/2)', 'شناخت کی تصدیق (2/2)')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
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
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Verify your identity', 'اپنی شناخت کی تصدیق کریں'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(
                  'Verified workers get the badge and appear to customers.',
                  'تصدیق شدہ کاریگروں کو بیج ملتا ہے اور وہ گاہکوں کو نظر آتے ہیں۔',
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 20),
              IdentityDocumentsSection(
                documents: _documents,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: context.tr('Submit & Verify', 'جمع کریں اور تصدیق کریں'),
                icon: Icons.verified_user_rounded,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
