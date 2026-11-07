import 'package:helpdesk_mobile/app/constants/api_endpoints.dart';
import 'package:helpdesk_mobile/core/network/api_client.dart';
import '../../domain/models/category_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> getCategoryById(int id);
  Future<CategoryModel> createCategory({
    required String name,
    String? description,
    int? parentId,
  });
  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    String? description,
    int? parentId,
  });
  Future<void> deleteCategory(int id);
}

class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await apiClient.get(ApiEndpoints.categories);
    final data = response.data as List<dynamic>;
    return data
        .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CategoryModel> getCategoryById(int id) async {
    final response = await apiClient.get(ApiEndpoints.categoryById(id));
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CategoryModel> createCategory({
    required String name,
    String? description,
    int? parentId,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.categories,
      data: {
        'name': name.trim(),
        if (description != null && description.isNotEmpty) 'description': description.trim(),
        'parentId': ?parentId,
      },
    );
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    String? description,
    int? parentId,
  }) async {
    final response = await apiClient.put(
      ApiEndpoints.categoryById(id),
      data: {
        'name': name.trim(),
        if (description != null && description.isNotEmpty) 'description': description.trim(),
        'parentId': ?parentId,
      },
    );
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCategory(int id) async {
    await apiClient.delete(ApiEndpoints.categoryById(id));
  }
}
