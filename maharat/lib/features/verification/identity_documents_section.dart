import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../core/widgets/cnic_upload_card.dart';
import '../../core/widgets/custom_text_field.dart';

/// The CNIC number and the three photos an identity check needs.
class IdentityDocuments {
  final cnicController = TextEditingController();
  Uint8List? front;
  Uint8List? back;
  Uint8List? selfie;

  static final cnicPattern = RegExp(r'^\d{5}-\d{7}-\d$');

  bool get hasAllPhotos => front != null && back != null && selfie != null;
  String get cnicNumber => cnicController.text.trim();

  void dispose() => cnicController.dispose();
}

/// CNIC number, front, back and a live selfie, with guidance that makes the
/// automatic face match succeed first time.
class IdentityDocumentsSection extends StatelessWidget {
  final IdentityDocuments documents;
  final VoidCallback onChanged;

  const IdentityDocumentsSection({
    super.key,
    required this.documents,
    required this.onChanged,
  });

  /// ID photos keep more detail than other photos so the face stays sharp.
  Future<Uint8List?> _pickDocument(BuildContext context) =>
      pickCompressedImage(context, maxDimension: 2000, maxBytes: 1200 * 1024);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.lightMint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.face_retouching_natural,
                    color: AppColors.darkGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr(
                        'Instant verification',
                        'فوری تصدیق',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'The app compares the photo on your CNIC with your selfie. A match of 80% or more verifies you straight away.\n'
                      '• Photograph the CNIC flat, in good light, without glare\n'
                      '• Take the selfie facing the camera, alone, without glasses or a mask',
                  'ایپ آپ کے شناختی کارڈ کی تصویر کا آپ کی سیلفی سے موازنہ کرتی ہے۔ 80 فیصد یا زیادہ مماثلت پر آپ کی فوراً تصدیق ہو جاتی ہے۔\n'
                      '• شناختی کارڈ کو سیدھا رکھ کر اچھی روشنی میں، چمک کے بغیر تصویر لیں\n'
                      '• سیلفی کیمرے کی طرف دیکھتے ہوئے، اکیلے، عینک یا ماسک کے بغیر لیں',
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGreen,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.lock_rounded, size: 16, color: AppColors.secondaryText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.tr(
                  'Your CNIC is used only for verification and is never shown to anyone.',
                  'آپ کا شناختی کارڈ صرف تصدیق کے لیے استعمال ہوتا ہے اور کسی کو نہیں دکھایا جاتا۔',
                ),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: context.tr('CNIC number', 'شناختی کارڈ نمبر'),
          hint: '31202-1234567-1',
          controller: documents.cnicController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.badge_rounded,
          validator: (val) {
            if (val == null || !IdentityDocuments.cnicPattern.hasMatch(val.trim())) {
              return context.tr(
                'Enter your CNIC as 31202-1234567-1',
                'شناختی کارڈ نمبر اس طرح لکھیں: 31202-1234567-1',
              );
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        CnicUploadCard(
          title: context.tr('1. CNIC front', '1. شناختی کارڈ کا سامنے والا رخ'),
          subtitle: context.tr(
            'The side with your photo and CNIC number',
            'وہ رخ جس پر آپ کی تصویر اور نمبر ہے',
          ),
          icon: Icons.badge_outlined,
          photo: documents.front,
          onTap: () async {
            final photo = await _pickDocument(context);
            if (photo != null) {
              documents.front = photo;
              onChanged();
            }
          },
        ),
        CnicUploadCard(
          title: context.tr('2. CNIC back', '2. شناختی کارڈ کا پچھلا رخ'),
          subtitle: context.tr(
            'The side with your address and barcode',
            'وہ رخ جس پر پتہ اور بارکوڈ ہے',
          ),
          icon: Icons.branding_watermark_outlined,
          photo: documents.back,
          onTap: () async {
            final photo = await _pickDocument(context);
            if (photo != null) {
              documents.back = photo;
              onChanged();
            }
          },
        ),
        CnicUploadCard(
          title: context.tr('3. Live selfie', '3. لائیو سیلفی'),
          subtitle: context.tr(
            'Only your face. Do not hold the CNIC in this photo.',
            'صرف آپ کا چہرہ۔ اس تصویر میں شناختی کارڈ نہ پکڑیں۔',
          ),
          icon: Icons.camera_front_rounded,
          actionHint: context.tr(
            'Tap to open the selfie camera',
            'سیلفی کیمرا کھولنے کے لیے ٹیپ کریں',
          ),
          photo: documents.selfie,
          onTap: () async {
            // Camera only: a gallery photo could be anyone's.
            final photo = await pickCompressedImage(
              context,
              maxDimension: 1600,
              maxBytes: 900 * 1024,
              cameraOnly: true,
              frontCamera: true,
            );
            if (photo != null) {
              documents.selfie = photo;
              onChanged();
            }
          },
        ),
      ],
    );
  }
}
