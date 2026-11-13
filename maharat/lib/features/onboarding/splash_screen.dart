import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/session_router.dart';
import '../../state/app_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    _start();
  }

  /// Restores the session while the splash plays, then routes the user.
  Future<void> _start() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (_hasFailed) setState(() => _hasFailed = false);
    try {
      await Future.wait([
        Future<void>.delayed(const Duration(milliseconds: 2500)),
        appState.bootstrap(),
      ]);
    } catch (error) {
      debugPrint('[startup] ${error.runtimeType}: $error');
      if (mounted) setState(() => _hasFailed = true);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            destinationFor(appState),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(100),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.handyman_rounded,
                      size: 56,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // The wordmark follows the chosen language.
                  if (context.isUrdu)
                    const Text(
                      'مہارت',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    )
                  else
                    const Text(
                      'MAHARAT',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: AppColors.white,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      context.tr(
                        "Bahawalpur's Local Service Platform",
                        'بہاولپور کا مقامی سروس پلیٹ فارم',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    context.tr(
                      'Verified local tradespeople.\nFree for everyone. No commission.',
                      'تصدیق شدہ مقامی کاریگر۔\nسب کے لیے مفت۔ کوئی کمیشن نہیں۔',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.lightMint,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_hasFailed)
                    TextButton(
                      onPressed: _start,
                      child: Text(
                        context.tr(
                          'Could not connect. Tap to retry.',
                          'رابطہ نہیں ہو سکا۔ دوبارہ کوشش کے لیے ٹیپ کریں۔',
                        ),
                        style: const TextStyle(color: AppColors.white),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
