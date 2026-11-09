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
import '../../../tickets/data/repositories/ticket_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.apiClient,
    this.ticketRepository,
    this.notificationRepository,
  });

  final ApiClient? apiClient;
  final TicketRepository? ticketRepository;
  final NotificationRepository? notificationRepository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationRepository _repository;
  List<NotificationModel> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _unreadOnly = false;
  int _currentPage = 0;
  int _totalPages = 1;
  int _unreadCount = 0;
  String? _errorMessage;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _repository = widget.notificationRepository ??
        NotificationRepositoryImpl(apiClient: widget.apiClient ?? ApiClient());
    _loadNotifications(resetPage: true);
  }

  Future<void> _loadNotifications({bool resetPage = true}) async {
    if (resetPage) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 0;
      });
    } else {
      if (_isLoadingMore || _currentPage + 1 >= _totalPages) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    final targetPage = resetPage ? 0 : _currentPage + 1;

    try {
      final pageResult = await _repository.getNotifications(
        page: targetPage,
        size: _pageSize,
        unreadOnly: _unreadOnly,
      );
      int unread = _unreadCount;
      try {
        unread = await _repository.getUnreadCount();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        if (resetPage) {
          _items = pageResult.content;
        } else {
          _items = [..._items, ...pageResult.content];
        }
        _currentPage = pageResult.pageNumber;
        _totalPages = pageResult.totalPages;
        _unreadCount = unread;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _handleTapNotification(NotificationModel item) async {
    if (!item.isRead) {
      try {
        await _repository.markAsRead(item.id);
        if (mounted) {
          setState(() {
            _items = _items
                .map((n) => n.id == item.id ? n.copyWith(isRead: true) : n)
                .toList();
            if (_unreadCount > 0) _unreadCount--;
          });
        }
      } catch (_) {}
    }

    if (!mounted) return;
    if (item.ticketId != null) {
      await context.push('/tickets/${item.ticketId}');
      if (mounted) {
        _loadNotifications(resetPage: true);
      }
    }
  }

  Future<void> _handleMarkOneRead(NotificationModel item) async {
    if (item.isRead) return;
    try {
      await _repository.markAsRead(item.id);
      if (!mounted) return;
      setState(() {
        if (_unreadOnly) {
          _items = _items.where((n) => n.id != item.id).toList();
        } else {
          _items = _items
              .map((n) => n.id == item.id ? n.copyWith(isRead: true) : n)
              .toList();
        }
        if (_unreadCount > 0) _unreadCount--;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as read: $e')),
      );
    }
  }

  Future<void> _handleMarkAllRead() async {
    try {
      await _repository.markAllAsRead();
      if (!mounted) return;
      await _loadNotifications(resetPage: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark all as read: $e')),
      );
    }
  }

  Future<void> _handleDeleteNotification(NotificationModel item) async {
    try {
      await _repository.deleteNotification(item.id);
      if (!mounted) return;
      setState(() {
        _items = _items.where((n) => n.id != item.id).toList();
        if (!item.isRead && _unreadCount > 0) {
          _unreadCount--;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasMore = _currentPage + 1 < _totalPages;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              AppBadge(
                label: '$_unreadCount new',
                variant: AppBadgeVariant.info,
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all_rounded),
              onPressed: _handleMarkAllRead,
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadNotifications(resetPage: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: !_unreadOnly,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: !_unreadOnly ? Colors.white : null,
                      fontWeight:
                          !_unreadOnly ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      if (_unreadOnly) {
                        setState(() => _unreadOnly = false);
                        _loadNotifications(resetPage: true);
                      }
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ChoiceChip(
                    label: Text('Unread ($_unreadCount)'),
                    selected: _unreadOnly,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _unreadOnly ? Colors.white : null,
                      fontWeight:
                          _unreadOnly ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      if (!_unreadOnly) {
                        setState(() => _unreadOnly = true);
                        _loadNotifications(resetPage: true);
                      }
                    },
                  ),
                  const Spacer(),
                  if (_unreadCount > 0)
                    TextButton.icon(
                      onPressed: _handleMarkAllRead,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: AppLoadingIndicator(
                        message: 'Loading notifications...',
                      ),
                    )
                  : _errorMessage != null
                      ? AppErrorState(
                          message: _errorMessage!,
                          onRetry: () => _loadNotifications(resetPage: true),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadNotifications(resetPage: true),
                          child: _items.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: AppSpacing.xxxl),
                                    AppEmptyState(
                                      title: _unreadOnly
                                          ? 'No Unread Notifications'
                                          : 'No Notifications Yet',
                                      message: _unreadOnly
                                          ? 'You have read all your notifications.'
                                          : 'Ticket creation and resolution updates will appear here.',
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  itemCount: _items.length + (hasMore ? 1 : 0),
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: AppSpacing.md),
                                  itemBuilder: (context, index) {
                                    if (index == _items.length) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: AppSpacing.md,
                                          ),
                                          child: _isLoadingMore
                                              ? const CircularProgressIndicator()
                                              : OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _loadNotifications(
                                                    resetPage: false,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.expand_more_rounded,
                                                  ),
                                                  label: Text(
                                                    'Load More (Page ${_currentPage + 1} of $_totalPages)',
                                                  ),
                                                ),
                                        ),
                                      );
                                    }

                                    final item = _items[index];
                                    final isResolved =
                                        item.type == 'TICKET_RESOLVED';

                                    return InkWell(
                                      onTap: () => _handleTapNotification(item),
                                      borderRadius: AppSpacing.borderRadiusLg,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.all(AppSpacing.md),
                                        decoration: BoxDecoration(
                                          color: !item.isRead
                                              ? AppColors.primary.withAlpha(
                                                  isDark ? 35 : 15,
                                                )
                                              : (isDark
                                                  ? AppColors.darkCard
                                                  : AppColors.lightCard),
                                          borderRadius:
                                              AppSpacing.borderRadiusLg,
                                          border: Border.all(
                                            color: !item.isRead
                                                ? AppColors.primary
                                                    .withAlpha(90)
                                                : (isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.lightBorder),
                                          ),
                                          boxShadow: const [AppSpacing.shadow1],
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: (isResolved
                                                      ? AppColors.success
                                                      : AppColors.primary)
                                                  .withAlpha(25),
                                              child: Icon(
                                                isResolved
                                                    ? Icons
                                                        .check_circle_outline_rounded
                                                    : Icons
                                                        .confirmation_number_outlined,
                                                color: isResolved
                                                    ? AppColors.success
                                                    : AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.md,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          item.title,
                                                          style: AppTypography
                                                              .bodyMedium
                                                              .copyWith(
                                                            fontWeight: !item
                                                                    .isRead
                                                                ? FontWeight
                                                                    .w800
                                                                : FontWeight
                                                                    .w600,
                                                            color: isDark
                                                                ? AppColors
                                                                    .darkTextPrimary
                                                                : AppColors
                                                                    .lightTextPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                      if (!item.isRead)
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration:
                                                              const BoxDecoration(
                                                            color: AppColors
                                                                .primary,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item.message,
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                      color: isDark
                                                          ? AppColors
                                                              .darkTextSecondary
                                                          : AppColors
                                                              .lightTextSecondary,
                                                    ),
                                                  ),
                                                  if (item.createdAt !=
                                                      null) ...[
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      item.createdAt!,
                                                      style: AppTypography
                                                          .labelSmall
                                                          .copyWith(
                                                        color: isDark
                                                            ? AppColors
                                                                .darkTextMuted
                                                            : AppColors
                                                                .lightTextMuted,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (!item.isRead)
                                                  IconButton(
                                                    tooltip: 'Mark as read',
                                                    icon: const Icon(
                                                      Icons.check_rounded,
                                                      size: 18,
                                                      color: AppColors.primary,
                                                    ),
                                                    onPressed: () =>
                                                        _handleMarkOneRead(
                                                      item,
                                                    ),
                                                  ),
                                                IconButton(
                                                  tooltip: 'Delete',
                                                  icon: const Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    size: 18,
                                                    color: AppColors.error,
                                                  ),
                                                  onPressed: () =>
                                                      _handleDeleteNotification(
                                                    item,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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
