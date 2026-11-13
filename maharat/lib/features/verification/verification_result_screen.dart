import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_messages.dart';
import '../../core/widgets/custom_button.dart';
import '../../models/verification_info.dart';
import '../../models/worker_model.dart';
import '../../state/app_state.dart';
import '../contractor/contractor_main_screen.dart';
import '../contractor/registration/contractor_reg_step2_screen.dart';
import '../worker/dashboard/worker_dashboard_screen.dart';
import '../worker/registration/worker_reg_step2_screen.dart';

/// Why an identity check failed, in the current language.
String verificationReason(BuildContext context, String? code, String? fallback) {
  switch (code) {
    case 'face_mismatch':
      return context.tr(
        'The face on your CNIC does not match your selfie. Retake both photos in good light.',
        'آپ کے شناختی کارڈ کا چہرہ سیلفی سے نہیں ملتا۔ اچھی روشنی میں دونوں تصاویر دوبارہ لیں۔',
      );
    case 'no_face_cnic':
      return context.tr(
        'We could not find the photo on your CNIC. Retake the front so the photo is sharp and free of glare.',
        'شناختی کارڈ پر تصویر نظر نہیں آئی۔ سامنے کا رخ دوبارہ واضح اور چمک کے بغیر لیں۔',
      );
    case 'no_face_selfie':
      return context.tr(
        'We could not see your face in the selfie. Take it facing the camera in good light.',
        'سیلفی میں چہرہ نظر نہیں آیا۔ اچھی روشنی میں کیمرے کی طرف دیکھ کر لیں۔',
      );
    case 'multiple_faces':
      return context.tr(
        'Your selfie must show only your face. Do not hold your CNIC or include other people.',
        'سیلفی میں صرف آپ کا چہرہ ہونا چاہیے۔ شناختی کارڈ نہ پکڑیں اور کوئی اور شخص نہ ہو۔',
      );
  }
  return fallback ??
      context.tr(
        'Please check your photos and submit again.',
        'براہ کرم اپنی تصاویر چیک کر کے دوبارہ جمع کریں۔',
      );
}

/// Runs the automatic face check right after a worker or contractor submits
/// their documents, and shows the result.
class VerificationResultScreen extends StatefulWidget {
  final bool contractor;

  const VerificationResultScreen({super.key, required this.contractor});

  @override
  State<VerificationResultScreen> createState() =>
      _VerificationResultScreenState();
}

class _VerificationResultScreenState extends State<VerificationResultScreen> {
  FaceCheckResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run(reset: false);
  }

  Future<void> _run({bool reset = true}) async {
    if (reset) {
      setState(() {
        _result = null;
        _error = null;
      });
    }
    try {
      final result = await Provider.of<AppState>(
        context,
        listen: false,
      ).runFaceCheck(contractor: widget.contractor);
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => widget.contractor
            ? const ContractorMainScreen()
            : const WorkerDashboardScreen(),
      ),
      (route) => false,
    );
  }

  void _retake() {
    final appState = Provider.of<AppState>(context, listen: false);
    final Widget screen;
    if (widget.contractor) {
      screen = ContractorRegStep2Screen.retry(appState.contractorProfile!);
    } else {
      screen = WorkerRegStep2Screen.retry(appState.workerProfile);
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final info = widget.contractor
        ? appState.contractorVerification
        : appState.workerVerification;
    final result = _result;

    return PopScope(
      canPop: result != null || _error != null,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(context.tr('Identity check', 'شناخت کی تصدیق')),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _error != null
                    ? _buildMessage(
                        icon: Icons.wifi_off_rounded,
                        color: AppColors.statusOrange,
                        title: context.tr(
                          'Could not check right now',
                          'ابھی تصدیق نہیں ہو سکی',
                        ),
                        body: _error!,
                        actions: [
                          CustomButton(
                            text: context.tr('Try again', 'دوبارہ کوشش کریں'),
                            onPressed: _run,
                          ),
                          const SizedBox(height: 10),
                          CustomButton(
                            text: context.tr('Later', 'بعد میں'),
                            type: ButtonType.outline,
                            onPressed: _goHome,
                          ),
                        ],
                      )
                    : result == null
                    ? _buildChecking()
                    : _buildResult(result, info),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecking() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(strokeWidth: 5),
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('Checking your photos...', 'آپ کی تصاویر چیک ہو رہی ہیں...'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(
            'We are comparing the photo on your CNIC with your selfie. This takes a few seconds.',
            'ہم آپ کے شناختی کارڈ کی تصویر کا سیلفی سے موازنہ کر رہے ہیں۔ چند سیکنڈ لگیں گے۔',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.secondaryText, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildResult(FaceCheckResult result, VerificationInfo? info) {
    final score = result.score ?? info?.score;
    final scoreText = score == null || score <= 0
        ? null
        : context.tr(
            'Face match: ${score.round()}%',
            'چہرے کی مماثلت: ${score.round()}%',
          );

    switch (result.status) {
      case VerificationStatus.approved:
        return _buildMessage(
          icon: Icons.verified_rounded,
          color: AppColors.primary,
          title: context.tr('You are verified!', 'آپ کی تصدیق ہو گئی!'),
          body: widget.contractor
              ? context.tr(
                  'Your shop is now visible to customers. Invite your workers to your team to start taking orders.',
                  'آپ کی دکان اب گاہکوں کو نظر آ رہی ہے۔ آرڈر لینے کے لیے اپنے کاریگروں کو ٹیم میں شامل کریں۔',
                )
              : context.tr(
                  'Your profile is now visible to customers and you can see jobs near you.',
                  'آپ کی پروفائل اب گاہکوں کو نظر آ رہی ہے اور آپ اپنے قریب کے کام دیکھ سکتے ہیں۔',
                ),
          badge: scoreText,
          actions: [
            CustomButton(
              text: context.tr('Continue', 'آگے بڑھیں'),
              onPressed: _goHome,
            ),
          ],
        );
      case VerificationStatus.rejected:
        return _buildMessage(
          icon: Icons.gpp_bad_rounded,
          color: AppColors.statusRed,
          title: context.tr('Not verified', 'تصدیق نہیں ہوئی'),
          body: verificationReason(context, result.code ?? info?.code, info?.reason),
          badge: scoreText,
          actions: [
            CustomButton(
              text: context.tr('Retake photos', 'تصاویر دوبارہ لیں'),
              icon: Icons.camera_alt_rounded,
              onPressed: _retake,
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: context.tr('Later', 'بعد میں'),
              type: ButtonType.outline,
              onPressed: _goHome,
            ),
          ],
        );
      case VerificationStatus.pending:
        final manual = result.code == 'not_configured';
        return _buildMessage(
          icon: manual ? Icons.hourglass_top_rounded : Icons.wifi_off_rounded,
          color: AppColors.statusOrange,
          title: manual
              ? context.tr('Submitted for review', 'جائزے کے لیے جمع ہو گیا')
              : context.tr('Could not check right now', 'ابھی تصدیق نہیں ہو سکی'),
          body: manual
              ? context.tr(
                  'Your documents are saved. Our team will review them shortly.',
                  'آپ کی دستاویزات محفوظ ہیں۔ ہماری ٹیم جلد ان کا جائزہ لے گی۔',
                )
              : context.tr(
                  'Your documents are saved. Try the check again in a moment.',
                  'آپ کی دستاویزات محفوظ ہیں۔ تھوڑی دیر بعد دوبارہ کوشش کریں۔',
                ),
          actions: [
            if (!manual) ...[
              CustomButton(
                text: context.tr('Try again', 'دوبارہ کوشش کریں'),
                onPressed: _run,
              ),
              const SizedBox(height: 10),
            ],
            CustomButton(
              text: context.tr('Continue', 'آگے بڑھیں'),
              type: manual ? ButtonType.primary : ButtonType.outline,
              onPressed: _goHome,
            ),
          ],
        );
    }
  }

  Widget _buildMessage({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    String? badge,
    required List<Widget> actions,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: color),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        if (badge != null) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.secondaryText, height: 1.5),
        ),
        const SizedBox(height: 28),
        ...actions,
      ],
    );
  }
}
