import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/contractor_model.dart';
import '../../../services/contractor_service.dart';
import '../../../state/app_state.dart';
import '../../verification/identity_documents_section.dart';
import '../../verification/verification_result_screen.dart';

/// The shop owner's identity check: CNIC and a live selfie.
class ContractorRegStep2Screen extends StatefulWidget {
  final ContractorApplication details;
  final Uint8List? shopPhoto;

  const ContractorRegStep2Screen({
    super.key,
    required this.details,
    this.shopPhoto,
  });

  /// Retaking the photos after a failed check keeps the saved shop details.
  ContractorRegStep2Screen.retry(ContractorModel shop, {super.key})
    : shopPhoto = null,
      details = ContractorApplication(
        businessName: shop.businessName,
        phone: shop.phone,
        trades: shop.trades,
        bio: shop.bio,
        serviceAreas: shop.serviceAreas,
        shopAddress: shop.shopAddress,
        location: shop.location,
        cnicNumber: '',
      );

  @override
  State<ContractorRegStep2Screen> createState() =>
      _ContractorRegStep2ScreenState();
}

class _ContractorRegStep2ScreenState extends State<ContractorRegStep2Screen> {
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
      await appState.registerContractor(
        widget.details.withCnic(_documents.cnicNumber),
        shopPhoto: widget.shopPhoto,
        front: _documents.front!,
        back: _documents.back!,
        selfie: _documents.selfie!,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const VerificationResultScreen(contractor: true),
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
        title: Text(context.tr('Owner Verification (2/2)', 'مالک کی تصدیق (2/2)')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Verify the shop owner', 'دکان کے مالک کی تصدیق'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(
                  'Verified shops get the badge and appear to customers.',
                  'تصدیق شدہ دکانوں کو بیج ملتا ہے اور وہ گاہکوں کو نظر آتی ہیں۔',
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
