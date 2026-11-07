import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../tickets/data/repositories/ticket_repository.dart';
import '../../../users/data/repositories/user_repository.dart';
import '../../domain/models/user_profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authController,
    this.apiClient,
    this.userRepository,
  });

  final AuthController authController;
  final ApiClient? apiClient;
  final UserRepository? userRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ApiClient _client;
  late final UserRepository _repository;
  late final TicketRepository _ticketRepo;
  UserProfileModel? _profile;
  bool _isLoading = true;
  bool _pushNotificationsEnabled = false;
  String? _errorMessage;

  static final List<int> _sampleAvatarPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  );

  @override
  void initState() {
    super.initState();
    _client = widget.apiClient ?? widget.authController.apiClient;
    _repository = widget.userRepository ?? UserRepositoryImpl(apiClient: _client);
    _ticketRepo = TicketRepositoryImpl(apiClient: _client);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _repository.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _profile = profile;
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

  Future<void> _showEditProfileDialog() async {
    if (_profile == null) return;
    final firstNameCtrl = TextEditingController(text: _profile!.firstName);
    final lastNameCtrl = TextEditingController(text: _profile!.lastName);
    final phoneCtrl = TextEditingController(text: _profile!.phoneNumber ?? '');
    final passwordCtrl = TextEditingController();
    String? avatarUrl = _profile!.imageUrl;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Edit My Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'First Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: lastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Last Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Avatar Photo:'),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          final uploaded = await _ticketRepo.uploadImage(
                            _sampleAvatarPng,
                            'avatar_${_profile!.id}_${DateTime.now().millisecondsSinceEpoch}.png',
                          );
                          if (uploaded.isNotEmpty) {
                            setModalState(() => avatarUrl = uploaded);
                          }
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text(avatarUrl != null && avatarUrl!.isNotEmpty ? 'Replace' : 'Upload'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty) return;
                try {
                  final updated = await _repository.updateCurrentUser(
                    firstName: firstNameCtrl.text.trim(),
                    lastName: lastNameCtrl.text.trim(),
                    phoneNumber: phoneCtrl.text.trim(),
                    imageUrl: avatarUrl,
                    password: passwordCtrl.text.trim().isNotEmpty
                        ? passwordCtrl.text.trim()
                        : null,
                  );
                  if (mounted) {
                    setState(() => _profile = updated);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update profile: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _togglePushNotifications(bool enabled) async {
    final token = 'local-android-token-${_profile?.id ?? 0}';
    try {
      if (enabled) {
        await _repository.registerDeviceToken(token: token);
      } else {
        await _repository.unregisterDeviceToken(token);
      }
      if (!mounted) return;
      setState(() => _pushNotificationsEnabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Device token registered for notifications.'
                : 'Device token unregistered.',
          ),
          backgroundColor: AppColors.info,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification token error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (_profile != null)
            IconButton(
              tooltip: 'Edit Profile',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _showEditProfileDialog,
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: AppLoadingIndicator(message: 'Loading user profile...'))
            : _errorMessage != null && _profile == null
                ? AppErrorState(message: _errorMessage!, onRetry: _loadProfile)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: AppSpacing.borderRadiusXl,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            boxShadow: const [AppSpacing.shadow1],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: AppColors.primary,
                                backgroundImage: _profile?.imageUrl != null &&
                                        _profile!.imageUrl!.isNotEmpty
                                    ? NetworkImage(UrlUtils.resolveImageUrl(_profile!.imageUrl))
                                    : null,
                                child: _profile?.imageUrl == null || _profile!.imageUrl!.isEmpty
                                    ? Text(
                                        _profile != null && _profile!.firstName.isNotEmpty
                                            ? _profile!.firstName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _profile?.fullName.isNotEmpty == true
                                    ? _profile!.fullName
                                    : 'Helpdesk User',
                                style: AppTypography.titleLarge.copyWith(
                                  color:
                                      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _profile?.email ?? '',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              if (_profile?.phoneNumber != null &&
                                  _profile!.phoneNumber!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _profile!.phoneNumber!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppBadge(
                                    label: _profile?.role ?? 'USER',
                                    variant: _profile?.role == 'ADMIN'
                                        ? AppBadgeVariant.error
                                        : (_profile?.role == 'TECHNICIAN'
                                            ? AppBadgeVariant.info
                                            : AppBadgeVariant.neutral),
                                  ),
                                  if (_profile?.departmentName != null) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            isDark ? AppColors.darkInput : AppColors.lightBackground,
                                        borderRadius: AppSpacing.borderRadiusSm,
                                      ),
                                      child: Text(
                                        _profile!.departmentName!,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton.icon(
                                onPressed: _showEditProfileDialog,
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Edit Personal Info & Photo'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        Text(
                          'Ticket Activity Metrics',
                          style: AppTypography.titleMedium.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                'Created',
                                _profile?.ticketsCreated ?? 0,
                                Icons.add_circle_outline,
                                AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _buildMetricTile(
                                'Assigned',
                                _profile?.ticketsAssigned ?? 0,
                                Icons.assignment_ind_outlined,
                                AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                'Open',
                                _profile?.ticketsOpen ?? 0,
                                Icons.pending_actions_outlined,
                                AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _buildMetricTile(
                                'Resolved',
                                _profile?.ticketsResolved ?? 0,
                                Icons.task_alt,
                                AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        Text(
                          'Settings & Information',
                          style: AppTypography.titleMedium.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: AppSpacing.borderRadiusLg,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                secondary: const Icon(Icons.notifications_active_outlined),
                                title: const Text('Push Notifications'),
                                subtitle: const Text('Register device token with backend'),
                                value: _pushNotificationsEnabled,
                                onChanged: _togglePushNotifications,
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.dns_outlined),
                                title: const Text('API Base URL'),
                                subtitle: Text(
                                  widget.authController.apiClient.config.apiBaseUrl,
                                  style: AppTypography.labelSmall,
                                ),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.phonelink_setup_rounded),
                                title: const Text('Environment'),
                                subtitle: Text(
                                  widget.authController.apiClient.config.environment.name
                                      .toUpperCase(),
                                  style: AppTypography.labelSmall,
                                ),
                              ),
                              const Divider(height: 1),
                              const ListTile(
                                leading: Icon(Icons.info_outline_rounded),
                                title: Text('App Version'),
                                subtitle: Text('v1.0.0+1 (Flutter Native Android)'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        AppButton(
                          text: 'Sign Out',
                          variant: AppButtonVariant.danger,
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Sign Out'),
                                content:
                                    const Text('Are you sure you want to log out of Helpdesk?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style:
                                        ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                    child: const Text(
                                      'Sign Out',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await widget.authController.logout();
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildMetricTile(String label, int value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
