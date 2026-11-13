import 'package:flutter/material.dart';
import '../features/contractor/contractor_main_screen.dart';
import '../features/contractor/registration/contractor_reg_step1_screen.dart';
import '../features/customer/customer_main_screen.dart';
import '../features/onboarding/language_selection_screen.dart';
import '../features/onboarding/profile_setup_screen.dart';
import '../features/worker/dashboard/worker_dashboard_screen.dart';
import '../features/worker/registration/worker_reg_step1_screen.dart';
import '../models/user_profile_model.dart';
import '../state/app_state.dart';

/// The screen a user belongs on, given their session and profile.
Widget destinationFor(AppState appState) {
  if (!appState.isAuthenticated) return const LanguageSelectionScreen();

  final user = appState.currentUser;
  if (!user.isComplete) return const ProfileSetupScreen();
  switch (user.userRole) {
    case UserRole.customer:
      return const CustomerMainScreen();
    case UserRole.worker:
      return user.isWorkerRegistered
          ? const WorkerDashboardScreen()
          : const WorkerRegStep1Screen();
    case UserRole.contractor:
      return user.isContractorRegistered
          ? const ContractorMainScreen()
          : const ContractorRegStep1Screen();
  }
}
