import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../data/repositories/department_repository.dart';
import '../../domain/models/department_model.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({
    super.key,
    this.apiClient,
    this.departmentRepository,
  });

  final ApiClient? apiClient;
  final DepartmentRepository? departmentRepository;

  @override
  State<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen> {
  late final DepartmentRepository _repository;
  List<DepartmentModel> _departments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.departmentRepository ??
        DepartmentRepositoryImpl(apiClient: widget.apiClient ?? ApiClient());
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getDepartments();
      if (!mounted) return;
      setState(() {
        _departments = list;
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

  Future<void> _showDepartmentDialog({DepartmentModel? editing}) async {
    final nameController = TextEditingController(text: editing?.name ?? '');
    final descController = TextEditingController(text: editing?.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editing == null ? 'Create Department' : 'Edit Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Department Name *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                if (editing == null) {
                  await _repository.createDepartment(
                    name: name,
                    description: descController.text.trim(),
                  );
                } else {
                  await _repository.updateDepartment(
                    id: editing.id,
                    name: name,
                    description: descController.text.trim(),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save department: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(editing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      _loadDepartments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        actions: [
          IconButton(
            tooltip: 'Add Department',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showDepartmentDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDepartmentDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text(
          'Add Department',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: AppLoadingIndicator(message: 'Loading departments...'))
            : _errorMessage != null
                ? AppErrorState(message: _errorMessage!, onRetry: _loadDepartments)
                : RefreshIndicator(
                    onRefresh: _loadDepartments,
                    child: _departments.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: AppSpacing.xxxl),
                              AppEmptyState(
                                title: 'No Departments Found',
                                message: 'Tap "Add Department" to create your first department.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: _departments.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final dept = _departments[index];
                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                  borderRadius: AppSpacing.borderRadiusLg,
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                  boxShadow: const [AppSpacing.shadow1],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(25),
                                        borderRadius: AppSpacing.borderRadiusMd,
                                      ),
                                      child: const Icon(
                                        Icons.business_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dept.name,
                                            style: AppTypography.titleMedium.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dept.description != null &&
                                                    dept.description!.isNotEmpty
                                                ? dept.description!
                                                : 'No description provided.',
                                            style: AppTypography.bodySmall.copyWith(
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      tooltip: 'Edit Department',
                                      onPressed: () => _showDepartmentDialog(editing: dept),
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
