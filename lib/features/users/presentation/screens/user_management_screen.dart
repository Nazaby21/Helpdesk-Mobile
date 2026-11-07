import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../profile/domain/models/user_profile_model.dart';
import '../../data/repositories/user_repository.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({
    super.key,
    this.apiClient,
    this.userRepository,
  });

  final ApiClient? apiClient;
  final UserRepository? userRepository;

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late final UserRepository _repository;
  List<UserProfileModel> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = widget.userRepository ??
        UserRepositoryImpl(apiClient: widget.apiClient ?? ApiClient());
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = list;
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

  Future<void> _handleDeleteUser(UserProfileModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete User ${user.fullName}?'),
        content: Text(
          'Are you sure you want to deactivate ${user.email}? This action performs a soft-delete.',
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
      await _repository.deleteUser(user.id);
      _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${user.fullName} deleted.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  AppBadgeVariant _roleBadgeVariant(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return AppBadgeVariant.error;
      case 'TECHNICIAN':
        return AppBadgeVariant.info;
      case 'USER':
      default:
        return AppBadgeVariant.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredUsers = _users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final inName = u.fullName.toLowerCase().contains(q);
      final inEmail = u.email.toLowerCase().contains(q);
      final inRole = u.role.toLowerCase().contains(q);
      final inDept = u.departmentName?.toLowerCase().contains(q) ?? false;
      return inName || inEmail || inRole || inDept;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/users/add');
          _loadUsers();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add User',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or role...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: AppLoadingIndicator(message: 'Loading user directory...'))
                  : _errorMessage != null
                      ? AppErrorState(message: _errorMessage!, onRetry: _loadUsers)
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          child: filteredUsers.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: AppSpacing.xxxl),
                                    AppEmptyState(
                                      title: 'No Users Found',
                                      message: 'No user accounts match your search filters.',
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                  itemCount: filteredUsers.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: AppSpacing.md),
                                  itemBuilder: (context, index) {
                                    final user = filteredUsers[index];
                                    return Container(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                        borderRadius: AppSpacing.borderRadiusLg,
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder,
                                        ),
                                        boxShadow: const [AppSpacing.shadow1],
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: AppColors.primary,
                                            child: Text(
                                              user.firstName.isNotEmpty
                                                  ? user.firstName[0].toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.fullName,
                                                  style: AppTypography.titleMedium.copyWith(
                                                    color: isDark
                                                        ? AppColors.darkTextPrimary
                                                        : AppColors.lightTextPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  user.email,
                                                  style: AppTypography.labelSmall.copyWith(
                                                    color: isDark
                                                        ? AppColors.darkTextMuted
                                                        : AppColors.lightTextMuted,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    AppBadge(
                                                      label: user.role,
                                                      variant: _roleBadgeVariant(user.role),
                                                    ),
                                                    if (user.departmentName != null) ...[
                                                      const SizedBox(width: AppSpacing.xs),
                                                      Text(
                                                        '• ${user.departmentName!}',
                                                        style: AppTypography.labelSmall.copyWith(
                                                          color: isDark
                                                              ? AppColors.darkTextSecondary
                                                              : AppColors.lightTextSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20),
                                            tooltip: 'Edit User',
                                            onPressed: () async {
                                              await context.push(
                                                '/users/${user.id}/edit',
                                                extra: user,
                                              );
                                              _loadUsers();
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: AppColors.error,
                                              size: 20,
                                            ),
                                            tooltip: 'Delete User',
                                            onPressed: () => _handleDeleteUser(user),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
