import 'package:helpdesk_mobile/app/constants/api_endpoints.dart';
import 'package:helpdesk_mobile/core/network/api_client.dart';
import '../../../profile/domain/models/user_profile_model.dart';

abstract class UserRepository {
  Future<UserProfileModel> getCurrentUser();
  Future<UserProfileModel> updateCurrentUser({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
    String? password,
  });
  Future<List<UserProfileModel>> getAllUsers();
  Future<UserProfileModel> getUserById(int id);
  Future<UserProfileModel> createUser({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    required String password,
    String? imageUrl,
    required String role,
    required int departmentId,
  });
  Future<UserProfileModel> updateUser({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    String? password,
    String? imageUrl,
    required String role,
    required int departmentId,
  });
  Future<void> deleteUser(int id);
  Future<void> registerDeviceToken({required String token, String deviceType = 'ANDROID'});
  Future<void> unregisterDeviceToken(String token);
}

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<UserProfileModel> getCurrentUser() async {
    final response = await apiClient.get(ApiEndpoints.userMe);
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserProfileModel> updateCurrentUser({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
    String? password,
  }) async {
    final response = await apiClient.put(
      ApiEndpoints.userMe,
      data: {
        if (firstName != null) 'firstName': firstName.trim(),
        if (lastName != null) 'lastName': lastName.trim(),
        if (phoneNumber != null) 'phoneNumber': phoneNumber.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl.trim(),
        if (password != null && password.trim().isNotEmpty) 'password': password.trim(),
      },
    );
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<UserProfileModel>> getAllUsers() async {
    final response = await apiClient.get(ApiEndpoints.users);
    final data = response.data;
    if (data is List) {
      return data
          .map((item) => UserProfileModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((item) => UserProfileModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<UserProfileModel> getUserById(int id) async {
    final response = await apiClient.get(ApiEndpoints.userById(id));
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserProfileModel> createUser({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    required String password,
    String? imageUrl,
    required String role,
    required int departmentId,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.users,
      data: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'phoneNumber': ?(phoneNumber != null && phoneNumber.isNotEmpty ? phoneNumber.trim() : null),
        'password': password,
        'imageUrl': ?(imageUrl != null && imageUrl.isNotEmpty ? imageUrl.trim() : null),
        'role': role,
        'departmentId': departmentId,
      },
    );
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserProfileModel> updateUser({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    String? password,
    String? imageUrl,
    required String role,
    required int departmentId,
  }) async {
    final response = await apiClient.put(
      ApiEndpoints.userById(id),
      data: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'phoneNumber': ?(phoneNumber != null && phoneNumber.isNotEmpty ? phoneNumber.trim() : null),
        'password': ?(password != null && password.isNotEmpty ? password : null),
        'imageUrl': ?(imageUrl != null && imageUrl.isNotEmpty ? imageUrl.trim() : null),
        'role': role,
        'departmentId': departmentId,
      },
    );
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteUser(int id) async {
    await apiClient.delete(ApiEndpoints.userById(id));
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    String deviceType = 'ANDROID',
  }) async {
    await apiClient.post(
      ApiEndpoints.deviceToken,
      data: {
        'token': token,
        'deviceType': deviceType,
      },
    );
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    await apiClient.delete(
      '${ApiEndpoints.deviceToken}?token=${Uri.encodeQueryComponent(token)}',
    );
  }
}
