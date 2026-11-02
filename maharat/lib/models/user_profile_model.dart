enum UserRole { customer, worker }

class UserProfileModel {
  final String name;
  final String phone;
  final UserRole userRole;
  final String language; // "English", "Urdu", "Roman Urdu"
  final String neighbourhood;
  final bool isWorkerRegistered;
  final bool isCnicVerified;

  UserProfileModel({
    required this.name,
    required this.phone,
    required this.userRole,
    required this.language,
    required this.neighbourhood,
    this.isWorkerRegistered = false,
    this.isCnicVerified = false,
  });

  UserProfileModel copyWith({
    String? name,
    String? phone,
    UserRole? userRole,
    String? language,
    String? neighbourhood,
    bool? isWorkerRegistered,
    bool? isCnicVerified,
  }) {
    return UserProfileModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      userRole: userRole ?? this.userRole,
      language: language ?? this.language,
      neighbourhood: neighbourhood ?? this.neighbourhood,
      isWorkerRegistered: isWorkerRegistered ?? this.isWorkerRegistered,
      isCnicVerified: isCnicVerified ?? this.isCnicVerified,
    );
  }
}
