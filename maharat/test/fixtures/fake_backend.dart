import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:maharat/models/contractor_model.dart';
import 'package:maharat/models/job_request_model.dart';
import 'package:maharat/models/review_model.dart';
import 'package:maharat/models/user_profile_model.dart';
import 'package:maharat/models/verification_info.dart';
import 'package:maharat/models/worker_model.dart';
import 'package:maharat/services/auth_service.dart';
import 'package:maharat/services/contractor_service.dart';
import 'package:maharat/services/job_service.dart';
import 'package:maharat/services/profile_service.dart';
import 'package:maharat/services/review_service.dart';
import 'package:maharat/services/storage_service.dart';
import 'package:maharat/services/verification_service.dart';
import 'package:maharat/services/worker_service.dart';
import 'package:maharat/state/app_state.dart';

const testUserId = 'user-1';

WorkerModel testWorker({
  String id = 'worker-1',
  String name = 'Mohammad Tariq',
  VerificationStatus status = VerificationStatus.approved,
}) {
  return WorkerModel(
    id: id,
    name: name,
    trade: 'Electrician',
    phone: '+923018765432',
    rating: 4.9,
    reviewCount: 1,
    experienceYears: 8,
    visitFee: 300,
    neighbourhood: 'Model Town A',
    serviceAreas: const ['Model Town A', 'Model Town B', 'Satellite Town'],
    bio: 'Certified master electrician with 8 years of experience.',
    verificationStatus: status,
    isAvailableToday: true,
    workPhotos: const [],
    reviews: [
      ReviewModel(
        id: 'r1',
        customerName: 'Usman Ali',
        rating: 5,
        comment: 'Very professional and charged a fair rate.',
        tags: const ['On time', 'Fair price'],
        date: 'Yesterday',
      ),
    ],
    completedJobsCount: 84,
  );
}

JobRequestModel testJob({
  String id = 'job-1',
  String status = 'Active',
  List<WorkerModel>? interested,
  String? assignedWorkerId,
}) {
  return JobRequestModel(
    id: id,
    customerId: testUserId,
    customerName: 'Ahmed Khan',
    tradeCategory: 'Electrician',
    description: 'Living room ceiling fan switch needs replacement.',
    location: 'Model Town A',
    urgency: 'Today',
    status: status,
    createdAt: DateTime(2026, 11, 1),
    interestedWorkers: interested ?? [testWorker()],
    assignedWorkerId: assignedWorkerId,
  );
}

class FakeAuthService implements AuthService {
  FakeAuthService({this.currentUserId = testUserId});

  final controller = StreamController<void>.broadcast();
  String? verifiedCode;
  Object? verifyError;

  @override
  String? currentUserId;

  @override
  Stream<void> get onSignedOut => controller.stream;

  @override
  Future<void> sendEmailOtp(String email) async {}

  @override
  Future<void> verifyEmailOtp(String email, String code) async {
    if (verifyError != null) throw verifyError!;
    verifiedCode = code;
    currentUserId = testUserId;
  }

  @override
  Future<void> signOut() async {
    currentUserId = null;
    controller.add(null);
  }

  bool deleted = false;

  @override
  Future<void> deleteAccount() async {
    deleted = true;
    await signOut();
  }
}

class FakeProfileService implements ProfileService {
  UserProfileModel profile = UserProfileModel(
    id: testUserId,
    name: 'Ahmed Khan',
    phone: '+923001234567',
    userRole: UserRole.customer,
    language: 'English',
    neighbourhood: 'Model Town A',
  );
  final updates = <Map<String, dynamic>>[];

  @override
  Future<UserProfileModel> fetch(String userId) async => profile;

  @override
  Future<void> update(String userId, Map<String, dynamic> fields) async {
    updates.add(fields);
  }
}

class FakeWorkerService implements WorkerService {
  List<WorkerModel> directory = [
    testWorker(),
    testWorker(id: 'worker-2', name: 'Zubair Ahmed'),
  ];
  WorkerModel? own;
  bool failWrites = false;
  bool applicationSubmitted = false;
  final deletedPhotoIds = <String>[];

  @override
  Future<List<WorkerModel>> fetchDirectory() async => directory;

  @override
  Future<WorkerModel?> fetchOwn(String userId) async => own;

  @override
  Future<VerificationInfo?> fetchVerification(String userId) async {
    final status = own?.verificationStatus;
    if (status == null) return null;
    return VerificationInfo(
      status: status,
      score: status == VerificationStatus.approved ? 92 : 41,
      code: status == VerificationStatus.rejected ? 'face_mismatch' : null,
      reason: status == VerificationStatus.rejected ? 'Photo blurry' : null,
    );
  }

  final profileUpdates = <Map<String, dynamic>>[];

  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> fields) async {
    if (failWrites) throw Exception('offline');
    profileUpdates.add(fields);
  }

  @override
  Future<void> submitApplication(
    WorkerApplication application, {
    required String frontPath,
    required String backPath,
    required String selfiePath,
  }) async {
    applicationSubmitted = true;
    own = testWorker(id: testUserId, status: VerificationStatus.pending);
  }

  @override
  Future<void> setAvailability(String userId, bool isAvailable) async {
    if (failWrites) throw Exception('offline');
  }

  @override
  Future<WorkPhoto> addPhoto(String userId, String storagePath) async {
    if (failWrites) throw Exception('limit reached');
    return WorkPhoto(id: 'photo-1', path: storagePath, url: 'https://x/y.jpg');
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    deletedPhotoIds.add(photoId);
  }
}

class FakeJobService implements JobService {
  List<JobRequestModel> customerJobs = [
    testJob(),
    testJob(id: 'job-2', status: 'Completed', assignedWorkerId: 'worker-1'),
  ];
  List<JobRequestModel> nearby = [testJob(id: 'job-3')];
  bool failCreate = false;
  bool failFetch = false;
  final completed = <String, String?>{};
  bool unsubscribed = false;

  @override
  Future<List<JobRequestModel>> fetchCustomerJobs(String userId) async {
    if (failFetch) throw Exception('offline');
    return customerJobs;
  }

  @override
  Future<List<JobRequestModel>> fetchNearbyJobs({
    required String userId,
    required String trade,
    required List<String> serviceAreas,
  }) async => nearby;

  List<JobRequestModel> contractorOrders = const [];
  List<JobRequestModel> assigned = const [];
  String? lastContractorId;

  @override
  Future<List<JobRequestModel>> fetchContractorOrders(
    String contractorId,
  ) async => contractorOrders;

  @override
  Future<List<JobRequestModel>> fetchAssignedJobs(String workerId) async =>
      assigned;

  @override
  Future<JobRequestModel> create({
    required String trade,
    required String description,
    required String location,
    required String urgency,
    required List<String> photoPaths,
    String? contractorId,
    LatLng? point,
    String addressDetails = '',
  }) async {
    if (failCreate) throw Exception('insert failed');
    lastContractorId = contractorId;
    return testJob(id: 'job-new', interested: const []);
  }

  @override
  Future<void> close(String jobId) async {}

  @override
  Future<void> complete(String jobId, String? workerId) async {
    completed[jobId] = workerId;
  }

  @override
  Future<void> expressInterest(String jobId, String workerId) async {}

  @override
  Object subscribeToChanges(VoidCallback onChange) => Object();

  @override
  Future<void> unsubscribe(Object subscription) async {
    unsubscribed = true;
  }
}

class FakeReviewService implements ReviewService {
  String? reviewedWorkerId;
  String? reviewedContractorId;

  @override
  Future<void> create({
    required String jobId,
    String? workerId,
    String? contractorId,
    required double rating,
    required String comment,
    required List<String> tags,
  }) async {
    reviewedWorkerId = workerId;
    reviewedContractorId = contractorId;
  }
}

class FakeContractorService implements ContractorService {
  List<ContractorModel> directory = const [];
  ContractorModel? own;
  List<TeamMembership> team = const [];
  List<TeamMembership> memberships = const [];
  final invitedPhones = <String>[];
  final orderReplies = <String, bool>{};
  final assignments = <String, List<String>>{};

  @override
  Future<List<ContractorModel>> fetchDirectory() async => directory;

  @override
  Future<ContractorModel?> fetchOwn(String userId) async => own;

  @override
  Future<VerificationInfo?> fetchVerification(String userId) async =>
      own == null ? null : VerificationInfo(status: own!.verificationStatus);

  @override
  Future<void> submitApplication(
    ContractorApplication application, {
    required String? shopPhotoPath,
    required String frontPath,
    required String backPath,
    required String selfiePath,
  }) async {
    own = testContractor(status: VerificationStatus.pending);
  }

  @override
  Future<void> update(String userId, Map<String, dynamic> fields) async {}

  @override
  Future<List<TeamMembership>> fetchTeam(String contractorId) async => team;

  @override
  Future<List<TeamMembership>> fetchMemberships(String workerId) async =>
      memberships;

  @override
  Future<String> inviteMember(String phone) async {
    invitedPhones.add(phone);
    return 'Mohammad Tariq';
  }

  @override
  Future<void> respondToInvite(String contractorId, bool accept) async {}

  @override
  Future<void> removeMembership(String contractorId, String workerId) async {}

  @override
  Future<void> respondToOrder(String jobId, bool accept) async {
    orderReplies[jobId] = accept;
  }

  @override
  Future<void> assignTeam(String jobId, List<String> workerIds) async {
    assignments[jobId] = workerIds;
  }
}

class FakeVerificationService implements VerificationService {
  FaceCheckResult result = const FaceCheckResult(
    status: VerificationStatus.approved,
    score: 91.4,
  );
  int checks = 0;

  @override
  Future<FaceCheckResult> check({required bool contractor}) async {
    checks++;
    return result;
  }
}

ContractorModel testContractor({
  String id = testUserId,
  VerificationStatus status = VerificationStatus.approved,
}) {
  return ContractorModel(
    id: id,
    businessName: 'Kashif Electric Works',
    ownerName: 'Ahmed Khan',
    phone: '+923003333333',
    trades: const ['Electrician', 'Plumber'],
    bio: 'Electric and plumbing work since 2010.',
    neighbourhood: 'Model Town A',
    serviceAreas: const ['Model Town A', 'Satellite Town'],
    shopAddress: 'Shop 4, Circular Road',
    location: null,
    shopPhotoUrl: null,
    isAcceptingOrders: true,
    verificationStatus: status,
    rating: 4.5,
    reviewCount: 2,
    completedJobsCount: 7,
  );
}

class FakeStorageService implements StorageService {
  final deletedJobPhotos = <String>[];
  final deletedWorkPhotos = <String>[];
  final uploadedCnic = <String>[];

  @override
  Future<String> uploadWorkPhoto(String userId, Uint8List bytes) async =>
      '$userId/work.jpg';

  @override
  Future<void> deleteWorkPhoto(String path) async {
    deletedWorkPhotos.add(path);
  }

  @override
  Future<List<String>> uploadJobPhotos(
    String userId,
    List<Uint8List> photos,
  ) async => [for (var i = 0; i < photos.length; i++) '$userId/job$i.jpg'];

  @override
  Future<void> deleteJobPhotos(List<String> paths) async {
    deletedJobPhotos.addAll(paths);
  }

  @override
  Future<String> uploadCnicDocument(
    String userId,
    String name,
    Uint8List bytes,
  ) async {
    uploadedCnic.add(name);
    return '$userId/$name.jpg';
  }

  @override
  Future<Map<String, String>> signJobPhotos(List<String> paths) async =>
      const {};
}

/// A full set of fakes wired into an [AppState].
class FakeBackend {
  FakeBackend({String? userId = testUserId})
    : auth = FakeAuthService(currentUserId: userId);

  final FakeAuthService auth;
  final profiles = FakeProfileService();
  final workers = FakeWorkerService();
  final jobs = FakeJobService();
  final reviews = FakeReviewService();
  final storage = FakeStorageService();
  final contractors = FakeContractorService();
  final verification = FakeVerificationService();

  AppState createState() => AppState(
    auth: auth,
    profiles: profiles,
    workers: workers,
    jobs: jobs,
    reviews: reviews,
    storage: storage,
    contractors: contractors,
    verification: verification,
  );
}

/// A signed-in customer who is also a registered worker, with loaded data.
Future<AppState> seededAppState() async {
  final backend = FakeBackend();
  backend.workers.own = testWorker(id: testUserId);
  final state = backend.createState();
  await state.bootstrap();
  return state;
}
