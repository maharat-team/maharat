import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/utils/error_messages.dart';
import '../core/utils/phone_utils.dart';
import '../models/job_request_model.dart';
import '../models/user_profile_model.dart';
import '../models/worker_model.dart';
import '../services/auth_service.dart';
import '../services/job_service.dart';
import '../services/profile_service.dart';
import '../services/review_service.dart';
import '../services/storage_service.dart';
import '../services/worker_service.dart';

enum LoadStatus { idle, loading, ready, error }

class AppState extends ChangeNotifier {
  AppState({
    AuthService? auth,
    ProfileService? profiles,
    WorkerService? workers,
    JobService? jobs,
    ReviewService? reviews,
    StorageService? storage,
  }) : _auth = auth ?? AuthService(),
       _profiles = profiles ?? ProfileService(),
       _workerService = workers ?? WorkerService(),
       _jobService = jobs ?? JobService(),
       _reviews = reviews ?? ReviewService(),
       _storage = storage ?? StorageService();

  final AuthService _auth;
  final ProfileService _profiles;
  final WorkerService _workerService;
  final JobService _jobService;
  final ReviewService _reviews;
  final StorageService _storage;

  UserProfileModel _currentUser = UserProfileModel.guest();
  WorkerModel? _workerProfile;
  String? _rejectionReason;
  List<WorkerModel> _workers = const [];
  List<JobRequestModel> _jobRequests = const [];
  List<JobRequestModel> _nearbyJobs = const [];

  LoadStatus _workersStatus = LoadStatus.idle;
  LoadStatus _jobsStatus = LoadStatus.idle;
  String? _workersError;
  String? _jobsError;

  StreamSubscription<void>? _signedOutSubscription;
  Object? _interestSubscription;
  Timer? _refreshDebounce;

  /// Called when the session ends for any reason, so the UI can leave
  /// protected screens.
  VoidCallback? onSessionEnded;

  // Getters
  bool get isAuthenticated => _auth.currentUserId != null;
  UserProfileModel get currentUser => _currentUser;
  WorkerModel get workerProfile => _workerProfile ?? WorkerModel.empty();
  String? get rejectionReason => _rejectionReason;
  List<WorkerModel> get workers => List.unmodifiable(_workers);
  List<JobRequestModel> get jobRequests => List.unmodifiable(_jobRequests);
  List<JobRequestModel> get nearbyJobRequests => List.unmodifiable(_nearbyJobs);

  LoadStatus get workersStatus => _workersStatus;
  LoadStatus get jobsStatus => _jobsStatus;
  String? get workersError => _workersError;
  String? get jobsError => _jobsError;

  List<JobRequestModel> get activeJobRequests =>
      _jobRequests.where((j) => j.status == 'Active').toList();

  List<JobRequestModel> get completedJobRequests =>
      _jobRequests.where((j) => j.status == 'Completed').toList();

  List<JobRequestModel> get closedJobRequests =>
      _jobRequests.where((j) => j.status == 'Closed').toList();

  bool isUrdu() => _currentUser.language == 'Urdu';

  String get _userId {
    final id = _auth.currentUserId;
    if (id == null) throw const FormatException('Please sign in again.');
    return id;
  }

  // Session

  /// Restores a persisted session. Throws if a session exists but the profile
  /// cannot be loaded, so the caller can offer a retry.
  Future<void> bootstrap() async {
    _signedOutSubscription ??= _auth.onSignedOut.listen(
      (_) => _handleSignedOut(),
    );
    if (isAuthenticated) await _loadSession();
  }

  Future<void> sendEmailOtp(String email) => _auth.sendEmailOtp(email);

  /// Verifies the code, then applies the choices made during onboarding.
  Future<void> verifyEmailOtp(String email, String code) async {
    final language = _currentUser.language;
    final role = _currentUser.userRole;
    await _auth.verifyEmailOtp(email, code);
    await _loadSession(language: language, role: role);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _handleSignedOut();
  }

  Future<void> _loadSession({String? language, UserRole? role}) async {
    final userId = _userId;
    var profile = await _profiles.fetch(userId);

    final changes = <String, dynamic>{};
    if (language != null && language != profile.language) {
      changes['language'] = language;
    }
    if (role != null && role != profile.userRole) {
      changes['active_role'] = role.name;
    }
    if (changes.isNotEmpty) {
      await _profiles.update(userId, changes);
      profile = profile.copyWith(language: language, userRole: role);
    }

    _currentUser = profile;
    await _refreshOwnWorker();
    notifyListeners();
    await refreshAll();
    _listenForInterests();
  }

  Future<void> _refreshOwnWorker() async {
    final userId = _userId;
    final worker = await _workerService.fetchOwn(userId);
    _workerProfile = worker;
    _rejectionReason = worker?.verificationStatus == VerificationStatus.rejected
        ? await _workerService.fetchRejectionReason(userId)
        : null;
    _currentUser = _currentUser.copyWith(
      isWorkerRegistered: worker != null,
      isCnicVerified: worker?.isCnicVerified ?? false,
    );
  }

  void _handleSignedOut() {
    final wasSignedIn = _currentUser.id.isNotEmpty;
    final subscription = _interestSubscription;
    _interestSubscription = null;
    if (subscription != null) unawaited(_jobService.unsubscribe(subscription));
    _refreshDebounce?.cancel();

    _currentUser = UserProfileModel.guest();
    _workerProfile = null;
    _rejectionReason = null;
    _workers = const [];
    _jobRequests = const [];
    _nearbyJobs = const [];
    _workersStatus = LoadStatus.idle;
    _jobsStatus = LoadStatus.idle;
    notifyListeners();
    if (wasSignedIn) onSessionEnded?.call();
  }

  void _listenForInterests() {
    if (_interestSubscription != null) return;
    try {
      _interestSubscription = _jobService.subscribeToInterests(() {
        _refreshDebounce?.cancel();
        _refreshDebounce = Timer(
          const Duration(milliseconds: 400),
          refreshJobs,
        );
      });
    } catch (error) {
      // Live updates are an enhancement; pull-to-refresh still works.
      debugPrint('Realtime unavailable: $error');
    }
  }

  // Loading

  Future<void> refreshAll() => Future.wait([refreshWorkers(), refreshJobs()]);

  Future<void> refreshWorkers() async {
    _workersStatus = LoadStatus.loading;
    _workersError = null;
    notifyListeners();
    try {
      _workers = await _workerService.fetchDirectory();
      _workersStatus = LoadStatus.ready;
    } catch (error) {
      _workersError = friendlyError(error);
      _workersStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> refreshJobs() async {
    if (!isAuthenticated) return;
    _jobsStatus = LoadStatus.loading;
    _jobsError = null;
    notifyListeners();
    try {
      final userId = _userId;
      // Picks up an approval or rejection made since the last load.
      await _refreshOwnWorker();
      final worker = _workerProfile;
      final results = await Future.wait([
        _jobService.fetchCustomerJobs(userId),
        if (worker != null && worker.isCnicVerified)
          _jobService.fetchNearbyJobs(
            userId: userId,
            trade: worker.trade,
            serviceAreas: worker.serviceAreas,
          ),
      ]);
      _jobRequests = results.first;
      _nearbyJobs = results.length > 1 ? results[1] : const [];
      _jobsStatus = LoadStatus.ready;
    } catch (error) {
      _jobsError = friendlyError(error);
      _jobsStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  // Preferences. Before sign-in these are held locally and saved afterwards.

  void setLanguage(String lang) {
    _currentUser = _currentUser.copyWith(language: lang);
    notifyListeners();
    _savePreference({'language': lang});
  }

  void setUserRole(UserRole role) {
    _currentUser = _currentUser.copyWith(userRole: role);
    notifyListeners();
    _savePreference({'active_role': role.name});
  }

  void _savePreference(Map<String, dynamic> fields) {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    _profiles.update(userId, fields).catchError((Object error) {
      debugPrint('Could not save preference: $error');
    });
  }

  // Profile

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? neighbourhood,
  }) async {
    final normalizedPhone = phone == null ? null : PhoneUtils.normalize(phone);
    if (phone != null && normalizedPhone == null) {
      throw const FormatException(PhoneUtils.invalidMessage);
    }
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isEmpty) {
      throw const FormatException('Please enter your name.');
    }

    await _profiles.update(_userId, {
      'full_name': ?trimmedName,
      'phone': ?normalizedPhone,
      'neighbourhood': ?neighbourhood,
    });
    _currentUser = _currentUser.copyWith(
      name: trimmedName,
      phone: normalizedPhone,
      neighbourhood: neighbourhood,
    );
    if (trimmedName != null) {
      _workerProfile = _workerProfile?.copyWith(name: trimmedName);
    }
    notifyListeners();
  }

  // Jobs

  Future<JobRequestModel> createJobRequest({
    required String trade,
    required String description,
    required String location,
    required String urgency,
    required List<Uint8List> photos,
  }) async {
    final paths = await _storage.uploadJobPhotos(_userId, photos);
    try {
      final job = await _jobService.create(
        trade: trade,
        description: description,
        location: location,
        urgency: urgency,
        photoPaths: paths,
      );
      _jobRequests = [job, ..._jobRequests];
      notifyListeners();
      return job;
    } catch (_) {
      await _storage.deleteJobPhotos(paths);
      rethrow;
    }
  }

  void _replaceJob(
    String jobId,
    JobRequestModel Function(JobRequestModel) update,
  ) {
    _jobRequests = [
      for (final job in _jobRequests) job.id == jobId ? update(job) : job,
    ];
    notifyListeners();
  }

  Future<void> closeJobRequest(String jobId) async {
    await _jobService.close(jobId);
    _replaceJob(jobId, (job) => job.copyWith(status: 'Closed'));
  }

  Future<void> completeJobRequest(String jobId, String workerId) async {
    await _jobService.complete(jobId, workerId);
    _replaceJob(
      jobId,
      (job) => job.copyWith(status: 'Completed', assignedWorkerId: workerId),
    );
  }

  Future<void> addReviewToWorker({
    required String workerId,
    required String jobId,
    required double rating,
    required String comment,
    required List<String> tags,
  }) async {
    await _reviews.create(
      jobId: jobId,
      workerId: workerId,
      rating: rating,
      comment: comment,
      tags: tags,
    );
    _replaceJob(
      jobId,
      (job) => job.copyWith(ratingGiven: rating, reviewComment: comment),
    );
    unawaited(refreshWorkers());
  }

  // Worker

  /// Uploads the CNIC images, then submits everything in one transaction.
  /// The worker stays pending until an admin approves them.
  Future<void> registerWorker(
    WorkerApplication application, {
    required Uint8List front,
    required Uint8List back,
    required Uint8List selfie,
  }) async {
    final userId = _userId;
    final paths = await Future.wait([
      _storage.uploadCnicDocument(userId, 'front', front),
      _storage.uploadCnicDocument(userId, 'back', back),
      _storage.uploadCnicDocument(userId, 'selfie', selfie),
    ]);
    await _workerService.submitApplication(
      application,
      frontPath: paths[0],
      backPath: paths[1],
      selfiePath: paths[2],
    );
    _currentUser = _currentUser.copyWith(userRole: UserRole.worker);
    await _refreshOwnWorker();
    notifyListeners();
  }

  Future<void> toggleWorkerAvailability(bool isAvailable) async {
    final worker = _workerProfile;
    if (worker == null) return;
    _workerProfile = worker.copyWith(isAvailableToday: isAvailable);
    notifyListeners();
    try {
      await _workerService.setAvailability(worker.id, isAvailable);
    } catch (_) {
      _workerProfile = worker;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> workerRespondToJob(String jobId) async {
    final worker = _workerProfile;
    if (worker == null) return;
    await _jobService.expressInterest(jobId, worker.id);
    _nearbyJobs = [
      for (final job in _nearbyJobs)
        job.id == jobId
            ? job.copyWith(
                interestedWorkers: [...job.interestedWorkers, worker],
              )
            : job,
    ];
    notifyListeners();
  }

  Future<void> addWorkPhoto(Uint8List photo) async {
    final worker = _workerProfile;
    if (worker == null) return;
    final path = await _storage.uploadWorkPhoto(worker.id, photo);
    try {
      final added = await _workerService.addPhoto(worker.id, path);
      _workerProfile = worker.copyWith(
        workPhotos: [added, ...worker.workPhotos],
      );
      notifyListeners();
    } catch (_) {
      await _storage.deleteWorkPhoto(path);
      rethrow;
    }
  }

  Future<void> deleteWorkPhoto(WorkPhoto photo) async {
    final worker = _workerProfile;
    if (worker == null) return;
    await _workerService.deletePhoto(photo.id);
    _workerProfile = worker.copyWith(
      workPhotos: worker.workPhotos.where((p) => p.id != photo.id).toList(),
    );
    notifyListeners();
    await _storage.deleteWorkPhoto(photo.path);
  }

  @override
  void dispose() {
    _signedOutSubscription?.cancel();
    _refreshDebounce?.cancel();
    super.dispose();
  }
}
