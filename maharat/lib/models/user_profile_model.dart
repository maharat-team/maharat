enum UserRole { customer, worker }

class UserProfileModel {
  final String id;
  final String name;
  final String phone;
  final UserRole userRole;
  final String language; // "English" or "Urdu"
  final String neighbourhood;
  final bool isWorkerRegistered;
  final bool isCnicVerified;

  UserProfileModel({
    this.id = '',
    required this.name,
    required this.phone,
    required this.userRole,
    required this.language,
    required this.neighbourhood,
    this.isWorkerRegistered = false,
    this.isCnicVerified = false,
  });

  factory UserProfileModel.guest() => UserProfileModel(
    name: '',
    phone: '',
    userRole: UserRole.customer,
    language: 'English',
    neighbourhood: '',
  );

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      userRole: UserRole.values.byName(json['active_role'] as String),
      language: json['language'] as String? ?? 'English',
      neighbourhood: json['neighbourhood'] as String? ?? '',
    );
  }

  bool get isComplete =>
      name.trim().isNotEmpty && phone.isNotEmpty && neighbourhood.isNotEmpty;

  UserProfileModel copyWith({
    String? id,
    String? name,
    String? phone,
    UserRole? userRole,
    String? language,
    String? neighbourhood,
    bool? isWorkerRegistered,
    bool? isCnicVerified,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
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
