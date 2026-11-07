import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../departments/data/repositories/department_repository.dart';
import '../../../departments/domain/models/department_model.dart';
import '../../../profile/domain/models/user_profile_model.dart';
import '../../data/repositories/user_repository.dart';

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({
    super.key,
    this.editingUser,
    this.apiClient,
    this.userRepository,
    this.departmentRepository,
  });

  final UserProfileModel? editingUser;
  final ApiClient? apiClient;
  final UserRepository? userRepository;
  final DepartmentRepository? departmentRepository;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();

  late String _selectedRole;
  int? _selectedDepartmentId;
  List<DepartmentModel> _departments = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  late final UserRepository _userRepo;
  late final DepartmentRepository _deptRepo;

  @override
  void initState() {
    super.initState();
    final u = widget.editingUser;
    _firstNameController = TextEditingController(text: u?.firstName ?? '');
    _lastNameController = TextEditingController(text: u?.lastName ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _phoneController = TextEditingController(text: u?.phoneNumber ?? '');
    _selectedRole = u?.role ?? 'USER';
    _selectedDepartmentId = u?.departmentId;

    final client = widget.apiClient ?? ApiClient();
    _userRepo = widget.userRepository ?? UserRepositoryImpl(apiClient: client);
    _deptRepo = widget.departmentRepository ?? DepartmentRepositoryImpl(apiClient: client);

    _loadDepartments();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final depts = await _deptRepo.getDepartments();
      if (!mounted) return;
      setState(() {
        _departments = depts;
        if (_selectedDepartmentId == null && depts.isNotEmpty) {
          _selectedDepartmentId = depts.first.id;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateDepartmentModal() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              try {
                if (widget.apiClient != null || widget.departmentRepository != null) {
                  final newDept = await _deptRepo.createDepartment(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                  );
                  _selectedDepartmentId = newDept.id;
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true) {
      _loadDepartments();
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a department.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final isEditing = widget.editingUser != null;
      if (widget.apiClient != null || widget.userRepository != null) {
        if (isEditing) {
          await _userRepo.updateUser(
            id: widget.editingUser!.id,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
            role: _selectedRole,
            departmentId: _selectedDepartmentId!,
          );
        } else {
          await _userRepo.createUser(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
            departmentId: _selectedDepartmentId!,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'User updated successfully!' : 'User created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingUser != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit User' : 'Add New User'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _firstNameController,
                        label: 'First Name *',
                        validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        controller: _lastNameController,
                        label: 'Last Name *',
                        validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _emailController,
                  label: 'Email Address *',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v.trim())) return 'Invalid email address';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _passwordController,
                  label: isEditing ? 'New Password (leave blank to keep)' : 'Password *',
                  isPassword: true,
                  validator: (v) {
                    if (!isEditing && (v == null || v.length < 4)) {
                      return 'Password must be at least 4 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Role Dropdown
                Text(
                  'User Role *',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                    border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusLg),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'USER', child: Text('Regular Employee (USER)')),
                    DropdownMenuItem(value: 'TECHNICIAN', child: Text('Technician (TECHNICIAN)')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Administrator (ADMIN)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Department Dropdown + Launcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Department *',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showCreateDepartmentModal,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ New Dept'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<int>(
                        initialValue: _selectedDepartmentId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                          border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusLg),
                        ),
                        items: _departments.map((dept) {
                          return DropdownMenuItem<int>(
                            value: dept.id,
                            child: Text(dept.name),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedDepartmentId = val),
                      ),
                const SizedBox(height: AppSpacing.xxl),

                AppButton(
                  text: isEditing ? 'Save Changes' : 'Create User',
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
