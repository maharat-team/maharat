import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_messages.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../routes/session_router.dart';
import '../../state/app_state.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  static const _codeLength = 6;
  // Supabase allows one code per address every 60 seconds.
  static const _resendSeconds = 60;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );

  bool _isOtpSent = false;
  bool _isLoading = false;
  int _timerSeconds = _resendSeconds;
  Timer? _timer;

  String get _email => _emailController.text.trim().toLowerCase();

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startResendTimer() {
    _timerSeconds = _resendSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    if (!_emailPattern.hasMatch(_email)) {
      _showMessage(
        context.tr(
          'Please enter a valid email address',
          'براہ کرم درست ای میل ایڈریس درج کریں',
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<AppState>(context, listen: false).sendEmailOtp(_email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });
      _clearCode();
      _startResendTimer();
      if (isResend) {
        _showMessage(
          context.tr('A new code is on its way.', 'نیا کوڈ بھیج دیا گیا ہے۔'),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showMessage(friendlyError(error));
    }
  }

  void _clearCode() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < _codeLength) {
      _showMessage(
        context.tr(
          'Please enter all $_codeLength digits of the code',
          'براہ کرم کوڈ کے تمام $_codeLength ہندسے درج کریں',
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.verifyEmailOtp(_email, otp);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destinationFor(appState)),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _clearCode();
      _otpFocusNodes.first.requestFocus();
      _showMessage(friendlyError(error));
    }
  }

  /// Handles typing and pasting. A value longer than one digit is spread across
  /// the following boxes, so a code copied from an email lands in one action.
  void _onCodeChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.split('');
      var position = index;
      for (final digit in digits) {
        if (position >= _codeLength) break;
        _otpControllers[position].text = digit;
        position++;
      }
      final next = position >= _codeLength ? _codeLength - 1 : position;
      _otpFocusNodes[next].requestFocus();
      return;
    }
    if (value.isNotEmpty && index < _codeLength - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_isOtpSent) {
              setState(() {
                _isOtpSent = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _isOtpSent ? _buildOtpView() : _buildEmailView(),
        ),
      ),
    );
  }

  Widget _buildEmailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Enter Your Email', 'اپنا ای میل درج کریں'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(
            'We will send a 6-digit verification code to your email.',
            'ہم آپ کے ای میل پر 6 ہندسوں کا تصدیقی کوڈ بھیجیں گے۔',
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          label: context.tr('Email Address', 'ای میل ایڈریس'),
          hint: 'you@example.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightMint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withAlpha(40)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr(
                    'Your email is only used to sign you in. Maharat is 100% free with no spam.',
                    'آپ کا ای میل صرف سائن ان کے لیے استعمال ہوتا ہے۔ مہارت مکمل مفت ہے، کوئی اسپام نہیں۔',
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
        const SizedBox(height: 40),
        CustomButton(
          text: context.tr('Send Verification Code', 'تصدیقی کوڈ بھیجیں'),
          isLoading: _isLoading,
          onPressed: _sendOtp,
        ),
      ],
    );
  }

  Widget _buildOtpView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Verification Code', 'تصدیقی کوڈ'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('Code sent to $_email', 'کوڈ بھیجا گیا: $_email'),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isOtpSent = false;
                });
              },
              child: Text(
                context.tr('Change', 'تبدیل کریں'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        Row(
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            _codeLength,
            (index) => Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 52),
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_codeLength),
                  ],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) => _onCodeChanged(index, value),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: _timerSeconds > 0
              ? Text(
                  context.tr(
                    'Resend code in ${_timerSeconds}s',
                    '$_timerSeconds سیکنڈ میں دوبارہ بھیجیں',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                )
              : TextButton(
                  onPressed: _isLoading ? null : () => _sendOtp(isResend: true),
                  child: Text(
                    context.tr('Resend Code', 'کوڈ دوبارہ بھیجیں'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            context.tr(
              'Not there? Check your spam folder.',
              'نہیں ملا؟ اسپام فولڈر چیک کریں۔',
            ),
            style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
        ),
        const SizedBox(height: 28),
        CustomButton(
          text: context.tr('Verify & Proceed', 'تصدیق کر کے آگے بڑھیں'),
          isLoading: _isLoading,
          onPressed: _verifyOtp,
        ),
      ],
    );
  }
}
