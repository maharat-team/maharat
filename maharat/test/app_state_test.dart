import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:maharat/features/customer/customer_main_screen.dart';
import 'package:maharat/features/onboarding/language_selection_screen.dart';
import 'package:maharat/features/onboarding/profile_setup_screen.dart';
import 'package:maharat/features/worker/dashboard/worker_dashboard_screen.dart';
import 'package:maharat/features/worker/registration/worker_reg_step1_screen.dart';
import 'package:maharat/models/user_profile_model.dart';
import 'package:maharat/models/worker_model.dart';
import 'package:maharat/routes/session_router.dart';
import 'package:maharat/services/worker_service.dart';
import 'package:maharat/state/app_state.dart';
import 'fixtures/fake_backend.dart';

void main() {
  final photo = Uint8List.fromList([1, 2, 3]);

  group('session', () {
    test('no session leaves the user as a guest', () async {
      final state = FakeBackend(userId: null).createState();
      await state.bootstrap();

      expect(state.isAuthenticated, isFalse);
      expect(state.workers, isEmpty);
    });

    test('a persisted session loads profile and data', () async {
      final state = FakeBackend().createState();
      await state.bootstrap();

      expect(state.currentUser.name, 'Ahmed Khan');
      expect(state.workers, hasLength(2));
      expect(state.jobRequests, hasLength(2));
      expect(state.workersStatus, LoadStatus.ready);
    });

    test('verifying a code saves the onboarding choices', () async {
      final backend = FakeBackend(userId: null);
      final state = backend.createState();
      await state.bootstrap();
      state.setLanguage('Urdu');
      state.setUserRole(UserRole.worker);
      expect(backend.profiles.updates, isEmpty);

      await state.verifyEmailOtp('a@b.co', '123456');

      expect(backend.auth.verifiedCode, '123456');
      expect(backend.profiles.updates.single, {
        'language': 'Urdu',
        'active_role': 'worker',
      });
      expect(state.currentUser.userRole, UserRole.worker);
    });

    test('a rejected code signs nobody in', () async {
      final backend = FakeBackend(userId: null);
      backend.auth.verifyError = Exception('bad code');
      final state = backend.createState();
      await state.bootstrap();

      await expectLater(
        state.verifyEmailOtp('a@b.co', '000000'),
        throwsException,
      );
      expect(state.isAuthenticated, isFalse);
    });

    test('session loss clears all user data and notifies once', () async {
      final backend = FakeBackend();
      backend.workers.own = testWorker(id: testUserId);
      final state = backend.createState();
      await state.bootstrap();
      var ended = 0;
      state.onSessionEnded = () => ended++;

      await state.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(ended, 1);
      expect(state.currentUser.id, isEmpty);
      expect(state.workers, isEmpty);
      expect(state.jobRequests, isEmpty);
      expect(state.workerProfile.id, isEmpty);
      expect(backend.jobs.unsubscribed, isTrue);
    });
  });

  group('routing', () {
    Future<Type> destination(FakeBackend backend) async {
      final state = backend.createState();
      await state.bootstrap();
      return destinationFor(state).runtimeType;
    }

    test('guest goes to onboarding', () async {
      expect(
        await destination(FakeBackend(userId: null)),
        LanguageSelectionScreen,
      );
    });

    test('incomplete profile goes to setup', () async {
      final backend = FakeBackend();
      backend.profiles.profile = backend.profiles.profile.copyWith(name: ' ');
      expect(await destination(backend), ProfileSetupScreen);
    });

    test('customer goes to the customer app', () async {
      expect(await destination(FakeBackend()), CustomerMainScreen);
    });

    test('unregistered worker goes to registration', () async {
      final backend = FakeBackend();
      backend.profiles.profile = backend.profiles.profile.copyWith(
        userRole: UserRole.worker,
      );
      expect(await destination(backend), WorkerRegStep1Screen);
    });

    test('registered worker goes to the dashboard', () async {
      final backend = FakeBackend();
      backend.profiles.profile = backend.profiles.profile.copyWith(
        userRole: UserRole.worker,
      );
      backend.workers.own = testWorker(id: testUserId);
      expect(await destination(backend), WorkerDashboardScreen);
    });
  });

  group('loading', () {
    test('a failed fetch reports an error and keeps the app usable', () async {
      final backend = FakeBackend();
      backend.jobs.failFetch = true;
      final state = backend.createState();
      await state.bootstrap();

      expect(state.jobsStatus, LoadStatus.error);
      expect(state.jobsError, isNotEmpty);
      expect(state.workersStatus, LoadStatus.ready);
    });

    test('a pending worker is not offered nearby jobs', () async {
      final backend = FakeBackend();
      backend.workers.own = testWorker(
        id: testUserId,
        status: VerificationStatus.pending,
      );
      final state = backend.createState();
      await state.bootstrap();

      expect(state.nearbyJobRequests, isEmpty);
      expect(state.currentUser.isCnicVerified, isFalse);
      expect(state.currentUser.isWorkerRegistered, isTrue);
    });

    test('a rejected worker sees the reason', () async {
      final backend = FakeBackend();
      backend.workers.own = testWorker(
        id: testUserId,
        status: VerificationStatus.rejected,
      );
      final state = backend.createState();
      await state.bootstrap();

      expect(state.rejectionReason, 'Photo blurry');
    });
  });

  group('profile', () {
    test('phone numbers are normalised before saving', () async {
      final backend = FakeBackend();
      final state = backend.createState();
      await state.bootstrap();

      await state.updateProfile(phone: '0300 765 4321');

      expect(backend.profiles.updates.last, {'phone': '+923007654321'});
      expect(state.currentUser.phone, '+923007654321');
    });

    test('an invalid phone number is rejected without saving', () async {
      final backend = FakeBackend();
      final state = backend.createState();
      await state.bootstrap();

      await expectLater(
        state.updateProfile(phone: '12345'),
        throwsFormatException,
      );
      expect(backend.profiles.updates, isEmpty);
    });
  });

  group('jobs', () {
    test('a new job appears first', () async {
      final state = FakeBackend().createState();
      await state.bootstrap();

      await state.createJobRequest(
        trade: 'Electrician',
        description: 'x',
        location: 'Model Town A',
        urgency: 'Today',
        photos: [photo],
      );

      expect(state.jobRequests.first.id, 'job-new');
    });

    test('uploaded photos are removed if the job cannot be saved', () async {
      final backend = FakeBackend();
      backend.jobs.failCreate = true;
      final state = backend.createState();
      await state.bootstrap();

      await expectLater(
        state.createJobRequest(
          trade: 'Electrician',
          description: 'x',
          location: 'Model Town A',
          urgency: 'Today',
          photos: [photo, photo],
        ),
        throwsException,
      );

      expect(backend.storage.deletedJobPhotos, hasLength(2));
    });

    test('completing records the chosen worker', () async {
      final backend = FakeBackend();
      final state = backend.createState();
      await state.bootstrap();

      await state.completeJobRequest('job-1', 'worker-2');

      expect(backend.jobs.completed['job-1'], 'worker-2');
      final job = state.jobRequests.firstWhere((j) => j.id == 'job-1');
      expect(job.status, 'Completed');
      expect(job.assignedWorkerId, 'worker-2');
    });

    test('a review reaches the assigned worker', () async {
      final backend = FakeBackend();
      final state = backend.createState();
      await state.bootstrap();

      await state.addReviewToWorker(
        workerId: 'worker-1',
        jobId: 'job-2',
        rating: 4.5,
        comment: '',
        tags: const [],
      );

      expect(backend.reviews.reviewedWorkerId, 'worker-1');
      final job = state.jobRequests.firstWhere((j) => j.id == 'job-2');
      expect(job.ratingGiven, 4.5);
    });
  });

  group('worker', () {
    Future<(FakeBackend, AppState)> signedInWorker() async {
      final backend = FakeBackend();
      backend.workers.own = testWorker(id: testUserId);
      final state = backend.createState();
      await state.bootstrap();
      return (backend, state);
    }

    test('registration uploads all documents and stays pending', () async {
      final backend = FakeBackend();
      final state = backend.createState();
      await state.bootstrap();

      await state.registerWorker(
        const WorkerApplication(
          trade: 'Electrician',
          phone: '+923001234567',
          bio: '',
          experienceYears: 1,
          visitFee: 0,
          serviceAreas: ['Model Town A'],
          cnicNumber: '31202-1234567-1',
        ),
        front: photo,
        back: photo,
        selfie: photo,
      );

      expect(backend.storage.uploadedCnic, ['front', 'back', 'selfie']);
      expect(backend.workers.applicationSubmitted, isTrue);
      expect(state.currentUser.isWorkerRegistered, isTrue);
      expect(state.workerProfile.isCnicVerified, isFalse);
    });

    test('availability rolls back when saving fails', () async {
      final (backend, state) = await signedInWorker();
      backend.workers.failWrites = true;

      await expectLater(state.toggleWorkerAvailability(false), throwsException);

      expect(state.workerProfile.isAvailableToday, isTrue);
    });

    test('responding marks the job as responded', () async {
      final (_, state) = await signedInWorker();

      await state.workerRespondToJob('job-3');

      final job = state.nearbyJobRequests.single;
      expect(job.interestedWorkers.any((w) => w.id == testUserId), isTrue);
    });

    test('adding a work photo updates the gallery', () async {
      final (_, state) = await signedInWorker();

      await state.addWorkPhoto(photo);

      expect(state.workerProfile.workPhotos.single.id, 'photo-1');
    });

    test('a failed photo save removes the uploaded file', () async {
      final (backend, state) = await signedInWorker();
      backend.workers.failWrites = true;

      await expectLater(state.addWorkPhoto(photo), throwsException);

      expect(backend.storage.deletedWorkPhotos, ['$testUserId/work.jpg']);
      expect(state.workerProfile.workPhotos, isEmpty);
    });

    test('deleting removes both the row and the file', () async {
      final (backend, state) = await signedInWorker();
      await state.addWorkPhoto(photo);

      await state.deleteWorkPhoto(state.workerProfile.workPhotos.single);

      expect(backend.workers.deletedPhotoIds, ['photo-1']);
      expect(backend.storage.deletedWorkPhotos, ['$testUserId/work.jpg']);
      expect(state.workerProfile.workPhotos, isEmpty);
    });
  });
}
