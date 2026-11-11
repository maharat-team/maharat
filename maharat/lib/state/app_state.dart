import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../core/l10n/l10n.dart';
import '../core/utils/error_messages.dart';
import '../core/utils/phone_utils.dart';
import '../models/contractor_model.dart';
import '../models/job_request_model.dart';
import '../models/user_profile_model.dart';
import '../models/verification_info.dart';
import '../models/worker_model.dart';
import '../services/auth_service.dart';
import '../services/contractor_service.dart';
import '../services/job_service.dart';
import '../services/language_store.dart';
import '../services/profile_service.dart';
import '../services/review_service.dart';
import '../services/storage_service.dart';
import '../services/verification_service.dart';
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
    ContractorService? contractors,
    VerificationService? verification,
    LanguageStore? languageStore,
    String initialLanguage = AppLanguage.english,
  }) : _auth = auth ?? AuthService(),
       _profiles = profiles ?? ProfileService(),
       _workerService = workers ?? WorkerService(),
       _jobService = jobs ?? JobService(),
       _reviews = reviews ?? ReviewService(),
       _storage = storage ?? StorageService(),
       _contractorService = contractors ?? ContractorService(),
       _verification = verification ?? VerificationService(),
       _languageStore = languageStore,
       _currentUser = UserProfileModel.guest(language: initialLanguage);

  final AuthService _auth;
  final ProfileService _profiles;
  final WorkerService _workerService;
  final JobService _jobService;
  final ReviewService _reviews;
  final StorageService _storage;
  final ContractorService _contractorService;
  final VerificationService _verification;
  final LanguageStore? _languageStore;

  UserProfileModel _currentUser;
  WorkerModel? _workerProfile;
  VerificationInfo? _workerVerification;
  ContractorModel? _contractorProfile;
  VerificationInfo? _contractorVerification;

  List<WorkerModel> _workers = const [];
  List<ContractorModel> _contractors = const [];
  List<JobRequestModel> _jobRequests = const [];
  List<JobRequestModel> _nearbyJobs = const [];
  List<JobRequestModel> _assignedJobs = const [];
  List<JobRequestModel> _contractorOrders = const [];
  List<TeamMembership> _team = const [];
  List<TeamMembership> _memberships = const [];

  LoadStatus _workersStatus = LoadStatus.idle;
  LoadStatus _contractorsStatus = LoadStatus.idle;
  LoadStatus _jobsStatus = LoadStatus.idle;
  String? _workersError;
  String? _contractorsError;
  String? _jobsError;

  StreamSubscription<void>? _signedOutSubscription;
  Object? _changesSubscription;
  Timer? _refreshDebounce;

  /// Called when the session ends for any reason, so the UI can leave
  /// protected screens.
  VoidCallback? onSessionEnded;

  // Getters
  bool get isAuthenticated => _auth.currentUserId != null;
  UserProfileModel get currentUser => _currentUser;
  WorkerModel get workerProfile => _workerProfile ?? WorkerModel.empty();
  bool get hasWorkerProfile => _workerProfile != null;
  VerificationInfo? get workerVerification => _workerVerification;
  String? get rejectionReason => _workerVerification?.reason;
  ContractorModel? get contractorProfile => _contractorProfile;
  VerificationInfo? get contractorVerification => _contractorVerification;

  List<WorkerModel> get workers => List.unmodifiable(_workers);
  List<ContractorModel> get contractors => List.unmodifiable(_contractors);
  List<JobRequestModel> get jobRequests => List.unmodifiable(_jobRequests);
  List<JobRequestModel> get nearbyJobRequests => List.unmodifiable(_nearbyJobs);
  List<JobRequestModel> get assignedJobs => List.unmodifiable(_assignedJobs);
  List<JobRequestModel> get contractorOrders =>
      List.unmodifiable(_contractorOrders);

  /// The contractor's team: invited and active members.
  List<TeamMembership> get team => List.unmodifiable(_team);
  List<WorkerModel> get activeTeam => _team
      .where((m) => m.isActive && m.worker != null)
      .map((m) => m.worker!)
      .toList();

  /// Invitations to this worker, and teams they belong to.
  List<TeamMembership> get pendingInvites =>
      _memberships.where((m) => m.isInvite).toList();
  List<TeamMembership> get myTeams =>
      _memberships.where((m) => m.isActive).toList();

  LoadStatus get workersStatus => _workersStatus;
  LoadStatus get contractorsStatus => _contractorsStatus;
  LoadStatus get jobsStatus => _jobsStatus;
  String? get workersError => _workersError;
  String? get contractorsError => _contractorsError;
  String? get jobsError => _jobsError;

  List<JobRequestModel> get activeJobRequests =>
      _jobRequests.where((j) => j.status == 'Active').toList();

  List<JobRequestModel> get completedJobRequests =>
      _jobRequests.where((j) => j.status == 'Completed').toList();

  List<JobRequestModel> get closedJobRequests =>
      _jobRequests.where((j) => j.status == 'Closed').toList();

  /// Where distances are measured from: the user's pin, or their worker base.
  LatLng? get myLocation =>
      _currentUser.location ?? _workerProfile?.baseLocation;

  bool isUrdu() => _currentUser.language == AppLanguage.urdu;

  String get _userId {
    final id = _auth.currentUserId;
    if (id == null) {
      throw FormatException(
        tr('Please sign in again.', 'براہ کرم دوبارہ سائن ان کریں۔'),
      );
    }
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

  /// Permanently deletes the account. The session ends afterwards.
  Future<void> deleteAccount() async {
    await _auth.deleteAccount();
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
    _rememberLanguage(profile.language);
    await _refreshOwnRoles();
    notifyListeners();
    await refreshAll();
    _listenForChanges();
  }

  Future<void> _refreshOwnRoles() async {
    final userId = _userId;
    final results = await Future.wait<Object?>([
      _workerService.fetchOwn(userId),
      _contractorService.fetchOwn(userId),
    ]);
    final worker = results[0] as WorkerModel?;
    final contractor = results[1] as ContractorModel?;
    _workerProfile = worker;
    _contractorProfile = contractor;

    final verifications = await Future.wait<VerificationInfo?>([
      worker == null
          ? Future<VerificationInfo?>.value()
          : _workerService.fetchVerification(userId),
      contractor == null
          ? Future<VerificationInfo?>.value()
          : _contractorService.fetchVerification(userId),
    ]);
    _workerVerification = verifications[0];
    _contractorVerification = verifications[1];

    _currentUser = _currentUser.copyWith(
      isWorkerRegistered: worker != null,
      isCnicVerified: worker?.isCnicVerified ?? false,
      isContractorRegistered: contractor != null,
      isContractorVerified: contractor?.isVerified ?? false,
    );
  }

  void _handleSignedOut() {
    final wasSignedIn = _currentUser.id.isNotEmpty;
    final subscription = _changesSubscription;
    _changesSubscription = null;
    if (subscription != null) unawaited(_jobService.unsubscribe(subscription));
    _refreshDebounce?.cancel();

    // The language choice belongs to the device, not the account.
    _currentUser = UserProfileModel.guest(language: _currentUser.language);
    _workerProfile = null;
    _workerVerification = null;
    _contractorProfile = null;
    _contractorVerification = null;
    _workers = const [];
    _contractors = const [];
    _jobRequests = const [];
    _nearbyJobs = const [];
    _assignedJobs = const [];
    _contractorOrders = const [];
    _team = const [];
    _memberships = const [];
    _workersStatus = LoadStatus.idle;
    _contractorsStatus = LoadStatus.idle;
    _jobsStatus = LoadStatus.idle;
    notifyListeners();
    if (wasSignedIn) onSessionEnded?.call();
  }

  void _listenForChanges() {
    if (_changesSubscription != null) return;
    try {
      _changesSubscription = _jobService.subscribeToChanges(() {
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

  Future<void> refreshAll() =>
      Future.wait([refreshWorkers(), refreshContractors(), refreshJobs()]);

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

  Future<void> refreshContractors() async {
    _contractorsStatus = LoadStatus.loading;
    _contractorsError = null;
    notifyListeners();
    try {
      _contractors = await _contractorService.fetchDirectory();
      _contractorsStatus = LoadStatus.ready;
    } catch (error) {
      _contractorsError = friendlyError(error);
      _contractorsStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  /// Everything that depends on the user's roles: their own requests, jobs
  /// near a worker, jobs a contractor sent them to, invitations, and a
  /// contractor's orders and team.
  Future<void> refreshJobs() async {
    if (!isAuthenticated) return;
    _jobsStatus = LoadStatus.loading;
    _jobsError = null;
    notifyListeners();
    try {
      final userId = _userId;
      // Picks up an approval or rejection made since the last load.
      await _refreshOwnRoles();
      final worker = _workerProfile;
      final contractor = _contractorProfile;
      final workerReady = worker != null && worker.isCnicVerified;
      final shopReady = contractor != null && contractor.isVerified;

      final results = await Future.wait<Object>([
        _jobService.fetchCustomerJobs(userId),
        workerReady
            ? _jobService.fetchNearbyJobs(
                userId: userId,
                trade: worker!.trade,
                serviceAreas: worker!.serviceAreas,
              )
            : Future<List<JobRequestModel>>.value(const []),
        workerReady
            ? _jobService.fetchAssignedJobs(userId)
            : Future<List<JobRequestModel>>.value(const []),
        workerReady
            ? _contractorService.fetchMemberships(userId)
            : Future<List<TeamMembership>>.value(const []),
        shopReady
            ? _jobService.fetchContractorOrders(userId)
            : Future<List<JobRequestModel>>.value(const []),
        shopReady
            ? _contractorService.fetchTeam(userId)
            : Future<List<TeamMembership>>.value(const []),
      ]);
      _jobRequests = results[0] as List<JobRequestModel>;
      _nearbyJobs = results[1] as List<JobRequestModel>;
      _assignedJobs = results[2] as List<JobRequestModel>;
      _memberships = results[3] as List<TeamMembership>;
      _contractorOrders = results[4] as List<JobRequestModel>;
      _team = results[5] as List<TeamMembership>;
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
    AppLanguage.isUrdu = lang == AppLanguage.urdu;
    notifyListeners();
    _rememberLanguage(lang);
    _savePreference({'language': lang});
  }

  void _rememberLanguage(String language) {
    final store = _languageStore;
    if (store != null) unawaited(store.save(language));
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
      throw FormatException(PhoneUtils.invalidMessage);
    }
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isEmpty) {
      throw FormatException(
        tr('Please enter your name.', 'براہ کرم اپنا نام درج کریں۔'),
      );
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

  /// Saves the user's exact home pin. Private to them.
  Future<void> updateMyLocation(LatLng point, String addressDetails) async {
    await _profiles.update(_userId, {
      'lat': point.latitude,
      'lng': point.longitude,
      'address_details': addressDetails.trim(),
    });
    _currentUser = _currentUser.copyWith(
      location: point,
      addressDetails: addressDetails.trim(),
    );
    notifyListeners();
  }

  // Jobs

  Future<JobRequestModel> createJobRequest({
    required String trade,
    required String description,
    required String location,
    required String urgency,
    required List<Uint8List> photos,
    String? contractorId,
    LatLng? point,
    String addressDetails = '',
  }) async {
    final paths = await _storage.uploadJobPhotos(_userId, photos);
    try {
      final job = await _jobService.create(
        trade: trade,
        description: description,
        location: location,
        urgency: urgency,
        photoPaths: paths,
        contractorId: contractorId,
        point: point,
        addressDetails: addressDetails,
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

  /// [workerId] is who did the job; null for a contractor order.
  Future<void> completeJobRequest(String jobId, String? workerId) async {
    await _jobService.complete(jobId, workerId);
    _replaceJob(
      jobId,
      (job) => job.copyWith(status: 'Completed', assignedWorkerId: workerId),
    );
  }

  /// Reviews the worker who did a job, or the contractor of an order.
  Future<void> addReview({
    required JobRequestModel job,
    required double rating,
    required String comment,
    required List<String> tags,
  }) async {
    await _reviews.create(
      jobId: job.id,
      workerId: job.isContractorOrder ? null : job.assignedWorkerId,
      contractorId: job.contractorId,
      rating: rating,
      comment: comment,
      tags: tags,
    );
    _replaceJob(
      job.id,
      (j) => j.copyWith(ratingGiven: rating, reviewComment: comment),
    );
    unawaited(job.isContractorOrder ? refreshContractors() : refreshWorkers());
  }

  /// Kept for screens and tests that review a worker directly.
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

  // Identity checks

  /// Runs the automatic face check for the worker or contractor application
  /// just submitted, then reloads the result.
  Future<FaceCheckResult> runFaceCheck({required bool contractor}) async {
    final result = await _verification.check(contractor: contractor);
    try {
      await _refreshOwnRoles();
    } catch (error) {
      debugPrint('Could not reload verification: $error');
    }
    notifyListeners();
    if (result.status == VerificationStatus.approved) unawaited(refreshJobs());
    return result;
  }

  // Worker

  /// Uploads the CNIC images and submits everything in one transaction.
  /// Call [runFaceCheck] next to verify automatically.
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
    await _refreshOwnRoles();
    notifyListeners();
  }

  /// Saves edits to the worker's own profile.
  Future<void> updateWorkerProfile({
    required String phone,
    required String bio,
    required int experienceYears,
    required int visitFee,
    required List<String> serviceAreas,
    LatLng? baseLocation,
  }) async {
    final worker = _workerProfile;
    if (worker == null) return;
    final normalizedPhone = PhoneUtils.normalize(phone);
    if (normalizedPhone == null) {
      throw FormatException(PhoneUtils.invalidMessage);
    }
    if (serviceAreas.isEmpty) {
      throw FormatException(
        tr(
          'Please select at least one service area.',
          'کم از کم ایک علاقہ منتخب کریں۔',
        ),
      );
    }
    await _workerService.updateProfile(worker.id, {
      'phone': normalizedPhone,
      'bio': bio.trim(),
      'experience_years': experienceYears,
      'visit_fee': visitFee,
      'service_areas': serviceAreas,
      'neighbourhood': serviceAreas.first,
      if (baseLocation != null) 'base_lat': baseLocation.latitude,
      if (baseLocation != null) 'base_lng': baseLocation.longitude,
    });
    await _refreshOwnRoles();
    notifyListeners();
    unawaited(refreshJobs());
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
    // Responding reveals the exact location; reload to pick it up.
    unawaited(refreshJobs());
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

  Future<void> respondToTeamInvite(String contractorId, bool accept) async {
    await _contractorService.respondToInvite(contractorId, accept);
    await refreshJobs();
  }

  Future<void> leaveTeam(String contractorId) async {
    await _contractorService.removeMembership(contractorId, _userId);
    await refreshJobs();
  }

  // Contractor

  /// Uploads the shop photo and CNIC images, then submits the application.
  /// Call [runFaceCheck] next.
  Future<void> registerContractor(
    ContractorApplication application, {
    required Uint8List? shopPhoto,
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
    final shopPath = shopPhoto == null
        ? null
        : await _storage.uploadWorkPhoto(userId, shopPhoto);
    await _contractorService.submitApplication(
      application,
      shopPhotoPath: shopPath,
      frontPath: paths[0],
      backPath: paths[1],
      selfiePath: paths[2],
    );
    _currentUser = _currentUser.copyWith(userRole: UserRole.contractor);
    await _refreshOwnRoles();
    notifyListeners();
  }

  Future<void> setAcceptingOrders(bool accepting) async {
    final shop = _contractorProfile;
    if (shop == null) return;
    _contractorProfile = shop.copyWith(isAcceptingOrders: accepting);
    notifyListeners();
    try {
      await _contractorService.update(shop.id, {
        'is_accepting_orders': accepting,
      });
    } catch (_) {
      _contractorProfile = shop;
      notifyListeners();
      rethrow;
    }
  }

  /// Invites a verified worker by mobile number. Returns their name.
  Future<String> inviteTeamMember(String phone) async {
    final normalized = PhoneUtils.normalize(phone);
    if (normalized == null) throw FormatException(PhoneUtils.invalidMessage);
    final name = await _contractorService.inviteMember(normalized);
    await refreshJobs();
    return name;
  }

  Future<void> removeTeamMember(String workerId) async {
    await _contractorService.removeMembership(_userId, workerId);
    _team = _team.where((m) => m.workerId != workerId).toList();
    notifyListeners();
  }

  Future<void> respondToOrder(String jobId, bool accept) async {
    await _contractorService.respondToOrder(jobId, accept);
    await refreshJobs();
  }

  Future<void> assignOrderTeam(String jobId, List<String> workerIds) async {
    await _contractorService.assignTeam(jobId, workerIds);
    await refreshJobs();
  }

  @override
  void dispose() {
    _signedOutSubscription?.cancel();
    _refreshDebounce?.cancel();
    super.dispose();
  }
}
