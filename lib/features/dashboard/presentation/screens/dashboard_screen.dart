import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../tickets/data/repositories/ticket_repository.dart';
import '../../domain/models/dashboard_stats_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.authController,
    this.apiClient,
    this.ticketRepository,
  });

  final AuthController authController;
  final ApiClient? apiClient;
  final TicketRepository? ticketRepository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final TicketRepository _repository;
  DashboardStatsModel? _stats;
  MonthlyStatsModel? _monthlyStats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.ticketRepository != null) {
      _repository = widget.ticketRepository!;
    } else {
      _repository = TicketRepositoryImpl(
        apiClient: widget.apiClient ?? widget.authController.apiClient,
      );
    }
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _repository.getDashboardStats();
      MonthlyStatsModel? monthly;
      try {
        monthly = await _repository.getMonthlyStats();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _monthlyStats = monthly;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAdmin = widget.authController.state.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Helpdesk Operations'),
        actions: [
          IconButton(
            tooltip: 'Activity & Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => widget.authController.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: AppLoadingIndicator(message: 'Loading dashboard statistics...'),
              )
            : _errorMessage != null
                ? AppErrorState(message: _errorMessage!, onRetry: _loadDashboardData)
                : RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryHover],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: AppSpacing.borderRadiusXl,
                              boxShadow: const [AppSpacing.shadowMd],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back!',
                                  style: AppTypography.headlineSmall.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Here is your ticket overview and system performance summary.',
                                  style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          Text(
                            'Quick Actions',
                            style: AppTypography.titleMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionTile(
                                  title: 'Ticket Queue',
                                  subtitle: 'Triage open issues',
                                  icon: Icons.confirmation_number_outlined,
                                  color: AppColors.primary,
                                  onTap: () => context.push('/tickets'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildActionTile(
                                  title: 'Incident Catalog',
                                  subtitle: 'Report or browse',
                                  icon: Icons.grid_view_rounded,
                                  color: AppColors.info,
                                  onTap: () => context.push('/incident-catalog'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionTile(
                                  title: 'Categories',
                                  subtitle: 'Manage sub-issues',
                                  icon: Icons.category_outlined,
                                  color: AppColors.warning,
                                  onTap: () => context.push('/categories'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildActionTile(
                                  title: 'Ticket History',
                                  subtitle: 'Resolved archive',
                                  icon: Icons.history_rounded,
                                  color: AppColors.success,
                                  onTap: () => context.push('/user/history'),
                                ),
                              ),
                            ],
                          ),
                          if (isAdmin) ...[
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionTile(
                                    title: 'Users',
                                    subtitle: 'Manage accounts',
                                    icon: Icons.people_outline_rounded,
                                    color: Colors.purple,
                                    onTap: () => context.push('/users'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _buildActionTile(
                                    title: 'Departments',
                                    subtitle: 'Manage org units',
                                    icon: Icons.business_outlined,
                                    color: Colors.teal,
                                    onTap: () => context.push('/departments'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),

                          Text(
                            'Incident Metrics',
                            style: AppTypography.titleMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiCard(
                                  title: 'Total Tickets',
                                  count: _stats?.totalTickets ?? 0,
                                  icon: Icons.all_inbox_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildKpiCard(
                                  title: 'Pending',
                                  count: _stats?.pendingTickets ?? 0,
                                  icon: Icons.pending_actions_rounded,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiCard(
                                  title: 'In Progress',
                                  count: _stats?.inProgressTickets ?? 0,
                                  icon: Icons.timelapse_rounded,
                                  color: AppColors.info,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildKpiCard(
                                  title: 'Completed',
                                  count: _stats?.completedTickets ?? 0,
                                  icon: Icons.check_circle_rounded,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          if (isAdmin) ...[
                            const SizedBox(height: AppSpacing.md),
                            _buildKpiCard(
                              title: 'Total Active Users',
                              count: _stats?.totalUsers ?? 0,
                              icon: Icons.people_alt_rounded,
                              color: Colors.purple,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),

                          if (_monthlyStats != null) ...[
                            Text(
                              'Monthly Resolution Trends',
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                borderRadius: AppSpacing.borderRadiusLg,
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.circle, size: 10, color: AppColors.success),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Resolved (${_monthlyStats!.received.fold(0, (a, b) => a + b)})',
                                            style: AppTypography.labelMedium,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.circle, size: 10, color: AppColors.warning),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Due/Pending (${_monthlyStats!.due.fold(0, (a, b) => a + b)})',
                                            style: AppTypography.labelMedium,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Overview: Completed issues vs active backlog throughout the year.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusLg,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            count.toString(),
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
