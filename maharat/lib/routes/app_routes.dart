import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/language_selection_screen.dart';
import '../features/onboarding/user_type_selection_screen.dart';
import '../features/onboarding/email_auth_screen.dart';
import '../features/customer/customer_main_screen.dart';
import '../features/worker/registration/worker_reg_step1_screen.dart';
import '../features/worker/dashboard/worker_dashboard_screen.dart';
import '../features/contractor/contractor_main_screen.dart';
import '../state/app_state.dart';

/// Shows [child] only to signed-in users. This is a navigation convenience;
/// the database policies are what actually protect the data.
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AppState, bool>(
      (state) => state.isAuthenticated,
    );
    return isAuthenticated ? child : const LanguageSelectionScreen();
  }
}

class AppRoutes {
  static const String splash = '/';
  static const String language = '/language';
  static const String userType = '/user_type';
  static const String emailAuth = '/email_auth';
  static const String customerMain = '/customer_main';
  static const String workerReg1 = '/worker_reg_1';
  static const String workerDashboard = '/worker_dashboard';
  static const String contractorMain = '/contractor_main';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    language: (context) => const LanguageSelectionScreen(),
    userType: (context) => const UserTypeSelectionScreen(),
    emailAuth: (context) => const EmailAuthScreen(),
    customerMain: (context) => const AuthGuard(child: CustomerMainScreen()),
    workerReg1: (context) => const AuthGuard(child: WorkerRegStep1Screen()),
    workerDashboard: (context) =>
        const AuthGuard(child: WorkerDashboardScreen()),
    contractorMain: (context) =>
        const AuthGuard(child: ContractorMainScreen()),
  };
}
