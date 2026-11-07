import 'package:helpdesk_mobile/app/constants/api_endpoints.dart';
import 'package:helpdesk_mobile/core/network/api_client.dart';
import '../../domain/models/department_model.dart';

abstract class DepartmentRepository {
  Future<List<DepartmentModel>> getDepartments();
  Future<DepartmentModel> getDepartmentById(int id);
  Future<DepartmentModel> createDepartment({
    required String name,
    String? description,
  });
  Future<DepartmentModel> updateDepartment({
    required int id,
    required String name,
    String? description,
  });
}

class DepartmentRepositoryImpl implements DepartmentRepository {
  const DepartmentRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<DepartmentModel>> getDepartments() async {
    final response = await apiClient.get(ApiEndpoints.departments);
    final data = response.data as List<dynamic>;
    return data
        .map((item) => DepartmentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DepartmentModel> getDepartmentById(int id) async {
    final response = await apiClient.get(ApiEndpoints.departmentById(id));
    return DepartmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<DepartmentModel> createDepartment({
    required String name,
    String? description,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.departments,
      data: {
        'name': name.trim(),
        'description': ?(description != null && description.isNotEmpty ? description.trim() : null),
      },
    );
    return DepartmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<DepartmentModel> updateDepartment({
    required int id,
    required String name,
    String? description,
  }) async {
    final response = await apiClient.put(
      ApiEndpoints.departmentById(id),
      data: {
        'name': name.trim(),
        'description': ?(description != null && description.isNotEmpty ? description.trim() : null),
      },
    );
    return DepartmentModel.fromJson(response.data as Map<String, dynamic>);
  }
}
