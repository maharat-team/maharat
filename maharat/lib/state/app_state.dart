import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../models/worker_model.dart';
import '../models/job_request_model.dart';
import '../models/review_model.dart';

class AppState extends ChangeNotifier {
  UserProfileModel _currentUser = UserProfileModel(
    name: 'Ahmed Khan',
    phone: '+92 300 1234567',
    userRole: UserRole.customer,
    language: 'English',
    neighbourhood: 'Model Town A',
    isWorkerRegistered: false,
    isCnicVerified: false,
  );

  WorkerModel _workerProfile = WorkerModel(
    id: 'w_user_1',
    name: 'Ahmed Khan',
    trade: 'Electrician',
    phone: '+92 300 1234567',
    rating: 4.8,
    reviewCount: 14,
    experienceYears: 5,
    visitFee: 300,
    neighbourhood: 'Model Town A',
    serviceAreas: ['Model Town A', 'Model Town B', 'Satellite Town'],
    bio: 'Experienced electrician specializing in residential wiring, breaker panels, UPS setup, and LED lighting solutions.',
    isCnicVerified: true,
    isAvailableToday: true,
    workPhotos: [],
    reviews: [
      ReviewModel(
        id: 'r_w1',
        customerName: 'Muhammad Salman',
        rating: 5.0,
        comment: 'Quick response and fixed the main breaker issue within 30 minutes.',
        tags: ['On time', 'Fair price', 'Skilled'],
        date: '2 days ago',
      ),
    ],
    completedJobsCount: 18,
  );

  final List<WorkerModel> _workers = [
    WorkerModel(
      id: 'w_1',
      name: 'Mohammad Tariq',
      trade: 'Electrician',
      phone: '+92 301 8765432',
      rating: 4.9,
      reviewCount: 42,
      experienceYears: 8,
      visitFee: 300,
      neighbourhood: 'Model Town A',
      serviceAreas: ['Model Town A', 'Model Town B', 'Satellite Town', 'Dubai Mahal Road'],
      bio: 'Certified Master Electrician with 8+ years experience in Bahawalpur. Expert in short circuit troubleshooting, UPS installation, DB boxes, and smart home wiring.',
      isCnicVerified: true,
      isAvailableToday: true,
      workPhotos: [
        'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=600&q=80',
      ],
      reviews: [
        ReviewModel(
          id: 'r1',
          customerName: 'Usman Ali',
          rating: 5.0,
          comment: 'Very professional electrician. Fixed the short circuit in my house cleanly and charged fair rate.',
          tags: ['On time', 'Clean work', 'Fair price'],
          date: 'Yesterday',
        ),
        ReviewModel(
          id: 'r2',
          customerName: 'Dr. Shahzad',
          rating: 4.8,
          comment: 'Arrived on time and explained the issue with UPS wiring clearly.',
          tags: ['Polite', 'Explained well'],
          date: '4 days ago',
        ),
      ],
      completedJobsCount: 84,
    ),
    WorkerModel(
      id: 'w_2',
      name: 'Rashid Mahmood',
      trade: 'Plumber',
      phone: '+92 302 9876543',
      rating: 4.8,
      reviewCount: 58,
      experienceYears: 12,
      visitFee: 200,
      neighbourhood: 'Satellite Town',
      serviceAreas: ['Satellite Town', 'Model Town A', 'One Unit Staff Colony', 'Commercial Area'],
      bio: 'Expert plumber for water tank cleaning, concealed pipe leaks, bathroom sanitary fittings, and motor installation.',
      isCnicVerified: true,
      isAvailableToday: true,
      workPhotos: [],
      reviews: [
        ReviewModel(
          id: 'r3',
          customerName: 'Bilal Hassan',
          rating: 5.0,
          comment: 'Resolved severe water blockage in master bathroom. Highly recommended!',
          tags: ['Skilled', 'Clean work'],
          date: '3 days ago',
        ),
      ],
      completedJobsCount: 110,
    ),
    WorkerModel(
      id: 'w_3',
      name: 'Umer Farooq',
      trade: 'AC Technician',
      phone: '+92 303 1122334',
      rating: 4.9,
      reviewCount: 31,
      experienceYears: 6,
      visitFee: 500,
      neighbourhood: 'Model Town B',
      serviceAreas: ['Model Town A', 'Model Town B', 'University Town', 'Cantonment'],
      bio: 'Inverter AC specialist. Complete jet wash service, R410/R32 gas charging, PCB repair, and new unit installation.',
      isCnicVerified: true,
      isAvailableToday: true,
      workPhotos: [],
      reviews: [
        ReviewModel(
          id: 'r4',
          customerName: 'Tariq Jameel',
          rating: 5.0,
          comment: 'Did complete chemical wash of my split AC. Cooling is now amazing!',
          tags: ['Clean work', 'Explained well', 'On time'],
          date: '1 week ago',
        ),
      ],
      completedJobsCount: 52,
    ),
    WorkerModel(
      id: 'w_4',
      name: 'Master Ghulam Abbas',
      trade: 'Mason',
      phone: '+92 304 4455667',
      rating: 4.7,
      reviewCount: 64,
      experienceYears: 15,
      visitFee: 0,
      neighbourhood: 'One Unit Staff Colony',
      serviceAreas: ['One Unit Staff Colony', 'Farid Gate', 'Trust Colony', 'Satellite Town'],
      bio: 'Master mason with 15 years experience in tile fitting, boundary walls, floor plaster, and brick renovation.',
      isCnicVerified: true,
      isAvailableToday: true,
      workPhotos: [],
      reviews: [
        ReviewModel(
          id: 'r5',
          customerName: 'Kashif Mehmood',
          rating: 4.5,
          comment: 'Did excellent tile work in kitchen. Solid craftsmanship.',
          tags: ['Skilled', 'Fair price'],
          date: '2 weeks ago',
        ),
      ],
      completedJobsCount: 140,
    ),
    WorkerModel(
      id: 'w_5',
      name: 'Khalid Hussain',
      trade: 'Carpenter',
      phone: '+92 305 7788990',
      rating: 4.8,
      reviewCount: 29,
      experienceYears: 10,
      visitFee: 300,
      neighbourhood: 'Dubai Mahal Road',
      serviceAreas: ['Dubai Mahal Road', 'Model Town A', 'Cantonment'],
      bio: 'Custom wooden door installation, lock replacement, wardrobe repair, and polish work.',
      isCnicVerified: true,
      isAvailableToday: false,
      workPhotos: [],
      reviews: [],
      completedJobsCount: 45,
    ),
    WorkerModel(
      id: 'w_6',
      name: 'Asif Raza',
      trade: 'Painter',
      phone: '+92 306 3344556',
      rating: 4.6,
      reviewCount: 22,
      experienceYears: 7,
      visitFee: 0,
      neighbourhood: 'University Town',
      serviceAreas: ['University Town', 'Model Town B', 'Trust Colony'],
      bio: 'Interior plastic emulsion, exterior weather sheet coating, wood varnish, and wall putty finish.',
      isCnicVerified: true,
      isAvailableToday: true,
      workPhotos: [],
      reviews: [],
      completedJobsCount: 38,
    ),
    WorkerModel(
      id: 'w_7',
      name: 'Zubair Ahmed',
      trade: 'Electrician',
      phone: '+92 307 2233445',
      rating: 4.7,
      reviewCount: 19,
      experienceYears: 5,
      visitFee: 250,
      neighbourhood: 'Cantonment',
      serviceAreas: ['Cantonment', 'Model Town A', 'Satellite Town'],
      bio: 'Fast electrician for ceiling lights, fancy lights, washing machine motor wiring, and main switchboard repair.',
      isCnicVerified: true,
      isAvailableToday: true,
      workPhotos: [],
      reviews: [],
      completedJobsCount: 29,
    ),
  ];

  late List<JobRequestModel> _jobRequests;

  AppState() {
    _jobRequests = [
      JobRequestModel(
        id: 'job_101',
        customerName: 'Ahmed Khan',
        customerPhone: '+92 300 1234567',
        tradeCategory: 'Electrician',
        description: 'UPS battery wiring is sparky and living room ceiling fan switch needs replacement.',
        hasVoiceNote: true,
        photoUrls: ['https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=400&q=80'],
        location: 'Model Town A',
        urgency: 'Today',
        status: 'Active',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        interestedWorkers: [
          _workers[0], // Mohammad Tariq
          _workers[6], // Zubair Ahmed
        ],
      ),
      JobRequestModel(
        id: 'job_102',
        customerName: 'Ahmed Khan',
        customerPhone: '+92 300 1234567',
        tradeCategory: 'Plumber',
        description: 'Kitchen sink tap leaking heavily and main bathroom water line pressure is low.',
        location: 'Satellite Town',
        urgency: 'Tomorrow',
        status: 'Active',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        interestedWorkers: [
          _workers[1], // Rashid Mahmood
        ],
      ),
      JobRequestModel(
        id: 'job_103',
        customerName: 'Ahmed Khan',
        customerPhone: '+92 300 1234567',
        tradeCategory: 'AC Technician',
        description: 'Split AC 1.5 Ton Master Chemical Wash & Gas Refill before summer.',
        location: 'Model Town A',
        urgency: 'Any Day',
        status: 'Completed',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        interestedWorkers: [_workers[2]],
        assignedWorkerName: 'Umer Farooq',
        ratingGiven: 5.0,
        reviewComment: 'Outstanding service by Umer Farooq. Cooling performance restored completely.',
      ),
    ];
  }

  // Getters
  UserProfileModel get currentUser => _currentUser;
  WorkerModel get workerProfile => _workerProfile;
  List<WorkerModel> get workers => List.unmodifiable(_workers);
  List<JobRequestModel> get jobRequests => List.unmodifiable(_jobRequests);

  List<JobRequestModel> get activeJobRequests =>
      _jobRequests.where((j) => j.status == 'Active').toList();

  List<JobRequestModel> get completedJobRequests =>
      _jobRequests.where((j) => j.status == 'Completed').toList();

  List<JobRequestModel> get closedJobRequests =>
      _jobRequests.where((j) => j.status == 'Closed').toList();

  // Setters & Actions
  void setLanguage(String lang) {
    _currentUser = _currentUser.copyWith(language: lang);
    notifyListeners();
  }

  void setUserRole(UserRole role) {
    _currentUser = _currentUser.copyWith(userRole: role);
    notifyListeners();
  }

  void updateProfile({String? name, String? phone, String? neighbourhood}) {
    _currentUser = _currentUser.copyWith(
      name: name ?? _currentUser.name,
      phone: phone ?? _currentUser.phone,
      neighbourhood: neighbourhood ?? _currentUser.neighbourhood,
    );
    notifyListeners();
  }

  void addJobRequest(JobRequestModel newJob) {
    _jobRequests.insert(0, newJob);
    notifyListeners();
  }

  void closeJobRequest(String jobId) {
    final index = _jobRequests.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      _jobRequests[index] = _jobRequests[index].copyWith(status: 'Closed');
      notifyListeners();
    }
  }

  void completeJobRequest(String jobId, {String? workerName}) {
    final index = _jobRequests.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      _jobRequests[index] = _jobRequests[index].copyWith(
        status: 'Completed',
        assignedWorkerName: workerName ?? _jobRequests[index].assignedWorkerName,
      );
      notifyListeners();
    }
  }

  void addReviewToWorker({
    required String workerId,
    required String jobId,
    required double rating,
    required String comment,
    required List<String> tags,
  }) {
    final workerIndex = _workers.indexWhere((w) => w.id == workerId);
    if (workerIndex != -1) {
      final worker = _workers[workerIndex];
      final newReview = ReviewModel(
        id: 'r_${DateTime.now().millisecondsSinceEpoch}',
        customerName: _currentUser.name,
        rating: rating,
        comment: comment,
        tags: tags,
        date: 'Just now',
      );

      final updatedReviews = List<ReviewModel>.from(worker.reviews)..insert(0, newReview);
      final newCount = worker.reviewCount + 1;
      final newAvgRating = double.parse(
        (((worker.rating * worker.reviewCount) + rating) / newCount).toStringAsFixed(1),
      );

      _workers[workerIndex] = worker.copyWith(
        rating: newAvgRating,
        reviewCount: newCount,
        reviews: updatedReviews,
        completedJobsCount: worker.completedJobsCount + 1,
      );
    }

    // Update job request
    final jobIndex = _jobRequests.indexWhere((j) => j.id == jobId);
    if (jobIndex != -1) {
      _jobRequests[jobIndex] = _jobRequests[jobIndex].copyWith(
        ratingGiven: rating,
        reviewComment: comment,
      );
    }

    notifyListeners();
  }

  void registerWorker(WorkerModel newWorker) {
    _workerProfile = newWorker;
    _currentUser = _currentUser.copyWith(
      isWorkerRegistered: true,
      userRole: UserRole.worker,
    );
    _workers.insert(0, newWorker);
    notifyListeners();
  }

  void setWorkerCnicVerified(bool status) {
    _workerProfile = _workerProfile.copyWith(isCnicVerified: status);
    _currentUser = _currentUser.copyWith(isCnicVerified: status);
    notifyListeners();
  }

  void toggleWorkerAvailability(bool isAvailable) {
    _workerProfile = _workerProfile.copyWith(isAvailableToday: isAvailable);
    notifyListeners();
  }

  void workerRespondToJob(String jobId) {
    final index = _jobRequests.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      final job = _jobRequests[index];
      if (!job.interestedWorkers.any((w) => w.id == _workerProfile.id)) {
        final updatedInterested = List<WorkerModel>.from(job.interestedWorkers)..add(_workerProfile);
        _jobRequests[index] = job.copyWith(interestedWorkers: updatedInterested);
        notifyListeners();
      }
    }
  }

  bool isUrdu() => _currentUser.language == 'Urdu';
}
