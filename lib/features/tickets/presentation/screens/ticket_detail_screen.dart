import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/models/ticket_model.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    this.authController,
    this.apiClient,
    this.ticketRepository,
  });

  final String ticketId;
  final AuthController? authController;
  final ApiClient? apiClient;
  final TicketRepository? ticketRepository;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late final TicketRepository _repository;
  TicketModel? _ticket;
  List<ChatMessageModel> _chatMessages = [];
  List<TicketStatusLogModel> _statusLogs = [];
  List<TicketAuditHistoryModel> _auditHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isActionLoading = false;
  bool _isSendingChat = false;
  final _chatInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.ticketRepository != null) {
      _repository = widget.ticketRepository!;
    } else {
      _repository = TicketRepositoryImpl(
        apiClient: widget.apiClient ?? widget.authController?.apiClient ?? ApiClient(),
      );
    }
    _loadTicketDetails();
  }

  @override
  void dispose() {
    _chatInputController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final id = int.tryParse(widget.ticketId);
    if (id == null) {
      setState(() {
        _errorMessage = 'Invalid ticket ID';
        _isLoading = false;
      });
      return;
    }

    try {
      final ticket = await _repository.getTicketById(id);
      List<ChatMessageModel> messages = [];
      List<TicketStatusLogModel> statusLogs = ticket.logs;
      List<TicketAuditHistoryModel> auditHistory = [];

      try {
        messages = await _repository.getTicketMessages(id);
      } catch (_) {}

      try {
        final fetchedLogs = await _repository.getTicketStatusLogs(id);
        if (fetchedLogs.isNotEmpty) {
          statusLogs = fetchedLogs;
        }
      } catch (_) {}

      try {
        auditHistory = await _repository.getTicketAuditHistory(id);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _chatMessages = messages;
        _statusLogs = statusLogs;
        _auditHistory = auditHistory;
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

  Future<void> _handleAcceptTicket() async {
    if (_ticket == null) return;
    setState(() => _isActionLoading = true);

    try {
      final updated = await _repository.updateTicketStatus(
        _ticket!.id,
        status: 'IN_PROGRESS',
        remark: 'Accepted by Technician',
      );
      if (!mounted) return;
      setState(() {
        _ticket = updated;
        _isActionLoading = false;
      });
      _loadTicketDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket accepted and moved to In Progress!'),
          backgroundColor: AppColors.info,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting ticket: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleCloseTicket() async {
    if (_ticket == null) return;

    final remarkController = TextEditingController(text: 'Issue resolved.');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter resolution remark:'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: remarkController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Close Ticket', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      final updated = await _repository.updateTicketStatus(
        _ticket!.id,
        status: 'COMPLETED',
        remark: remarkController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _ticket = updated;
        _isActionLoading = false;
      });
      _loadTicketDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket resolved and completed!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error closing ticket: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleDeleteTicket() async {
    if (_ticket == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Ticket #TCK-${_ticket!.id}?'),
        content: const Text(
          'Are you sure you want to delete this ticket? This action cannot be undone.',
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

    setState(() => _isActionLoading = true);
    try {
      await _repository.deleteTicket(_ticket!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket deleted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete ticket: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _sendChatMessage() async {
    final text = _chatInputController.text.trim();
    if (text.isEmpty || _ticket == null || _isSendingChat) return;

    _chatInputController.clear();
    setState(() => _isSendingChat = true);

    try {
      final saved = await _repository.sendTicketMessage(
        _ticket!.id,
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _chatMessages.add(saved);
        _isSendingChat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingChat = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showImagePreview(String url) {
    final resolvedUrl = UrlUtils.resolveImageUrl(url);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: AppSpacing.borderRadiusLg,
                child: Image.network(resolvedUrl, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  AppBadgeVariant _statusVariant(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return AppBadgeVariant.success;
      case 'IN_PROGRESS':
        return AppBadgeVariant.info;
      case 'PENDING':
      default:
        return AppBadgeVariant.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final role = widget.authController?.state.role ?? UserRole.admin;
    final canManageStatus = role == UserRole.admin || role == UserRole.technician;
    final canEditOrDelete = role == UserRole.admin || role == UserRole.user;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Ticket #${widget.ticketId}')),
        body: const Center(child: AppLoadingIndicator(message: 'Loading ticket details...')),
      );
    }

    if (_errorMessage != null || _ticket == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Ticket #${widget.ticketId}')),
        body: AppErrorState(
          message: _errorMessage ?? 'Ticket not found',
          onRetry: _loadTicketDetails,
        ),
      );
    }

    final ticket = _ticket!;
    final isPending = ticket.status.toUpperCase() == 'PENDING';
    final isInProgress = ticket.status.toUpperCase() == 'IN_PROGRESS';
    final isCompleted = ticket.status.toUpperCase() == 'COMPLETED';

    return Scaffold(
      appBar: AppBar(
        title: Text('#TCK-${ticket.id}'),
        actions: [
          if (!isCompleted && canEditOrDelete) ...[
            IconButton(
              tooltip: 'Edit Ticket',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final updated = await context.push<bool>('/tickets/${ticket.id}/edit');
                if (updated == true) {
                  _loadTicketDetails();
                }
              },
            ),
            IconButton(
              tooltip: 'Delete Ticket',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: _isActionLoading ? null : _handleDeleteTicket,
            ),
          ],
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTicketDetails,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
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
                      children: [
                        AppBadge(
                          label: ticket.status,
                          variant: _statusVariant(ticket.status),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppBadge(
                          label: '${ticket.priority} Priority',
                          variant: ticket.priority.toUpperCase() == 'HIGH'
                              ? AppBadgeVariant.error
                              : AppBadgeVariant.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      ticket.ticketTitle,
                      style: AppTypography.titleLarge.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (ticket.categoryName != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Category: ${ticket.categoryName} ${ticket.subCategoryName != null ? '› ${ticket.subCategoryName}' : ''}',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Requester: ${ticket.createdByName ?? 'User'} • Assigned: ${ticket.assignedName ?? 'Unassigned'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action Buttons (Technician / Admin triage)
              if (canManageStatus && isPending)
                AppButton(
                  text: 'Accept Ticket (Claim)',
                  isLoading: _isActionLoading,
                  onPressed: _handleAcceptTicket,
                )
              else if (canManageStatus && isInProgress)
                ElevatedButton.icon(
                  onPressed: _isActionLoading ? null : _handleCloseTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
                  ),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text(
                    _isActionLoading ? 'Closing...' : 'Close & Resolve Ticket',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                )
              else if (isCompleted)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Ticket resolved and closed.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              // Description section
              Text(
                'Description',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Text(
                  ticket.description.isEmpty ? 'No description provided.' : ticket.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Image Attachments
              if (ticket.imageUrls.isNotEmpty) ...[
                Text(
                  'Attachments (${ticket.imageUrls.length})',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ticket.imageUrls.length,
                    separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final url = UrlUtils.resolveImageUrl(ticket.imageUrls[index]);
                      return InkWell(
                        onTap: () => _showImagePreview(url),
                        borderRadius: AppSpacing.borderRadiusMd,
                        child: ClipRRect(
                          borderRadius: AppSpacing.borderRadiusMd,
                          child: Image.network(
                            url,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Status Transition Logs
              if (_statusLogs.isNotEmpty) ...[
                Text(
                  'Status Timeline (${_statusLogs.length})',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: AppSpacing.borderRadiusLg,
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _statusLogs.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final log = _statusLogs[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 10, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.fromStatus != null
                                      ? '${log.fromStatus} → ${log.toStatus}'
                                      : (log.toStatus ?? 'Status updated'),
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (log.remark != null && log.remark!.isNotEmpty)
                                  Text(
                                    log.remark!,
                                    style: AppTypography.bodySmall,
                                  ),
                                if (log.changedByName != null || log.changedAt != null)
                                  Text(
                                    '${log.changedByName ?? 'System'} • ${log.changedAt ?? ''}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Ticket Audit History
              if (_auditHistory.isNotEmpty) ...[
                Text(
                  'Audit History (${_auditHistory.length})',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: AppSpacing.borderRadiusLg,
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _auditHistory.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final entry = _auditHistory[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.history_edu_rounded, size: 16, color: AppColors.info),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.action}: ${entry.comment}',
                                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (entry.performAt != null)
                                  Text(
                                    entry.performAt!,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Real-Time Chat Conversation
              Text(
                'Discussion & Messages',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    if (_chatMessages.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Text('No comments yet. Send a message below.'),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _chatMessages.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final msg = _chatMessages[index];
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkInput : AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.sender,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    msg.content,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  ),
                                  if (msg.timestamp != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      msg.timestamp!,
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatInputController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onSubmitted: (_) => _sendChatMessage(),
                            ),
                          ),
                          IconButton(
                            icon: _isSendingChat
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded, color: AppColors.primary),
                            onPressed: _isSendingChat ? null : _sendChatMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
