import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maharat/features/customer/customer_main_screen.dart';
import 'package:maharat/features/customer/find/find_workers_tab.dart';
import 'package:maharat/features/customer/home/customer_home_tab.dart';
import 'package:maharat/features/customer/job_requests/request_job_screen.dart';
import 'package:maharat/features/customer/job_requests/request_sent_screen.dart';
import 'package:maharat/features/customer/job_requests/my_requests_tab.dart';
import 'package:maharat/features/customer/profile/customer_profile_tab.dart';
import 'package:maharat/features/customer/reviews/rate_experience_screen.dart';
import 'package:maharat/features/customer/worker_profile/worker_profile_screen.dart';
import 'package:maharat/core/widgets/request_card.dart';
import 'package:maharat/core/widgets/worker_card.dart';
import 'package:maharat/features/onboarding/language_selection_screen.dart';
import 'package:maharat/features/onboarding/phone_auth_screen.dart';
import 'package:maharat/features/onboarding/splash_screen.dart';
import 'package:maharat/features/onboarding/user_type_selection_screen.dart';
import 'package:maharat/features/worker/dashboard/worker_dashboard_screen.dart';
import 'package:maharat/features/worker/profile/worker_own_profile_screen.dart';
import 'package:maharat/features/worker/registration/worker_reg_step1_screen.dart';
import 'package:maharat/features/worker/registration/worker_reg_step2_screen.dart';
import 'package:maharat/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('screens fit phone, tablet-width, and landscape viewports', (
    tester,
  ) async {
    final screenBuilders = <(String, Widget Function(AppState))>[
      ('splash', (_) => const SplashScreen()),
      ('language selection', (_) => const LanguageSelectionScreen()),
      ('role selection', (_) => const UserTypeSelectionScreen()),
      ('phone authentication', (_) => const PhoneAuthScreen()),
      (
        'worker card',
        (state) => Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WorkerCard(
                worker: state.workers.first,
                onTap: () {},
                onWhatsAppTap: () {},
                onCallTap: () {},
              ),
            ],
          ),
        ),
      ),
      (
        'request card',
        (state) => Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RequestCard(
                request: state.activeJobRequests.first,
                onTap: () {},
                onCloseTap: () {},
              ),
            ],
          ),
        ),
      ),
      (
        'customer home',
        (_) => CustomerHomeTab(
          onNavigateToFind: () {},
          onNavigateToRequests: () {},
        ),
      ),
      ('worker search', (_) => const FindWorkersTab()),
      ('job requests list', (_) => const MyRequestsTab()),
      ('customer profile', (_) => const CustomerProfileTab()),
      ('customer tabs', (_) => const CustomerMainScreen()),
      ('worker dashboard', (_) => const WorkerDashboardScreen()),
      ('worker profile', (_) => const WorkerOwnProfileScreen()),
      ('worker registration step 1', (_) => const WorkerRegStep1Screen()),
      (
        'worker registration step 2',
        (_) => const WorkerRegStep2Screen(
          trade: 'Electrician',
          experienceYears: 5,
          phone: '+92 300 1234567',
          visitFee: 300,
          serviceAreas: ['Model Town A'],
          bio: 'Experienced electrician.',
        ),
      ),
      ('job request', (_) => const RequestJobScreen()),
      (
        'request sent',
        (state) => RequestSentScreen(request: state.activeJobRequests.first),
      ),
      (
        'worker details',
        (state) => WorkerProfileScreen(worker: state.workers.first),
      ),
      (
        'review form',
        (state) =>
            RateExperienceScreen(jobRequest: state.completedJobRequests.first),
      ),
    ];
    const sizes = [
      Size(320, 568),
      Size(360, 800),
      Size(430, 932),
      Size(640, 360),
    ];

    tester.view.devicePixelRatio = 1;
    for (final size in sizes) {
      tester.view.physicalSize = size;
      for (final (name, buildScreen) in screenBuilders) {
        final appState = AppState();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appState,
            child: MaterialApp(home: buildScreen(appState)),
          ),
        );
        await tester.pump();
        if (name == 'language selection') {
          expect(find.text('Roman Urdu'), findsNothing);
          expect(find.text('Urdu'), findsOneWidget);
          expect(find.text('English'), findsOneWidget);
        }
        final exception = tester.takeException();
        if (exception != null) {
          if (name == 'worker dashboard' ||
              name == 'worker profile' ||
              name == 'request sent') {
            debugDumpRenderTree();
          }
          final details = exception is FlutterError
              ? exception.toStringDeep()
              : exception.toString();
          fail('$name at ${size.width}x${size.height}: $details');
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 3));
        appState.dispose();
      }
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('phone entry remains scrollable with the keyboard visible', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: PhoneAuthScreen()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    tester.view.resetViewInsets();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
