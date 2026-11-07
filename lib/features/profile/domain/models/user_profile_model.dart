class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.imageUrl,
    required this.role,
    this.departmentId,
    this.departmentName,
    this.createdAt,
    this.updatedAt,
    this.ticketsCreated = 0,
    this.ticketsAssigned = 0,
    this.ticketsResolved = 0,
    this.ticketsOpen = 0,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? imageUrl;
  final String role;
  final int? departmentId;
  final String? departmentName;
  final String? createdAt;
  final String? updatedAt;
  final int ticketsCreated;
  final int ticketsAssigned;
  final int ticketsResolved;
  final int ticketsOpen;

  String get fullName => '$firstName $lastName'.trim();

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as int? ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      imageUrl: json['imageUrl'] as String?,
      role: json['role'] as String? ?? 'USER',
      departmentId: json['departmentId'] as int?,
      departmentName: json['departmentName'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      ticketsCreated: json['ticketsCreated'] as int? ?? 0,
      ticketsAssigned: json['ticketsAssigned'] as int? ?? 0,
      ticketsResolved: json['ticketsResolved'] as int? ?? 0,
      ticketsOpen: json['ticketsOpen'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'role': role,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'ticketsCreated': ticketsCreated,
      'ticketsAssigned': ticketsAssigned,
      'ticketsResolved': ticketsResolved,
      'ticketsOpen': ticketsOpen,
    };
  }
}
