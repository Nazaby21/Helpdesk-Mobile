import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationBellAction extends StatefulWidget {
  const NotificationBellAction({
    super.key,
    required this.apiClient,
    this.notificationRepository,
  });

  final ApiClient apiClient;
  final NotificationRepository? notificationRepository;

  @override
  State<NotificationBellAction> createState() => _NotificationBellActionState();
}

class _NotificationBellActionState extends State<NotificationBellAction> {
  late final NotificationRepository _repository;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.notificationRepository ??
        NotificationRepositoryImpl(apiClient: widget.apiClient);
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      if (!mounted) return;
      setState(() {
        _unreadCount = count;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () async {
        await context.push('/notifications');
        _fetchUnreadCount();
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded),
          if (_unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
