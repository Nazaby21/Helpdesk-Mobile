class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.subCategories = const [],
  });

  final int id;
  final String name;
  final String? description;
  final int? parentId;
  final List<CategoryModel> subCategories;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      parentId: json['parentId'] as int?,
      subCategories: (json['subCategories'] as List<dynamic>?)
              ?.map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parentId': parentId,
      'subCategories': subCategories.map((e) => e.toJson()).toList(),
    };
  }
}
