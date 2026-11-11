import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maharat/core/l10n/l10n.dart';
import 'package:maharat/core/utils/geo.dart';
import 'package:maharat/core/utils/phone_utils.dart';
import 'package:maharat/features/contractor/contractor_main_screen.dart';
import 'package:maharat/features/contractor/registration/contractor_reg_step1_screen.dart';
import 'package:maharat/features/onboarding/language_selection_screen.dart';
import 'package:maharat/features/onboarding/user_type_selection_screen.dart';
import 'package:maharat/main.dart';
import 'package:maharat/models/user_profile_model.dart';
import 'package:maharat/models/verification_info.dart';
import 'package:maharat/models/worker_model.dart';
import 'package:maharat/routes/session_router.dart';
import 'fixtures/fake_backend.dart';

void main() {
  tearDown(() => AppLanguage.isUrdu = false);

  group('language', () {
    test('choosing Urdu switches text produced outside widgets', () {
      final state = FakeBackend(userId: null).createState();
      state.setLanguage(AppLanguage.urdu);

      expect(AppLanguage.isUrdu, isTrue);
      expect(PhoneUtils.invalidMessage, contains('موبائل'));
      expect(state.isUrdu(), isTrue);
    });

    test('the device language survives sign-out', () async {
      final backend = FakeBackend();
      final state = backend.createState();
      await state.bootstrap();
      state.setLanguage(AppLanguage.urdu);

      await state.signOut();

      expect(state.currentUser.language, AppLanguage.urdu);
    });

    testWidgets('Urdu lays the app out right-to-left with Urdu text', (
      tester,
    ) async {
      final state = FakeBackend(userId: null).createState();
      await tester.pumpWidget(MaharatApp(appState: state));
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(LanguageSelectionScreen), findsOneWidget);
      expect(find.text('Select Language'), findsOneWidget);

      await tester.tap(find.text('اردو'));
      await tester.pumpAndSettle();

      expect(find.text('زبان منتخب کریں'), findsOneWidget);
      expect(find.text('Select Language'), findsNothing);
      final direction = Directionality.of(
        tester.element(find.byType(LanguageSelectionScreen)),
      );
      expect(direction, TextDirection.rtl);

      await tester.tap(find.text('آگے بڑھیں'));
      await tester.pumpAndSettle();
      expect(find.byType(UserTypeSelectionScreen), findsOneWidget);
      expect(find.text('میری دکان ہے / میں ٹھیکیدار ہوں'), findsOneWidget);
    });
  });

  group('identity check', () {
    test('an approved face check marks the worker verified', () async {
      final backend = FakeBackend();
      backend.workers.own = testWorker(
        id: testUserId,
        status: VerificationStatus.pending,
      );
      final state = backend.createState();
      await state.bootstrap();
      expect(state.currentUser.isCnicVerified, isFalse);

      backend.workers.own = testWorker(id: testUserId);
      final result = await state.runFaceCheck(contractor: false);

      expect(result.status, VerificationStatus.approved);
      expect(backend.verification.checks, 1);
      expect(state.currentUser.isCnicVerified, isTrue);
      expect(state.workerVerification?.score, 92);
    });

    test('a failed check keeps the reason for the worker', () async {
      final backend = FakeBackend();
      backend.workers.own = testWorker(
        id: testUserId,
        status: VerificationStatus.rejected,
      );
      backend.verification.result = const FaceCheckResult(
        status: VerificationStatus.rejected,
        score: 41,
        code: 'face_mismatch',
      );
      final state = backend.createState();
      await state.bootstrap();

      final result = await state.runFaceCheck(contractor: false);

      expect(result.code, 'face_mismatch');
      expect(state.workerVerification?.code, 'face_mismatch');
      expect(state.rejectionReason, 'Photo blurry');
    });
  });

  group('contractors', () {
    test('a contractor lands on their shop once registered', () async {
      final backend = FakeBackend();
      backend.profiles.profile = backend.profiles.profile.copyWith(
        userRole: UserRole.contractor,
      );
      final state = backend.createState();
      await state.bootstrap();
      expect(destinationFor(state), isA<ContractorRegStep1Screen>());

      backend.contractors.own = testContractor();
      await state.refreshJobs();

      expect(state.currentUser.isContractorVerified, isTrue);
      expect(destinationFor(state), isA<ContractorMainScreen>());
    });

    test('orders, invitations and assignments go to the backend', () async {
      final backend = FakeBackend();
      backend.contractors.own = testContractor();
      final state = backend.createState();
      await state.bootstrap();

      final name = await state.inviteTeamMember('0301 8765432');
      await state.respondToOrder('job-9', true);
      await state.assignOrderTeam('job-9', ['worker-1']);

      expect(name, 'Mohammad Tariq');
      expect(backend.contractors.invitedPhones.single, '+923018765432');
      expect(backend.contractors.orderReplies['job-9'], isTrue);
      expect(backend.contractors.assignments['job-9'], ['worker-1']);
    });

    test('an invalid number is refused before reaching the server', () async {
      final backend = FakeBackend();
      backend.contractors.own = testContractor();
      final state = backend.createState();
      await state.bootstrap();

      await expectLater(
        state.inviteTeamMember('12345'),
        throwsA(isA<FormatException>()),
      );
      expect(backend.contractors.invitedPhones, isEmpty);
    });

    test('a customer order to a shop carries the shop and the pin', () async {
      final backend = FakeBackend();
      final state = backend.createState();
      await state.bootstrap();

      await state.createJobRequest(
        trade: 'Electrician',
        description: 'Rewire kitchen',
        location: 'Model Town A',
        urgency: 'Today',
        photos: const [],
        contractorId: 'shop-1',
        point: LatLng(29.39, 71.68),
      );

      expect(backend.jobs.lastContractorId, 'shop-1');
    });

    test('a contractor order is completed without naming a worker', () async {
      final backend = FakeBackend();
      final state = backend.createState();
      await state.bootstrap();

      await state.completeJobRequest('job-1', null);

      expect(backend.jobs.completed.containsKey('job-1'), isTrue);
      expect(backend.jobs.completed['job-1'], isNull);
    });
  });

  group('maps', () {
    test('distances are measured in kilometres', () {
      final modelTown = LatLng(29.3800, 71.6900);
      final fridGate = LatLng(29.3956, 71.6836);
      final km = distanceKm(modelTown, fridGate);
      expect(km, greaterThan(1.7));
      expect(km, lessThan(2.0));
    });

    test('pins outside Bahawalpur are rejected', () {
      expect(Bahawalpur.contains(Bahawalpur.center), isTrue);
      expect(Bahawalpur.contains(LatLng(31.5204, 74.3587)), isFalse); // Lahore
    });
  });

  test('account deletion ends the session', () async {
    final backend = FakeBackend();
    final state = backend.createState();
    await state.bootstrap();

    await state.deleteAccount();

    expect(backend.auth.deleted, isTrue);
    expect(state.isAuthenticated, isFalse);
  });
}
