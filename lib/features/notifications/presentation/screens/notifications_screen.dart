import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../tickets/data/repositories/ticket_repository.dart';
import '../../../tickets/domain/models/ticket_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.apiClient,
    this.ticketRepository,
  });

  final ApiClient? apiClient;
  final TicketRepository? ticketRepository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final TicketRepository _repository;
  List<ActivityNotificationModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.ticketRepository ??
        TicketRepositoryImpl(apiClient: widget.apiClient ?? ApiClient());
    _loadActivityFeed();
  }

  Future<void> _loadActivityFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getActivityFeed();
      if (!mounted) return;
      setState(() {
        _items = list;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity & Notifications'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadActivityFeed,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: AppLoadingIndicator(message: 'Loading activity feed...'))
            : _errorMessage != null
                ? AppErrorState(message: _errorMessage!, onRetry: _loadActivityFeed)
                : RefreshIndicator(
                    onRefresh: _loadActivityFeed,
                    child: _items.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: AppSpacing.xxxl),
                              AppEmptyState(
                                title: 'No Recent Activity',
                                message: 'Ticket events and updates will appear here.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: _items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return InkWell(
                                onTap: () => context.push('/tickets/${item.id}'),
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
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppColors.primary.withAlpha(25),
                                        backgroundImage: item.image != null && item.image!.isNotEmpty
                                            ? NetworkImage(UrlUtils.resolveImageUrl(item.image))
                                            : null,
                                        child: item.image == null || item.image!.isEmpty
                                            ? const Icon(
                                                Icons.notifications_active_outlined,
                                                color: AppColors.primary,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: AppTypography.bodyMedium.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.subTitle,
                                              style: AppTypography.bodySmall.copyWith(
                                                color: isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                            if (item.createdAt != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                item.createdAt!,
                                                style: AppTypography.labelSmall.copyWith(
                                                  color: isDark
                                                      ? AppColors.darkTextMuted
                                                      : AppColors.lightTextMuted,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
      ),
    );
  }
}
