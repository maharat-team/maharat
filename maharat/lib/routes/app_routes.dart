import 'package:flutter/material.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/language_selection_screen.dart';
import '../features/onboarding/user_type_selection_screen.dart';
import '../features/onboarding/phone_auth_screen.dart';
import '../features/customer/customer_main_screen.dart';
import '../features/worker/registration/worker_reg_step1_screen.dart';
import '../features/worker/dashboard/worker_dashboard_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String language = '/language';
  static const String userType = '/user_type';
  static const String phoneAuth = '/phone_auth';
  static const String customerMain = '/customer_main';
  static const String workerReg1 = '/worker_reg_1';
  static const String workerDashboard = '/worker_dashboard';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        language: (context) => const LanguageSelectionScreen(),
        userType: (context) => const UserTypeSelectionScreen(),
        phoneAuth: (context) => const PhoneAuthScreen(),
        customerMain: (context) => const CustomerMainScreen(),
        workerReg1: (context) => const WorkerRegStep1Screen(),
        workerDashboard: (context) => const WorkerDashboardScreen(),
      };
}
