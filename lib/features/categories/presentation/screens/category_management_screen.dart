import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../data/repositories/category_repository.dart';
import '../../domain/models/category_model.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({
    super.key,
    this.apiClient,
    this.categoryRepository,
  });

  final ApiClient? apiClient;
  final CategoryRepository? categoryRepository;

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late final CategoryRepository _repository;
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.categoryRepository ??
        CategoryRepositoryImpl(apiClient: widget.apiClient ?? ApiClient());
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateCategoryDialog({int? parentId, String? parentName}) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(parentId == null ? 'Create Main Category' : 'Add Sub-Issue to $parentName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                await _repository.createCategory(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  parentId: parentId,
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Error creating category: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true) {
      _loadCategories();
    }
  }

  Future<void> _showEditCategoryDialog(CategoryModel cat, {int? parentId}) async {
    final nameController = TextEditingController(text: cat.name);
    final descController = TextEditingController(text: cat.description ?? '');

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(parentId == null ? 'Edit Category' : 'Edit Sub-Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                await _repository.updateCategory(
                  id: cat.id,
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  parentId: parentId ?? cat.parentId,
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Error updating category: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == true) {
      _loadCategories();
    }
  }

  Future<void> _handleDeleteCategory(CategoryModel cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${cat.name}"?'),
        content: const Text(
          'Warning: If this category is referenced by existing tickets, the backend will prevent deletion.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repository.deleteCategory(cat.id);
      _loadCategories();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "${cat.name}" deleted.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        actions: [
          IconButton(
            tooltip: 'Add Category',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showCreateCategoryDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: AppLoadingIndicator(message: 'Loading categories...'))
            : _errorMessage != null
                ? AppErrorState(message: _errorMessage!, onRetry: _loadCategories)
                : RefreshIndicator(
                    onRefresh: _loadCategories,
                    child: _categories.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: AppSpacing.xxxl),
                              AppEmptyState(
                                title: 'No Categories',
                                message: 'Click "+" above to create your first category.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: _categories.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                  borderRadius: AppSpacing.borderRadiusLg,
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.folder_outlined, color: AppColors.primary),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            cat.name,
                                            style: AppTypography.titleMedium.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 20),
                                          tooltip: 'Edit category',
                                          onPressed: () => _showEditCategoryDialog(cat),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_box_outlined, size: 20),
                                          tooltip: 'Add sub-issue template',
                                          onPressed: () => _showCreateCategoryDialog(
                                            parentId: cat.id,
                                            parentName: cat.name,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          tooltip: 'Delete category',
                                          onPressed: () => _handleDeleteCategory(cat),
                                        ),
                                      ],
                                    ),
                                    if (cat.description != null && cat.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        cat.description!,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                    const Divider(height: AppSpacing.xl),
                                    if (cat.subCategories.isEmpty)
                                      Text(
                                        'No sub-issues defined.',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.lightTextMuted,
                                        ),
                                      )
                                    else
                                      Column(
                                        children: cat.subCategories.map((sub) {
                                          return ListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            leading: const Icon(
                                              Icons.subdirectory_arrow_right_rounded,
                                              size: 18,
                                            ),
                                            title: Text(sub.name, style: AppTypography.bodyMedium),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                                  onPressed: () => _showEditCategoryDialog(
                                                    sub,
                                                    parentId: cat.id,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    size: 18,
                                                    color: AppColors.error,
                                                  ),
                                                  onPressed: () => _handleDeleteCategory(sub),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
      ),
    );
  }
}
