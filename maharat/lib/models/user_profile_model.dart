import 'package:latlong2/latlong.dart';
import '../core/utils/geo.dart';

enum UserRole { customer, worker, contractor }

class UserProfileModel {
  final String id;
  final String name;
  final String phone;
  final UserRole userRole;
  final String language; // "English" or "Urdu"
  final String neighbourhood;
  final LatLng? location;
  final String addressDetails;
  final bool isWorkerRegistered;
  final bool isCnicVerified;
  final bool isContractorRegistered;
  final bool isContractorVerified;

  UserProfileModel({
    this.id = '',
    required this.name,
    required this.phone,
    required this.userRole,
    required this.language,
    required this.neighbourhood,
    this.location,
    this.addressDetails = '',
    this.isWorkerRegistered = false,
    this.isCnicVerified = false,
    this.isContractorRegistered = false,
    this.isContractorVerified = false,
  });

  factory UserProfileModel.guest({String language = 'English'}) =>
      UserProfileModel(
        name: '',
        phone: '',
        userRole: UserRole.customer,
        language: language,
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
      location: latLngOrNull(json['lat'], json['lng']),
      addressDetails: json['address_details'] as String? ?? '',
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
    LatLng? location,
    String? addressDetails,
    bool? isWorkerRegistered,
    bool? isCnicVerified,
    bool? isContractorRegistered,
    bool? isContractorVerified,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      userRole: userRole ?? this.userRole,
      language: language ?? this.language,
      neighbourhood: neighbourhood ?? this.neighbourhood,
      location: location ?? this.location,
      addressDetails: addressDetails ?? this.addressDetails,
      isWorkerRegistered: isWorkerRegistered ?? this.isWorkerRegistered,
      isCnicVerified: isCnicVerified ?? this.isCnicVerified,
      isContractorRegistered:
          isContractorRegistered ?? this.isContractorRegistered,
      isContractorVerified: isContractorVerified ?? this.isContractorVerified,
    );
  }
}
